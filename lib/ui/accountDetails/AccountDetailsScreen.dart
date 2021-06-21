import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tender620/constants.dart';
import 'package:tender620/main.dart';
import 'package:tender620/model/User.dart';
import 'package:tender620/services/FirebaseHelper.dart';
import 'package:tender620/services/helper.dart';

class AccountDetailsScreen extends StatefulWidget {
  final User user;

  AccountDetailsScreen({Key key, @required this.user}) : super(key: key);

  @override
  _AccountDetailsScreenState createState() {
    return _AccountDetailsScreenState(user);
  }
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  User user;
  GlobalKey<FormState> _key = new GlobalKey();
  AutovalidateMode _validate = AutovalidateMode.disabled;
  String firstName, lastName, email, mobile;

  _AccountDetailsScreenState(this.user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Account Details'),
        ),
        body: Builder(
            builder: (buildContext) => SingleChildScrollView(
                  child: Form(
                    key: _key,
                    autovalidateMode: _validate,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16.0, right: 16, bottom: 8, top: 24),
                            child: Text(
                              'PUBLIC INFO',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                          Material(
                              elevation: 2,
                              color: isDarkMode(context)
                                  ? Colors.black12
                                  : Colors.white,
                              child: ListView(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  children: ListTile.divideTiles(
                                      context: buildContext,
                                      tiles: [
                                        ListTile(
                                          title: Text(
                                            'First Name',
                                            style: TextStyle(
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          trailing: ConstrainedBox(
                                            constraints:
                                                BoxConstraints(maxWidth: 100),
                                            child: TextFormField(
                                              onSaved: (String val) {
                                                firstName = val;
                                              },
                                              validator: validateName,
                                              textInputAction:
                                                  TextInputAction.next,
                                              textAlign: TextAlign.end,
                                              initialValue: user.firstName,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: isDarkMode(context)
                                                      ? Colors.white
                                                      : Colors.black),
                                              cursorColor: Color(COLOR_ACCENT),
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              keyboardType: TextInputType.text,
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: 'First name',
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          vertical: 5)),
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Last Name',
                                            style: TextStyle(
                                                color: isDarkMode(context)
                                                    ? Colors.white
                                                    : Colors.black),
                                          ),
                                          trailing: ConstrainedBox(
                                            constraints:
                                                BoxConstraints(maxWidth: 100),
                                            child: TextFormField(
                                              onSaved: (String val) {
                                                lastName = val;
                                              },
                                              validator: validateName,
                                              textInputAction:
                                                  TextInputAction.next,
                                              textAlign: TextAlign.end,
                                              initialValue: user.lastName,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: isDarkMode(context)
                                                      ? Colors.white
                                                      : Colors.black),
                                              cursorColor: Color(COLOR_ACCENT),
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              keyboardType: TextInputType.text,
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: 'Last name',
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          vertical: 5)),
                                            ),
                                          ),
                                        ),
                                      ]).toList())),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16.0, right: 16, bottom: 8, top: 24),
                            child: Text(
                              'PRIVATE DETAILS',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                          Material(
                            elevation: 2,
                            color: isDarkMode(context)
                                ? Colors.black12
                                : Colors.white,
                            child: ListView(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                children: ListTile.divideTiles(
                                  context: buildContext,
                                  tiles: [
                                    ListTile(
                                      title: Text(
                                        'Email Address',
                                        style: TextStyle(
                                            color: isDarkMode(context)
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                      trailing: ConstrainedBox(
                                        constraints:
                                            BoxConstraints(maxWidth: 200),
                                        child: TextFormField(
                                          onSaved: (String val) {
                                            email = val;
                                          },
                                          validator: validateEmail,
                                          textInputAction: TextInputAction.next,
                                          initialValue: user.email,
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black),
                                          cursorColor: Color(COLOR_ACCENT),
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Email Address',
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 5)),
                                        ),
                                      ),
                                    ),
                                    ListTile(
                                      title: Text(
                                        'Phone Number',
                                        style: TextStyle(
                                            color: isDarkMode(context)
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                      trailing: ConstrainedBox(
                                        constraints:
                                            BoxConstraints(maxWidth: 150),
                                        child: TextFormField(
                                          onSaved: (String val) {
                                            mobile = val;
                                          },
                                          validator: validateMobile,
                                          textInputAction: TextInputAction.done,
                                          initialValue: user.phoneNumber,
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black),
                                          cursorColor: Color(COLOR_ACCENT),
                                          keyboardType: TextInputType.phone,
                                          decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Phone Number',
                                              contentPadding:
                                                  EdgeInsets.only(bottom: 2)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ).toList()),
                          ),
                          Padding(
                              padding:
                                  const EdgeInsets.only(top: 32.0, bottom: 16),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                    minWidth: double.infinity),
                                child: Material(
                                  elevation: 2,
                                  color: isDarkMode(context)
                                      ? Colors.black12
                                      : Colors.white,
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.all(12.0),
                                    onPressed: () async {
                                      _validateAndSave(buildContext);
                                    },
                                    child: Text(
                                      'Save',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Color(COLOR_PRIMARY)),
                                    ),
                                  ),
                                ),
                              )),
                        ]),
                  ),
                )));
  }

  _validateAndSave(BuildContext buildContext) async {
    if (_key.currentState.validate()) {
      _key.currentState.save();
      if (user.email != email) {
        TextEditingController _passwordController = new TextEditingController();
        showDialog(
          builder: (context) => Dialog(
            elevation: 16,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Inorder to change your email, you must type your password first',
                      style: TextStyle(color: Colors.red, fontSize: 17),
                      textAlign: TextAlign.start,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(hintText: 'Password'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: RaisedButton(
                        color: Color(COLOR_ACCENT),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                        onPressed: () async {
                          if (_passwordController.text.isEmpty) {
                            showAlertDialog(context, "Empty Password",
                                "Password is required to update email");
                          } else {
                            Navigator.pop(context);
                            showProgress(context, 'Verifying...', false);
                            auth.UserCredential result = await auth
                                .FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                    email: user.email,
                                    password: _passwordController.text)
                                .catchError((onError) {
                              hideProgress();
                              showAlertDialog(context, 'Couldn\'t verify',
                                  'Please double check the password and try again.');
                            });
                            _passwordController.dispose();
                            if (result.user != null) {
                              await result.user.updateEmail(email);
                              updateProgress('Saving details...');
                              await _updateUser(buildContext);
                              hideProgress();
                            } else {
                              hideProgress();
                              Scaffold.of(buildContext).showSnackBar(SnackBar(
                                  content: Text(
                                'Couldn\'t verify, Please try again.',
                                style: TextStyle(fontSize: 17),
                              )));
                            }
                          }
                        },
                        child: Text(
                          'Verify',
                          style: TextStyle(
                              color: isDarkMode(context)
                                  ? Colors.black
                                  : Colors.white),
                        ),
                      ),
                    )
                  ],
                )),
          ),
          context: context,
        );
      } else {
        showProgress(context, "Saving details...", false);
        await _updateUser(buildContext);
        hideProgress();
      }
    } else {
      setState(() {
        _validate = AutovalidateMode.onUserInteraction;
      });
    }
  }

  _updateUser(BuildContext buildContext) async {
    user.firstName = firstName;
    user.lastName = lastName;
    user.email = email;
    user.phoneNumber = mobile;
    var updatedUser = await FireStoreUtils.updateCurrentUser(user);
    if (updatedUser != null) {
      MyAppState.currentUser = user;
      Scaffold.of(buildContext).showSnackBar(SnackBar(
          content: Text(
        'Details saved successfully',
        style: TextStyle(fontSize: 17),
      )));
    } else {
      Scaffold.of(buildContext).showSnackBar(SnackBar(
          content: Text(
        'Couldn\'t save details, Please try again.',
        style: TextStyle(fontSize: 17),
      )));
    }
  }
}
