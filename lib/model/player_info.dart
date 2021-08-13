class PlayerInfo {
  bool hasSong;
  bool isPaused;
  int volumePercent;
  int seekbarCurrentPosition;
  String seekbarCurrentPositionHuman;
  double statePercent;
  String likeStatus;
  String repeatType;

  PlayerInfo({
    this.hasSong = false,
    this.isPaused = true,
    this.volumePercent = 0,
    this.seekbarCurrentPosition = 0,
    this.seekbarCurrentPositionHuman = '0:00',
    this.statePercent = 0.0,
    this.likeStatus = 'INDIFFERENT',
    this.repeatType = 'NONE',
  });

  factory PlayerInfo.fromJson(Map<String, dynamic> parsedJson) => PlayerInfo(
        hasSong: parsedJson['hasSong'],
        isPaused: parsedJson['isPaused'],
        volumePercent: parsedJson['volumePercent'],
        seekbarCurrentPosition: parsedJson['seekbarCurrentPosition'],
        seekbarCurrentPositionHuman: parsedJson['seekbarCurrentPositionHuman'],
        statePercent: fixDouble(parsedJson['statePercent']),
        likeStatus: parsedJson['likeStatus'],
        repeatType: parsedJson['repeatType'],
      );

  Map<String, dynamic> toJson() => {
        'hasSong': hasSong,
        'isPaused': isPaused,
        'volumePercent': volumePercent,
        'seekbarCurrentPosition': seekbarCurrentPosition,
        'seekbarCurrentPositionHuman': seekbarCurrentPositionHuman,
        'statePercent': statePercent,
        'likeStatus': likeStatus,
        'repeatType': repeatType,
      };
}

fixDouble(value) {
  if (value == 0) return 0.0;
  return value;
}
