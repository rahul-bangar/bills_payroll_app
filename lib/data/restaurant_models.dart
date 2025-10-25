class Restaurant {
  String id;
  String name;
  DateTime createdDate;
  bool isDeleted;

  Restaurant({
    required this.id,
    required this.name,
    required this.createdDate,
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdDate': createdDate.toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory Restaurant.fromJson(Map<String, dynamic> j) => Restaurant(
        id: j['id'],
        name: j['name'],
        createdDate: DateTime.parse(j['createdDate']),
        isDeleted: j['isDeleted'] ?? false,
      );
}