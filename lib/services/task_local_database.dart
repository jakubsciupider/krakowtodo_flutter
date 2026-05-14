import 'package:hive_ce/hive.dart';
import '../models/task.dart';

class TaskLocalDatabase {
  // pobieranie kontenera tasks z maina() w main.dart
  static Box get _box => Hive.box("tasks");

  static List<Task> getTasks() {
    // zwracanie wszystkich danych z kontenera hive tasks
    return _box.values.map((item) {
      return Task.fromMap(Map<String, dynamic>.from(item));
    }).toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    await _box.clear();

    // zapisywanie danych dopasownych do ich klucza (k:v)
    for (final task in tasks) {
      await _box.put(task.id, task.toMap());
    }
  }

  static Future<void> addTask(Task task) async {
    // dodawania taska do kontenera
    await _box.put(task.id, task.toMap());
  }

  static Future<void> updateTask(Task task) async {
    // aktualizacja taska
    await _box.put(task.id, task.toMap());
  }

  static Future<void> deleteTask(int id) async {
    // usuwanie taska z kontenera po danym id, ktory bedzie kluczem
    await _box.delete(id);
  }

  static Future<void> deleteAllTasks() async {
    await _box.clear();
  }

  static bool isEmpty() {
    return _box.isEmpty;
  }
}