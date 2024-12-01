import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importar firebase_core
import 'screens/health_stats_screen.dart';

void main() async {
  // Asegurarse de que los widgets están inicializados antes de ejecutar la app
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Stats',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF6200EE),
        scaffoldBackgroundColor: Color(0xFFF7F7F7),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Color(0xFF6200EE)),
          titleTextStyle: TextStyle(
            color: Color(0xFF6200EE),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      home: HealthStatsScreen(),
    );
  }
}
