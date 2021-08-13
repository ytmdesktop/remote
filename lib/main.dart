import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ytmdesktop_remote/page/player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final String _title = "Remote Control";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      /*theme: ThemeData(
        textTheme: GoogleFonts.latoTextTheme(
          TextTheme(
            bodyText2: TextStyle(color: Colors.white),
          ),
        ),
        scaffoldBackgroundColor: Color.fromRGBO(0, 0, 0, 1),
        //primaryColorBrightness: brightness,
        //brightness: brightness,
        appBarTheme: AppBarTheme(
          elevation: 0,
          color: Colors.transparent,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.transparent,
        ),
      ),*/
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          color: Colors.white,
          textTheme: TextTheme(
            headline6: TextStyle(color: Colors.grey[800]),
          ),
          iconTheme: IconThemeData(color: Colors.grey[700]),
        ),
        backgroundColor: Colors.white,
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        tabBarTheme: TabBarTheme(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.lato(),
            unselectedLabelStyle: GoogleFonts.lato()),
        textTheme: GoogleFonts.latoTextTheme(
          TextTheme(
            bodyText2: TextStyle(color: Colors.black),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        appBarTheme: AppBarTheme(
          color: Colors.grey[900],
          textTheme: TextTheme(
            headline6: TextStyle(color: Colors.grey[100]),
          ),
          iconTheme: IconThemeData(color: Colors.grey[100]),
        ),
        backgroundColor: Colors.grey,
        brightness: Brightness.dark,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.grey[700], foregroundColor: Colors.white),
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.grey[900],
        textTheme: GoogleFonts.aBeeZeeTextTheme(
          TextTheme(
            bodyText2: TextStyle(color: Colors.white),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PlayerPage(title: _title),
    );
  }
}
