import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:todo_app/models/task.dart';

class TaskController extends GetxController {
  final tasks = <Task>[].obs;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    _loadTasksFromStorage();
  }

  Future<void> _loadTasksFromStorage() async {
    String? tasksJson = await _storage.read(key: 'tasks');
    if (tasksJson != null) {
      List<Task> storedTasks = decodeTasksFromJson(tasksJson);
      tasks.assignAll(storedTasks);
    }
  }

  List<Task> decodeTasksFromJson(String tasksJson) {
    List<dynamic> tasksList = jsonDecode(tasksJson);
    return tasksList.map((taskJson) => Task.fromJson(taskJson)).toList();
  }

  Future<void> addOrUpdateTask(Task task) async {
    if (tasks.any((t) => t.id == task.id)) {
      int index = tasks.indexWhere((t) => t.id == task.id);
      tasks[index] = task;
    } else {
      tasks.add(task);
    }
    await _saveTasksToStorage();
  }

  Future<void> _saveTasksToStorage() async {
    String tasksJson = jsonEncode(tasks.map((task) => task.toJson()).toList());
    await _storage.write(key: 'tasks', value: tasksJson);
  }

  void deleteTask(String taskId) {
    tasks.removeWhere((task) => task.id == taskId);
    _saveTasksToStorage();
  }
}
