import 'package:flutter/material.dart';
import '../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  RecipeCard({required this.recipe});

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
              'Valor de la pastilla: ${recipe.pillValue}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6200EE),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Pastillas por hora: ${recipe.pillsPerHour}',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            if (recipe.additionalMessage.isNotEmpty)
              Text(
                'Mensaje adicional: ${recipe.additionalMessage}',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}
