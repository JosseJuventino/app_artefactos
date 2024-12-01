import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importar firebase_core
import 'package:firebase_database/firebase_database.dart'; // Importar Realtime Database

class AddRecipeForm extends StatefulWidget {
  final Function(String, int, String) onSubmit;

  AddRecipeForm({required this.onSubmit});

  @override
  _AddRecipeFormState createState() => _AddRecipeFormState();
}

class _AddRecipeFormState extends State<AddRecipeForm> {
  final _pillValueController = TextEditingController();
  final _pillsPerHourController = TextEditingController();
  final _messageController = TextEditingController();

  // Esta función se encargará de guardar los datos en Realtime Database
  Future<void> _submitForm() async {
    final pillValue = _pillValueController.text;
    final pillsPerHour = int.tryParse(_pillsPerHourController.text) ?? 0;
    final additionalMessage = _messageController.text;

    // Validaciones
    if (pillValue.isEmpty || pillsPerHour == 0) {
      return;
    }

    // Guardar los datos en Realtime Database
    try {
      final DatabaseReference database = FirebaseDatabase.instance.reference();

      // Accede a la ruta 'recipes' en Realtime Database y agrega un nuevo nodo
      await database.child('recipes').push().set({
        'pillValue': pillValue,
        'pillsPerHour': pillsPerHour,
        'additionalMessage': additionalMessage,
        'timestamp':
            ServerValue.timestamp, // Agrega la marca de tiempo del servidor
      });

      // Llamar a la función onSubmit para pasar los datos a un widget superior, si es necesario
      widget.onSubmit(pillValue, pillsPerHour, additionalMessage);

      // Mostrar un mensaje de éxito (opcional)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receta agregada con éxito')),
      );

      // Limpiar los campos después de agregar
      _pillValueController.clear();
      _pillsPerHourController.clear();
      _messageController.clear();
    } catch (e) {
      // En caso de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar la receta: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _pillValueController,
          decoration: InputDecoration(labelText: 'Valor de la pastilla'),
        ),
        TextField(
          controller: _pillsPerHourController,
          decoration: InputDecoration(labelText: 'Pastillas por hora'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _messageController,
          decoration: InputDecoration(
            labelText: 'Mensaje adicional',
            alignLabelWithHint: true, // Alinea la etiqueta con el texto
          ),
          maxLines: 5, // Establecemos el área de texto de 5 líneas
          keyboardType:
              TextInputType.multiline, // Permite múltiples líneas en el teclado
          textInputAction:
              TextInputAction.newline, // Permite saltar a la siguiente línea
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submitForm, // Llamamos a la función _submitForm
          child: Text(
            'Agregar',
            style: TextStyle(
              fontWeight: FontWeight.bold, // Poner el texto en negrita
              color: Colors.white, // Poner el texto en blanco
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6200EE), // Color morado del botón
          ),
        ),
      ],
    );
  }
}

void main() async {
  // Asegúrate de que los widgets están inicializados antes de ejecutar la app
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

class HealthStatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agregar Receta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AddRecipeForm(
          onSubmit: (pillValue, pillsPerHour, additionalMessage) {
            // Aquí puedes manejar la lógica después de que se agregue la receta
            print(
                'Receta agregada: $pillValue, $pillsPerHour, $additionalMessage');
          },
        ),
      ),
    );
  }
}
