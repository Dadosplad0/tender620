import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:tender620/constants.dart';
import 'package:tender620/main.dart';
import 'package:tender620/model/HomeConversationModel.dart';
import 'package:tender620/model/MessageData.dart';
import 'package:tender620/model/User.dart';
import 'package:tender620/services/FirebaseHelper.dart';
import 'package:tender620/services/helper.dart';
import 'package:tender620/ui/container/ContainerScreen.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum SignalingState {
  CallStateNew,
  CallStateRinging,
  CallStateInvite,
  CallStateConnected,
  CallStateBye,
  ConnectionOpen,
  ConnectionClosed,
  ConnectionError,
}

/*
 * callbacks for Signaling API.
 */
typedef void SignalingStateCallback(SignalingState state);
typedef void StreamStateCallback(MediaStream stream);
typedef void OtherEventCallback(dynamic event);
typedef void GroupStreamStateCallback(List<MediaStream> listOfStreams);

class GroupVideoCallsHandler {
  Timer countdownTimer;
  var _peerConnections = new Map<String, RTCPeerConnection>();
  var _remoteCandidates = [];
  Map<String, List<dynamic>> _localCandidates = Map();
  List<MediaStreamTrack> _listOfStreams = [];
  StreamSubscription hangupSub;
  Map<String, MediaStream> _remoteStreams = Map();
  Map<String, RTCSessionDescription> _pendingOffers = Map();
  SignalingStateCallback onStateChange;
  StreamStateCallback onLocalStream;
  MediaStream _localStream;
  GroupStreamStateCallback onStreamListUpdate;
  OtherEventCallback onPeersUpdate;
  String _selfId = MyAppState.currentUser.userID;
  final bool isCaller;
  final HomeConversationModel homeConversationModel;
  List<dynamic> _membersJson = [];
  FireStoreUtils _fireStoreUtils = FireStoreUtils();

  StreamSubscription<DocumentSnapshot> messagesStreamSubscription;

  final String callerID;

  bool callStarted = false;
  bool callAnswered = false;

  bool didUserHangup = false;

