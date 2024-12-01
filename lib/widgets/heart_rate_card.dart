import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HeartRateCard extends StatefulWidget {
  @override
  _HeartRateCardState createState() => _HeartRateCardState();
}

class _HeartRateCardState extends State<HeartRateCard> {
  List<FlSpot> heartRateData = [];
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

    // Luego cargamos los datos de Firestore
    _loadHeartRateData();
  }

  // Cargar los datos de pulso cardíaco desde Firestore
  Future<void> _loadHeartRateData() async {
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

      // Lista para almacenar las frecuencias cardíacas de cada día
      List<FlSpot> spots = [];

      // Iterar sobre los días de la semana en el orden correcto
      for (String day in daysOfWeek) {
        bool dayFound = false;

        // Buscar el documento correspondiente al día
        for (var doc in snapshot.docs) {
          if (doc.id == day) {
            // Obtener las lecturas de frecuencia cardíaca para ese día desde el arreglo 'heartRate'
            var heartRateList = doc['heartRate'] as List<dynamic>;

            if (heartRateList.isEmpty) {
              print('No hay datos de pulso para $day');
            } else {
              // Obtener la última lectura de pulso para ese día
              var lastHeartRate = heartRateList.last;
              double heartRate = lastHeartRate['value'].toDouble();

              print('Último pulso para $day: $heartRate BPM');

              // Agregar el dato al gráfico
              int dayIndex = _getDayIndex(
                  day); // Convertir el nombre del día en un índice (0-6)
              spots.add(FlSpot(dayIndex.toDouble(), heartRate));
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
        heartRateData = spots;
        isLoading = false; // Los datos se cargaron
      });

      if (heartRateData.isEmpty) {
        setState(() {
          errorMessage = "No se encontraron lecturas de pulso.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error al cargar los datos: $e";
        isLoading = false;
      });
      print("Error al cargar los datos de pulso: $e");
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
              "Pulso Cardiaco del Día",
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
                  : heartRateData.isEmpty
                      ? Center(
                          child: Text(
                              errorMessage)) // Si no hay datos, mostrar el error
                      : LineChart(
                          LineChartData(
                            minY: 60,
                            maxY: 100,
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
                                  interval: 5,
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
                                spots: heartRateData,
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
              "Último Pulso: ${heartRateData.isNotEmpty ? heartRateData.last.y.toStringAsFixed(1) : 'N/A'} BPM",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
