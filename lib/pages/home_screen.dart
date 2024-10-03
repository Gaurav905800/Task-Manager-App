import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animations/animations.dart';
import 'package:todo_app/controller/task_controller.dart';
import 'package:todo_app/pages/add_screen.dart';
import 'package:todo_app/pages/detail_page.dart';
import 'package:todo_app/pages/search_screen.dart';

class HomeScreen extends StatelessWidget {
  final TaskController taskController = Get.put(TaskController());

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          IconButton(
            onPressed: () {
              Get.to(() => const SearchScreen());
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Obx(
        () {
          final sortedTasks = List.of(taskController.tasks)
            ..sort((a, b) {
              int priorityComparison =
                  b.priority.index.compareTo(a.priority.index);
              if (priorityComparison == 0) {
                return a.dueDate.compareTo(b.dueDate);
              }
              return priorityComparison;
            });

          return sortedTasks.isEmpty
              ? const Center(
                  child: Text(
                    'No tasks added yet!',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : ListView.builder(
                  itemCount: sortedTasks.length,
                  itemBuilder: (context, index) {
                    final task = sortedTasks[index];
                    return Dismissible(
                      key: Key(task.id.toString()),
                      background: Container(
                        color: Colors.lime,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          taskController.deleteTask(task.id!);
                          return true;
                        } else if (direction == DismissDirection.startToEnd) {
                          Get.to(() => TaskFormScreen(task: task));
                          return false;
                        }
                        return null;
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                        child: OpenContainer(
                          closedElevation: 4.0,
                          transitionType: ContainerTransitionType.fade,
                          transitionDuration: const Duration(milliseconds: 700),
                          closedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          closedBuilder:
                              (BuildContext _, void Function() openContainer) {
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    task.description,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'Priority: ${task.priority.toString().split('.').last}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'Due Date: ${task.dueDate.toLocal().toString().split(' ')[0]}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            );
                          },
                          openBuilder: (BuildContext context,
                              void Function({Object? returnValue})
                                  closeContainer) {
                            return TaskDetailScreen(task: task);
                          },
                        ),
                      ),
                    );
                  },
                );
        },
      ),
      floatingActionButton: OpenContainer(
        closedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        closedColor: Theme.of(context).primaryColor,
        closedElevation: 6.0,
        transitionDuration: const Duration(milliseconds: 700),
        openBuilder: (context, _) {
          return const TaskFormScreen();
        },
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return FloatingActionButton(
            onPressed: openContainer,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
