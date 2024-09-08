import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:todo_app/bloc/task_event.dart';
import 'package:todo_app/bloc/task_state.dart';
import 'package:todo_app/models/task.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  TaskBloc() : super(TaskLoading()) {
    on<LoadTasks>((event, emit) async {
      try {
        final tasks = await _loadTasksFromStorage();
        emit(TaskLoaded(tasks));
      } catch (e) {
        emit(TaskError(error: e.toString()));
      }
    });

    on<AddTask>((event, emit) async {
      if (state is TaskLoaded) {
        final currentTasks = (state as TaskLoaded).tasks;
        final updatedTasks = List<Task>.from(currentTasks)..add(event.task);
        emit(TaskLoaded(updatedTasks));
        await _saveTasksToStorage(updatedTasks);
      }
    });

    on<UpdateTask>((event, emit) async {
      if (state is TaskLoaded) {
        final currentTasks = (state as TaskLoaded).tasks;
        final updatedTasks = List<Task>.from(currentTasks)
          ..removeWhere((task) => task.id == event.task.id)
          ..add(event.task);
        emit(TaskLoaded(updatedTasks));
        await _saveTasksToStorage(updatedTasks);
      }
    });

    on<DeleteTask>((event, emit) async {
      if (state is TaskLoaded) {
        final currentTasks = (state as TaskLoaded).tasks;
        final updatedTasks = List<Task>.from(currentTasks)
          ..removeWhere((task) => task.id == event.taskId);
        emit(TaskLoaded(updatedTasks));
        await _saveTasksToStorage(updatedTasks);
      }
    });
  }

  Future<List<Task>> _loadTasksFromStorage() async {
    try {
      final jsonString = await _storage.read(key: 'tasks');
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.map((json) => Task.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  Future<void> _saveTasksToStorage(List<Task> tasks) async {
    try {
      final jsonString =
          json.encode(tasks.map((task) => task.toJson()).toList());
      await _storage.write(key: 'tasks', value: jsonString);
    } catch (e) {
      throw Exception('Failed to save tasks: $e');
    }
  }
}
