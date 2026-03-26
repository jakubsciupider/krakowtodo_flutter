import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final int completedTasks = tasks.where((t) => t.done).length;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("KrakFlow"),
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Masz dziś ${tasks.length} zadania"),
                  SizedBox(height: 16)
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
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return TaskCard(
                      title: tasks[index].title,
                      subtitle: "Deadline: ${tasks[index].deadline}\nPriorytet: ${tasks[index].priority}",
                      icon: tasks[index].done ? Icons.check_circle : Icons.radio_button_unchecked
                    );
                  },
                ),
              ),
            ],
          ),
        )
      ),
    );
  }
}

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

List<Task> tasks = [
  Task(title: "Przeczytać o podstawach flutter", deadline: "28.03.2026", done: true, priority: "wysoki"),
  Task(title: "Zainstalować Android Studio", deadline: "27.03.2026", done: true, priority: "średni"),
  Task(title: "Zainstalować Android SDK", deadline: "27.03.2026", done: false, priority: "średni"),
  Task(title: "Zapoznać się z Git", deadline: "29.03.2026", done: false, priority: "wysoki")
];

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}