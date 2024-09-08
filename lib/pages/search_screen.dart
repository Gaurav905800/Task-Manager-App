import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_app/bloc/task_bloc.dart';
import 'package:todo_app/bloc/task_event.dart';
import 'package:todo_app/bloc/task_state.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/pages/detail_page.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Task> allTasks = [];
  List<Task> filteredTasks = [];

  @override
  void initState() {
    super.initState();
    BlocProvider.of<TaskBloc>(context).add(LoadTasks());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TaskLoaded) {
            allTasks = state.tasks;
            if (_searchController.text.isEmpty) {
              filteredTasks = allTasks;
            } else {
              filteredTasks = allTasks
                  .where((task) => task.title
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase()))
                  .toList();
            }

            return ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.description),
                  trailing: Text(
                      'Priority: ${task.priority.toString().split('.').last}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(
                          task: task,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          } else if (state is TaskError) {
            return Center(
              child: Text('Error: ${state.error}'),
            );
          } else {
            return const Center(child: Text('Something went wrong'));
          }
        },
      ),
    );
  }
}
