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
  List<Recipe> recipes = [];

  @override
  void initState() {
    super.initState();
    // Obtener las recetas al inicializar el estado
    _loadRecipes();
  }

  void _loadRecipes() {
    final database = FirebaseDatabase.instance.reference();

    // Escuchar la carga inicial de todas las recetas
    database.child('recipes').once().then((event) {
      final data = event.snapshot.value;

      if (data != null && data is Map) {
        List<Recipe> loadedRecipes = [];
        Map<dynamic, dynamic> recipesMap = data;

        recipesMap.forEach((key, value) {
          // Asegurarse de que 'value' es un Map y no otro tipo de objeto
          if (value is Map) {
            final newRecipe = Recipe(
              pillValue: value['pillValue'],
              pillsPerHour: value['pillsPerHour'],
              additionalMessage: value['additionalMessage'],
            );
            loadedRecipes.add(newRecipe);
          }
        });

        // Actualizamos la lista de recetas al cargar desde la base de datos
        setState(() {
          recipes = loadedRecipes;
        });
      }
    });

    // Escuchar cambios en tiempo real como ya se explicó
    database.child('recipes').onChildAdded.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final newRecipe = Recipe(
          pillValue: data['pillValue'],
          pillsPerHour: data['pillsPerHour'],
          additionalMessage: data['additionalMessage'],
        );
        setState(() {
          recipes.add(newRecipe); // Agregar receta a la lista
        });
      }
    });

    // Detectar cambios en recetas existentes
    database.child('recipes').onChildChanged.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final updatedRecipe = Recipe(
          pillValue: data['pillValue'],
          pillsPerHour: data['pillsPerHour'],
          additionalMessage: data['additionalMessage'],
        );

        setState(() {
          // Actualizamos la receta en la lista si ya existe
          final index = recipes.indexWhere((recipe) =>
              recipe.pillValue ==
              updatedRecipe.pillValue); // Buscar por pillValue
          if (index != -1) {
            recipes[index] = updatedRecipe; // Actualizar receta
          }
        });
      }
    });

    // Detectar eliminación de recetas
    database.child('recipes').onChildRemoved.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final removedRecipe = Recipe(
          pillValue: data['pillValue'],
          pillsPerHour: data['pillsPerHour'],
          additionalMessage: data['additionalMessage'],
        );

        setState(() {
          // Eliminar receta de la lista
          recipes.removeWhere(
              (recipe) => recipe.pillValue == removedRecipe.pillValue);
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

  // En HealthStatsScreen, después de agregar la receta
  void _addRecipe(
      String pillValue, int pillsPerHour, String additionalMessage) {
    Navigator.of(context).pop(); // Cerrar el formulario de agregar receta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Receta agregada con éxito')),
    );
  }

  // Función para abrir el formulario de agregar receta
  void _openAddRecipeDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Agregar Receta',
              style: TextStyle(color: Color(0xFF6200EE))),
          content: AddRecipeForm(onSubmit: _addRecipe),
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
            ...recipes.map((recipe) => RecipeCard(recipe: recipe)).toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddRecipeDialog,
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF6200EE),
      ),
    );
  }
}
