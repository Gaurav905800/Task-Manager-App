import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/pages/detail_page.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Task> allTasks = [];
  List<Task> filteredTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasksFromStorage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasksFromStorage() async {
    String? tasksJson = await _storage.read(key: 'tasks');

    if (tasksJson != null) {
      List<Task> tasks = decodeTasksFromJson(tasksJson);
      setState(() {
        allTasks = tasks;
        filteredTasks = tasks;
      });
    }
  }

  List<Task> decodeTasksFromJson(String tasksJson) {
    List<dynamic> tasksList = jsonDecode(tasksJson);
    return tasksList.map((taskJson) => Task.fromJson(taskJson)).toList();
  }

  void _searchTask(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredTasks = allTasks;
      } else {
        filteredTasks = allTasks
            .where((task) =>
                task.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
          ),
          onChanged: _searchTask,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _searchController.clear();
                filteredTasks = allTasks;
              });
            },
          ),
        ],
      ),
      body: filteredTasks.isEmpty
          ? const Center(child: Text('No tasks found'))
          : ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.description),
                  trailing: Text(
                      'Priority: ${task.priority.toString().split('.').last}'),
                  onTap: () {
                    Get.to(() => TaskDetailScreen(task: task));
                  },
                );
              },
            ),
    );
  }
}
