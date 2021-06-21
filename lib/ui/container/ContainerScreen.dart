import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tender620/constants.dart';
import 'package:tender620/main.dart';
import 'package:tender620/model/ConversationModel.dart';
import 'package:tender620/model/HomeConversationModel.dart';
import 'package:tender620/model/User.dart';
import 'package:tender620/services/FirebaseHelper.dart';
import 'package:tender620/services/helper.dart';
import 'package:tender620/ui/addListing/AddListingScreen.dart';
import 'package:tender620/ui/categories/CategoriesScreen.dart';
import 'package:tender620/ui/conversationsScreen/ConversationsScreen.dart';
import 'package:tender620/ui/home/HomeScreen.dart';
import 'package:tender620/ui/mapView/MapViewScreen.dart';
import 'package:tender620/ui/profile/ProfileScreen.dart';
import 'package:tender620/ui/search/SearchScreen.dart';
import 'package:tender620/ui/videoCall/VideoCallScreen.dart';
import 'package:tender620/ui/videoCallsGroupChat/VideoCallsGroupScreen.dart';
import 'package:tender620/ui/voiceCall/VoiceCallScreen.dart';
import 'package:tender620/ui/voiceCallsGroupChat/VoiceCallsGroupScreen.dart';
import 'package:provider/provider.dart';

enum DrawerSelection { Home, Conversations, Categories, Search, Profile }

class ContainerScreen extends StatefulWidget {
  final User user;
  static bool onGoingCall = false;

  ContainerScreen({Key key, @required this.user}) : super(key: key);

  @override
  _ContainerState createState() {
    return _ContainerState(user);
  }
}

class _ContainerState extends State<ContainerScreen> {
  final User user;
  DrawerSelection _drawerSelection = DrawerSelection.Home;
  String _appBarTitle = 'Home';

  int _selectedTapIndex = 0;

  _ContainerState(this.user);

  Widget _currentWidget;

