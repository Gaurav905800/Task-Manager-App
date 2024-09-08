enum PriorityNew { low, medium, high }

class Task {
  var id;
  String title;
  String description;
  PriorityNew priority;
  DateTime dueDate;
  bool isCompleted;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    this.isCompleted = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: PriorityNew.values[json['priority']],
      dueDate: DateTime.parse(json['dueDate']),
      isCompleted: json['isCompleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}
