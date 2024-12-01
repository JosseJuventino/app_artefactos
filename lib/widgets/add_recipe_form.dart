import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class AddPillBoxForm extends StatefulWidget {
  final Function(String, int, List<String>, String) onSubmit;

  AddPillBoxForm({required this.onSubmit});

  @override
  _AddPillBoxFormState createState() => _AddPillBoxFormState();
}

class _AddPillBoxFormState extends State<AddPillBoxForm> {
  final _pillNameController = TextEditingController();
  final _pillCountController = TextEditingController();
  final _noteController = TextEditingController();
  List<String> _schedule = [];

  // Esta función se encargará de guardar los datos en Realtime Database
  Future<void> _submitForm() async {
    final pillName = _pillNameController.text;
    final pillCount = int.tryParse(_pillCountController.text) ?? 0;
    final note = _noteController.text;

    // Validaciones
    if (pillName.isEmpty || pillCount <= 0 || _schedule.isEmpty) {
      return;
    }

    // Guardar los datos en Realtime Database
    try {
      final DatabaseReference database = FirebaseDatabase.instance.reference();

      // Accede a la ruta 'pillBoxes' en Realtime Database y agrega un nuevo nodo
      await database.child('pillBoxes').push().set({
        'pillName': pillName,
        'pillCount': pillCount,
        'schedule': _schedule,
        'note': note,
        'timestamp': ServerValue.timestamp,
      });

      // Llamar a la función onSubmit para pasar los datos a un widget superior, si es necesario
      widget.onSubmit(pillName, pillCount, _schedule, note);

      // Mostrar un mensaje de éxito (opcional)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Caja de pastillas agregada con éxito')),
      );

      // Limpiar los campos después de agregar
      _pillNameController.clear();
      _pillCountController.clear();
      _noteController.clear();
      _schedule.clear(); // Limpiar horarios
    } catch (e) {
      // En caso de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar la caja de pastillas: $e')),
      );
    }
  }

  void _addScheduleTime() async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      String formattedTime = selectedTime.format(context);
      setState(() {
        _schedule.add(formattedTime);
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Permitir desplazamiento
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pillNameController,
            decoration: InputDecoration(labelText: 'Nombre de la pastilla'),
          ),
          SizedBox(height: 16), // Espaciado
          TextField(
            controller: _pillCountController,
            decoration: InputDecoration(labelText: 'Cantidad de pastillas'),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16), // Espaciado
          // Mostrar horarios seleccionados
          Wrap(
            spacing: 8.0,
            children: _schedule.map((time) {
              return Chip(
                label: Text(time),
                onDeleted: () {
                  setState(() {
                    _schedule.remove(time);
                  });
                },
              );
            }).toList(),
          ),
          SizedBox(height: 16), // Espaciado
          ElevatedButton(
            onPressed: _addScheduleTime,
            child: Text(
              'Agregar Horario',
              style: TextStyle(color: Colors.white), // Cambiar color a blanco
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6200EE),
            ),
          ),
          SizedBox(height: 16), // Espaciado

          ElevatedButton(
            onPressed: _submitForm,
            child: Text(
              'Agregar',
              style: TextStyle(
                fontWeight: FontWeight.bold, // Hacer el texto en negrita
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6200EE),
            ),
          ),
        ],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      appBar: AppBar(title: Text('Agregar Caja de Pastillas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AddPillBoxForm(
          onSubmit: (pillName, pillCount, schedule, note) {
            // Aquí puedes manejar la lógica después de que se agregue la caja de pastillas
            print(
                'Caja de pastillas agregada: $pillName, $pillCount, $schedule, $note');
          },
        ),
      ),
    );
  }
}
