import 'package:flutter/material.dart';
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
      home: TaskListScreen(),
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

  //Checkbox method for tasks
  Future<void> _updateTaskStatus(String taskId, bool isCompleted) async {
    await FirebaseFirestore.instance.collection('Tasks').doc(taskId).update({
      'isCompleted': isCompleted,
    });
  }

//Delete method for tasks
  Future<void> _deletetask(String taskId) async {
    await FirebaseFirestore.instance.collection('Tasks').doc(taskId).delete();
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
      await _firestore.collection('Tasks').add({
        'Name': taskName,
        'isCompleted': false,
      });
      // _nameController.clear(); // Clear the input after adding the task
    }
  }

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
      await FirebaseFirestore.instance.collection('Tasks').doc(taskId).update({
        'Name': taskName,
        //'isCompleted': false,
      });
      // _nameController.clear(); // Clear the input after adding the task
    }
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
