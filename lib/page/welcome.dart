import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  WelcomePage({Key key}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  SharedPreferences _prefs;

  @override
  initState() {
    super.initState();
    initSettings();
  }

  void initSettings() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void save() {
    _prefs.setBool('is_first_access', false);
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 40, bottom: 15),
            child: Image.asset(
              'assets/image/logo256x256.png',
              width: 70,
            ),
          ),
          Text(
            "YTMDesktop\nRemote Control",
            textScaleFactor: 1.25,
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: EdgeInsets.only(top: 60, left: 20, right: 20),
            child: Text(
              'To start, activate the remote control on the desktop player, go to:',
              textScaleFactor: 1.1,
            ),
          ),
          Container(
            //color: Colors.red,
            height: 150,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: RichText(
                  textAlign: TextAlign.center,
                  textScaleFactor: 1.25,
                  text: TextSpan(children: <TextSpan>[
                    TextSpan(
                      text: 'Settings',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextSpan(
                        text: ' > ', style: TextStyle(color: Colors.grey[700])),
                    TextSpan(
                      text: 'Integrations',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextSpan(
                        text: ' > ', style: TextStyle(color: Colors.grey[700])),
                    TextSpan(
                      text: 'Remote Control',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    )
                  ]),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "If you are selected 'Protect remote control with password', then when adding the server enter the generated password.",
              textScaleFactor: 1.1,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 10),
            child: OutlineButton(
              onPressed: () {
                save();
                Navigator.pop(context);
              },
              child: Text("Let's go", textScaleFactor: 1.1,),
              //shape: StadiumBorder(),
            ),
          )
        ],
      ),
    ));
  }
}
