const defaultQueueList = [];

class PlaylistInfo {
  List<dynamic> list;

  PlaylistInfo({
    this.list = defaultQueueList,
  });

  factory PlaylistInfo.fromJson(Map<String, dynamic> parsedJson) =>
      PlaylistInfo(
        list: parsedJson['list'],
      );

  Map<String, dynamic> toJson() => {
        'list': list,
      };
}
