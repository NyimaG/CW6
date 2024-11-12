import 'package:flutter/material.dart';

class Subtask {
  String name;
  String day;
  String start;
  String finish;
  bool isCompleted;

  Subtask(
      {required this.name,
      required this.day,
      required this.start,
      required this.finish,
      required this.isCompleted});

//mapping to subtask fields from the database; each subtask is an array of maps (map = subtasks) for each main task

  factory Subtask.fromMap(Map<String, dynamic> data) {
    return Subtask(
      name: data['name'] ?? '',
      day: data['day'] ?? '',
      start: data['start'] ?? '',
      finish: data['finish'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
    );
  }

//mapping variables for input to subtask fields in database
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'day': day,
      'start': start,
      'finish': finish,
      'isCompleted': isCompleted,
    };
  }
}
