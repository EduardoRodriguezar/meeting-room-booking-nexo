import 'package:flutter/material.dart';

Color obtenerColor(String color) {
  switch (color) {
    case "Rojo":
      return Colors.red;

    case "Morado":
      return Colors.deepPurple;

    case "Verde":
      return Colors.green;

    case "Azul":
      return Colors.blue;

    default:
      return Colors.grey;
  }
}