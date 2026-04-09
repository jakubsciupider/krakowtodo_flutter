class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority
  });
}

class TaskRepository {
  static List<Task> tasks = [
    Task(title: "Przeczytać o podstawach flutter", deadline: "28.03.2026", done: true, priority: "wysoki"),
    Task(title: "Zainstalować Android Studio", deadline: "27.03.2026", done: true, priority: "średni"),
    Task(title: "Zainstalować Android SDK", deadline: "27.03.2026", done: false, priority: "średni"),
    Task(title: "Zapoznać się z Git", deadline: "29.03.2026", done: false, priority: "wysoki")
  ];
}