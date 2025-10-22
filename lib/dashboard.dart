import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'profile.dart';
import 'add_task_page.dart'; // 🚀 Nueva Importación

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  // 🔹 Página 1: Lista de tareas
  Widget _buildTasksPage() {
    final user = FirebaseAuth.instance.currentUser!;
    final tasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks');

    return StreamBuilder<QuerySnapshot>(
      stream: tasksRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar tareas.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!.docs;

        if (tasks.isEmpty) {
          return const Center(
            child: Text(
              'No tienes tareas aún.\nPresiona + para añadir una nueva.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final title = task['title'] ?? '';
            final description = task['description'] ?? '';

            return Card(
              color: const Color.fromARGB(255, 26, 26, 26),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                title: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  description,
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.cyanAccent),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showTaskDialog(context, tasksRef, task);
                    } else if (value == 'delete') {
                      // 💡 NOTA: Aquí deberías considerar cancelar la notificación asociada a esta tarea.
                      tasksRef.doc(task.id).delete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🔹 Mostrar diálogo para añadir o editar tarea
  // Este método AHORA se usa SOLO para EDITAR tareas (desde el PopUpMenuButton)
  void _showTaskDialog(
    BuildContext context,
    CollectionReference tasksRef, [
    DocumentSnapshot? task,
  ]) {
    final titleController = TextEditingController(
      text: task != null ? task['title'] : '',
    );
    final descController = TextEditingController(
      text: task != null ? task['description'] : '',
    );

    // ... (Tu lógica del AlertDialog para edición, sin cambios)
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          task == null ? 'Nueva tarea' : 'Editar tarea',
          style: const TextStyle(color: Colors.cyanAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Título',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.cyanAccent),
                ),
              ),
            ),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Descripción',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.cyanAccent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.redAccent),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
            ),
            child: Text(task == null ? 'Guardar' : 'Actualizar'),
            onPressed: () async {
              final title = titleController.text.trim();
              final desc = descController.text.trim();

              if (title.isEmpty) return;

              if (task == null) {
                // NOTA: Esta rama 'Guardar' no se usará desde el FAB, solo si la llamas directamente.
                await tasksRef.add({
                  'title': title,
                  'description': desc,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              } else {
                await tasksRef.doc(task.id).update({
                  'title': title,
                  'description': desc,
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [_buildTasksPage(), const ProfilePage()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 47, 211, 233),
                Color.fromARGB(255, 0, 0, 0),
                Color.fromARGB(255, 238, 92, 151),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Tareas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.cyanAccent,
              child: const Icon(Icons.add, color: Colors.black),
              onPressed: () {
                // 🚀 CAMBIO CLAVE: Navegar a AddTaskPage para crear nuevas tareas.
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTaskPage()),
                );
                // El código anterior (llamando a _showTaskDialog) fue reemplazado.
              },
            )
          : null,
    );
  }
}
