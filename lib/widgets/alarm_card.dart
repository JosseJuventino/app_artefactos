import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AlarmCard extends StatelessWidget {
  final DateTime? lastAlarmTime;
  final String alarmMessage;
  final bool isAlarmButtonEnabled;
  final String Function() getRemainingTime;
  final VoidCallback onAlarmPressed;

  AlarmCard({
    required this.lastAlarmTime,
    required this.alarmMessage,
    required this.isAlarmButtonEnabled,
    required this.getRemainingTime,
    required this.onAlarmPressed,
  });

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
      return DateFormat('dd/MM/yyyy hh:mm a')
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
                  _getFormattedTime(lastAlarmTime),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16, // Aumento del tamaño del texto
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.alarm,
                    color: isAlarmButtonEnabled
                        ? Color(
                            0xFF6200EE) // Color morado cuando está habilitado
                        : Colors.grey, // Gris cuando está deshabilitado
                  ),
                  onPressed: isAlarmButtonEnabled ? onAlarmPressed : null,
                ),
              ],
            ),
            SizedBox(height: 12),
            // Mostrar el mensaje de "Esperar X minutos" si es que existe
            if (alarmMessage.isNotEmpty)
              Text(
                alarmMessage,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}
