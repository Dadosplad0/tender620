import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tender620/constants.dart';
import 'package:tender620/main.dart';
import 'package:tender620/model/User.dart';
import 'package:tender620/services/FirebaseHelper.dart';
import 'package:tender620/services/helper.dart';
import 'package:tender620/ui/accountDetails/AccountDetailsScreen.dart';
import 'package:tender620/ui/adminDashboard/AdminDashboardScreen.dart';
import 'package:tender620/ui/auth/AuthScreen.dart';
import 'package:tender620/ui/contactUs/ContactUsScreen.dart';
import 'package:tender620/ui/favoriteListings/FavoriteListingsScreen.dart';
import 'package:tender620/ui/myListings/MyListingsScreen.dart';
import 'package:tender620/ui/settings/SettingsScreen.dart';
import 'package:tender620/ui/upgradeAccount/UpgradeAccount.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  ProfileScreen({Key key, @required this.user}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState(user);
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  User user;
  FireStoreUtils _fireStoreUtils = FireStoreUtils();

  _ProfileScreenState(this.user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Platform.isIOS
          ? AppBar(
              title: Text('Profile'),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
            Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 32, right: 32),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                Center(
                    child:
                        displayCircleImage(user.profilePictureURL, 130, false)),
                Positioned(
                  left: 80,
                  right: 0,
                  child: FloatingActionButton(
                      backgroundColor: Color(COLOR_ACCENT),
                      child: Icon(
                        Icons.camera_alt,
                        color:
                            isDarkMode(context) ? Colors.black : Colors.white,
                      ),
                      mini: true,
                      onPressed: _onCameraClick),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 32, left: 32),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                user.fullName(),
                style: TextStyle(
                    color: isDarkMode(context) ? Colors.white : Colors.black,
                    fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              children: skipNulls(<Widget>[
                ListTile(
                  dense: true,
                  onTap: () {
                    push(context, MyListingsScreen());
                  },
                  title: Text(
                    'My Listings',
                    style: TextStyle(fontSize: 16),
                  ),
                  leading: Image.asset(
                    'assets/images/listings_logo.png',
                    height: 24,
                    width: 24,
                    color: Color(COLOR_PRIMARY),
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    push(context, new FavoriteListingScreen());
                  },
                  title: Text(
                    'My Favorites',
                    style: TextStyle(fontSize: 16),
                  ),
                  leading: Icon(
                    Icons.favorite,
                    color: Colors.red,
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    push(context, new AccountDetailsScreen(user: user));
                  },
                  title: Text(
                    'Account Details',
                    style: TextStyle(fontSize: 16),
                  ),
                  leading: Icon(
                    Icons.person,
                    color: Colors.blue,
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) {
                        return UpgradeAccount();
                      },
                    );
                  },
                  title: Text(
                    user.isVip != null && user.isVip
                        ? 'Cancel subscription'
                        : 'Upgrade Account',
                    style: TextStyle(fontSize: 16),
                  ),
                  leading: Image.asset(
                    'assets/images/vip.png',
                    height: 24,
                    width: 24,
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    push(context, new SettingsScreen(user: user));
                  },
                  title: Text(
                    'Settings',
                    style: TextStyle(fontSize: 16),
                  ),
                  leading: Icon(
                    Icons.settings,
                    color:
                        isDarkMode(context) ? Colors.white70 : Colors.black45,
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    push(context, new ContactUsScreen());
                  },
                  title: Text(
                    'Contact Us',
                    style: TextStyle(fontSize: 16),
                  ),
                  leading: Icon(
                    Icons.call,
                    color: Colors.green,
                  ),
                ),
                user.isAdmin
                    ? ListTile(
                        dense: true,
                        onTap: () {
                          push(context, new AdminDashboardScreen());
                        },
                        title: Text(
                          'Admin Dashboard',
                          style: TextStyle(fontSize: 16),
                        ),
                        leading: Icon(
                          Icons.dashboard,
                          color: Colors.blueGrey,
                        ),
                      )
                    : null,
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: FlatButton(
                color: Colors.transparent,
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode(context) ? Colors.white : Colors.black,
                  ),
                ),
                splashColor: isDarkMode(context)
                    ? Colors.grey[700]
                    : Colors.grey.shade200,
                onPressed: () async {
                  user.active = false;
                  user.lastOnlineTimestamp = Timestamp.now();
                  await FireStoreUtils.updateCurrentUser(user);
                  await auth.FirebaseAuth.instance.signOut();
                  user = null;
                  MyAppState.currentUser = null;
                  pushAndRemoveUntil(context, AuthScreen(), false);
                },
                padding: EdgeInsets.only(top: 12, bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  _onCameraClick() {
    final action = CupertinoActionSheet(
      message: Text(
        "Add profile picture",
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Remove Picture"),
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.pop(context);
            showProgress(context, 'Removing picture...', false);
            if (user.profilePictureURL.isNotEmpty)
              await _fireStoreUtils.deleteImage(user.profilePictureURL);
            user.profilePictureURL = '';
            await FireStoreUtils.updateCurrentUser(user);
            MyAppState.currentUser = user;
            hideProgress();
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Choose from gallery"),
          onPressed: () async {
            Navigator.pop(context);
            PickedFile image =
                await _imagePicker.getImage(source: ImageSource.gallery);
            if (image != null) {
              await _imagePicked(File(image.path));
            }
            setState(() {});
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Take a picture"),
          onPressed: () async {
            Navigator.pop(context);
            PickedFile image =
                await _imagePicker.getImage(source: ImageSource.camera);
            if (image != null) {
              await _imagePicked(File(image.path));
            }
            setState(() {});
          },
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  Future<void> _imagePicked(File image) async {
    showProgress(context, 'Uploading image...', false);
    user.profilePictureURL =
        await _fireStoreUtils.uploadUserImageToFireStorage(image, user.userID);
    await FireStoreUtils.updateCurrentUser(user);
    MyAppState.currentUser = user;
    hideProgress();
  }
}
