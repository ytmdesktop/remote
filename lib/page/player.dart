import 'package:flutter/material.dart';
import 'package:overlay_screen/overlay_screen.dart';
import 'package:share/share.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marquee/marquee.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:ytmdesktop_remote/model/track_info.dart';
import 'package:ytmdesktop_remote/model/player_info.dart';
import 'package:ytmdesktop_remote/model/queue_info.dart';
import 'package:ytmdesktop_remote/model/playlist_info.dart';
import 'package:ytmdesktop_remote/model/lyrics_info.dart';

// import 'package:ytmdesktop_remote/page/settings.dart';
// import 'package:ytmdesktop_remote/page/server_list.dart';
import 'package:ytmdesktop_remote/page/server_add.dart';

import 'package:back_button_interceptor/back_button_interceptor.dart';

import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:ytmdesktop_remote/page/welcome.dart';

const KEY_VOLUME_UP = 'Audio Volume Up';
const KEY_VOLUME_DOWN = 'Audio Volume Down';

final _urlImage = RegExp(r'(https?)://');

enum ConnectionStatus { disconnected, connecting, connected }

final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

class PlayerPage extends StatefulWidget {
  PlayerPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _PlayerPageState createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  Socket socket;

  TrackInfo trackInfo = TrackInfo();
  PlayerInfo playerInfo = PlayerInfo();
  QueueInfo queueInfo = QueueInfo();
  PlaylistInfo playlistInfo = PlaylistInfo();
  LyricsInfo lyricsInfo = LyricsInfo();

  //ValueNotifier<TrackInfo> _trackInfo = ValueNotifier(TrackInfo());

  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String serverName;
  String serverIp;
  String serverPassword;
  SharedPreferences prefs;

  bool _showFastRewind = false;
  bool _showFastForward = false;
  bool _showOverflowCover = false;
  Timer _showOverflowCoverTimer;
  String _lastTrackId = '';
  bool _hasSong = false;
  bool _isFirstSong = true;
  bool _isLastSong = true;

  String _connectionText = "-";

  ScrollController _listViewController = new ScrollController();
  PanelController _panelController = new PanelController();
  TabController _tabController;

