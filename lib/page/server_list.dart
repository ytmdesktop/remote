import 'package:flutter/material.dart';

class ServerList extends StatefulWidget {
  @override
  _ServerListState createState() => _ServerListState();
}

class _ServerListState extends State<ServerList> {
  @override
  initState() {
    super.initState();
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).appBarTheme.color,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, {"reload": false,});
            },
          ),
        ),
      ),
    );
  }
}
