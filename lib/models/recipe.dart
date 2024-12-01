class PillBox {
  final String id; // ID único de la caja de pastillas
  final String pillName; // Nombre de la pastilla
  final int pillCount; // Cantidad de pastillas
  final List<String> schedule; // Horarios de toma de pastillas
  final String note; // Nota adicional

  PillBox({
    required this.id,
    required this.pillName,
    required this.pillCount,
    required this.schedule,
    required this.note,
  });

  // Método para crear una instancia de PillBox a partir de un mapa (por ejemplo, desde Firebase)
  factory PillBox.fromMap(String id, Map<dynamic, dynamic> data) {
    return PillBox(
      id: id,
      pillName: data['pillName'] ?? '',
      pillCount: data['pillCount'] ?? 0,
      schedule: List<String>.from(data['schedule'] ?? []),
      note: data['note'] ?? '',
    );
  }

  // Método para convertir una instancia de PillBox a un mapa (por ejemplo, para guardar en Firebase)
  Map<String, dynamic> toMap() {
    return {
      'pillName': pillName,
      'pillCount': pillCount,
      'schedule': schedule,
      'note': note,
    };
  }
}
