import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'subclass.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TaskListScreen(),
    );
  }
}

class Task {
  String name = " ";
  bool isCompleted = false;
  String taskId;
  List<Subtask> subtasks;

  Task(
      {required this.name,
      required this.isCompleted,
      required this.taskId,
      this.subtasks = const []});

// Factory method to create a Task from Firestore document data
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    var subtaskList = (data['Subtasks'] as List<dynamic>? ?? [])
        .map((subtask) => Subtask.fromMap(subtask))
        .toList();

    return Task(
      name: data['name'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      taskId: doc.id,
      subtasks: subtaskList, // Use the document ID as taskId
    );
  }
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<List<Task>> _tasksStream;
  //final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set up a stream to listen for task data from Firestore
    _tasksStream = _firestore.collection('tasks').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  //Checkbox method for tasks
  Future<void> _updateTaskStatus(String taskId, bool isCompleted) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'isCompleted': isCompleted,
    });
  }

//Delete method for tasks
  Future<void> _deletetask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
  }

  // form for subtask fields
  Future<void> _showAddSubTaskDialog(String taskId) async {
    TextEditingController subTaskNameController = TextEditingController();
    TextEditingController startTimeController = TextEditingController();
    TextEditingController finishTimeController = TextEditingController();
    String selectedDay = 'Monday'; // Default day

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Subtask'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subTaskNameController,
                  decoration: InputDecoration(labelText: 'Subtask Name'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: InputDecoration(labelText: 'Day'),
                  items: [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday'
                  ].map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedDay = value;
                    }
                  },
                ),
                TextField(
                  controller: startTimeController,
                  decoration:
                      InputDecoration(labelText: 'Start Time (e.g., 08:00 AM)'),
                  readOnly: true,
                  onTap: () async {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      startTimeController.text = pickedTime.format(context);
                    }
                  },
                ),
                TextField(
                  controller: finishTimeController,
                  decoration: InputDecoration(
                      labelText: 'Finish Time (e.g., 09:00 AM)'),
                  readOnly: true,
                  onTap: () async {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      finishTimeController.text = pickedTime.format(context);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newSubTask = Subtask(
                  name: subTaskNameController.text,
                  day: selectedDay,
                  start: startTimeController.text,
                  finish: finishTimeController.text,
                  isCompleted: false,
                );

                // Add the new subtask to Firestore
                _addSubTask(taskId, newSubTask);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

// method to map input to subtask array for each Task in firebase

  Future<void> _addSubTask(String taskId, Subtask newSubtask) async {
    final taskRef = _firestore.collection('tasks').doc(taskId);

    await taskRef.update({
      'Subtasks': FieldValue.arrayUnion([newSubtask.toMap()]),
    });
  }

//Form for adding a new task
  Future<void> _showAddTaskDialog() async {
    TextEditingController taskNameController = TextEditingController();

    // Show dialog to enter the task name
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: TextField(
            controller: taskNameController,
            decoration: InputDecoration(hintText: 'Enter task name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Call addTask with the text from the input field
                addTask(taskNameController.text);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  //add task method
  Future<void> addTask(String taskName) async {
    if (taskName.isNotEmpty) {
      await _firestore.collection('tasks').add({
        'name': taskName,
        'isCompleted': false,
      });
      // _nameController.clear(); // Clear the input after adding the task
    }
  }

  /* Future<void> _showAddTaskDialog() async {
    TextEditingController taskNameController = TextEditingController();
    List<Map<String, dynamic>> subtasks = [];

    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController subtaskNameController = TextEditingController();
        TextEditingController subtaskDayController = TextEditingController();
        TextEditingController subtaskStartTimeController =
            TextEditingController();
        TextEditingController subtaskFinishTimeController =
            TextEditingController();

        bool showSubtaskFields = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: taskNameController,
                      decoration: InputDecoration(hintText: 'Enter task name'),
                    ),
                    SizedBox(height: 16),

                    // Button to add subtask fields
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showSubtaskFields = !showSubtaskFields;
                        });
                      },
                      child: Text(showSubtaskFields
                          ? 'Hide Subtask Fields'
                          : 'Add Subtask'),
                    ),

                    if (showSubtaskFields)
                      Column(
                        children: [
                          TextField(
                            controller: subtaskNameController,
                            decoration:
                                InputDecoration(hintText: 'Subtask name'),
                          ),
                          TextField(
                            controller: subtaskDayController,
                            decoration:
                                InputDecoration(hintText: 'Day of the week'),
                          ),
                          TextField(
                            controller: subtaskStartTimeController,
                            decoration: InputDecoration(hintText: 'Start time'),
                          ),
                          TextField(
                            controller: subtaskFinishTimeController,
                            decoration:
                                InputDecoration(hintText: 'Finish time'),
                          ),
                          SizedBox(height: 8),

                          ElevatedButton(
                            onPressed: () {
                              // Add the subtask to the list
                              setState(() {
                                subtasks.add({
                                  'name': subtaskNameController.text,
                                  'day': subtaskDayController.text,
                                  'start': subtaskStartTimeController.text,
                                  'finish': subtaskFinishTimeController.text,
                                  'isCompleted': false,
                                });
                              });

                              // Clear subtask fields
                              subtaskNameController.clear();
                              subtaskDayController.clear();
                              subtaskStartTimeController.clear();
                              subtaskFinishTimeController.clear();
                            },
                            child: Text('Add Subtask'),
                          ),

                          SizedBox(height: 8),

                          // Display the list of subtasks
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: subtasks.map((subtask) {
                              return ListTile(
                                title: Text(subtask['name']),
                                subtitle: Text(
                                    '${subtask['day']} | ${subtask['start']} - ${subtask['finish']}'),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Call addTask with the text from the input field and subtasks list
                    addTask(taskNameController.text, subtasks);
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Add Task'),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Modified addTask function to include subtasks
  Future<void> addTask(
      String taskName, List<Map<String, dynamic>> subtasks) async {
    if (taskName.isNotEmpty) {
      await FirebaseFirestore.instance.collection('tasks').add({
        'name': taskName,
        'isCompleted': false,
        'Subtasks': subtasks, // Add subtasks to Firestore
      });
    }
  }
*/
//form to update/edit task
  Future<void> _showUpdateTaskDialog(String taskId) async {
    TextEditingController taskNameController = TextEditingController();

    // Show dialog to enter the task name
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: TextField(
            controller: taskNameController,
            decoration: InputDecoration(hintText: 'Enter task name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Call addTask with the text from the input field
                _changeTask(taskNameController.text, taskId);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

// method to update/edit task
  Future<void> _changeTask(String taskName, taskId) async {
    if (taskName.isNotEmpty) {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'name': taskName,
        //'isCompleted': false,
      });
      // _nameController.clear(); // Clear the input after adding the task
    }
  }

  Future<void> _toggleSubtaskCompletion(String taskId, Subtask subtask) async {
    final taskRef = _firestore.collection('tasks').doc(taskId);
    final updatedSubtask = subtask.toMap()
      ..['isCompleted'] = !subtask.isCompleted;

    await taskRef.update({
      'Subtasks': FieldValue.arrayRemove([subtask.toMap()]),
    });
    await taskRef.update({
      'Subtasks': FieldValue.arrayUnion([updatedSubtask]),
    });
  }

  Future<void> _deleteSubTask(String taskId, Subtask subTask) async {
    final taskRef = _firestore.collection('tasks').doc(taskId);

    // Remove the specified subtask from the subtasks array in Firestore
    await taskRef.update({
      'Subtasks': FieldValue.arrayRemove([subTask.toMap()]),
    });
  }

//widget to display subtasks
  Widget _buildSubtasks(Task task) {
    return Column(
      children: task.subtasks.map((subtask) {
        return ListTile(
          title: Text(subtask.name),
          subtitle:
              Text('${subtask.day}, ${subtask.start} - ${subtask.finish}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: subtask.isCompleted,
                onChanged: (_) =>
                    _toggleSubtaskCompletion(task.taskId, subtask),
                activeColor: Colors.green,
                checkColor: Colors.white,
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteSubTask(task.taskId, subtask),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Task List'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: StreamBuilder<List<Task>>(
          stream: _tasksStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No tasks found.'));
            }

            final tasks = snapshot.data!;
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  child: ExpansionTile(
                    title: Text(task.name),
                    subtitle:
                        Text(task.isCompleted ? 'Completed' : 'Not Completed'),
                    trailing: SizedBox(
                      width: 180,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _showAddSubTaskDialog(task.taskId),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showUpdateTaskDialog(task.taskId),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deletetask(task.taskId),
                          ),
                          Checkbox(
                            value: task.isCompleted,
                            onChanged: (bool? newValue) {
                              if (newValue != null) {
                                _updateTaskStatus(task.taskId, newValue);
                              }
                            },
                            activeColor: Colors.green,
                            checkColor: Colors.white,
                          )
                        ],
                      ),
                    ),
                    children: [
                      _buildSubtasks(task),
                    ],
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            //print("Button pressed");
            _showAddTaskDialog();
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}







//THIS IS MY ORGINAL CODE WITHOUT SUBLIST; IT WORKS fl

/*import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TaskListScreen(), // Set TaskListScreen as the home screen
    );
  }
}

class Task {
  String name = " ";
  bool isCompleted = false;
  String taskId;

  Task({required this.name, required this.isCompleted, required this.taskId});

  // Factory method to create a Task from Firestore document data
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Task(
      name: data['Name'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      taskId: doc.id, // Use the document ID as taskId
    );
  }
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<List<Task>> _tasksStream;
  //final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set up a stream to listen for task data from Firestore
    _tasksStream = _firestore.collection('Tasks').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  Future<void> _showAddTaskDialog() async {
    TextEditingController taskNameController = TextEditingController();

    // Show dialog to enter the task name
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: TextField(
            controller: taskNameController,
            decoration: InputDecoration(hintText: 'Enter task name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Call addTask with the text from the input field
                addTask(taskNameController.text);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUpdateTaskDialog(String taskId) async {
    TextEditingController taskNameController = TextEditingController();

    // Show dialog to enter the task name
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: TextField(
            controller: taskNameController,
            decoration: InputDecoration(hintText: 'Enter task name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Call addTask with the text from the input field
                _changeTask(taskNameController.text, taskId);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> addTask(String taskName) async {
    if (taskName.isNotEmpty) {
      await _firestore.collection('Tasks').add({
        'Name': taskName,
        'isCompleted': false,
      });
      // _nameController.clear(); // Clear the input after adding the task
    }
  }

  Future<void> _updateTaskStatus(String taskId, bool isCompleted) async {
    await FirebaseFirestore.instance.collection('Tasks').doc(taskId).update({
      'isCompleted': isCompleted,
    });
  }

  Future<void> _changeTask(String taskName, taskId) async {
    if (taskName.isNotEmpty) {
      await FirebaseFirestore.instance.collection('Tasks').doc(taskId).update({
        'Name': taskName,
        //'isCompleted': false,
      });
      // _nameController.clear(); // Clear the input after adding the task
    }
  }

  Future<void> _deletetask(String taskId) async {
    await FirebaseFirestore.instance.collection('Tasks').doc(taskId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Task List'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: StreamBuilder<List<Task>>(
          stream: _tasksStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No tasks found.'));
            }

            final tasks = snapshot.data!;
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  title: Text(task.name),
                  subtitle:
                      Text(task.isCompleted ? 'Completed' : 'Not Completed'),
                  /*onTap: () {
                    // Toggle completion status in Firestore
                    _firestore.collection('Tasks').doc(task.taskId).update({
                      'isCompleted': !task.isCompleted,
                    });
                  },*/
                  trailing: SizedBox(
                    width: 150,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showUpdateTaskDialog(task.taskId),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deletetask(task.taskId),
                        ),
                        Checkbox(
                          value: task.isCompleted,
                          onChanged: (bool? newValue) {
                            if (newValue != null) {
                              _updateTaskStatus(task.taskId, newValue);
                            }
                          },
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            //print("Button pressed");
            _showAddTaskDialog();
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
*/