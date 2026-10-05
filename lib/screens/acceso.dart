import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../base.dart';
import '../controller.dart';

class AccesoScreen extends StatefulWidget {
  const AccesoScreen({super.key});
  @override
  State<AccesoScreen> createState() => _AccesoScreenState();
}

class _AccesoScreenState extends State<AccesoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _leer(String uid) async {
    final ok = await context.read<AppController>().loginTarjeta(uid);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credencial no reconocida')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.azulOscuro, AppTheme.azulMedio])),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school, size: 60, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text('Universidad Politécnica\nde Juventino Rosas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w300)),
                    const SizedBox(height: 8),
                    const Text('Control de Acceso a Laboratorios',
                        style: TextStyle(
                            color: AppTheme.naranja,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 40),
                    AnimatedBuilder(
                      animation: _anim,
                      builder: (context, child) => Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white
                                  .withOpacity(0.3 + _anim.value * 0.7),
                              width: 3),
                        ),
                        child: Center(
                            child: Icon(Icons.contactless,
                                size: 90,
                                color: Colors.white.withOpacity(
                                    0.5 + _anim.value * 0.5))),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text('Acerca tu credencial al lector',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 32),
                    if (AppConfig.modoPruebas)
                      Wrap(spacing: 8, children: [
                        ElevatedButton(
                            onPressed: () => _leer('270'),
                            child: const Text('Docente 270')),
                        ElevatedButton(
                            onPressed: () => _leer('150'),
                            child: const Text('Docente 150')),
                        ElevatedButton(
                            onPressed: () => _leer('320'),
                            child: const Text('Docente 320')),
                      ]),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: const Text("No traigo mi credencial",
                          style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.underline)),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginManualScreen extends StatefulWidget {
  const LoginManualScreen({super.key});
  @override
  State<LoginManualScreen> createState() => _LoginManualScreenState();
}

class _LoginManualScreenState extends State<LoginManualScreen> {
  final _u = TextEditingController();
  final _c = TextEditingController();
  bool _cargando = false;

  Future<void> _entrar() async {
    setState(() => _cargando = true);
    final ok = await context
        .read<AppController>()
        .loginManual(_u.text.trim(), _c.text.trim());
    if (!mounted) return;
    setState(() => _cargando = false);
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario o contraseña incorrectos')));
    }
  }

  @override
  void dispose() {
    _u.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.login, size: 80, color: AppTheme.azulOscuro),
              const SizedBox(height: 24),
              TextField(
                  controller: _u,
                  decoration: const InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 16),
              TextField(
                  controller: _c,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock)),
                  onSubmitted: (_) => _entrar()),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _cargando ? null : _entrar,
                      child: const Text('Iniciar sesión'))),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver')),
            ]),
          ),
        ),
      ),
    );
  }
}
