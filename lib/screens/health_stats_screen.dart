import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/alarm_card.dart';
import '../widgets/temperature_card.dart';
import '../widgets/heart_rate_card.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import '../widgets/add_recipe_form.dart';
import 'package:firebase_database/firebase_database.dart'; // Importamos Realtime Database
import 'package:firebase_core/firebase_core.dart'; // Para inicializar Firebase

class HealthStatsScreen extends StatefulWidget {
  @override
  _HealthStatsScreenState createState() => _HealthStatsScreenState();
}

class _HealthStatsScreenState extends State<HealthStatsScreen> {
  DateTime? lastAlarmTime;
  bool isAlarmButtonEnabled = true;
  String alarmMessage = "";
  Timer? _timer;

  // Lista para almacenar las recetas
  List<PillBox> pillBoxes = [];

  @override
  void initState() {
    super.initState();
    // Obtener las recetas al inicializar el estado
    _loadPillBoxes();
  }

  void _loadPillBoxes() {
    final database = FirebaseDatabase.instance.reference();

    // Escuchar todos los cambios en tiempo real
    database.child('pillBoxes').onValue.listen((event) {
      final data = event.snapshot.value;

      if (data != null && data is Map) {
        List<PillBox> loadedPillBoxes = [];
        Map<dynamic, dynamic> pillBoxesMap = data;

        pillBoxesMap.forEach((key, value) {
          if (value is Map) {
            final newPillBox = PillBox(
              id: key, // Añadir un ID único
              pillName: value['pillName'],
              pillCount: value['pillCount'],
              schedule: List<String>.from(value['schedule']),
              note: value['note'],
            );
            loadedPillBoxes.add(newPillBox);
          }
        });

        setState(() {
          pillBoxes = loadedPillBoxes;
        });
      }
    });
  }

  // Función que devuelve el tiempo restante en formato "minutos segs"
  String getRemainingTime() {
    if (lastAlarmTime == null) {
      return "Listo para sonar";
    }
    final diff = DateTime.now().difference(lastAlarmTime!);
    final remainingSeconds = 300 - diff.inSeconds; // 300 segundos = 5 minutos
    if (remainingSeconds > 0) {
      final minutes = remainingSeconds ~/ 60;
      final seconds = remainingSeconds % 60;
      return "Esperar $minutes min $seconds sec"; // Formato minutos y segundos
    } else {
      return "Listo para sonar";
    }
  }

  // Llamada cuando se presiona el botón de alarma
  void onAlarmPressed() {
    setState(() {
      lastAlarmTime = DateTime.now();
      isAlarmButtonEnabled = false;
      alarmMessage = getRemainingTime();
    });

    // Configurar el Timer para actualizar el estado cada segundo
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        alarmMessage = getRemainingTime();
      });

      // Si el temporizador llega a cero, habilitamos el botón
      if (DateTime.now().difference(lastAlarmTime!).inSeconds >= 300) {
        _timer?.cancel();
        setState(() {
          isAlarmButtonEnabled = true;
          alarmMessage = "Listo para sonar";
        });
      }
    });
  }

  void _addPillBox(
      String pillName, int pillCount, List<String> schedule, String note) {
    Navigator.of(context)
        .pop(); // Cerrar el formulario de agregar caja de pastillas
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Caja de pastillas agregada con éxito')),
    );
  }

  void _openAddPillBoxDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Agregar Caja de Pastillas',
              style: TextStyle(color: Color(0xFF6200EE))),
          content:
              AddPillBoxForm(onSubmit: _addPillBox), // Cambiar a _addPillBox
        );
      },
    );
  }

  @override
  void dispose() {
    // Cancelar el Timer cuando se abandona la pantalla
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Stats'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // AlarmCard para mostrar la información de la alarma
            AlarmCard(
              lastAlarmTime: lastAlarmTime,
              alarmMessage: alarmMessage,
              isAlarmButtonEnabled: isAlarmButtonEnabled,
              getRemainingTime: getRemainingTime,
              onAlarmPressed: onAlarmPressed,
            ),
            SizedBox(height: 20),
            // Agregar tarjetas de Temperatura y Frecuencia Cardíaca
            TemperatureCard(),
            SizedBox(height: 20),
            HeartRateCard(),
            SizedBox(height: 20),
            // Mostrar las recetas agregadas
            Text(
              'Recetas Agregadas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6200EE),
              ),
            ),
            // Mostrar las recetas que se han cargado desde Realtime Database
            ...pillBoxes
                .map((pillBox) => PillBoxCard(pillBox: pillBox))
                .toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPillBoxDialog,
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF6200EE),
      ),
    );
  }
}
