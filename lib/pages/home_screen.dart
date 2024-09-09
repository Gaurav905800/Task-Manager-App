import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
// ignore: depend_on_referenced_packages
import 'package:timezone/data/latest.dart' as tz;
// ignore: depend_on_referenced_packages
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_app/bloc/task_bloc.dart';
import 'package:todo_app/bloc/task_event.dart';
import 'package:todo_app/bloc/task_state.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/pages/add_screen.dart';
import 'package:todo_app/pages/detail_page.dart';
import 'package:todo_app/pages/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadTasksFromStorage();
    tz.initializeTimeZones(); // Initialize time zones
  }

  void _initializeNotifications() async {
    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('app_icon');

    fln.DarwinInitializationSettings initializationSettingsIOS =
        fln.DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {}

  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    String? payload = notificationResponse.payload;
  }

  Future<void> _loadTasksFromStorage() async {
    const storage = FlutterSecureStorage();
    String? tasksJson = await storage.read(key: 'tasks');

    if (tasksJson != null) {
      List<Task> tasks = decodeTasksFromJson(tasksJson);

      DateTime today = DateTime.now();
      DateTime oneWeekFromNow = today.add(const Duration(days: 7));
      bool hasTodayTask = tasks.any((task) =>
          task.dueDate.year == today.year &&
          task.dueDate.month == today.month &&
          task.dueDate.day == today.day);

      // Check if there are tasks due in one week
      for (var task in tasks) {
        if (task.dueDate.isAtSameMomentAs(oneWeekFromNow)) {
          _scheduleNotificationForOneWeekBefore(task);
        }
      }

      if (hasTodayTask) {
        _showNotification("Check your today's tasks", "Task Reminder");
      }
    }
  }

  void _scheduleNotificationForOneWeekBefore(Task task) async {
    // Convert the due date to a TZDateTime object.
    final scheduledDate = task.dueDate.subtract(const Duration(days: 7));

    // Set the notification time to 9 AM of the calculated date.
    final scheduleTime = tz.TZDateTime.from(
      DateTime(
          scheduledDate.year, scheduledDate.month, scheduledDate.day, 9, 0, 0),
      tz.local,
    );

    // Ensure the scheduled time is in the future.
    if (scheduleTime.isAfter(tz.TZDateTime.now(tz.local))) {
      const fln.AndroidNotificationDetails androidPlatformChannelSpecifics =
          fln.AndroidNotificationDetails(
        'weekly_reminder_channel_id',
        'Weekly Reminder',
        channelDescription: 'Reminder for tasks due in one week',
        importance: fln.Importance.max,
        priority: fln.Priority.high,
        ticker: 'Weekly Reminder',
      );

      const fln.NotificationDetails platformChannelSpecifics =
          fln.NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Upcoming Task Reminder',
        'You have a task due in one week: ${task.title}',
        scheduleTime,
        platformChannelSpecifics,
        // ignore: deprecated_member_use
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  List<Task> decodeTasksFromJson(String tasksJson) {
    List<dynamic> tasksList = jsonDecode(tasksJson);
    return tasksList.map((taskJson) => Task.fromJson(taskJson)).toList();
  }

  Future<void> _showNotification(String body, String title) async {
    const fln.AndroidNotificationDetails androidPlatformChannelSpecifics =
        fln.AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      ticker: 'ticker',
    );

    const fln.NotificationDetails platformChannelSpecifics =
        fln.NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

  void clearSecureStorage() async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    print('All data cleared from secure storage.');
  }

  void navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          IconButton(
            onPressed: navigateToSearch,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TaskLoaded) {
            final tasks = state.tasks
              ..sort((a, b) => _comparePriority(a.priority, b.priority));

            if (tasks.isEmpty) {
              return const Center(
                child: Text(
                  'No tasks added yet!',
                  style: TextStyle(fontSize: 20),
                ),
              );
            } else {
              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Dismissible(
                    key: Key(task.id.toString()),
                    background: Container(
                      color: Colors.green,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        context.read<TaskBloc>().add(DeleteTask(task.id!));
                        return true;
                      } else if (direction == DismissDirection.startToEnd) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskFormScreen(task: task),
                          ),
                        );
                        return false;
                      }
                      return null;
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskDetailScreen(task: task),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 4,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              task.description,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Priority: ${task.priority.toString().split('.').last}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Due Date: ${task.dueDate.toLocal().toString().split(' ')[0]}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          } else if (state is TaskError) {
            return Center(
              child: Text('Error: ${state.error}'),
            );
          } else {
            return const Center(child: Text('Something went wrong'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TaskFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  int _comparePriority(PriorityNew a, PriorityNew b) {
    if (a == PriorityNew.high && b != PriorityNew.high) {
      return -1;
    } else if (a == PriorityNew.medium && b == PriorityNew.low) {
      return -1;
    } else if (a == b) {
      return 0;
    } else {
      return 1;
    }
  }
}
