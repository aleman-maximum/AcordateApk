import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/task.dart';
import 'services/notification_service.dart';

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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveTask() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedDate == null || _selectedTime == null) {
      setState(() => _error = 'Debes completar todos los campos, incluyendo fecha y hora.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Usuario no autenticado.');
      return;
    }

    final dueDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      final tasksRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks');

      final taskData = {
        'title': _titleController.text.trim(),
        'userId': user.uid,
        'dueDate': Timestamp.fromDate(dueDate),
        'priority': _selectedPriority.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await tasksRef.add(taskData);

      final task = Task(
        id: docRef.id,
        title: _titleController.text.trim(),
        userId: user.uid,
        dueDate: dueDate,
        priority: _selectedPriority,
      );

      // Aquí sí funciona, porque pasas el objeto Task
      await _notificationService.scheduleNotification(task);

      if (mounted) Navigator.pop(context);
    } catch (e) {
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
      final formatted = '${date.day}/${date.month}/${date.year}';
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final ampm = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$formatted a las $hour:$minute $ampm';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Tarea'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la Tarea',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent, width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'El título es obligatorio' : null,
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.white10,
                child: ListTile(
                  title: Text(
                    formatDate(_selectedDate, _selectedTime),
                    style: TextStyle(
                        color:
                            _selectedDate == null ? Colors.white54 : Colors.white),
                  ),
                  trailing:
                      const Icon(Icons.calendar_today, color: Colors.cyanAccent),
                  onTap: () async {
                    await _pickDate();
                    if (mounted && _selectedDate != null) {
                      await _pickTime();
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text('Prioridad:',
                  style: TextStyle(fontSize: 16, color: Colors.white70)),
              Column(
                children: Priority.values.map((priority) {
                  return RadioListTile<Priority>(
                    title: Text(priority.name.toUpperCase(),
                        style: TextStyle(
                            color: priority == Priority.alta
                                ? Colors.redAccent
                                : Colors.white)),
                    value: priority,
                    groupValue: _selectedPriority,
                    onChanged: (value) =>
                        setState(() => _selectedPriority = value!),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _saveTask,
                child: const Text('Guardar Tarea',
                    style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
