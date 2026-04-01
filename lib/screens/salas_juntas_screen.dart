import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sala.dart';
import '../utils/color_helper.dart';

class SalasJuntasScreen extends StatelessWidget {
  const SalasJuntasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ver Salas de Juntas"),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF50B3C8),
        onPressed: () => _abrirModalSala(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("salas").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final salas = snapshot.data!.docs.map((doc) {
            return Sala.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

          Map<String, List<Sala>> salasPorUbicacion = {};

          for (var sala in salas) {
            salasPorUbicacion.putIfAbsent(sala.ubicacion, () => []);
            salasPorUbicacion[sala.ubicacion]!.add(sala);
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: salasPorUbicacion.entries.map((entry) {
              final ubicacion = entry.key;
              final listaSalas = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ubicación : $ubicacion",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ...listaSalas.map((sala) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.shade200, blurRadius: 6)
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text("Personas "),
                                  Text("${sala.capacidad}",
                                      style: const TextStyle(
                                          fontWeight:
                                          FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(sala.nombre,
                                  style: const TextStyle(
                                      fontSize: 16)),
                              const SizedBox(height: 5),
                              Text(
                                sala.permiteZoom
                                    ? "Active - ZOOM"
                                    : "Active",
                                style: const TextStyle(
                                    color: Colors.green),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              Column(
                                children: [
                                  const Text("Color"),
                                  const SizedBox(height: 5),
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor:
                                    obtenerColor(
                                        sala.color),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _abrirModalSala(
                                        context,
                                        sala: sala),
                              )
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20)
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  /// MODAL CREAR / EDITAR
  void _abrirModalSala(BuildContext context, {Sala? sala}) {
    final formKey = GlobalKey<FormState>();

    final nombreController =
    TextEditingController(text: sala?.nombre ?? "");
    final capacidadController =
    TextEditingController(text: sala?.capacidad.toString() ?? "");
    final ubicacionController =
    TextEditingController(text: sala?.ubicacion ?? "");
    final hexController = TextEditingController();

    bool permiteZoom = sala?.permiteZoom ?? true;
    bool activo = sala?.activa ?? true;

    String color = sala?.color ?? "Azul";

    bool guardando = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sala == null
                              ? "Crear Sala de Juntas"
                              : "Editar Sala",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 25),

                        _campo("Nombre", nombreController),

                        const SizedBox(height: 15),

                        _campo(
                          "Capacidad",
                          capacidadController,
                          keyboard: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) {
                              return "Ingrese capacidad";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        _campo("Ubicación", ubicacionController),

                        const SizedBox(height: 20),

                        SwitchListTile(
                          title: const Text("Permitir Zoom"),
                          value: permiteZoom,
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF50B3C8),
                          onChanged: (v) => setState(() => permiteZoom = v),
                        ),

                        SwitchListTile(
                          title: const Text("Activo"),
                          value: activo,
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF50B3C8),
                          onChanged: (v) => setState(() => activo = v),
                        ),

                        const SizedBox(height: 10),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Color"),
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 10,
                          children: [
                            _colorItem("Morado", color,
                                    (v) => setState(() => color = v)),
                            _colorItem("Azul", color,
                                    (v) => setState(() => color = v)),
                            _colorItem("Rojo", color,
                                    (v) => setState(() => color = v)),
                            _colorItem("Verde", color,
                                    (v) => setState(() => color = v)),
                          ],
                        ),

                        const SizedBox(height: 15),

                        TextField(
                          controller: hexController,
                          decoration: const InputDecoration(
                            labelText: "Color HEX (#FF5733)",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 25),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[700],
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Cancelar",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                const Color(0xFFC7DF2D),
                              ),
                              onPressed: guardando
                                  ? null
                                  : () async {
                                if (!formKey
                                    .currentState!
                                    .validate()) return;

                                setState(() =>
                                guardando = true);

                                try {
                                  final data = {
                                    "nombre":
                                    nombreController.text,
                                    "capacidad": int.tryParse(
                                        capacidadController
                                            .text) ??
                                        0,
                                    "ubicacion":
                                    ubicacionController.text,
                                    "permite_zoom":
                                    permiteZoom,
                                    "activa": activo,
                                    "color": hexController
                                        .text
                                        .isNotEmpty
                                        ? hexController.text
                                        : color,
                                  };

                                  if (sala == null) {
                                    await FirebaseFirestore
                                        .instance
                                        .collection(
                                        "salas")
                                        .add(data);
                                  } else {
                                    await FirebaseFirestore
                                        .instance
                                        .collection(
                                        "salas")
                                        .doc(sala.id)
                                        .update(data);
                                  }

                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(
                                      context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Sala guardada correctamente"),
                                      backgroundColor:
                                      Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(
                                      context)
                                      .showSnackBar(
                                    SnackBar(
                                      content:
                                      Text("Error: $e"),
                                      backgroundColor:
                                      Colors.red,
                                    ),
                                  );
                                }

                                setState(() =>
                                guardando = false);
                              },
                              child: guardando
                                  ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text("Guardar",
                                  style: TextStyle(
                                      color: Colors.black)),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _campo(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text,
        String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _colorItem(
      String nombre, String seleccionado, Function(String) onTap) {
    final seleccionadoActual = nombre == seleccionado;

    return GestureDetector(
      onTap: () => onTap(nombre),
      child: CircleAvatar(
        radius: seleccionadoActual ? 16 : 14,
        backgroundColor: obtenerColor(nombre),
        child: seleccionadoActual
            ? const Icon(Icons.check,
            size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}