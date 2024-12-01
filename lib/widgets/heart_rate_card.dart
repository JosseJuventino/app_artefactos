import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';

class HeartRateCard extends StatefulWidget {
  @override
  _HeartRateCardState createState() => _HeartRateCardState();
}

class _HeartRateCardState extends State<HeartRateCard> {
  List<FlSpot> heartRateData = [];
  bool isLoading = true;
  String errorMessage = '';
  double latestHeartRate = 0.0; // Variable para almacenar el último pulso

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

    // Cargar los datos de Firebase Realtime Database
    _loadHeartRateData();
    _loadLatestHeartRate(); // Cargar el último pulso
  }

  // Cargar los datos de pulso cardíaco desde Firebase Realtime Database (para el gráfico)
  void _loadHeartRateData() {
    final dbRef = FirebaseDatabase.instance.ref('weeklyStats');

    // Escuchar cambios en la base de datos en tiempo real
    dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;

      if (data == null) {
        setState(() {
          errorMessage = "No hay datos disponibles";
          isLoading = false;
        });
        return;
      }

      List<FlSpot> spots = [];

      // Iterar sobre los días de la semana y obtener las frecuencias cardíacas
      for (String day in daysOfWeek) {
        var dayData = data[day];
        if (dayData != null) {
          // Obtener el valor de "heart" del día
          var heartRate = dayData['heart'];

          if (heartRate != null) {
            // Convertir el valor de heart a double
            double heart = double.tryParse(heartRate.toString()) ?? 0.0;

            // Mapear el día a un índice para el gráfico
            int dayIndex = _getDayIndex(
                day); // Convertir el nombre del día en un índice (0-6)
            spots.add(FlSpot(dayIndex.toDouble(), heart));
          }
        }
      }

      setState(() {
        heartRateData = spots;
        isLoading = false;
      });
    });
  }

  // Cargar el último valor de pulso desde 'latestData'
  void _loadLatestHeartRate() {
    final dbRef = FirebaseDatabase.instance.ref('latestData');

    // Escuchar cambios en la base de datos en tiempo real
    dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;

      if (data == null) {
        setState(() {
          errorMessage = "No hay datos disponibles para el último pulso";
        });
        return;
      }

      // Obtener el último valor de pulso de 'latestData'
      var heartRate = data['heart'];

      if (heartRate != null) {
        setState(() {
          latestHeartRate = double.tryParse(heartRate.toString()) ?? 0.0;
        });
      }
    });
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
              "Pulso cardíaco semanal", // Título del card
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
                      child: CircularProgressIndicator()) // Indicador de carga
                  : heartRateData.isEmpty
                      ? Center(
                          child: Text(errorMessage)) // Error si no hay datos
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
              "Último Pulso: ${latestHeartRate.toStringAsFixed(1)} BPM", // Mostrar el último pulso
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