  @override
  void initState() {
    super.initState();

    OverlayScreen().saveScreens({
      'welcome': CustomOverlayScreen(
        //backgroundColor: Colors.grey,
        backgroundColor: Colors.white,
        content: WelcomePage(),
      )
    });

    BackButtonInterceptor.add(backButtonInterceptor);

    initSettings();

    MediaNotification.setListener('pause', () {
      mediaPlayPauseTrack();
    });

    MediaNotification.setListener('play', () {
      mediaPlayPauseTrack();
    });

    MediaNotification.setListener('next', () {
      mediaNextTrack();
    });

    MediaNotification.setListener('prev', () {
      mediaPreviousTrack();
    });

    // MediaNotification.setListener('select', () {});

    RawKeyboard.instance.addListener((RawKeyEvent key) {
      if (key is RawKeyDownEvent) {
        if (key.data.physicalKey.debugName == KEY_VOLUME_UP ||
            key.data.logicalKey.debugName == KEY_VOLUME_UP) {
          mediaVolumeUp();
        }

        if (key.data.physicalKey.debugName == KEY_VOLUME_DOWN ||
            key.data.logicalKey.debugName == KEY_VOLUME_DOWN) {
          mediaVolumeDown();
        }
      }
    });

    _tabController = new TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        showLyrics();
      }
    });
  }

  bool backButtonInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (_panelController.isPanelOpen) {
      _panelController.close();
    } else {
      return false;
    }

    return true;
  }

  void initSettings() async {
    prefs = await SharedPreferences.getInstance();

    bool isFirstAccess = true;
    isFirstAccess = prefs.getBool('is_first_access');
    
    if (isFirstAccess == null || isFirstAccess == true) {
      OverlayScreen().show(
        context,
        identifier: 'welcome',
      );
    }

    setState(() {
      serverName = prefs.getString('server_name');
      serverIp = prefs.getString('server_ip');
      serverPassword = prefs.getString('server_password');
    });

    if (serverIp != null) {
      socketConnect();
    }

    if (serverIp == null || serverIp.length < 7) {
      Navigator.push(
              context, MaterialPageRoute(builder: (context) => ServerAdd()))
          .then((_) {
        if (_ != null && _['reload'] == true) {
          setState(() {
            serverName = prefs.getString('server_name');
            serverIp = prefs.getString('server_ip');
            serverPassword = prefs.getString('server_password');
          });
          resetValues();
          socketConnect();
        }
      });
    }
  }

  socketConnect() async {
    socket = io('http://$serverIp:9863', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false
    });

    _connectionText = 'Connecting to $serverIp';

    socket.io.options['extraHeaders'] = {'password': serverPassword};

    socket.on('reconnect', (_) {
      setState(() {
        _connectionStatus = ConnectionStatus.connected;
        _connectionText = 'Connected';
      });
    });

    socket.on('reconnect_attempt', (attempt) {
      setState(() {
        _connectionStatus = ConnectionStatus.connecting;
        int _total = attempt + 1;
        _connectionText = 'Connecting to $serverIp ($_total)';
      });

      /*if (attempt > 5) {
        socketDisconnect();
      }*/
    });

    socket.on('reconnect_failed', (args) {
      print("reconnect_failed");
    });

    socket.on('reconnect_error', (args) {
      setState(() {
        _connectionText = 'Failed to connect with $serverIp';
      });
    });

    socket.on('connect', (_) {
      setState(() {
        _connectionStatus = ConnectionStatus.connected;
        _connectionText = 'Connected';
      });
    });

    socket.on('disconnect', (_) {
      setState(() {
        _connectionText = 'Disconnected';
      });
      resetValues();
    });

    socket.on('error', (_) {
      resetValues();
    });

    socket.on('tick', (data) {
      setState(() {
        playerInfo = PlayerInfo.fromJson(data['player']);
        trackInfo = TrackInfo.fromJson(data['track']);
        _hasSong = playerInfo.hasSong;

        if (trackInfo.id != _lastTrackId) {
          Future.delayed(Duration(milliseconds: 600), () {
            socket.emit('query-queue');
          });
          Future.delayed(Duration(seconds: 5), () {
            socket.emit('query-playlist');
          });
        }

        MediaNotification.showNotification(
            title: trackInfo.title,
            author: trackInfo.author,
            isPlaying: !playerInfo.isPaused);

        if (_tabController.index == 1) {
          socket.emit('query-lyrics');
        }
      });
    });

    socket.on('player', (player) {
      playerInfo = PlayerInfo.fromJson(player);
    });

    socket.on('track', (track) {
      trackInfo = TrackInfo.fromJson(track);
    });

    socket.on('queue', (queue) {
      queueInfo = QueueInfo.fromJson(queue);
      Future.delayed(Duration(milliseconds: 200), () {
        _scrollToQueueIndex(queueInfo.currentIndex);
      });

      _isFirstSong = (queueInfo.currentIndex == 0);
      _isLastSong = (queueInfo.currentIndex + 1 == queueInfo.list.length);
    });

    socket.on('playlist', (playlist) {
      playlistInfo = PlaylistInfo.fromJson(playlist);
    });

    socket.on('lyrics', (lyrics) {
      setState(() {
        lyricsInfo = LyricsInfo.fromJson(lyrics);
      });
    });

    /*socket.on('info', (serverInfo) {
      if ('1.12.0'.compareTo(serverInfo['app']['version']) == -1) {
        SnackBar snackBar = SnackBar(
          duration: Duration(minutes: 60),
          backgroundColor: Colors.red,
          content: Text(
            "Update to v1.12 or more",
            style: TextStyle(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        );

        _scaffoldKey.currentState.showSnackBar(snackBar);
        socket.disconnect();
      }
    });*/

    socket.connect();
  }

  void socketDisconnect() {
    if (socket != null) {
      socket.disconnect();
    }
    resetValues();
  }

  void showSnackbar(String text,
      {Widget prepend, Duration duration, SnackBarAction action}) {
    _scaffoldKey.currentState.removeCurrentSnackBar();
    SnackBar snackBar = SnackBar(
      duration: (duration) ?? Duration(seconds: 4),
      backgroundColor: Colors.black,
      content: Row(
        children: <Widget>[
          (prepend != null) ? prepend : Text(""),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
      action: (action) ?? null,
    );
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  void showPlaylistDialog(BuildContext context) {
    AlertDialog alertDialog = AlertDialog(
      backgroundColor: Color.fromRGBO(33, 33, 33, 1),
      title: Text('Playlists (${playlistInfo.list.length})'),
      content: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: ListView.builder(
          itemCount: playlistInfo.list.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(playlistInfo.list[index].toString()),
              onTap: () {
                addToPlaylist(index);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );

    showDialog(context: context, child: alertDialog);
  }

  void mediaPreviousTrack() {
    socket.emit('media-commands', ["track-previous"]);
  }

  void mediaPlayPauseTrack() {
    socket.emit('media-commands', ["track-play"]);
  }

  void mediaNextTrack() {
    socket.emit('media-commands', ["track-next"]);
  }

  void mediaThumbUpTrack() {
    socket.emit('media-commands', ["track-thumbs-up"]);
  }

  void mediaThumbDownTrack() {
    socket.emit('media-commands', ["track-thumbs-down"]);
  }

  void mediaVolumeUp() {
    socket.emit('media-commands', ["player-volume-up"]);
  }

  void mediaVolumeDown() {
    socket.emit('media-commands', ["player-volume-down"]);
  }

  void forwardXSeconds() {
    socket.emit('media-commands', ['player-forward']);
  }

  void rewindXSeconds() {
    socket.emit('media-commands', ['player-rewind']);
  }

  void changeSeekbar(value) {
    socket.emit('media-commands', ['player-set-seekbar', value]);
  }

  void setQueueItem(value) {
    socket.emit('media-commands', ['player-set-queue', value.toString()]);
  }

  void showLyrics() {
    socket.emit('media-commands', ['show-lyrics-hidden']);
    socket.emit('query-lyrics');
  }

  void repeat() {
    socket.emit('media-commands', ['player-repeat']);
  }

  void shuffle() {
    socket.emit('media-commands', ['player-shuffle']);
  }

  void addToLibrary() {
    socket.emit('media-commands', ['player-add-library']);
  }

  void addToPlaylist(value) {
    socket.emit('media-commands', ['player-add-playlist', value.toString()]);
  }

  void resetValues() {
    setState(() {
      trackInfo = TrackInfo();
      playerInfo = PlayerInfo();
      queueInfo = QueueInfo();
      playlistInfo = PlaylistInfo();
      lyricsInfo = LyricsInfo();

      _connectionStatus = ConnectionStatus.disconnected;
      _connectionText = 'Disconnected';

      _isFirstSong = true;
      _isLastSong = true;

      _lastTrackId = '';

      _tabController.index = 0;
    });

    _panelController.close();
  }

  void showOverflowCover() {
    if (_showOverflowCoverTimer is Timer) {
      _showOverflowCoverTimer.cancel();
    }
    setState(() {
      _showOverflowCover = true;
      _showOverflowCoverTimer =
          Timer(Duration(seconds: 3), () => {_showOverflowCover = false});
    });
  }

  Widget songCover() {
    if (_connectionStatus == ConnectionStatus.connected && _hasSong) {
      return Container(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5.0),
          child: Image.network(
            trackInfo.cover,
            gaplessPlayback: true,
          ),
        ),
      );
    }

    return Container(
      child: ClipRRect(
        child: Image.asset(
          'assets/image/logo256x256.png',
          width: MediaQuery.of(context).size.width * .3,
        ),
      ),
    );
  }

  Widget playerControls() {
    Widget _value;

    if (_connectionStatus == ConnectionStatus.connected) {
      if (_hasSong) {
        if (trackInfo.title.length < 30) {
          _value = Text(
            trackInfo.title,
            style: TextStyle(
              fontSize: 21.0,
              fontWeight: FontWeight.bold,
            ),
            textScaleFactor: 0.88,
            textAlign: TextAlign.center,
          );
        } else {
          _value = Marquee(
            text: trackInfo.title,
            style: TextStyle(
              fontSize: 21.0,
              fontWeight: FontWeight.bold,
            ),
            scrollAxis: Axis.horizontal,
            blankSpace: 50,
          );
        }
      } else {
        _value = Text(
          "Ready to play",
          style: TextStyle(
            fontSize: 21.0,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        );
      }
    } else {
      _value = Text(
        _connectionText,
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
        textScaleFactor: 0.88,
      );
    }

    return Container(
      width: MediaQuery.of(context).size.width * .96,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.shuffle),
                onPressed: (_hasSong) ? shuffle : null,
              ),
              Container(
                alignment: Alignment.center,
                height: 40,
                width: MediaQuery.of(context).size.width * .55,
                child: _value,
              ),
              IconButton(
                icon: repeatTypeIcon(),
                highlightColor: Colors.red,
                onPressed: (_hasSong) ? repeat : null,
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.only(bottom: 0),
            child: Text(
              trackInfo.author,
              overflow: TextOverflow.fade,
              maxLines: 1,
              softWrap: false,
              textScaleFactor: 0.88,
            ),
          ),
          Row(
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width * .96,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3.0,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  ),
                  child: Slider.adaptive(
                    activeColor: Colors.redAccent,
                    value: playerInfo.seekbarCurrentPosition.toDouble(),
                    max: trackInfo.duration.toDouble(),
                    onChanged: (value) {
                      changeSeekbar(value);
                    },
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Stack(
                overflow: Overflow.visible,
                children: <Widget>[
                  Flex(
                    direction: Axis.horizontal,
                  ),
                  Positioned(
                    top: -15,
                    left: 24.0,
                    child: Text(
                      playerInfo.seekbarCurrentPositionHuman,
                      textScaleFactor: 0.8,
                    ),
                  ),
                ],
              ),
              Stack(
                overflow: Overflow.visible,
                children: <Widget>[
                  Flex(
                    direction: Axis.horizontal,
                  ),
                  Positioned(
                    top: -15,
                    right: 24.0,
                    child: Text(
                      trackInfo.durationHuman,
                      textScaleFactor: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.only(top: 4, bottom: 0),
            width: MediaQuery.of(context).size.width * .94,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: FlatButton(
                    child: Icon(Icons.thumb_down),
                    onPressed: (_hasSong) ? mediaThumbDownTrack : null,
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(15.0),
                    textColor: (playerInfo.likeStatus == 'DISLIKE')
                        ? Colors.white
                        : Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: FlatButton(
                    child: Icon(Icons.skip_previous, size: 35.0),
                    onPressed:
                        (_hasSong && !_isFirstSong) ? mediaPreviousTrack : null,
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(15.0),
                  ),
                ),
                Expanded(
                  child: RawMaterialButton(
                    onPressed: (_connectionStatus == ConnectionStatus.connected)
                        ? mediaPlayPauseTrack
                        : null,
                    child: Icon(
                      (playerInfo.isPaused) ? Icons.play_arrow : Icons.pause,
                      color: Colors.red,
                      size: 35,
                    ),
                    shape: CircleBorder(),
                    elevation: 3.0,
                    highlightElevation: 20,
                    fillColor: Colors.white,
                    padding: EdgeInsets.all(15.0),
                  ),
                ),
                Expanded(
                  child: FlatButton(
                    child: Icon(Icons.skip_next, size: 35.0),
                    onPressed:
                        (_hasSong && !_isLastSong) ? mediaNextTrack : null,
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(15.0),
                  ),
                ),
                Expanded(
                  child: FlatButton(
                    child: Icon(Icons.thumb_up),
                    onPressed: (_hasSong) ? mediaThumbUpTrack : null,
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(15.0),
                    textColor: (playerInfo.likeStatus == 'LIKE')
                        ? Colors.white
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToQueueIndex(index) {
    if (index > 0 && _tabController.index == 0) {
      _listViewController.animateTo(72.0 * index,
          duration: Duration(milliseconds: 1500), curve: Curves.fastOutSlowIn);
    }
  }

  Widget repeatTypeIcon() {
    if (playerInfo.repeatType == 'ONE') {
      return Icon(
        Icons.repeat_one,
      );
    }

    if (playerInfo.repeatType == 'ALL') {
      return Icon(
        Icons.repeat,
      );
    }

    return Icon(
      Icons.repeat,
      color: Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    Size _screenSize = MediaQuery.of(context).size;
    double _coverSize = _screenSize.width;

    _coverSize = _coverSize * .9;

    if (_screenSize.width <= 320) {
      _coverSize = _coverSize * .56;
    } else if (_screenSize.width > 320 && _screenSize.width <= 400) {
      _coverSize = _coverSize * .83;
    } else if (_screenSize.width > 400 && _screenSize.width <= 500) {
      _coverSize = _coverSize * .97;
    } else if (_screenSize.width > 500) {
      _coverSize = _coverSize * .8;
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: appBar(),
      body: SlidingUpPanel(
        isDraggable:
            (_connectionStatus == ConnectionStatus.connected && _hasSong)
                ? true
                : false,
        color: Color.fromRGBO(33, 33, 33, 1),
        controller: _panelController,
        minHeight: 50.0,
        maxHeight: MediaQuery.of(context).size.height * .908,
        header: Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * .46),
          child: Divider(
            thickness: 3,
            color: Colors.grey,
          ),
        ),
        panel: AbsorbPointer(
          absorbing:
              (_connectionStatus == ConnectionStatus.connected && _hasSong)
                  ? false
                  : true,
          child: DefaultTabController(
            length: 2,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  onTap: (_) {
                    _panelController.open();
                  },
                  tabs: [
                    Tab(
                      icon: Icon(Icons.queue_music),
                    ),
                    Tab(
                      icon: Icon(Icons.music_note),
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  Tab(
                    child: tabQueue(),
                  ),
                  SingleChildScrollView(
                    child: tabLyrics(),
                  )
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: <Widget>[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        height: _coverSize,
                        child: Center(
                          child: songCover(),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              if (_connectionStatus ==
                                      ConnectionStatus.connected &&
                                  _hasSong) {
                                showOverflowCover();
                              }
                            },
                            onDoubleTap: () {
                              if (_connectionStatus ==
                                      ConnectionStatus.connected &&
                                  _hasSong) {
                                setState(() {
                                  _showFastRewind = true;
                                  Timer(Duration(milliseconds: 500),
                                      () => {_showFastRewind = false});
                                });
                                rewindXSeconds();
                              }
                            },
                            child: Container(
                              width: _coverSize / 2,
                              height: _coverSize,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  (_showFastRewind)
                                      ? Color.fromRGBO(0, 0, 0, .3)
                                      : Colors.transparent,
                                  Colors.transparent
                                ]),
                              ),
                              child: Visibility(
                                visible: _showFastRewind,
                                child: Icon(
                                  Icons.fast_rewind,
                                  size: 70,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_connectionStatus ==
                                      ConnectionStatus.connected &&
                                  _hasSong) {
                                showOverflowCover();
                              }
                            },
                            onDoubleTap: () {
                              if (_connectionStatus ==
                                      ConnectionStatus.connected &&
                                  _hasSong) {
                                setState(() {
                                  _showFastForward = true;
                                  Timer(Duration(milliseconds: 500),
                                      () => {_showFastForward = false});
                                });
                                forwardXSeconds();
                              }
                            },
                            child: Container(
                              width: _coverSize / 2,
                              height: _coverSize,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.transparent,
                                  (_showFastForward)
                                      ? Color.fromRGBO(0, 0, 0, .3)
                                      : Colors.transparent
                                ]),
                              ),
                              child: Visibility(
                                visible: _showFastForward,
                                child: Icon(
                                  Icons.fast_forward,
                                  size: 70,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Visibility(
                        visible: _showOverflowCover,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showOverflowCover = false;
                              });
                            },
                            child: Container(
                              width: _coverSize,
                              height: _coverSize,
                              color: Color.fromRGBO(0, 0, 0, .6),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      FlatButton(
                                        onPressed: () {
                                          Share.share(trackInfo.url);
                                        },
                                        shape: CircleBorder(),
                                        color:
                                            Color.fromRGBO(255, 255, 255, .2),
                                        child: Padding(
                                          padding: EdgeInsets.all(15),
                                          child: Icon(Icons.share),
                                        ),
                                      ),
                                      FlatButton(
                                        onPressed: () {
                                          showPlaylistDialog(context);
                                        },
                                        shape: CircleBorder(),
                                        color:
                                            Color.fromRGBO(255, 255, 255, .2),
                                        child: Padding(
                                          padding: EdgeInsets.all(15),
                                          child: Icon(Icons.playlist_add),
                                        ),
                                      ),
                                      FlatButton(
                                        onPressed: () {
                                          addToLibrary();
                                        },
                                        shape: CircleBorder(),
                                        color:
                                            Color.fromRGBO(255, 255, 255, .2),
                                        child: Padding(
                                          padding: EdgeInsets.all(15),
                                          child: (trackInfo.inLibrary)
                                              ? Icon(Icons.check)
                                              : Icon(Icons.library_add),
                                        ),
                                      ),
                                    ],
                                  ),
                                  /*SizedBox(
                                  height: 15,
                                ),*/
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      FlatButton(
                                        onPressed: () {
                                          showOverflowCover();
                                          mediaVolumeDown();
                                        },
                                        shape: CircleBorder(),
                                        color:
                                            Color.fromRGBO(255, 255, 255, .2),
                                        child: Padding(
                                          padding: EdgeInsets.all(15),
                                          child: Icon(Icons.volume_down),
                                        ),
                                      ),
                                      Text(
                                        '${playerInfo.volumePercent}%',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      FlatButton(
                                        onPressed: () {
                                          showOverflowCover();
                                          mediaVolumeUp();
                                        },
                                        shape: CircleBorder(),
                                        color:
                                            Color.fromRGBO(255, 255, 255, .2),
                                        child: Padding(
                                          padding: EdgeInsets.all(15),
                                          child: Icon(Icons.volume_up),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 160),
                    child: playerControls(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tabQueue() {
    bool _isCurrent;

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 5),
      controller: _listViewController,
      itemCount: queueInfo.list.length,
      itemBuilder: (BuildContext context, int index) {
        _isCurrent = false;
        if (queueInfo.currentIndex == index) {
          _isCurrent = true;
          if (trackInfo.id != _lastTrackId) {
            _lastTrackId = trackInfo.id;
          }
        }

        return Container(
          color: (_isCurrent)
              ? Color.fromRGBO(255, 255, 255, .1)
              : Colors.transparent,
          child: ListTile(
            onTap: () {
              setQueueItem(index);
            },
            title: Text(
              queueInfo.list[index]['title'],
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              queueInfo.list[index]['author'],
            ),
            trailing: Text(
              queueInfo.list[index]['duration'],
              style: TextStyle(color: Color.fromRGBO(200, 200, 200, 1)),
            ),
            leading: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                (_urlImage.hasMatch(queueInfo.list[index]['cover']))
                    ? Image.network(
                        queueInfo.list[index]['cover'],
                        width: 56,
                        height: 56,
                      )
                    : Icon(
                        Icons.photo_size_select_actual,
                        color: Colors.grey,
                        size: 55,
                      ),
                Visibility(
                  visible: _isCurrent,
                  child: Container(
                    width: 56,
                    height: 56,
                    color: Color.fromRGBO(0, 0, 0, .4),
                    child: Icon(
                      Icons.audiotrack,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget tabLyrics() {
    String data = lyricsInfo.data;

    if (lyricsInfo.provider == "" && lyricsInfo.data == "Loading...") {
      data = "Loading...";
    }

    if (lyricsInfo.provider == "-") {
      data = lyricsInfo.data;
    }

    return Container(
      padding: EdgeInsets.only(top: 30),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: data,
          children: [
            TextSpan(
              text: (lyricsInfo.provider.length > 1)
                  ? '\n\n\nLyrics provided by ${lyricsInfo.provider}\n'
                  : '',
              style: TextStyle(
                color: Colors.grey,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget appBar() {
    if (_hasSong && _panelController.panelPosition > .30) {
      return AppBar(
        elevation: 0,
        title: ListTile(
          onTap: () {
            _panelController.close();
          },
          contentPadding: EdgeInsets.zero,
          leading: Image.network(
            trackInfo.cover,
            width: 40,
            height: 40,
          ),
          title: Text(
            trackInfo.title,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            trackInfo.author,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Wrap(
            spacing: 2,
            children: <Widget>[
              SizedBox(
                width: 50,
                child: IconButton(
                  onPressed: () {
                    mediaPlayPauseTrack();
                  },
                  icon: Icon(
                    (playerInfo.isPaused) ? Icons.play_arrow : Icons.pause,
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: IconButton(
                  onPressed: (_hasSong && !_isLastSong) ? mediaNextTrack : null,
                  icon: Icon(Icons.skip_next),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppBar(
      elevation: 0,
      title: AnimatedOpacity(
        opacity: 1,
        duration: Duration(milliseconds: 100),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 19,
                  ),
                ),
                padding: EdgeInsets.only(left: 6),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Icon(Icons.devices),
          onPressed: () {
            Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ServerAdd()))
                .then((params) {
              if (params != null && params['reload'] == true) {
                socketDisconnect();
                serverName = prefs.getString('server_name');
                serverIp = prefs.getString('server_ip');
                serverPassword = prefs.getString('server_password');
                resetValues();
                socketConnect();
              }
            });
          },
        )
      ],
    );
  }

  double calcInverse(value) {
    return 1 - value;
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(backButtonInterceptor);
    _tabController.dispose();
    MediaNotification.hideNotification();

    super.dispose();
  }
}
