import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'dart:convert';

class ServerAdd extends StatefulWidget {
  @override
  _ServerAddState createState() => _ServerAddState();
}

class _ServerAddState extends State<ServerAdd> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  SharedPreferences prefs;
  TextEditingController textFieldNameController = TextEditingController();
  TextEditingController textFieldIpController = TextEditingController();
  TextEditingController textFieldPasswordController = TextEditingController();
  bool _serverIsProtected = false;

  void initSettings() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getString('server_ip') != null) {
      textFieldNameController.value =
          TextEditingValue(text: prefs.getString('server_name'));
      textFieldIpController.value =
          TextEditingValue(text: prefs.getString('server_ip'));
      textFieldPasswordController.value =
          TextEditingValue(text: prefs.getString('server_password'));
    }

    if (prefs.getString('server_ip') == null) {
      scanQRCode();
    }
  }

  void scanQRCode() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", false, ScanMode.QR);

      Map<String, dynamic> decoded = jsonDecode(barcodeScanRes);

      textFieldNameController.value = TextEditingValue(text: decoded['name']);
      textFieldIpController.value = TextEditingValue(text: decoded['ip']);

      if (decoded['isProtected'] != null && decoded['isProtected'] == true) {
        _serverIsProtected = decoded['isProtected'];
      }
    } catch (e) {
      SnackBar snackBar = SnackBar(
        content: Icon(
          Icons.error_outline,
          color: Colors.red,
        ),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  @override
  initState() {
    super.initState();
    initSettings();
  }

  void save() async {
    await prefs.setString('server_name', textFieldNameController.text.trim());
    await prefs.setString('server_ip', textFieldIpController.text.trim());
    await prefs.setString(
        'server_password', textFieldPasswordController.text.trim().toUpperCase());

    print("Saved");

    Navigator.pop(context, {"reload": true});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: Theme.of(context).textTheme,
        brightness: Brightness.dark,
        accentColor: Colors.white,
      ),
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.save),
          onPressed: () {
            save();
          },
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).appBarTheme.color,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, {"reload": false});
            },
          ),
          actions: <Widget>[
            FlatButton(
              child: Icon(Icons.crop_free),
              onPressed: scanQRCode,
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.width * .15),
                  child: Text(
                    'Connection',
                    style: TextStyle(
                      fontSize: 26,
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * .8,
                  height: 70,
                  child: TextField(
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: "Name",
                      counterText: '',
                    ),
                    keyboardType: TextInputType.text,
                    controller: textFieldNameController,
                    textAlign: TextAlign.center,
                    maxLength: 50,
                    textInputAction: TextInputAction.none,
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * .8,
                  height: 70,
                  child: TextField(
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: "Ip",
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    controller: textFieldIpController,
                    textAlign: TextAlign.center,
                    maxLength: 15,
                    textInputAction: TextInputAction.none,
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * .8,
                  height: 70,
                  child: TextField(
                    style: TextStyle(fontSize: 16),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: "Password",
                      counterText: '',
                    ),
                    keyboardType: TextInputType.text,
                    controller: textFieldPasswordController,
                    textAlign: TextAlign.center,
                    maxLength: 15,
                    textInputAction: TextInputAction.none,
                  ),
                ),
                Visibility(
                  visible: _serverIsProtected,
                  child: Center(
                    child: Text(
                      "This server is protected with password",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