  @override
  void initState() {
    super.initState();
    _currentWidget = HomeScreen();
    if (CALLS_ENABLED) _listenForCalls();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: user,
      child: Scaffold(
        bottomNavigationBar: Platform.isIOS
            ? BottomNavigationBar(
                currentIndex: _selectedTapIndex,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      {
                        setState(() {
                          _selectedTapIndex = 0;
                          _drawerSelection = DrawerSelection.Home;
                          _appBarTitle = 'Home';
                          _currentWidget = HomeScreen();
                        });
                        break;
                      }
                    case 1:
                      {
                        setState(() {
                          _selectedTapIndex = 1;
                          _drawerSelection = DrawerSelection.Categories;
                          _appBarTitle = 'Categories';
                          _currentWidget = CategoriesScreen();
                        });
                        break;
                      }
                    case 2:
                      {
                        setState(() {
                          _selectedTapIndex = 2;
                          _drawerSelection = DrawerSelection.Conversations;
                          _appBarTitle = 'Conversations';
                          _currentWidget = ConversationsScreen(
                            user: user,
                          );
                        });
                        break;
                      }
                    case 3:
                      {
                        setState(() {
                          _selectedTapIndex = 3;
                          _drawerSelection = DrawerSelection.Search;
                          _appBarTitle = 'Search';
                          _currentWidget = SearchScreen();
                        });
                        break;
                      }
                  }
                },
                unselectedItemColor: Colors.grey,
                selectedItemColor: Color(COLOR_PRIMARY),
                items: [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.category), label: 'Categories'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.message), label: 'Conversations'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.search), label: 'Search'),
                  ])
            : null,
        drawer: Platform.isIOS
            ? null
            : Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    Consumer<User>(
                      builder: (context, user, _) {
                        return DrawerHeader(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              displayCircleImage(
                                  user.profilePictureURL, 75, false),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  user.fullName(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    user.email,
                                    style: TextStyle(color: Colors.white),
                                  )),
                            ],
                          ),
                          decoration: BoxDecoration(
                            color: Color(COLOR_PRIMARY),
                          ),
                        );
                      },
                    ),
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected: _drawerSelection == DrawerSelection.Home,
                        title: Text('Home'),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.Home;
                            _appBarTitle = 'Home';
                            _currentWidget = HomeScreen();
                          });
                        },
                        leading: Icon(Icons.home),
                      ),
                    ),
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                          selected:
                              _drawerSelection == DrawerSelection.Categories,
                          leading: Icon(Icons.category),
                          title: Text('Categories'),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _drawerSelection = DrawerSelection.Categories;
                              _appBarTitle = 'Categories';
                              _currentWidget = CategoriesScreen();
                            });
                          }),
                    ),
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                        selected:
                            _drawerSelection == DrawerSelection.Conversations,
                        leading: Icon(Icons.message),
                        title: Text('Conversations'),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _drawerSelection = DrawerSelection.Conversations;
                            _appBarTitle = 'Conversations';
                            _currentWidget = ConversationsScreen(
                              user: user,
                            );
                          });
                        },
                      ),
                    ),
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                          selected: _drawerSelection == DrawerSelection.Search,
                          title: Text('Search'),
                          leading: Icon(Icons.search),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _drawerSelection = DrawerSelection.Search;
                              _appBarTitle = 'Search';
                              _currentWidget = SearchScreen();
                            });
                          }),
                    ),
                    ListTileTheme(
                      style: ListTileStyle.drawer,
                      selectedColor: Color(COLOR_PRIMARY),
                      child: ListTile(
                          selected: _drawerSelection == DrawerSelection.Profile,
                          title: Text('Profile'),
                          leading: Icon(Icons.account_circle),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _drawerSelection = DrawerSelection.Profile;
                              _appBarTitle = 'Profile';
                              _currentWidget = ProfileScreen(
                                user: MyAppState.currentUser,
                              );
                            });
                          }),
                    ),
                  ],
                ),
              ),
        appBar: AppBar(
          leading: Platform.isIOS
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).push(new MaterialPageRoute(
                          builder: (context) => ProfileScreen(user: user)));
                      setState(() {});
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(360),
                      child: FadeInImage(
                          fit: BoxFit.cover,
                          placeholder:
                              Image.asset('assets/images/placeholder.jpg')
                                  .image,
                          image: NetworkImage(
                            user.profilePictureURL,
                          )),
                    ),
                  ),
                )
              : null,
          actions: skipNulls([
            _currentWidget is HomeScreen
                ? IconButton(
                    tooltip: 'Add Listing',
                    icon: Icon(
                      Icons.add,
                    ),
                    onPressed: () => push(context, AddListingScreen()))
                : null,
            _currentWidget is HomeScreen
                ? IconButton(
                    tooltip: 'Map',
                    icon: Icon(
                      Icons.map,
                    ),
                    onPressed: () => push(
                      context,
                      MapViewScreen(
                        listings: HomeScreenState.listings,
                        fromHome: true,
                      ),
                    ),
                  )
                : null
          ]),
          title: Text(
            _appBarTitle,
          ),
        ),
        body: _currentWidget,
      ),
    );
  }

  void _listenForCalls() {
    Stream callStream = FireStoreUtils.firestore
        .collection(USERS)
        .doc(user.userID)
        .collection(CALL_DATA)
        .snapshots();
    // ignore: cancel_subscriptions
    final callSubscription = callStream.listen((event) async {
      if (event.docs.isNotEmpty) {
        DocumentSnapshot callDocument = event.docs.first;
        if (callDocument.id != user.userID) {
          DocumentSnapshot userSnapShot = await FireStoreUtils.firestore
              .collection(USERS)
              .doc(event.docs.first.id)
              .get();
          User caller = User.fromJson(userSnapShot.data());
          print('${caller.fullName()} called you');
          print('${callDocument.data()['type'] ?? 'null'}');
          String type = callDocument.data()['type'] ?? '';
          bool isGroupCall = callDocument.data()['isGroupCall'] ?? false;
          String callType = callDocument.data()['callType'] ?? '';
          Map<String, dynamic> connections =
              callDocument.data()['connections'] ?? Map<String, dynamic>();
          List<dynamic> groupCallMembers =
              callDocument.data()['members'] ?? <dynamic>[];
          if (type == 'offer') {
            if (callType == VIDEO) {
              if (isGroupCall) {
                if (!ContainerScreen.onGoingCall &&
                    connections.keys.contains(getConnectionID(caller.userID)) &&
                    connections[getConnectionID(caller.userID)]['description']
                            ['type'] ==
                        'offer') {
                  ContainerScreen.onGoingCall = true;
                  List<User> members = [];
                  groupCallMembers.forEach((element) {
                    members.add(User.fromJson(element));
                  });
                  push(
                    context,
                    VideoCallsGroupScreen(
                        homeConversationModel: HomeConversationModel(
                            isGroupChat: true,
                            conversationModel: ConversationModel.fromJson(
                                callDocument.data()['conversationModel']),
                            members: members),
                        isCaller: false,
                        caller: caller,
                        sessionDescription:
                            connections[getConnectionID(caller.userID)]
                                ['description']['sdp'],
                        sessionType: connections[getConnectionID(caller.userID)]
                            ['description']['type']),
                  );
                }
              } else {
                push(
                  context,
                  VideoCallScreen(
                      homeConversationModel: HomeConversationModel(
                          isGroupChat: false,
                          conversationModel: null,
                          members: [caller]),
                      isCaller: false,
                      sessionDescription: callDocument.data()['data']
                          ['description']['sdp'],
                      sessionType: callDocument.data()['data']['description']
                          ['type']),
                );
              }
            } else if (callType == VOICE) {
              if (isGroupCall) {
                if (!ContainerScreen.onGoingCall &&
                    connections.keys.contains(getConnectionID(caller.userID)) &&
                    connections[getConnectionID(caller.userID)]['description']
                            ['type'] ==
                        'offer') {
                  ContainerScreen.onGoingCall = true;
                  List<User> members = [];
                  groupCallMembers.forEach((element) {
                    members.add(User.fromJson(element));
                  });
                  push(
                    context,
                    VoiceCallsGroupScreen(
                        homeConversationModel: HomeConversationModel(
                            isGroupChat: true,
                            conversationModel: ConversationModel.fromJson(
                                callDocument.data()['conversationModel']),
                            members: members),
                        isCaller: false,
                        caller: caller,
                        sessionDescription:
                            connections[getConnectionID(caller.userID)]
                                ['description']['sdp'],
                        sessionType: connections[getConnectionID(caller.userID)]
                            ['description']['type']),
                  );
                }
              } else {
                push(
                  context,
                  VoiceCallScreen(
                      homeConversationModel: HomeConversationModel(
                          isGroupChat: false,
                          conversationModel: null,
                          members: [caller]),
                      isCaller: false,
                      sessionDescription: callDocument.data()['data']
                          ['description']['sdp'],
                      sessionType: callDocument.data()['data']['description']
                          ['type']),
                );
              }
            }
          }
        } else {
          print('you called someone');
        }
      }
    });
    auth.FirebaseAuth.instance.authStateChanges().listen((event) {
      if (event == null) {
        callSubscription.cancel();
      }
    });
  }

  String getConnectionID(String friendID) {
    String connectionID;
    String selfID = MyAppState.currentUser.userID;
    if (friendID.compareTo(selfID) < 0) {
      connectionID = friendID + selfID;
    } else {
      connectionID = selfID + friendID;
    }
    return connectionID;
  }
}
