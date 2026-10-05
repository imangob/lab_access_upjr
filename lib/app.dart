import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'base.dart';
import 'controller.dart';
import 'screens/acceso.dart';
import 'screens/inicio.dart';
import 'screens/registro.dart'; // De aquí sale EstudiantadoScreen

// Llave global para poder navegar desde el lector USB sin contexto
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class LabAccessApp extends StatelessWidget {
  const LabAccessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppController()..inicializar(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Control de Acceso UPJR',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'MX')],
        initialRoute: '/',
        routes: {
          '/': (_) => const AccesoScreen(),
          '/login': (_) => const LoginManualScreen(),
          '/home': (_) => const AppShell(),
          '/estudiantado': (_) => const EstudiantadoScreen(),
        },
      ),
    );
  }
}
