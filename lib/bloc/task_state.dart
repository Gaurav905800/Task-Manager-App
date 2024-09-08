import 'package:equatable/equatable.dart';
import 'package:todo_app/models/task.dart';

abstract class TaskState extends Equatable {
  @override
  List<Object> get props => [];
}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<Task> tasks;

  TaskLoaded(this.tasks);

  @override
  List<Object> get props => [tasks];
}

class TaskError extends TaskState {
  final String error;

  TaskError({required this.error});

  @override
  List<Object> get props => [error];
}
