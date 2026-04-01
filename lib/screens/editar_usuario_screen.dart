import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarUsuarioScreen extends StatefulWidget {
  const EditarUsuarioScreen({super.key});

  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {

  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;

  bool cargando = true;
  String fotoUrl = "";

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {

    final doc = await FirebaseFirestore.instance
        .collection("usuarios")
        .doc(user!.uid)
        .get();

    final data = doc.data()!;

    _nombreController.text = data["nombre"] ?? "";
    _correoController.text = data["correo"] ?? "";
    fotoUrl = data["foto_url"] ?? "";

    setState(() {
      cargando = false;
    });
  }

  Future<void> _guardar() async {

    try {

      /// actualizar firestore
      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(user!.uid)
          .update({
        "nombre": _nombreController.text,
        "correo": _correoController.text,
      });

      /// actualizar contraseña si se escribió
      if (_passwordController.text.isNotEmpty) {
        await user!.updatePassword(_passwordController.text);
      }

      if (!mounted) return;

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al actualizar: $e"),
        ),
      );

    }

  }

  @override
  Widget build(BuildContext context) {

    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final nombre = _nombreController.text;

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),

      appBar: AppBar(
        title: const Text("Perfil"),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [

              const SizedBox(height: 10),

              const SizedBox(height: 25),

              /// AVATAR
              _UserAvatar(
                nombre: nombre,
                fotoUrl: fotoUrl,
              ),

              const SizedBox(height: 30),

              /// CARD FORM
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text("Name"),

                    const SizedBox(height: 8),

                    TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text("Correo"),

                    const SizedBox(height: 8),

                    TextField(
                      controller: _correoController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text("Contraseña"),

                    const SizedBox(height: 8),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "********",
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            foregroundColor: Colors.white, // texto blanco
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Cancelar"),
                        ),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffBFD020),
                            foregroundColor: Colors.white, // texto blanco
                          ),
                          onPressed: _guardar,
                          child: const Text("Guardar"),
                        ),

                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {

  final String nombre;
  final String fotoUrl;

  const _UserAvatar({
    required this.nombre,
    required this.fotoUrl,
  });

  @override
  Widget build(BuildContext context) {

    if (fotoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 45,
        backgroundImage: NetworkImage(fotoUrl),
      );
    }

    String iniciales = "";

    final partes = nombre.split(" ");

    if (partes.isNotEmpty) {
      iniciales = partes[0][0];
    }

    if (partes.length > 1) {
      iniciales += partes[1][0];
    }

    return CircleAvatar(
      radius: 45,
      backgroundColor: const Color(0xffC6E218),
      child: Text(
        iniciales.toUpperCase(),
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}