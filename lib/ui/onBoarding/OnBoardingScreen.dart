import 'package:flutter/material.dart';
import 'package:tender620/constants.dart';
import 'package:tender620/services/helper.dart';
import 'package:tender620/ui/auth/AuthScreen.dart';
import 'package:page_view_indicators/circle_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _currentPageNotifier = ValueNotifier<int>(0);

final List<String> _titlesList = [
  'Build your perfect app',
  'Map View',
  'Saved Listings',
  'Advanced Custom Filters',
  'Add New Listings',
  'Chat',
  'Get Notified'
];

final List<String> _subtitlesList = [
  'Use this starter kit to make your own classifieds app in minutes.',
  'Visualize listings on the map to make your search easier.',
  'Save your favorite listings to come back to them later.',
  'Custom dynamic filters to accommodate all markets and all customer needs.',
  'Add new listings directly from the app including photo gallery and filters.',
  'Communicate with your customers and vendors in real-time.',
  'Stay on top of your game with real-time push notifications.'
];

final List<dynamic> _imageList = [
  'assets/images/listings_logo.png',
  Icons.map,
  Icons.favorite_border,
  Icons.settings,
  Icons.photo_camera,
  Icons.chat,
  Icons.notifications_none
];
final List<Widget> _pages = [];

List<Widget> populatePages(BuildContext context) {
  _pages.clear();
  _titlesList.asMap().forEach((index, value) => _pages.add(getPage(
      _imageList.elementAt(index),
      value,
      _subtitlesList.elementAt(index),
      context,
      _isLastPage(index + 1, _titlesList.length))));
  return _pages;
}

Widget _buildCircleIndicator() {
  return CirclePageIndicator(
    selectedDotColor: Colors.white,
    dotColor: Colors.white30,
    itemCount: _pages.length,
    currentPageNotifier: _currentPageNotifier,
  );
}

Widget getPage(dynamic image, String title, String subTitle,
    BuildContext context, bool isLastPage) {
  return Stack(
    children: <Widget>[
      Center(
        child: Container(
          color: Color(COLOR_PRIMARY),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 200.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: image is String
                        ? Image.asset(
                            image,
                            color: Colors.white,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            image as IconData,
                            color: Colors.white,
                            size: 150,
                          ),
                  ),
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      subTitle,
                      style: TextStyle(color: Colors.white, fontSize: 14.0),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      Visibility(
        visible: isLastPage,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: OutlineButton(
                onPressed: () {
                  setFinishedOnBoarding();
                  pushReplacement(context, new AuthScreen());
                },
                child: Text(
                  'Continue',
                  style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                borderSide: BorderSide(color: Colors.white),
                shape: StadiumBorder(),
              ),
            )),
      ),
    ],
  );
}

Future<bool> setFinishedOnBoarding() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.setBool(FINISHED_ON_BOARDING, true);
}

bool _isLastPage(int currentPosition, int pagesNumber) {
  if (currentPosition == pagesNumber) {
    return true;
  } else {
    return false;
  }
}

class OnBoardingScreen extends StatefulWidget {
  @override
  _OnBoardingScreenState createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: <Widget>[
        PageView(
          children: populatePages(context),
          onPageChanged: (int index) {
            _currentPageNotifier.value = index;
          },
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 50.0),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _buildCircleIndicator(),
          ),
        )
      ],
    ));
  }

  @override
  void dispose() {
    _currentPageNotifier.dispose();
    super.dispose();
  }
}
