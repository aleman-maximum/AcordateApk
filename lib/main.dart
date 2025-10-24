import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 🔒 IMPORTACIÓN NECESARIA PARA APP CHECK
import 'package:firebase_app_check/firebase_app_check.dart';

// 🧭 Importaciones CLAVE para Timezone
import 'package:timezone/data/latest_all.dart' as tz; // Carga los datos de zona
import 'package:timezone/timezone.dart' as tz; // Para usar TZDateTime

import 'firebase_options.dart';
import 'login.dart';
import 'dashboard.dart';

// 🚀 Importación del servicio de notificaciones
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Firebase Core
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🧭 2. INICIALIZAR LA BASE DE DATOS DE ZONA HORARIA (¡CRÍTICO!)
  // Esto debe hacerse antes de inicializar el servicio de notificaciones.
  tz.initializeTimeZones();

  // 🔒 3. INICIALIZACIÓN DE APP CHECK
  await FirebaseAppCheck.instance.activate(
    // Configuración para Android
    androidProvider: AndroidProvider.playIntegrity,

    // 💻 Configuración para Web
    webProvider: ReCaptchaV3Provider(
      '6Lc1H_UrAAAAANltWq-pY11iXLcm83744gdTrbVn', // Tu clave reCAPTCHA
    ),
  );

  // 🚀 4. Inicializar el Servicio de Notificaciones
  await NotificationService().initNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasking Check', // Título de la aplicación
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
            return const DashboardPage();
          }

          // Si no hay sesión, mostramos el login
          return const LoginPage();
        },
      ),
    );
  }
}
