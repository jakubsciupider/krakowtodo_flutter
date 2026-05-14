import '../models/task.dart';
import 'task_api_service.dart';
import 'task_local_database.dart';

class TaskSyncService {
  static Future<void> loadInitialDataIfNeeded() async {
    // jezeli nasza lokalna baza ma juz dane to ponownie nie beda one pobierane

    if (!TaskLocalDatabase.isEmpty()) {
      return;
    }

    // jezeli natomiast ich nie ma to sa one pobierane i zapisywane
    final tasks = await TaskApiService.fetchTasks();
    await TaskLocalDatabase.saveTasks(tasks);
  }
}