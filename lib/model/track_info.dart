class TrackInfo {
  String author;
  String title;
  String album;
  String cover;
  int duration;
  String durationHuman;
  String url;
  String id;
  bool isVideo;
  bool isAdvertisement;
  bool inLibrary;

  TrackInfo({
    this.author = '',
    this.title = '',
    this.album = '',
    this.cover = '',
    this.duration = 0,
    this.durationHuman = '0:00',
    this.url = '',
    this.id = '',
    this.isVideo = false,
    this.isAdvertisement = false,
    this.inLibrary = false,
  });

  factory TrackInfo.fromJson(Map<String, dynamic> parsedJson) => TrackInfo(
        author: parsedJson['author'],
        title: parsedJson['title'],
        album: parsedJson['album'],
        cover: parsedJson['cover'],
        duration: parsedJson['duration'],
        durationHuman: parsedJson['durationHuman'],
        url: parsedJson['url'],
        id: parsedJson['id'],
        isVideo: parsedJson['isVideo'],
        isAdvertisement: parsedJson['isAdvertisement'],
        inLibrary: parsedJson['inLibrary'],
      );

  Map<String, dynamic> toJson() => {
        'author': author,
        'title': title,
        'album': album,
        'cover': cover,
        'duration': duration,
        'durationHuman': durationHuman,
        'url': url,
        'id': id,
        'isVideo': isVideo,
        'isAdvertisement': isAdvertisement,
        'inLibrary': inLibrary,
      };
}