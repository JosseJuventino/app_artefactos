import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart'; // Asegúrate de importar Firebase
import 'dart:async'; // Importa StreamSubscription

class AlarmCard extends StatefulWidget {
  final String alarmMessage; // Mensaje de alarma
  final bool isAlarmButtonEnabled; // Estado del botón de alarma
  final String Function()
      getRemainingTime; // Función para obtener el tiempo restante
  final VoidCallback
      onAlarmPressed; // Callback cuando se presiona el botón de alarma
  final Function(DateTime)
      updateLastAlarmTime; // Callback para actualizar la última hora de apertura

  AlarmCard({
    required this.alarmMessage,
    required this.isAlarmButtonEnabled,
    required this.getRemainingTime,
    required this.onAlarmPressed,
    required this.updateLastAlarmTime,
  });

  @override
  _AlarmCardState createState() => _AlarmCardState();
}

class _AlarmCardState extends State<AlarmCard> {
  DateTime? lastOpenHour; // Última hora de apertura
  int totalPills = 0;

  // Variables para almacenar las suscripciones
  late StreamSubscription<DatabaseEvent> _openHourSubscription;
  late StreamSubscription<DatabaseEvent> _totalPillsSubscription;

  @override
  void initState() {
    super.initState();
    _loadData(); // Cargar la última hora de apertura desde Firebase
  }

  DateTime _parseFirebaseDate(String date) {
    // Ejemplo de entrada: "02/12/2024 04:45 a.m."
    final parts = date.split(' ');
    final dateParts = parts[0].split('/');
    final timeParts = parts[1].split(':');

    int day = int.parse(dateParts[0]);
    int month = int.parse(dateParts[1]);
    int year = int.parse(dateParts[2]);
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);

    // Ajustar la hora para el formato AM/PM
    if (parts[2].toLowerCase() == 'p.m.' && hour != 12) {
      hour += 12; // Convertir a formato 24 horas
    } else if (parts[2].toLowerCase() == 'a.m.' && hour == 12) {
      hour = 0; // Convertir 12 AM a 0 horas
    }

    return DateTime(year, month, day, hour, minute);
  }

  void _loadData() {
    final dbRefOpenHour = FirebaseDatabase.instance.ref('/openHour/');
    final dbRefTotalPills = FirebaseDatabase.instance.ref('/totalPills/');

    // Cargar la última hora de apertura
    _openHourSubscription = dbRefOpenHour.onValue.listen((event) {
      final data = event.snapshot.value as String?;
      if (data != null) {
        try {
          setState(() {
            lastOpenHour = _parseFirebaseDate(data);
          });
        } catch (e) {
          print("Error al parsear la fecha: $e");
        }
      }
    });

    // Cargar la cantidad total de pastillas
    _totalPillsSubscription = dbRefTotalPills.onValue.listen((event) {
      final data = event.snapshot.value as int?;
      if (data != null) {
        setState(() {
          totalPills = data; // Actualiza el total de pastillas
        });
      } else {
        setState(() {
          totalPills = 0; // Si no hay datos, establece en 0
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancela las suscripciones al eliminar el widget
    _openHourSubscription.cancel();
    _totalPillsSubscription.cancel();
    super.dispose();
  }

  // Formatear la fecha y hora según el caso
  String _getFormattedTime(DateTime? time) {
    if (time == null) return "No se ha abierto aún";

    final now = DateTime.now();
    final difference = now.difference(time);

    // Si la diferencia es menor a 24 horas, mostramos "Hoy a las [hora]"
    if (difference.inHours < 24) {
      return "Hoy a las ${DateFormat('hh:mm a').format(time)}"; // Formato "12:30 PM"
    }
    // Si es más de 24 horas pero menos de 48, mostramos "Ayer"
    else if (difference.inHours < 48) {
      return "Ayer a las ${DateFormat('hh:mm a').format(time)}";
    } else {
      return DateFormat('dd/MM/yyyy hh :mm a')
          .format(time); // Fecha completa si es más de 2 días
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Última apertura de caja de pastillas",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6200EE), // Color morado para el título
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                // Mostrar la fecha y hora formateada de la última apertura
                Text(
                  _getFormattedTime(lastOpenHour),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16, // Aumento del tamaño del texto
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.alarm,
                    color: widget.isAlarmButtonEnabled
                        ? Color(
                            0xFF6200EE) // Color morado cuando está habilitado
                        : Colors.grey, // Gris cuando está deshabilitado
                  ),
                  onPressed: widget.isAlarmButtonEnabled
                      ? () {
                          // Llamar al callback para actualizar la última hora de alarma
                          DateTime now = DateTime.now();
                          widget.updateLastAlarmTime(now);
                          widget
                              .onAlarmPressed(); // Llamar al callback original
                        }
                      : null,
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              "Cantidad de pastillas restantes en caja: $totalPills",
              style: TextStyle(
                fontSize: 16, // Tamaño de la fuente
                fontWeight: FontWeight.bold, // Peso de la fuente
                color: Colors.black, // Color del texto
              ),
            ),
            // Mostrar el mensaje de "Esperar X minutos" si es que existe
            if (widget.alarmMessage.isNotEmpty)
              Text(
                widget.alarmMessage,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}
