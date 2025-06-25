import 'package:flutter/material.dart';
import 'package:sscaleg/Uteis/paleta_cores.dart';

class Estilo {
  ThemeData get estiloGeral => ThemeData(
    primaryColor: PaletaCores.corAzulEscuro,
    appBarTheme: const AppBarTheme(
      color: PaletaCores.corAzulEscuro,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(

      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(width: 1, color: PaletaCores.corCastanho),
        borderRadius: BorderRadius.circular(10),
      ),
      extendedTextStyle: TextStyle(fontSize: 15, color: Colors.black,),
    ),

    cardTheme: const CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(width: 1, color: PaletaCores.corAzulCiano),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      errorStyle: const TextStyle(fontSize: 13, color: Colors.red),
      hintStyle: const TextStyle(
        color: PaletaCores.corAzulEscuro,
        fontSize: 16,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
          color: PaletaCores.corAzulEscuro,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
          color: PaletaCores.corAzulEscuro,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
          color: PaletaCores.corAzulEscuro,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(width: 1, color: Colors.red),
        borderRadius: BorderRadius.circular(10),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          width: 1,
          color: PaletaCores.corAzulEscuro,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      labelStyle: const TextStyle(
        color: PaletaCores.corAzulEscuro,
        fontSize: 16,
      ),
    ),
  );
}
