class LyricsInfo {
  String provider;
  String data;
  bool hasLoaded;

  LyricsInfo({
    this.provider = '',
    this.data = '',
    this.hasLoaded = false,
  });

  factory LyricsInfo.fromJson(Map<String, dynamic> parsedJson) => LyricsInfo(
        provider: parsedJson['provider'],
        data: parsedJson['data'],
        hasLoaded: parsedJson['hasLoaded'],
      );

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'data': data,
        'hasLoaded': hasLoaded,
      };
}