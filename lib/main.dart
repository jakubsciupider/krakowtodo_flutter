import 'package:flutter/material.dart';
import 'task_repository.dart';

import '../services/task_api_service.dart';

void main() {
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

  bool isLoading = true; // flaga ladowania aplikacji
  late Future<List<Task>> _tasksFuture;

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
                        onPressed: () {
                          setState(() {
                            TaskRepository.tasks.clear(); // usuwanie wszystkich taskow
                          });
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
              child: TaskListScreen(filter: selectedFilter),
            )
            /* statyczne wyswietlanie taskow
            Expanded(
              child: ListView.builder(
                // zamiast wyszukiwac wszystkie taski z taskrepository to korzysta sie z filtrowanych taskow
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];

                  return Dismissible(
                    // unikalny identyfiikator elementu
                    key: ValueKey(task.title),

                    // ponizszy fragment kodu wykonuje sie po usunieciu taska
                    onDismissed: (direction) {
                      setState(() {
                        TaskRepository.tasks.remove(task);
                      });

                      // tekst, ktory zostanie wykonany po usunieciu za pomoca snackbaru
                      // pojawi sie na dole ekranu na calej szerokosci
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
                      onChanged: (value) {
                        setState(() {
                          task.done = value!;
                        });
                      },
                      onTap: () async {
                        final Task? updatedTask = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EditTaskScreen(task: task)
                          ),
                        );

                        // setState odswiezy w tym momencie ekran

                        if (updatedTask != null) {
                          setState(() {
                            TaskRepository.tasks[index] = updatedTask;
                          });
                        }

                      }
                    ),
                  );
                },
              ),
            ), */
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
            setState(() {
              TaskRepository.tasks.add(newTask);
            });
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
  const TaskListScreen({super.key, required this.filter});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> tasksFuture;
  @override
  void initState() {
    super.initState();
    tasksFuture = TaskApiService.fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Błąd: ${snapshot.error}"));
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
            return TaskCard(
              title: task.title,
              subtitle: "Deadline: ${task.deadline}\nPriorytet: ${task.priority}",
              done: task.done,
              onChanged: (value) {
                setState(() => task.done = value!);
              },
            );
          },
        );
      },
    );
  }
}