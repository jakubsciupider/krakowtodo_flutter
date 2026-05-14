import 'package:flutter/material.dart';
import 'package:krakowtodo_flutter/services/task_local_database.dart';
import 'package:krakowtodo_flutter/services/task_sync_service.dart';
import 'task_repository.dart';

import '../services/task_api_service.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/task.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter(); // inicjalizacja hivea pod flutter
  await Hive.openBox("tasks"); // otwarcie kontenera na taski

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String filter = "wszystkie";
  String selectedFilter = "wszystkie";

  bool isLoading = true;
  late Future<List<Task>> _tasksFuture;

  final GlobalKey<_TaskListScreenState> _taskListKey = GlobalKey<_TaskListScreenState>();

  @override
  void initState() {
    super.initState();
    // zapytanie wysylane tylko raz przy starcie
    _tasksFuture = TaskApiService.fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    // w tej zmiennej znajduje sie obecnie przefiltrowana lista
    List<Task> filteredTasks = TaskRepository.tasks;

    // warunki przy filtrowaniu
    if (selectedFilter == "wykonane") {
      // wylapanie wykonanych taskow po parametrze done
      filteredTasks = TaskRepository.tasks.where((task) => task.done).toList();
    } else if (selectedFilter == "do zrobienia") {
      // wylapanie niewykonanych taskow - done maja ustawione na false
      filteredTasks = TaskRepository.tasks.where((task) => !task.done).toList();
    }

    final int completedTasks = TaskRepository.tasks.where((t) => t.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
        actions: [ // dodanie ikony kosza i funkcjonalnosci usuwania wszystkich taskow
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Potwierdzenie"),
                    content: const Text("Czy na pewno chcesz usunąć wszystkie zadania?"),
                    actions: [
                      TextButton( // anulowanie usuniecia
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Anuluj"),
                      ),
                      TextButton(
                          onPressed: () async {
                            // usuwanie wszystkich taskow z bazy
                            await TaskLocalDatabase.deleteAllTasks();
                            TaskRepository.tasks.clear();

                            // odswiezenie taskow/widoku
                            _taskListKey.currentState?.refreshTasks();

                            setState(() {});
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Usunięto wszystkie zadania!"),
                              ),
                            );
                          },
                          child: const Text("Usuń")
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Column(
              // wysrodkowanie napisu
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Masz dziś ${TaskRepository.tasks.length} zadania"),
                  SizedBox(height: 16),

                  // przyciski do filtrowania w jednym wierszu
                  Row(
                    // wysrodkowane wszystkich przyciskow
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => selectedFilter = "wszystkie"),
                        style: TextButton.styleFrom(
                          // zmiana koloru napisow
                          foregroundColor: selectedFilter == "wszystkie" ? Colors.green : Colors.deepPurple,
                        ),
                        child: const Text("Wszystkie"),
                      ),
                      TextButton(
                        onPressed: () => setState(() => selectedFilter = "do zrobienia"),
                        style: TextButton.styleFrom(
                          foregroundColor: selectedFilter == "do zrobienia" ? Colors.green : Colors.deepPurple,
                        ),
                        child: const Text("Do zrobienia"),
                      ),
                      TextButton(
                        onPressed: () => setState(() => selectedFilter = "wykonane"),
                        style: TextButton.styleFrom(
                          foregroundColor: selectedFilter == "wykonane" ? Colors.green : Colors.deepPurple,
                        ),
                        child: const Text("Wykonane"),
                      ),
                    ],
                  )
                ]
            ),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Zostały ci $completedTasks zadania do wykonania"),
                  SizedBox(height: 16)
                ]
            ),
            Text(
              "Dzisiejsze zadania",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic
              ),
            ),
            // pobierane taski z API
            Expanded(
              child: TaskListScreen(
                key: _taskListKey,
                filter: selectedFilter,
                onTasksChanged: () {
                  setState(() {});
                },
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => AddTaskScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );

          if (newTask != null) {
            await TaskLocalDatabase.updateTask(newTask); // zapis do bazy/aktualizacja
            _taskListKey.currentState?.refreshTasks();
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// lab7 - rozbudowane klasy TaskCard

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;

  // nowe parametry
  final bool done;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    this.onChanged,
    this.onTap,
  });

  // rozbudowa widgetu build

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
            value: done,
            onChanged: onChanged
        ),
        title: Text(
            title,
            style: TextStyle(
              // jezeli task zostanie wykonany to bedzie widoczny jako przekreslony i jasniejszy
              decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
              color: done ? Colors.grey : Colors.black,
            )
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Nowe zadanie"),
        ),
        body: Padding(
            padding: EdgeInsets.all(16),
            child: Column (
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Tytuł zadania",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: deadlineController,
                  decoration: const InputDecoration(
                    labelText: "Termin zadania",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: priorityController,
                  decoration: const InputDecoration(
                    labelText: "Priorytet zadania",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final newTask = Task(
                        id: Random().nextInt(1000000),
                        title: titleController.text,
                        deadline: deadlineController.text,
                        priority: priorityController.text,
                        done: false,
                      );

                      if (newTask.title.isNotEmpty) {
                        Navigator.pop(context, newTask);
                      }
                    },
                    child: const Text("Zapisz"),
                  ),
                )
              ],
            )
        )
    );
  }
}

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController titleController;
  late TextEditingController deadlineController;
  late TextEditingController priorityController;

  @override
  void initState() {
    super.initState();

    // inicjalizacja kontrolerow tylko jeden raz
    titleController = TextEditingController(text: widget.task.title);
    deadlineController = TextEditingController(text: widget.task.deadline);
    priorityController = TextEditingController(text: widget.task.priority);
  }

  @override
  void dispose() {
    // zwalnanie pamieci zajmowanej przez powyzsze kontrolery
    titleController.dispose();
    deadlineController.dispose();
    priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edytuj zadanie"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(
                labelText: "Termin zadania",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priorityController,
              decoration: const InputDecoration(
                labelText: "Priorytet zadania",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final updatedTask = Task(
                    id: widget.task.id, // dodanie pola id
                    title: titleController.text,
                    deadline: deadlineController.text,
                    priority: priorityController.text,
                    done: widget.task.done,
                  );

                  if (updatedTask.title.isNotEmpty) {
                    Navigator.pop(context, updatedTask);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Zaktualizuj"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  final String filter;
  final VoidCallback? onTasksChanged;

  const TaskListScreen({super.key, required this.filter, this.onTasksChanged});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();
    tasksFuture = loadTasks();
  }

  void refreshTasks() {
    setState(() {
      tasksFuture = loadTasks();
    });
  }

  Future<List<Task>> loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded();
    return TaskLocalDatabase.getTasks();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator()
          );
        }

        if (snapshot.hasError) {
          return Center(
              child: Text("Błąd: ${snapshot.error}")
          );
        }

        // pobieranie i filtrowanie taskow
        final allTasks = snapshot.data ?? [];

        final filteredTasks = allTasks.where((task) {
          if (widget.filter == "wykonane") return task.done;
          if (widget.filter == "do zrobienia") return !task.done;
          return true;
        }).toList();

        if (filteredTasks.isEmpty) {
          return const Center(child: Text("Brak zadań dla tego filtra"));
        }

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];

            return Dismissible(
              key: ValueKey(task.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) async {
                // usuwanie pojedynczego taska
                await TaskLocalDatabase.deleteTask(task.id);

                setState(() {
                  tasksFuture = loadTasks();
                });

                if (widget.onTasksChanged != null) {
                  widget.onTasksChanged!();
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Zadanie zostało usunięte!"),
                  ),
                );
              },
              child: TaskCard(
                title: task.title,
                subtitle: "Deadline: ${task.deadline}\nPriorytet: ${task.priority}",
                done: task.done,
                onChanged: (value) async {
                  final updatedTask = Task(
                    id: task.id,
                    title: task.title,
                    deadline: task.deadline,
                    priority: task.priority,
                    done: value ?? false,
                  );
                  await TaskLocalDatabase.updateTask(updatedTask);
                  setState(() {
                    tasksFuture = loadTasks();
                  });
                  if (widget.onTasksChanged != null) {
                    widget.onTasksChanged!();
                  }
                },
                onTap: () async {
                  final Task? updatedTask = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTaskScreen(task: task),
                    ),
                  );
                  if (updatedTask != null) {
                    await TaskLocalDatabase.updateTask(updatedTask);
                    setState(() {
                      tasksFuture = loadTasks();
                    });
                    if (widget.onTasksChanged != null) {
                      widget.onTasksChanged!();
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}