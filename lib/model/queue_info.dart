const defaultQueueList = [];

class QueueInfo {
  bool automix;
  int currentIndex;
  List<dynamic> list;

  QueueInfo({
    this.automix = false,
    this.currentIndex = 0,
    this.list = defaultQueueList,
  });

  factory QueueInfo.fromJson(Map<String, dynamic> parsedJson) => QueueInfo(
        automix: parsedJson['automix'],
        currentIndex: parsedJson['currentIndex'],
        list: parsedJson['list'],
      );

  Map<String, dynamic> toJson() => {
        'automix': automix,
        'currentIndex': currentIndex,
        'list': list,
      };
}
