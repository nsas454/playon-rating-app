class Category {
  final int id;
  final String game;
  final String name;
  final String code;
  final bool isAcceptingEntry;
  final int? entryFee;
  final int entryRegistrationCount;
  final int? entryMax;

  Category({
    required this.id,
    required this.game,
    required this.name,
    required this.code,
    required this.isAcceptingEntry,
    this.entryFee,
    required this.entryRegistrationCount,
    this.entryMax,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      game: json['game'],
      name: json['name'],
      code: json['code'] ?? '',
      isAcceptingEntry: json['is_accepting_entry'] ?? false,
      entryFee: json['entry_fee'],
      entryRegistrationCount: json['entry_registration_count'] ?? 0,
      entryMax: json['entry_max'],
    );
  }
}

class Game {
  final String slug;
  final String name;
  final String place;
  final String placeAddress;
  final String startDate;
  final String endDate;
  final String? entryDeadline;
  final String organizationName;
  final bool enableWebEntry;
  final List<Category> categories;

  Game({
    required this.slug,
    required this.name,
    required this.place,
    required this.placeAddress,
    required this.startDate,
    required this.endDate,
    this.entryDeadline,
    required this.organizationName,
    required this.enableWebEntry,
    required this.categories,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      slug: json['slug'],
      name: json['name'],
      place: json['place'] ?? '',
      placeAddress: json['place_address'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      entryDeadline: json['entry_deadline'],
      organizationName: json['organization_name'] ?? '',
      enableWebEntry: json['enable_web_entry'] ?? false,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((c) => Category.fromJson(c))
              .toList() ??
          [],
    );
  }

  List<Category> get acceptingCategories =>
      categories.where((c) => c.isAcceptingEntry).toList();
}
