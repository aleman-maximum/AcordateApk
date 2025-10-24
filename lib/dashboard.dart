import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_task_page.dart';
import 'profile.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Usuario no autenticado',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final screens = [
      _buildTasksPage(user),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('TaskingCheck'),
        backgroundColor: Colors.black,
      ),
      body: screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.cyanAccent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddTaskPage()),
                ).then((_) => setState(() {})); // refrescar al volver
              },
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Mis Tareas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  /// Página de tareas del usuario autenticado
  Widget _buildTasksPage(User user) {
    final tasksStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .orderBy('dueDate')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No hay tareas disponibles',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final tasks = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index].data() as Map<String, dynamic>;
            final title = task['title'] ?? 'Sin título';
            final priority = task['priority'] ?? 'media';

            DateTime? dueDate;
            if (task['dueDate'] != null && task['dueDate'] is Timestamp) {
              dueDate = (task['dueDate'] as Timestamp).toDate();
            }

            Color priorityColor;
            switch (priority) {
              case 'alta':
                priorityColor = Colors.redAccent;
                break;
              case 'media':
                priorityColor = Colors.orangeAccent;
                break;
              case 'baja':
                priorityColor = Colors.greenAccent;
                break;
              default:
                priorityColor = Colors.white;
            }

            return Card(
              color: Colors.white10,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: dueDate != null
                    ? Text(
                        'Vence: ${dueDate.day}/${dueDate.month}/${dueDate.year} a las ${dueDate.hour}:${dueDate.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white70),
                      )
                    : const Text(
                        'Sin fecha',
                        style: TextStyle(color: Colors.white70),
                      ),
                trailing: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
