import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'controller.dart';

String _bufferUid = '';

// Función que escucha el teclado globalmente (Lector USB tipo teclado)
bool _manejadorTecladoGlobal(KeyEvent event) {
  // 1. Ignorar si el usuario está escribiendo en un TextField (Login manual, etc.)
  final primaryFocus = WidgetsBinding.instance.focusManager.primaryFocus;
  if (primaryFocus != null && primaryFocus.context != null) {
    if (primaryFocus.context!.findAncestorWidgetOfExactType<EditableText>() != null) {
      return false; // Hay un campo de texto enfocado, dejar que escriba normal
    }
  }

  if (event is KeyDownEvent) {
    // 2. Si presiona Enter, procesar el UID acumulado
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_bufferUid.isNotEmpty) {
        final uid = _bufferUid;
        _bufferUid = '';
        _procesarLectura(uid);
        return true; // Consumimos el Enter para que no haga "clic" en botones
      }
    } 
    // 3. Si es una letra/número, acumularlo al buffer
    else if (event.character != null && event.character!.trim().isNotEmpty) {
      _bufferUid += event.character!;
      // Los lectores USB escriben muy rápido. Si pasa medio segundo y no hay Enter, limpiamos.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_bufferUid.length < 20) _bufferUid = '';
      });
      return true; // Consumimos la tecla para que no se escriba en la pantalla
    }
  }
  return false;
}

void _procesarLectura(String uid) {
  final context = navigatorKey.currentContext;
  if (context == null) return;
  
  final ctrl = Provider.of<AppController>(context, listen: false);
  ctrl.loginTarjeta(uid).then((ok) {
    if (ok) {
      // Si estaba en la pantalla de acceso, lo mandamos al Home
      navigatorKey.currentState?.pushReplacementNamed('/home');
    }
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Activar el listener global del teclado
  HardwareKeyboard.instance.addHandler(_manejadorTecladoGlobal);
  
  runApp(const LabAccessApp());
}
