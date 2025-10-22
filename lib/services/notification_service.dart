import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as futil; // 🔑 USAMOS EL PREFIJO 'futil' (Flutter Util)
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/task.dart'; // Tu modelo de datos (sin prefijo)

class NotificationService {
  final futil.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      futil.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Inicializar Timezone (¡AQUÍ VA ESTA LÓGICA!)
    tzdata.initializeTimeZones();
    tz.setLocalLocation(
      tz.getLocation('America/Mexico_City'),
    ); // Ajusta a tu zona horaria

    // 2. Inicializar el plugin para Android
    const futil.AndroidInitializationSettings initializationSettingsAndroid =
        futil.AndroidInitializationSettings('@mipmap/ic_launcher');

    const futil.InitializationSettings initializationSettings =
        futil.InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleNotification(Task task) async {
    // 1. Definir la hora de la notificación (ej: 30 minutos antes del vencimiento)
    final scheduledDate = task.dueDate.subtract(const Duration(minutes: 30));

    // 2. Convertir a la zona horaria local (¡AQUÍ ESTÁ LA DEFINICIÓN DE scheduledTZ!)
    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    // 3. Si la fecha programada ya pasó, no notificar
    if (scheduledTZ.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    // 4. Detalles de la notificación
    const futil.AndroidNotificationDetails androidDetails =
        futil.AndroidNotificationDetails(
          'task_channel_id',
          'Recordatorios de Tareas',
          channelDescription: 'Alertas para tareas pendientes con prioridad',
          importance: futil.Importance.max,
          priority: futil.Priority.high,
          playSound: true,
        );

    const futil.NotificationDetails platformDetails = futil.NotificationDetails(
      android: androidDetails,
    );

    final notificationId = task.id.hashCode;
    final taskPriorityName = task.priority
        .toString()
        .split('.')
        .last
        .toUpperCase();

    // 5. Programar la notificación
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      '🚨 Tarea de Prioridad $taskPriorityName 🚨',
      '¡Atención! "${task.title}" vence en 30 minutos.',
      scheduledTZ, // Aquí se usa la variable definida
      platformDetails,
      androidScheduleMode: futil.AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(Task task) async {
    await flutterLocalNotificationsPlugin.cancel(task.id.hashCode);
  }
}
