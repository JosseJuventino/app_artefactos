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
  PillBox? lastPillBox;

  @override
  void initState() {
    super.initState();
    _loadPillBoxes();
  }

  void _loadPillBoxes() {
    final database = FirebaseDatabase.instance.reference();

    database.child('pillBoxes').onValue.listen((event) {
      final data = event.snapshot.value;

      if (data != null && data is Map) {
        List<PillBox> loadedPillBoxes = [];
        Map<dynamic, dynamic> pillBoxesMap = data;

        pillBoxesMap.forEach((key, value) {
          if (value is Map) {
            final newPillBox = PillBox(
              id: key,
              pillName: value['pillName'],
              pillCount: value['pillCount'],
              schedule: List<String>.from(value['schedule']),
              note: value['note'],
              timestamp: value['timestamp'], // Asegúrate de tener este campo
            );
            loadedPillBoxes.add(newPillBox);
          }
        });

        setState(() {
          pillBoxes = loadedPillBoxes;

          // Obtener la última PillBox basada en el timestamp
          if (pillBoxes.isNotEmpty) {
            lastPillBox =
                pillBoxes.reduce((a, b) => a.timestamp > b.timestamp ? a : b);
            _scheduleNotification(
                lastPillBox!); // Programar la notificación para la última PillBox
          }
        });
      }
    });
  }

  void _scheduleNotification(PillBox pillBox) {
    // Programar un Timer para verificar la hora
    Timer.periodic(Duration(minutes: 1), (timer) {
      DateTime now = DateTime.now();

      // Comprobar si ahora es la hora de tomar la pastilla
      for (String schedule in pillBox.schedule) {
        // Supongamos que schedule tiene el formato "h:mm AM/PM"
        try {
          DateTime scheduledTime = _parseTime(schedule);
          int scheduleHour = scheduledTime.hour;
          int scheduleMinute = scheduledTime.minute;

          if (now.hour == scheduleHour && now.minute == scheduleMinute) {
            _updateNotificationStatus(pillBox);
            timer.cancel(); // Detener el timer después de la notificación
            break; // Salir del bucle si se ha encontrado una coincidencia
          }
        } catch (e) {
          print("Error al parsear el horario: $schedule");
        }
      }
    });
  }

// Función para convertir el horario en formato "h:mm AM/PM" a un objeto DateTime
  DateTime _parseTime(String time) {
    // Dividir la cadena en partes
    List<String> parts = time.split(' ');
    String timePart = parts[0];
    String amPm = parts[1];

    // Dividir la parte de la hora y los minutos
    List<String> timeParts = timePart.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);

    // Convertir a formato de 24 horas
    if (amPm.toUpperCase() == 'PM' && hour != 12) {
      hour += 12; // Convertir a 24 horas
    } else if (amPm.toUpperCase() == 'AM' && hour == 12) {
      hour = 0; // Convertir 12 AM a 0 horas
    }

    // Retornar un nuevo DateTime con la fecha actual y la hora programada
    return DateTime.now()
        .copyWith(hour: hour, minute: minute, second: 0, millisecond: 0);
  }

  void _updateNotificationStatus(PillBox pillBox) async {
    final database = FirebaseDatabase.instance.reference();

    // Cambiar el valor de notificacion a 'yes'
    await database.child('notification/').set('yes');

    // Cambiar el valor de notificacion a 'no' después de 3 segundos
    Future.delayed(Duration(seconds: 3), () async {
      await database.child('notification/').set('no');
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

  void onAlarmPressed() {
    // Obtener la referencia a la base de datos
    final database = FirebaseDatabase.instance.reference();

    // Actualizar el valor de notification a "yes" en la base de datos
    database.child('notification/').set("yes").then((_) {
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

      // Cambiar notification a "no" después de 3 segundos
      Future.delayed(Duration(seconds: 3), () {
        database.child('notification/').set("no").then((_) {
          print("Notification set to 'no'"); // Confirmación en consola
        }).catchError((error) {
          print("Error al actualizar notification: $error");
        });
      });
    }).catchError((error) {
      // Manejar el error si la actualización falla
      print("Error al actualizar notification: $error");
    });
  }

  void updateLastAlarmTime(DateTime newTime) {
    setState(() {
      lastAlarmTime = newTime;
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
              alarmMessage: alarmMessage,
              isAlarmButtonEnabled: isAlarmButtonEnabled,
              getRemainingTime: getRemainingTime,
              onAlarmPressed: onAlarmPressed,
              updateLastAlarmTime: updateLastAlarmTime,
            ),
            SizedBox(height: 20),
            // Agregar tarjetas de Temperatura y Frecuencia Cardíaca
            TemperatureCard(),
            SizedBox(height: 20),
            HeartRateCard(),
            SizedBox(height: 20),
            // Mostrar las recetas agregadas
            Text(
              'Caja de pastillas',
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
