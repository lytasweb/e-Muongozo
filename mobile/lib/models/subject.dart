class Subject {
  final int id;
  final String name;
  final String level;
  final String category;
  final String icon;
  final String color;
  final int topicCount;

  const Subject({
    required this.id,
    required this.name,
    required this.level,
    this.category = 'Other',
    required this.icon,
    required this.color,
    this.topicCount = 0,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'],
        name: json['name'],
        level: json['level'],
        category: json['category'] ?? 'Other',
        icon: json['icon'] ?? 'A',
        color: json['color'] ?? '#3B82F6',
        topicCount: json['topic_count'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'category': category,
        'icon': icon,
        'color': color,
        'topic_count': topicCount,
      };
}
