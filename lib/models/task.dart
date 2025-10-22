// Archivo: lib/models/task.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Enum para la Prioridad
enum Priority { baja, media, alta }

class Task {
  final String id;
  final String title;
  final String userId;
  final DateTime dueDate;
  final Priority priority;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.userId,
    required this.dueDate,
    required this.priority,
    this.isCompleted = false,
  });

  // ... (Resto de los métodos fromFirestore y toFirestore)
  // Dejamos el cuerpo aquí por brevedad, asumiendo que ya lo tienes
  factory Task.fromFirestore(DocumentSnapshot doc) {
    // ... Implementación ...
    throw UnimplementedError();
  }

  Map<String, dynamic> toFirestore() {
    // ... Implementación ...
    throw UnimplementedError();
  }
}
