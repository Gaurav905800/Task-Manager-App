import 'package:flutter/material.dart';
import 'package:todo_app/controller/task_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'package:todo_app/models/task.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  // ignore: library_private_types_in_public_api
  _TaskFormScreenState createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  PriorityNew _selectedPriority = PriorityNew.low;
  DateTime _dueDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  final TaskController taskController = Get.find();

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedPriority = widget.task!.priority;
      _dueDate = widget.task!.dueDate;
    }
  }

  String _generateUniqueId() {
    return const Uuid().v4();
  }

  void _saveTask() {
    if (_formKey.currentState?.validate() ?? false) {
      final task = Task(
        id: widget.task?.id ?? _generateUniqueId(),
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _selectedPriority,
        dueDate: _dueDate,
      );
      if (widget.task == null) {
        taskController.addOrUpdateTask(task);
      } else {
        taskController.addOrUpdateTask(task);
      }
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task != null ? 'Edit Task' : 'Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                maxLength: 100,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<PriorityNew>(
                value: _selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: PriorityNew.values.map((PriorityNew priority) {
                  return DropdownMenuItem<PriorityNew>(
                    value: priority,
                    child: Text(priority.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (PriorityNew? newValue) {
                  setState(() {
                    _selectedPriority = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a priority';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      'Due Date: ${_dueDate.toLocal().toString().split(' ')[0]}'),
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null && pickedDate != _dueDate) {
                        setState(() {
                          _dueDate = pickedDate;
                        });
                      }
                    },
                    child: const Text('Select Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _saveTask,
                child: Text(widget.task == null ? 'Submit' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
