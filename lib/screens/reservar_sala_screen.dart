import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ReservarSalaScreen extends StatefulWidget {
  const ReservarSalaScreen({super.key});

  @override
  State<ReservarSalaScreen> createState() => _ReservarSalaScreenState();
}

class _ReservarSalaScreenState extends State<ReservarSalaScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  /// Stream de reservas filtrado por el día seleccionado
  Stream<QuerySnapshot> getReservasDelDia() {
    final inicio = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final fin = inicio.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection("reservas")
        .where("fecha_inicio", isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where("fecha_inicio", isLessThan: Timestamp.fromDate(fin))
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Sala de Juntas", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Colors.black),
            onPressed: () => setState(() {
              _selectedDay = DateTime.now();
              _focusedDay = DateTime.now();
            }),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF50B3C8),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _abrirModalReserva(context),
      ),
      body: Column(
        children: [
          /// 📅 CALENDARIO
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2F7),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2030),
              focusedDay: _focusedDay,
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                todayTextStyle: TextStyle(color: Colors.black),
                selectedDecoration: BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
              ),
            ),
          ),

          const SizedBox(height: 10),
          Text(DateFormat('dd MMMM', 'es').format(_selectedDay),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

          /// 📋 LISTA DE RESERVAS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getReservasDelDia(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final reservas = snapshot.data!.docs;
                if (reservas.isEmpty) return const Center(child: Text("Sin reservas para hoy"));

                return ListView.builder(
                  itemCount: reservas.length,
                  itemBuilder: (context, index) {
                    final doc = reservas[index];
                    final data = doc.data() as Map<String, dynamic>;

                    DateTime inicio = (data["fecha_inicio"] as Timestamp).toDate();
                    DateTime fin = (data["fecha_fin"] as Timestamp).toDate();
                    Duration duracion = fin.difference(inicio);

                    return Slidable(
                      key: ValueKey(doc.id),
                      startActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) => _abrirModalReserva(context, doc: doc),
                            backgroundColor: Colors.blue,
                            icon: Icons.edit,
                            label: 'Editar',
                          ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) => _confirmarEliminacion(doc.id),
                            backgroundColor: Colors.red,
                            icon: Icons.delete,
                            label: 'Eliminar',
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => _abrirModalReserva(context, doc: doc, soloVer: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(DateFormat('h:mm a').format(inicio).toLowerCase(),
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text("${duracion.inMinutes} min",
                                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(height: 40, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 15)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data["titulo"], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                                    FutureBuilder<DocumentSnapshot>(
                                      future: (data["sala_id"] as DocumentReference).get(),
                                      builder: (context, salaSnap) {
                                        String nombreSala = salaSnap.hasData ? salaSnap.data!["nombre"] : "...";
                                        return Text(nombreSala, style: const TextStyle(color: Colors.grey));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _abrirModalReserva(BuildContext context, {DocumentSnapshot? doc, bool soloVer = false}) async {
    final formKey = GlobalKey<FormState>();
    final tituloController = TextEditingController(text: doc != null ? doc["titulo"] : "");
    final descController = TextEditingController(text: doc != null ? (doc.data() as Map).containsKey('descripcion') ? doc["descripcion"] : "" : "");

    DateTime fechaSel = doc != null ? (doc["fecha_inicio"] as Timestamp).toDate() : _selectedDay;
    TimeOfDay horaInicio = TimeOfDay.fromDateTime(fechaSel);
    int duracionMinutos = doc != null
        ? (doc["fecha_fin"] as Timestamp).toDate().difference((doc["fecha_inicio"] as Timestamp).toDate()).inMinutes
        : 60;

    bool esRecurrente = doc != null ? doc["es_recurrente"] : false;
    String tipoRecurrencia = doc != null && (doc.data() as Map).containsKey('tipo_recurrencia') && doc["tipo_recurrencia"] != null ? doc["tipo_recurrencia"] : "Diario";
    DocumentReference? salaRef = doc != null ? doc["sala_id"] : null;
    List<String> participantesSeleccionados = doc != null && (doc.data() as Map).containsKey('participantes') ? List<String>.from(doc["participantes"] ?? []) : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(soloVer ? "Detalle de Reunión" : (doc == null ? "Nueva Reunión" : "Editar Reunión"),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),

                  TextFormField(
                    controller: tituloController,
                    enabled: !soloVer,
                    decoration: const InputDecoration(labelText: "Título"),
                    validator: (v) => v!.isEmpty ? "Campo requerido" : null,
                  ),

                  const SizedBox(height: 10),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection("salas").where("activa", isEqualTo: true).snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const LinearProgressIndicator();
                      return DropdownButtonFormField<DocumentReference>(
                        value: salaRef,
                        disabledHint: salaRef != null ? FutureBuilder<DocumentSnapshot>(
                          future: salaRef!.get(),
                          builder: (context, s) => Text(s.hasData ? s.data!["nombre"] : "Cargando..."),
                        ) : null,
                        // SOLUCIÓN AL ERROR: Usar onChanged como null para deshabilitar
                        onChanged: soloVer ? null : (val) => setModalState(() => salaRef = val),
                        items: snap.data!.docs.map((s) => DropdownMenuItem(value: s.reference, child: Text(s["nombre"]))).toList(),
                        decoration: const InputDecoration(labelText: "Ubicación / Sala"),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  ListTile(
                    title: const Text("Hora de Inicio"),
                    trailing: Text(horaInicio.format(context)),
                    onTap: soloVer ? null : () async {
                      final picked = await showTimePicker(context: context, initialTime: horaInicio);
                      if (picked != null) setModalState(() => horaInicio = picked);
                    },
                  ),

                  // SOLUCIÓN AL ERROR: Quitar 'enabled' y usar 'onChanged: null'
                  DropdownButtonFormField<int>(
                    value: duracionMinutos,
                    items: [30, 60, 90, 120].map((m) => DropdownMenuItem(value: m, child: Text("$m minutos"))).toList(),
                    onChanged: soloVer ? null : (v) => setModalState(() => duracionMinutos = v!),
                    decoration: const InputDecoration(labelText: "Duración"),
                  ),

                  CheckboxListTile(
                    title: const Text("Evento Recurrente"),
                    value: esRecurrente,
                    onChanged: soloVer ? null : (v) => setModalState(() => esRecurrente = v!),
                  ),

                  if (esRecurrente)
                    DropdownButtonFormField<String>(
                      value: tipoRecurrencia,
                      items: ["Diario", "Semanal", "Mensual"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: soloVer ? null : (v) => setModalState(() => tipoRecurrencia = v!),
                      decoration: const InputDecoration(labelText: "Repetir cada..."),
                    ),

                  const SizedBox(height: 10),

                  const Align(alignment: Alignment.centerLeft, child: Text("Participantes", style: TextStyle(fontWeight: FontWeight.bold))),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection("usuarios").where("activo", isEqualTo: true).snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox();
                      return Wrap(
                        spacing: 8,
                        children: snap.data!.docs.map((u) {
                          final isSel = participantesSeleccionados.contains(u.id);
                          return FilterChip(
                            label: Text(u["nombre"]),
                            selected: isSel,
                            onSelected: soloVer ? null : (selected) {
                              setModalState(() {
                                selected ? participantesSeleccionados.add(u.id) : participantesSeleccionados.remove(u.id);
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  if (!soloVer)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF50B3C8), minimumSize: const Size(double.infinity, 50)),
                      onPressed: () async {
                        if (!formKey.currentState!.validate() || salaRef == null) return;

                        final dtInicio = DateTime(fechaSel.year, fechaSel.month, fechaSel.day, horaInicio.hour, horaInicio.minute);
                        final dtFin = dtInicio.add(Duration(minutes: duracionMinutos));

                        final payload = {
                          "titulo": tituloController.text,
                          "descripcion": descController.text,
                          "fecha_inicio": Timestamp.fromDate(dtInicio),
                          "fecha_fin": Timestamp.fromDate(dtFin),
                          "sala_id": salaRef,
                          "es_recurrente": esRecurrente,
                          "tipo_recurrencia": esRecurrente ? tipoRecurrencia : null,
                          "participantes": participantesSeleccionados,
                          "actualizado_en": Timestamp.now(),
                        };

                        if (doc == null) {
                          payload["fecha_creacion"] = Timestamp.now();
                          payload["creada_por"] = "Sistemas Especiales"; // Identificador corporativo AVANS
                          await FirebaseFirestore.instance.collection("reservas").add(payload);
                        } else {
                          await doc.reference.update(payload);
                        }
                        Navigator.pop(context);
                      },
                      child: Text(doc == null ? "Crear Reserva" : "Actualizar Reserva", style: const TextStyle(color: Colors.white)),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmarEliminacion(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar reunión?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection("reservas").doc(id).delete();
                Navigator.pop(context);
              },
              child: const Text("Eliminar", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}