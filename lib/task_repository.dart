import 'models/task.dart';

class TaskRepository {
  static List<Task> tasks = [
    Task(id: 1, title: "Przeczytać o podstawach flutter", deadline: "28.03.2026", done: true, priority: "wysoki"),
    Task(id: 2, title: "Zainstalować Android Studio", deadline: "27.03.2026", done: true, priority: "średni"),
    Task(id: 3, title: "Zainstalować Android SDK", deadline: "27.03.2026", done: false, priority: "średni"),
    Task(id: 4, title: "Zapoznać się z Git", deadline: "29.03.2026", done: false, priority: "wysoki")
  ];
}