import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'reservar_sala_screen.dart';
import 'configuracion_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;
    final nombre = user?.displayName ?? "Usuario";

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            onPressed: () async {
              await AuthService().cerrarSesion();
              Navigator.pop(context);
            },
          )
        ],
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// SALUDO
                  Text(
                    "¡Hola! $nombre",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xffBFD020),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// SUBTITULO
                  const Text(
                    "Selecciona qué hacer",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xff4f5238),
                    ),
                  ),

                  const SizedBox(height: 60),

                  /// BOTON RESERVAR
                  MenuButton(
                    icon: Icons.meeting_room,
                    text: "Reservar Sala",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReservarSalaScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 25),

                  /// BOTON CONFIGURACION
                  MenuButton(
                    icon: Icons.settings,
                    text: "Configuración",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ConfiguracionScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MenuButton extends StatelessWidget {

  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const MenuButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton.icon(

        icon: Icon(
          icon,
          size: 30,
          color: Colors.white,
        ),

        label: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff50B3C8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        onPressed: onPressed,
      ),
    );
  }
}