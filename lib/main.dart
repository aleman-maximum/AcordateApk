import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'dashboard.dart';
// 🚀 Nueva Importación: El servicio que creamos
import 'services/notification_service.dart';

// Instancia global del servicio de notificaciones
final NotificationService _notificationService = NotificationService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🚀 2. Inicializar el Servicio de Notificaciones
  await _notificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasking Check', // Cambié el título para reflejar la app de tareas
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Muestra un spinner mientras Firebase revisa la sesión
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Si hay un usuario logueado, vamos al dashboard
          if (snapshot.hasData) {
            // NOTA: Para implementar la verificación de correo aquí,
            // se recomienda añadir una lógica de verificación en el StreamBuilder:
            /*
            final user = snapshot.data;
            if (user != null && !user.emailVerified) {
                return const VerificationRequiredPage(); // Si no ha verificado
            }
            */
            return const DashboardPage();
          }

          // Si no hay sesión, mostramos el login
          return const LoginPage();
        },
      ),
    );
  }
}
