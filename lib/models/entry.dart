class EntryRegistration {
  final int id;
  final String? gameName;
  final String? gameSlug;
  final String? gameStartDate;
  final String categoryName;
  final bool isCancel;
  final bool paid;
  final String? entryDeadline;

  EntryRegistration({
    required this.id,
    this.gameName,
    this.gameSlug,
    this.gameStartDate,
    required this.categoryName,
    required this.isCancel,
    required this.paid,
    this.entryDeadline,
  });

  factory EntryRegistration.fromJson(Map<String, dynamic> json) {
    final game = json['game'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;
    return EntryRegistration(
      id: json['id'],
      gameName: game?['name'],
      gameSlug: game?['slug'],
      gameStartDate: game?['start_date'],
      categoryName: category?['name'] ?? json['category_name'] ?? '',
      isCancel: json['is_cancel'] ?? false,
      paid: json['paid'] ?? false,
      entryDeadline: game?['entry_deadline'],
    );
  }
}
