class PillBox {
  final String id; // ID único de la caja de pastillas
  final String pillName; // Nombre de la pastilla
  final int pillCount; // Cantidad de pastillas
  final List<String> schedule; // Horarios de toma de pastillas
  final String note; // Nota adicional
  final int timestamp; // Timestamp para la última modificación

  PillBox({
    required this.id,
    required this.pillName,
    required this.pillCount,
    required this.schedule,
    required this.note,
    required this.timestamp, // Asegúrate de incluir el timestamp en el constructor
  });

  // Método para crear una instancia de PillBox a partir de un mapa (por ejemplo, desde Firebase)
  factory PillBox.fromMap(String id, Map<dynamic, dynamic> data) {
    return PillBox(
      id: id,
      pillName: data['pillName'] ?? '',
      pillCount: data['pillCount'] ?? 0,
      schedule: List<String>.from(data['schedule'] ?? []),
      note: data['note'] ?? '',
      timestamp:
          data['timestamp'] ?? 0, // Asegúrate de obtener el timestamp del mapa
    );
  }

  // Método para convertir una instancia de PillBox a un mapa (por ejemplo, para guardar en Firebase)
  Map<String, dynamic> toMap() {
    return {
      'pillName': pillName,
      'pillCount': pillCount,
      'schedule': schedule,
      'note': note,
      'timestamp': timestamp, // Incluir el timestamp en el mapa
    };
  }
}
