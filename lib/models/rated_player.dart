class RatedPlayer {
  final int id;
  final String name;
  final String? gender;
  final String? birthday;
  final String? placeName;
  final double? rating;
  final double? bestRating;
  final int? gameCount;
  final int? winCount;
  final int? loseCount;
  final int? rank;

  RatedPlayer({
    required this.id,
    required this.name,
    this.gender,
    this.birthday,
    this.placeName,
    this.rating,
    this.bestRating,
    this.gameCount,
    this.winCount,
    this.loseCount,
    this.rank,
  });

  factory RatedPlayer.fromJson(Map<String, dynamic> json) {
    return RatedPlayer(
      id: json['id'],
      name: json['name'] ?? '',
      gender: json['gender'],
      birthday: json['birthday'],
      placeName: json['place_name'],
      rating: (json['rating'] as num?)?.toDouble(),
      bestRating: (json['best_rating'] as num?)?.toDouble(),
      gameCount: json['game_count'],
      winCount: json['win_count'],
      loseCount: json['lose_count'],
      rank: json['rank'],
    );
  }

  String get genderText {
    switch (gender) {
      case '1':
        return '男性';
      case '2':
        return '女性';
      default:
        return '未設定';
    }
  }

  double get winRate {
    if (gameCount == null || gameCount == 0) return 0;
    return (winCount ?? 0) / gameCount! * 100;
  }
}
