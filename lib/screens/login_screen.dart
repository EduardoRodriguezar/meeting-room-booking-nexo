import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final AuthService _auth = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool loading = false;

  /// abrir aviso privacidad
  Future<void> abrirPrivacidad() async {

    final url = Uri.parse(
        "https://avans.com/politica-privacidad/");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  /// alerta profesional
  void mostrarAlerta(String titulo, String mensaje) {

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            child: const Text("Aceptar"),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  /// login correo
  Future<void> loginCorreo() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
    });

    try {

      final user = await _auth.iniciarSesionCorreo(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null) {

        mostrarAlerta(
            "Bienvenido",
            "Inicio de sesión exitoso");

        Future.delayed(const Duration(seconds: 1), () {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            ),
          );

        });

      }

    } catch (e) {

      mostrarAlerta(
          "Error",
          e.toString().replaceAll("Exception:", ""));

    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [

                /// LOGOS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Image.asset(
                      "assets/images/avans.png",
                      height: 60,
                    ),

                    const SizedBox(width: 20),

                    Image.asset(
                      "assets/images/pogen.png",
                      height: 60,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                /// CARD LOGIN
                Container(
                  width: 320,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xffcccccc),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [

                        const Text(
                          "Iniciar Sesión",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// EMAIL
                        TextFormField(
                          controller: emailController,
                          validator: (value) {

                            if (value == null || value.isEmpty) {
                              return "Ingresa tu correo";
                            }

                            if (!value.contains("@")) {
                              return "Correo inválido";
                            }

                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Correo",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        /// PASSWORD
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          validator: (value) {

                            if (value == null || value.isEmpty) {
                              return "Ingresa tu contraseña";
                            }

                            if (value.length < 6) {
                              return "Mínimo 6 caracteres";
                            }

                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Contraseña",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// BOTON LOGIN
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff50B3C8),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: loading ? null : loginCorreo,
                            child: loading
                                ? const CircularProgressIndicator(
                                color: Colors.white)
                                : const Text("Entrar"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text("o"),

                const SizedBox(height: 20),

                /// GOOGLE
                SizedBox(
                  width: 320,
                  child: OutlinedButton.icon(
                    icon: Image.network(
                      "https://developers.google.com/identity/images/g-logo.png",
                      height: 22,
                    ),
                    label: const Text("Continuar con Google"),
                    onPressed: () async {

                      final user =
                      await _auth.iniciarSesionConGoogle();

                      if (user != null) {

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeScreen(),
                          ),
                        );

                      }
                    },
                  ),
                ),

                const SizedBox(height: 25),

                /// AVISO PRIVACIDAD (LINK)
                GestureDetector(
                  onTap: abrirPrivacidad,
                  child: const Text(
                    "Aviso de Privacidad",
                    style: TextStyle(
                      color: Color(0xffBFD020),
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}