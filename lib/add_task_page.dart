// Archivo: lib/add_task_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/task.dart';
import 'services/notification_service.dart'; // Tu servicio de notificaciones

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Priority _selectedPriority = Priority.media;
  String? _error;

  final NotificationService _notificationService = NotificationService();

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() => _selectedTime = pickedTime);
    }
  }

  Future<void> _saveTask() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedDate == null || _selectedTime == null) {
      setState(
        () => _error =
            'Debes completar todos los campos, incluyendo fecha y hora.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Usuario no autenticado.');
      return;
    }

    // 1. Combinar Fecha y Hora
    final dueDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      // 2. Crear una referencia temporal para la tarea (ID se llenará al guardar)
      final tempTask = Task(
        id: 'temp',
        title: _titleController.text,
        userId: user.uid,
        dueDate: dueDate,
        priority: _selectedPriority,
      );

      // 3. Guardar en Firestore (en la colección anidada del usuario)
      final tasksCollectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks');

      final taskRef = await tasksCollectionRef.add(tempTask.toFirestore());

      // 4. Crear el objeto Task FINAL con el ID de Firestore
      final finalTask = Task(
        id: taskRef.id, // ID final
        title: _titleController.text,
        userId: user.uid,
        dueDate: dueDate,
        priority: _selectedPriority,
      );

      // 5. Programar la Notificación
      await _notificationService.scheduleNotification(finalTask);

      if (mounted) {
        Navigator.pop(context);
      }
    } on Exception catch (e) {
      setState(() => _error = 'Error al guardar la tarea: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formatDate(DateTime? date, TimeOfDay? time) {
      if (date == null || time == null) return 'Seleccionar Fecha y Hora';
      final formattedDate = '${date.day}/${date.month}/${date.year}';
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final ampm = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$formattedDate a las $hour:$minute $ampm';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Tarea'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ... (Tu TextFormField para el título)
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la Tarea',
                  border: OutlineInputBorder(),
                  // Agrega estilos si usas tema oscuro
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent, width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Selector de Fecha y Hora
              Card(
                color: Colors.white10,
                child: ListTile(
                  title: Text(
                    formatDate(_selectedDate, _selectedTime),
                    style: TextStyle(
                      color: _selectedDate == null
                          ? Colors.white54
                          : Colors.white,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.calendar_today,
                    color: Colors.cyanAccent,
                  ),
                  onTap: () async {
                    await _pickDate();
                    if (mounted && _selectedDate != null) {
                      await _pickTime();
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Selector de Prioridad
              const Text(
                'Prioridad:',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              Column(
                children: Priority.values.map((Priority priority) {
                  return RadioListTile<Priority>(
                    title: Text(
                      priority.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        color: priority == Priority.alta
                            ? Colors.redAccent
                            : Colors.white,
                      ),
                    ),
                    value: priority,
                    groupValue: _selectedPriority,
                    onChanged: (Priority? value) {
                      setState(() => _selectedPriority = value!);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),

              // Botón de Guardar
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _saveTask,
                child: const Text(
                  'Guardar Tarea y Programar Alerta',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