  GroupVideoCallsHandler(
      {@required this.isCaller,
      this.callerID,
      @required this.homeConversationModel});

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
      {
        'url': 'turn:95.217.132.49:80?transport=udp',
        'username': 'c38d01c8',
        'credential': 'f7bf2454'
      },
      {
        'url': 'turn:95.217.132.49:80?transport=tcp',
        'username': 'c38d01c8',
        'credential': 'f7bf2454'
      },
    ]
  };

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };
  Map<String, StreamSubscription> mapOfUserListener = Map();

  void initCall(String peerID, BuildContext context) async {
    print('GroupVideoCallsHandler.initCall init');
    if (this.onStateChange != null) {
      this.onStateChange(SignalingState.CallStateNew);
    }
    _localStream = await createStream();
    listenForMessages();
    homeConversationModel.members.forEach((element) {
      print('GroupVideoCallsHandler.initCall ${element.fullName()}');
      _membersJson.add(element.toJson());
    });
    await Future.forEach(homeConversationModel.members,
        (User groupMember) async {
      print('GroupVideoCallsHandler.initCall ${groupMember.fullName()} '
          '${homeConversationModel.members.length}');
      _createPeerConnection(getConnectionID(groupMember.userID))
          .then((pc) async {
        _peerConnections[getConnectionID(groupMember.userID)] = pc;
        if (isCaller) {
          await _createOffer(groupMember.userID, pc, context);
        }
      });
    });
    if (isCaller) {
      startCountDown(context);
      updateChat(context);
    }
  }

  close() async {
    callAnswered = false;
    callStarted = false;
    if (_localStream != null) {
      _localStream.dispose();
      _localStream = null;
    }
    _peerConnections.forEach((key, pc) {
      pc.close();
    });

    mapOfUserListener.forEach((key, value) => value.cancel());
    if (messagesStreamSubscription != null) {
      messagesStreamSubscription.cancel();
    }
  }

  String getConnectionID(String friendID) {
    String connectionID;
    if (friendID.compareTo(this._selfId) < 0) {
      connectionID = friendID + this._selfId;
    } else {
      connectionID = this._selfId + friendID;
    }
    return connectionID;
  }

  void bye() async {
    print('VideoCallsHandler.bye');
    if (isCaller && !callStarted) {
      await closeBeforeAnyoneAnswer();
    } else {
      print('GroupVideoCallsHandler.bye callStarted');
      await FireStoreUtils.firestore
          .collection(USERS)
          .doc(_selfId)
          .collection(CALL_DATA)
          .doc(isCaller ? _selfId : callerID)
          .get(GetOptions(source: Source.server))
          .then((value) async {
        var byeRequest = value.data();
        print('GroupVideoCallsHandler.bye then((value) async');
        byeRequest['hangup'] = true;
        byeRequest['connections'] =
            (value.data()['connections'] as Map<String, dynamic>)..clear();

        DocumentReference documentReference = FireStoreUtils.firestore
            .collection(USERS)
            .doc(_selfId)
            .collection(CALL_DATA)
            .doc(isCaller ? _selfId : callerID);
        if (byeRequest != null) {
          await documentReference.set(byeRequest);
          print('GroupVideoCallsHandler.bye documentReference.setData'
              '(${byeRequest['connections']} ${byeRequest['hangup']})');
        } else {
          await documentReference.delete();
          print('GroupVideoCallsHandler.bye documentReference.delete()');
        }
      });
    }
  }

  void onMessage(Map<String, dynamic> message, String connectionID) async {
    Map<String, dynamic> mapData = message;
    var connections = mapData['connections'];
    var data = connections[connectionID];
    if (isCaller || callStarted && callAnswered) {
      if (mapData.containsKey('hangup') &&
          (mapData['hangup'] ?? false) == true) {
        print('GroupVideoCallsHandler.onMessage hangup');
        if (_peerConnections.containsKey(connectionID) &&
            _peerConnections[connectionID] != null) {
          _peerConnections[connectionID].close();
          _peerConnections[connectionID] = null;
          _peerConnections.remove(connectionID);
        }
        if (_remoteStreams.containsKey(connectionID) &&
            _remoteStreams[connectionID] != null) {
          _listOfStreams
              .remove(_remoteStreams[connectionID].getVideoTracks().first);
          _remoteStreams.remove(connectionID);
          if (this.onStreamListUpdate != null)
            this.onStreamListUpdate(_remoteStreams.values.toList());
        }
        print('GroupVideoCallsHandler.onMessage ${_peerConnections.length}');
        if (_peerConnections.length == 1) {
          await _deleteMyCallFootprint();
        }
      }
    }
    print('GroupVideoCallsHandler.onMessage $connectionID');
    if (data != null)
      switch (data['type']) {
        case 'offer':
          {
            var id = data['from'];
            if (id != _selfId) {
              print('VideoCallsHandler.onMessage offer');
            } else {
              print('VideoCallsHandler.onMessage you offered a call');
            }
            if (!isCaller) {
              await _onOfferReceivedFromOtherClient(
                  data['description'], connectionID);
            }
          }
          break;
        case 'answer':
          {
            if (countdownTimer.isActive) countdownTimer.cancel();
            callStarted = true;
            callAnswered = true;
            print('VideoCallsHandler.onMessage answer $connectionID');
            var description = data['description'];
            if (this.onStateChange != null)
              this.onStateChange(SignalingState.CallStateConnected);
            var pc = _peerConnections[connectionID];
            print('${pc == null} is null');
            if (pc != null) {
              await pc.setRemoteDescription(new RTCSessionDescription(
                  description['sdp'], description['type']));
            }

            await _sendCandidate(connectionID);
          }
          break;
        case 'candidate':
          {
            if (callStarted && callAnswered) {
              print('VideoCallsHandler.onMessage candidate');
              List<dynamic> candidates = data['candidate'];
              var pc = _peerConnections[connectionID];
              await Future.forEach(candidates, (candidateMap) async {
                RTCIceCandidate candidate = new RTCIceCandidate(
                    candidateMap['candidate'],
                    candidateMap['sdpMid'],
                    candidateMap['sdpMLineIndex']);
                if (pc != null) {
                  await pc.addCandidate(candidate);
                } else {
                  _remoteCandidates.add(candidate);
                }
              });

              if (this.onStateChange != null)
                this.onStateChange(SignalingState.CallStateConnected);

              if (!isCaller) {
                await _sendCandidate(connectionID);
              }
            }
          }
          break;
        default:
          break;
      }
  }

  Future<MediaStream> createStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth':
              '640', // Provide your own width, height and frame rate here
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };

    MediaStream stream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    if (this.onLocalStream != null) {
      this.onLocalStream(stream);
    }
    return stream;
  }

  Future<RTCPeerConnection> _createPeerConnection(String connectionID) async {
    RTCPeerConnection pc = await createPeerConnection(_iceServers, _config);
    pc.addStream(_localStream);
    _localCandidates[connectionID] = <dynamic>[];
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      _localCandidates[connectionID].add(candidate.toMap());
    };
    pc.onAddStream = (stream) {
      _remoteStreams[connectionID] = stream;
      _listOfStreams.add(_remoteStreams[connectionID].getVideoTracks().first);
      if (this.onStreamListUpdate != null)
        this.onStreamListUpdate(_remoteStreams.values.toList());
    };
    pc.onRemoveStream = (stream) {
      _remoteStreams.values
          .toList()
          .removeWhere((MediaStream it) => it.id == stream.id);
      _listOfStreams.removeWhere((element) => element.id == stream.id);
      if (this.onStreamListUpdate != null)
        this.onStreamListUpdate(_remoteStreams.values.toList());
    };
    return pc;
  }

  _createOffer(String id, RTCPeerConnection pc, BuildContext context) async {
    try {
      RTCSessionDescription offer = await pc.createOffer(_constraints);
      pc.setLocalDescription(offer);
      await _sendOffer({
        'to': id,
        'from': _selfId,
        'description': {'sdp': offer.sdp, 'type': offer.type},
        'type': 'offer',
      }, context: context);
    } catch (e) {
      print(e.toString());
    }
  }

  _createAnswer(String id, RTCPeerConnection pc) async {
    try {
      RTCSessionDescription s = await pc.createAnswer(_constraints);
      pc.setLocalDescription(s);
      await _sendAnswer({
        'to': id.replaceAll(_selfId, ''),
        'from': _selfId,
        'description': {'sdp': s.sdp, 'type': s.type},
        'type': 'answer',
      });
    } catch (e) {
      print(e.toString());
    }
  }

  _sendOffer(Map<String, dynamic> data, {BuildContext context}) async {
    var request = new Map<String, dynamic>();
    print('GroupVideoCallsHandler._sendOffer to ${data['to']} from $_selfId');
    request["connections"] = {getConnectionID(data['to']): data};
    if (isCaller) {
      request['type'] = 'offer';
      request['isGroupCall'] = true;
      request['callType'] = VIDEO;
      request['members'] = _membersJson;
      request['conversationModel'] =
          homeConversationModel.conversationModel.toJson();
      await FireStoreUtils.firestore
          .collection(USERS)
          .doc(data['to'])
          .collection(CALL_DATA)
          .get(GetOptions(source: Source.server))
          .then((value) async {
        if (value.docs.isEmpty) {
          await FireStoreUtils.firestore
              .collection(USERS)
              .doc(data['to'])
              .collection(CALL_DATA)
              .doc(_selfId)
              .set(request);
        } else {
          showAlertDialog(context, 'Call', 'this user has an on-going call');
        }
      });
    } else {
      FireStoreUtils.firestore
          .collection(USERS)
          .doc(_selfId)
          .collection(CALL_DATA)
          .doc(callerID)
          .get(GetOptions(source: Source.server))
          .then((value) async {
        Map<String, dynamic> connections = value.data()['connections'];
        connections[getConnectionID(data['to'])] = data;
        request["connections"] = connections;
        await FireStoreUtils.firestore
            .collection(USERS)
            .doc(_selfId)
            .collection(CALL_DATA)
            .doc(callerID)
            .set(request, SetOptions(merge: true));
      });
    }
  }

  listenForMessages() {
    for (User member in homeConversationModel.members) {
      if (member.userID != _selfId) {
        Stream<DocumentSnapshot> messagesStream = FireStoreUtils.firestore
            .collection(USERS)
            .doc(member.userID)
            .collection(CALL_DATA)
            .doc(callerID)
            .snapshots();
        mapOfUserListener[getConnectionID(member.userID)] =
            messagesStream.listen((call) {
          print(
              'GroupVideoCallsHandler.listenForMessages ${getConnectionID(member.userID)}');
          if (call != null && call.exists) {
            onMessage(call.data(), getConnectionID(member.userID));
          } else {
            if (!isCaller &&
                !call.exists &&
                !callStarted &&
                getConnectionID(member.userID).contains(callerID)) {
              print('GroupVideoCallsHandler.listenForMessages caller '
                  'hangup');
              if (!didUserHangup) {
                didUserHangup = true;
                countdownTimer.cancel();
                ContainerScreen.onGoingCall = false;
                callStarted = false;
                callAnswered = false;
                if (this.onStateChange != null)
                  this.onStateChange(SignalingState.CallStateBye);
              }
            }
          }
        });
      }
    }
  }

  void startCountDown(BuildContext context) {
    print('VideoCallsHandler.startCountDown');
    countdownTimer = new Timer(Duration(minutes: 1), () {
      print('VideoCallsHandler.startCountDown periodic');
      bye();
      if (!isCaller) {
        print('FlutterRingtonePlayer _hangUp lets stop');
        FlutterRingtonePlayer.stop();
      }
      Navigator.of(context).pop();
    });
  }

  acceptCall(String sessionDescription, String sessionType) async {
    if (this.onStateChange != null) {
      this.onStateChange(SignalingState.CallStateNew);
    }
    callAnswered = true;
    String id = getConnectionID(callerID);
    RTCPeerConnection pc = _peerConnections[id];
    await pc.setRemoteDescription(
        new RTCSessionDescription(sessionDescription, sessionType));
    await _createAnswer(id, pc);
    await establishConnectionWithOtherClients();
    await respondToPendingOffers();

//    if (this._remoteCandidates.length > 0) {
//      _remoteCandidates.forEach((candidate) async {
//        await pc.addCandidate(candidate);
//      });
//      _remoteCandidates.clear();
//    }
  }

  _sendAnswer(Map<String, dynamic> data) async {
    callStarted = true;
    print('GroupVideoCallsHandler._sendAnswer $_selfId ${data['to']}');
    var request = new Map<String, dynamic>();
    FireStoreUtils.firestore
        .collection(USERS)
        .doc(_selfId)
        .collection(CALL_DATA)
        .doc(callerID)
        .get(GetOptions(source: Source.server))
        .then((callDocument) async {
      Map<String, dynamic> connections =
          callDocument.data()['connections'] ?? Map<String, dynamic>();
      connections[getConnectionID(data['to'])] = data;
      request['type'] = 'answer';
      request['isGroupCall'] = true;
      request['callType'] = VIDEO;
      request['members'] = _membersJson;
      request['conversationModel'] =
          homeConversationModel.conversationModel.toJson();
      request['connections'] = connections;

      await FireStoreUtils.firestore
          .collection(USERS)
          .doc(_selfId)
          .collection(CALL_DATA)
          .doc(callerID)
          .set(request, SetOptions(merge: true));
    });
  }

  _sendCandidate(String connectionID) async {
    print('GroupVideoCallsHandler._sendCandidate $connectionID');
    String receiverID = connectionID.replaceAll(_selfId, '');
    var request = new Map<String, dynamic>();
    var data = new Map<String, dynamic>();

    data['type'] = 'candidate';
    data['candidate'] = _localCandidates[connectionID];
    data['from'] = _selfId;
    data['to'] = receiverID;

    FireStoreUtils.firestore
        .collection(USERS)
        .doc(isCaller ? receiverID : _selfId)
        .collection(CALL_DATA)
        .doc(callerID)
        .get(GetOptions(source: Source.server))
        .then((value) async {
      Map<String, dynamic> connections =
          value.data()['connections'] ?? Map<String, dynamic>();
      connections[connectionID] = data;
      request['type'] = 'candidate';
      request['isGroupCall'] = true;
      request['callType'] = VIDEO;
      request['members'] = _membersJson;
      request['conversationModel'] =
          homeConversationModel.conversationModel.toJson();
      request['connections'] = connections;
      await FireStoreUtils.firestore
          .collection(USERS)
          .doc(_selfId)
          .collection(CALL_DATA)
          .doc(callerID)
          .set(request);
    });
  }

  void updateChat(BuildContext context) async {
    MessageData message = MessageData(
        content: '${MyAppState.currentUser.fullName()} Started a group video '
            'call.',
        created: Timestamp.now(),
        senderFirstName: MyAppState.currentUser.firstName,
        senderID: MyAppState.currentUser.userID,
        senderLastName: MyAppState.currentUser.lastName,
        senderProfilePictureURL: MyAppState.currentUser.profilePictureURL,
        url: Url(mime: '', url: ''),
        videoThumbnail: '');

    await _fireStoreUtils.sendMessage(
        homeConversationModel.members,
        homeConversationModel.isGroupChat,
        message,
        homeConversationModel.conversationModel);
    homeConversationModel.conversationModel.lastMessageDate = Timestamp.now();
    homeConversationModel.conversationModel.lastMessage = message.content;

    await _fireStoreUtils
        .updateChannel(homeConversationModel.conversationModel);
  }

  closeBeforeAnyoneAnswer() async {
    print('GroupVideoCallsHandler.closeBeforeAnyoneAnswer');
    await Future.forEach(homeConversationModel.members, (element) {
      FireStoreUtils.firestore
          .collection(USERS)
          .doc(element.userID)
          .collection(CALL_DATA)
          .doc(_selfId)
          .delete();
    });
  }

  establishConnectionWithOtherClients() {
    print('GroupVideoCallsHandler.establishConnectionWithOtherClients');
    homeConversationModel.members.forEach((client) {
      String receiverID = client.userID;
      if (receiverID != callerID && _selfId.compareTo(receiverID) < 0) {
        print('GroupVideoCallsHandler.establishConnectionWithOtherClients '
            'sending offer $_selfId $receiverID');
        FireStoreUtils.firestore
            .collection(USERS)
            .doc(_selfId)
            .collection(CALL_DATA)
            .doc(callerID)
            .get(GetOptions(source: Source.server))
            .then((value) async {
          Map<String, dynamic> connections = value.data()['connections'];
          if (!connections.containsKey(getConnectionID(receiverID))) {
            RTCPeerConnection pc =
                _peerConnections[getConnectionID(receiverID)];
            RTCSessionDescription offer = await pc.createOffer(_constraints);
            pc.setLocalDescription(offer);
            await _sendOffer({
              'to': receiverID,
              'from': _selfId,
              'description': {'sdp': offer.sdp, 'type': offer.type},
              'type': 'offer',
            });
          }
        });
      }
    });
  }

  _deleteMyCallFootprint() async {
    print('GroupVideoCallsHandler._deleteMyCallFootprint '
        '${homeConversationModel.members.length}');
    await Future.forEach(homeConversationModel.members, (member) async {
      print('GroupVideoCallsHandler._deleteMyCallFootprint${member.userID}');
      await FireStoreUtils.firestore
          .collection(USERS)
          .doc(member.userID)
          .collection(CALL_DATA)
          .doc(isCaller ? _selfId : callerID)
          .delete();
      print('GroupVideoCallsHandler._deleteMyCallFootprint ${member.userID}');
    });
    ContainerScreen.onGoingCall = false;
    callStarted = false;
    callAnswered = false;
    if (this.onStateChange != null)
      this.onStateChange(SignalingState.CallStateBye);
  }

  _onOfferReceivedFromOtherClient(
      Map<String, dynamic> description, String connectionID) async {
    if (callAnswered) {
      RTCPeerConnection pc = _peerConnections[connectionID];
      await pc.setRemoteDescription(
          RTCSessionDescription(description['sdp'], description['type']));
      _createAnswer(connectionID, pc);
    } else {
      _pendingOffers[connectionID] =
          RTCSessionDescription(description['sdp'], description['type']);
    }
  }

  respondToPendingOffers() async {
    await Future.forEach(_pendingOffers.entries, (MapEntry element) async {
      print('GroupVideoCallsHandler.respondToPendingOffers ${element.key}');
      RTCPeerConnection pc = _peerConnections[element.key];
      await pc?.setRemoteDescription(element.value);
      await _createAnswer(element.key, pc);
    });
  }
}
