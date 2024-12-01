import 'package:flutter/material.dart';
import '../models/recipe.dart'; // Asegúrate de que este es el nombre correcto del modelo

class PillBoxCard extends StatelessWidget {
  final PillBox pillBox;

  PillBoxCard({required this.pillBox});

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
              'Nombre de la pastilla: ${pillBox.pillName}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6200EE),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Cantidad de pastillas: ${pillBox.pillCount}',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Horarios: ${pillBox.schedule.join(', ')}', // Mostrar los horarios de toma
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
