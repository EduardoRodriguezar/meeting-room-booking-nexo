class Sala {
  final String id;
  final String nombre;
  final String ubicacion;
  final int capacidad;
  final bool activa;
  final bool permiteZoom;
  final String color;

  Sala({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.capacidad,
    required this.activa,
    required this.permiteZoom,
    required this.color,
  });

  factory Sala.fromFirestore(String id, Map<String, dynamic> data) {
    return Sala(
      id: id,
      nombre: data["nombre"] ?? "",
      ubicacion: data["ubicacion"] ?? "",
      capacidad: data["capacidad"] ?? 0,
      activa: data["activa"] ?? false,
      permiteZoom: data["permite_zoom"] ?? false,
      color: data["color"] ?? "",
    );
  }
}