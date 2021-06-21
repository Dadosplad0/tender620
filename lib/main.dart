import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:tender620/constants.dart';
import 'package:tender620/services/FirebaseHelper.dart';
import 'package:tender620/services/helper.dart';
import 'package:tender620/ui/auth/AuthScreen.dart';
import 'package:tender620/ui/container/ContainerScreen.dart';
import 'package:tender620/ui/onBoarding/OnBoardingScreen.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/User.dart';

void main() {
  InAppPurchaseConnection.enablePendingPurchases();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static User currentUser;
  StreamSubscription tokenStream;

  // Set default `_initialized` and `_error` state to false
  bool _initialized = false;
  bool _error = false;

  // Define an async function to initialize FlutterFire
  void initializeFlutterFire() async {
    try {
      // Wait for Firebase to initialize and set `_initialized` state to true
      await Firebase.initializeApp();
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error message if initialization failed
    if (_error) {
      return Container(
        color: Colors.white,
        child: Center(
            child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 25,
            ),
            SizedBox(height: 16),
            Text(
              'Failed to initialise firebase!',
              style: TextStyle(color: Colors.red, fontSize: 25),
            ),
          ],
        )),
      );
    }
    // Show a loader until FlutterFire is initialized
    if (!_initialized) {
      return Container(
        color: Colors.white,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    AppBarTheme _lightAndroidBar = AppBarTheme(
        centerTitle: true,
        color: Color(COLOR_PRIMARY),
        iconTheme: IconThemeData(color: Colors.white),
        textTheme: TextTheme(
            headline6: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                letterSpacing: 0,
                fontWeight: FontWeight.w500)),
        brightness: Brightness.light);

    AppBarTheme _darkAndroidBar = AppBarTheme(
        centerTitle: true,
        color: Color(COLOR_PRIMARY),
        iconTheme: IconThemeData(color: Colors.black),
        textTheme: TextTheme(
            headline6: TextStyle(
                color: Colors.black,
                fontSize: 20.0,
                letterSpacing: 0,
                fontWeight: FontWeight.w500)),
        brightness: Brightness.dark);

    AppBarTheme _lightIOSBar = AppBarTheme(
        centerTitle: true,
        color: Colors.transparent,
        elevation: 0,
        actionsIconTheme: IconThemeData(color: Color(COLOR_PRIMARY)),
        iconTheme: IconThemeData(color: Color(COLOR_PRIMARY)),
        textTheme: TextTheme(
            headline6: TextStyle(
                color: Color(COLOR_PRIMARY),
                fontSize: 20.0,
                letterSpacing: 0,
                fontWeight: FontWeight.w500)),
        brightness: Brightness.light);
    AppBarTheme _darkIOSBar = AppBarTheme(
        centerTitle: true,
        color: Colors.transparent,
        elevation: 0,
        actionsIconTheme: IconThemeData(color: Color(COLOR_PRIMARY)),
        iconTheme: IconThemeData(color: Color(COLOR_PRIMARY)),
        textTheme: TextTheme(
            headline6: TextStyle(
                color: Color(COLOR_PRIMARY),
                fontSize: 20.0,
                letterSpacing: 0,
                fontWeight: FontWeight.w500)),
        brightness: Brightness.dark);
    return MaterialApp(
        title: 'FlutterListings',
        theme: ThemeData(
            primaryColor: Color(COLOR_PRIMARY),
            cursorColor: Color(COLOR_PRIMARY_DARK),
            appBarTheme: Platform.isAndroid ? _lightAndroidBar : _lightIOSBar,
            bottomSheetTheme: BottomSheetThemeData(
                backgroundColor: Colors.white.withOpacity(.9)),
            accentColor: Color(COLOR_PRIMARY),
            brightness: Brightness.light),
        darkTheme: ThemeData(
            primaryColor: Color(COLOR_PRIMARY),
            cursorColor: Color(COLOR_PRIMARY_DARK),
            appBarTheme: Platform.isAndroid ? _darkAndroidBar : _darkIOSBar,
            bottomSheetTheme: BottomSheetThemeData(
                backgroundColor: Colors.black12.withOpacity(.3)),
            accentColor: Color(COLOR_PRIMARY),
            brightness: Brightness.dark),
        debugShowCheckedModeBanner: false,
        color: Color(COLOR_PRIMARY),
        home: OnBoarding());
  }

  @override
  void initState() {
    initializeFlutterFire();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    FireStoreUtils.firebaseMessaging.configure(
      onBackgroundMessage: Platform.isIOS ? null : backgroundMessageHandler,
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
    );
    FireStoreUtils.firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(
            sound: true, badge: true, alert: true, provisional: true));
    FireStoreUtils.firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    tokenStream =
        FireStoreUtils.firebaseMessaging.onTokenRefresh.listen((event) {
      if (currentUser != null && event != null) {
        currentUser.fcmToken = event;
        FireStoreUtils.updateCurrentUser(currentUser);
      }
    });
  }

  @override
  void dispose() {
    tokenStream.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (auth.FirebaseAuth.instance.currentUser != null && currentUser != null) {
      if (state == AppLifecycleState.paused) {
        //user offline
        tokenStream.pause();
        currentUser.active = false;
        currentUser.lastOnlineTimestamp = Timestamp.now();
        FireStoreUtils.updateCurrentUser(currentUser);
      } else if (state == AppLifecycleState.resumed) {
        //user online
        tokenStream.resume();
        currentUser.active = true;
        FireStoreUtils.updateCurrentUser(currentUser);
      }
    }
  }
}

class OnBoarding extends StatefulWidget {
  @override
  State createState() {
    return OnBoardingState();
  }
}

class OnBoardingState extends State<OnBoarding> {
  Future hasFinishedOnBoarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool finishedOnBoarding = (prefs.getBool(FINISHED_ON_BOARDING) ?? false);

    if (finishedOnBoarding) {
      auth.User firebaseUser = auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        User user = await FireStoreUtils().getCurrentUser(firebaseUser.uid);
        if (user != null) {
          user.active = true;
          await FireStoreUtils.updateCurrentUser(user);
          MyAppState.currentUser = user;
          pushReplacement(context, new ContainerScreen(user: user));
        } else {
          pushReplacement(context, new AuthScreen());
        }
      } else {
        pushReplacement(context, new AuthScreen());
      }
    } else {
      pushReplacement(context, new OnBoardingScreen());
    }
  }

  @override
  void initState() {
    super.initState();
    hasFinishedOnBoarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(COLOR_PRIMARY),
      body: Center(
        child: CircularProgressIndicator(
          backgroundColor: isDarkMode(context) ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

Future<dynamic> backgroundMessageHandler(Map<String, dynamic> message) {
  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }

  // Or do other work.
}
