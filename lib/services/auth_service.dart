import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> iniciarSesionCorreo(String email, String password) async {
    try {

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) return null;

      /// verificar si está activo en firestore
      final doc = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        throw Exception("Usuario no registrado");
      }

      if (doc.data()?["activo"] != true) {
        throw Exception("Usuario desactivado");
      }

      return user;

    } on FirebaseAuthException catch (e) {

      if (e.code == 'user-not-found') {
        throw Exception("Usuario no encontrado");
      }

      if (e.code == 'wrong-password') {
        throw Exception("Contraseña incorrecta");
      }

      if (e.code == 'invalid-email') {
        throw Exception("Correo inválido");
      }

      throw Exception("Error de autenticación");

    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<User?> iniciarSesionConGoogle() async {
    try {
      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        await _guardarUsuario(user);
      }

      return user;
    } catch (e) {
      print("Error Google Login: $e");
      return null;
    }
  }

  Future<void> _guardarUsuario(User user) async {
    final doc = FirebaseFirestore.instance
        .collection("usuarios")
        .doc(user.uid);

    final snapshot = await doc.get();

    if (!snapshot.exists) {
      await doc.set({
        "nombre": user.displayName,
        "correo": user.email,
        "foto_url": user.photoURL,
        "rol": "usuario",
        "activo": true,
        "fecha_creacion": FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> cerrarSesion() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}