import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TemperatureCard extends StatefulWidget {
  @override
  _TemperatureCardState createState() => _TemperatureCardState();
}

class _TemperatureCardState extends State<TemperatureCard> {
  List<FlSpot> temperatureData = [];
  bool isLoading = true;
  String errorMessage = '';

  // Lista de días de la semana
  final List<String> daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadTemperatureData();
  }

  // Cargar los datos de temperatura desde Firestore
  Future<void> _loadTemperatureData() async {
    try {
      // Acceder a la colección weeklyStats
      var snapshot =
          await FirebaseFirestore.instance.collection('weeklyStats').get();

      // Verificamos si la colección tiene documentos
      if (snapshot.docs.isEmpty) {
        setState(() {
          errorMessage = "No hay datos de la semana en 'weeklyStats'.";
          isLoading = false;
        });
        print("No hay datos en 'weeklyStats'");
        return;
      }

      // Lista para almacenar las temperaturas de cada día
      List<FlSpot> spots = [];

      // Iterar sobre los días de la semana en el orden correcto
      for (String day in daysOfWeek) {
        bool dayFound = false;

        // Buscar el documento correspondiente al día
        for (var doc in snapshot.docs) {
          if (doc.id == day) {
            // Obtener las lecturas de temperatura para ese día desde el arreglo 'temperatures'
            var temperaturesList = doc['temperatures'] as List<dynamic>;

            if (temperaturesList.isEmpty) {
              print('No hay datos de temperatura para $day');
            } else {
              // Obtener la última lectura de temperatura para ese día
              var lastTemperature = temperaturesList.last;
              double temperature = lastTemperature['value'].toDouble();

              print('Última temperatura para $day: $temperature °C');

              // Agregar el dato al gráfico
              int dayIndex = _getDayIndex(
                  day); // Convertir el nombre del día en un índice (0-6)
              spots.add(FlSpot(dayIndex.toDouble(), temperature));
            }

            dayFound = true;
            break; // Si encontramos el documento, salimos del ciclo
          }
        }

        // Si no encontramos el documento para ese día, lo ignoramos
        if (!dayFound) {
          print('No se encontró el documento para $day');
        }
      }

      // Si encontramos datos, actualizamos el estado
      setState(() {
        temperatureData = spots;
        isLoading = false; // Los datos se cargaron
      });

      if (temperatureData.isEmpty) {
        setState(() {
          errorMessage = "No se encontraron lecturas de temperatura.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error al cargar los datos: $e";
        isLoading = false;
      });
      print("Error al cargar los datos: $e");
    }
  }

  // Función para mapear el nombre del día al índice (0-6)
  int _getDayIndex(String day) {
    return daysOfWeek.indexOf(day);
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
              "Temperatura del Día",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6200EE),
              ),
            ),
            SizedBox(height: 12),
            Container(
              height: 250,
              child: isLoading
                  ? Center(
                      child:
                          CircularProgressIndicator()) // Mostrar indicador de carga
                  : temperatureData.isEmpty
                      ? Center(
                          child: Text(
                              errorMessage)) // Si no hay datos, mostrar el error
                      : LineChart(
                          LineChartData(
                            minY: 35,
                            maxY: 40,
                            gridData: FlGridData(
                              show: true,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.2),
                                  strokeWidth: 1,
                                );
                              },
                              getDrawingVerticalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.2),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: 0.5,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    List<String> daysOfWeek = [
                                      'Lun',
                                      'Mar',
                                      'Mié',
                                      'Jue',
                                      'Vie',
                                      'Sáb',
                                      'Dom'
                                    ];
                                    return Text(
                                      daysOfWeek[value.toInt()],
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.5),
                                  width: 1),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: temperatureData,
                                isCurved: false,
                                color: Color(0xFF6200EE),
                                barWidth: 4,
                                isStrokeCapRound: true,
                                belowBarData: BarAreaData(show: false),
                              ),
                            ],
                          ),
                        ),
            ),
            SizedBox(height: 12),
            Text(
              "Última Temperatura: ${temperatureData.isNotEmpty ? temperatureData.last.y.toStringAsFixed(1) : 'N/A'} °C",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
