import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../base.dart';
import '../controller.dart';
import '../storage.dart';
import 'horarios.dart';
import 'registro.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _pagina = 0;

  List<_Item> _items() => [
        _Item(Icons.home, 'Inicio'),
        _Item(Icons.calendar_today, 'Elegir horario'),
        _Item(Icons.assessment, 'Registro semanal'),
        _Item(Icons.folder, 'Documentos'),
        if (AppConfig.modoPruebas) _Item(Icons.bug_report, 'Pruebas'),
      ];

  List<Widget> _paginas() => [
        HomeScreen(irA: (i) => setState(() => _pagina = i)),
        const HorariosScreen(),
        const RegistroScreen(),
        const DocumentosScreen(),
        if (AppConfig.modoPruebas) const PruebasScreen(),
      ];

  Future<void> _salida() async {
    await context.read<AppController>().registrarSalida();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Salida registrada')));
    }
  }

  Future<void> _logout() async {
    await context.read<AppController>().logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final items = _items();
    final paginas = _paginas();
    final ancha = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(items[_pagina].titulo),
        actions: [
          IconButton(
              icon: const Icon(Icons.exit_to_app),
              tooltip: 'Registrar salida',
              onPressed: _salida),
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: _logout),
        ],
      ),
      drawer: ancha
          ? null
          : Drawer(
              child: ListView(children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: AppTheme.azulOscuro),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.school, color: Colors.white, size: 40),
                        const SizedBox(height: 8),
                        Text(
                            context
                                    .read<AppController>()
                                    .docente
                                    ?.nombreCompleto ??
                                '',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                      ]),
                ),
                for (int i = 0; i < items.length; i++)
                  ListTile(
                    leading: Icon(items[i].icono),
                    title: Text(items[i].titulo),
                    selected: i == _pagina,
                    onTap: () {
                      setState(() => _pagina = i);
                      Navigator.pop(context);
                    },
                  ),
              ]),
            ),
      body: ancha
          ? Row(children: [
              NavigationRail(
                selectedIndex: _pagina,
                onDestinationSelected: (i) => setState(() => _pagina = i),
                labelType: NavigationRailLabelType.all,
                backgroundColor: AppTheme.azulOscuro,
                selectedIconTheme: const IconThemeData(color: AppTheme.naranja),
                unselectedIconTheme:
                    const IconThemeData(color: Colors.white70),
                selectedLabelTextStyle:
                    const TextStyle(color: AppTheme.naranja),
                unselectedLabelTextStyle:
                    const TextStyle(color: Colors.white70),
                destinations: [
                  for (final it in items)
                    NavigationRailDestination(
                        icon: Icon(it.icono), label: Text(it.titulo)),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: paginas[_pagina]),
            ])
          : paginas[_pagina],
    );
  }
}

class _Item {
  final IconData icono;
  final String titulo;
  _Item(this.icono, this.titulo);
}

class HomeScreen extends StatelessWidget {
  final void Function(int) irA;
  const HomeScreen({super.key, required this.irA});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(builder: (context, ctrl, _) {
      final d = ctrl.docente;
      if (d == null) return const Center(child: Text('No hay sesión activa'));
      final ahora = ctrl.ahora;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hola, ${d.nombreCompleto}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(d.carrera.abreviatura),
                        const SizedBox(height: 8),
                        Text('Semana ${ctrl.semanaActual} de ${AppConfig.totalSemanas}'),
                        Text(Reloj.fecha(ahora)),
                      ]))),
          const SizedBox(height: 16),
          if (ctrl.sesionAbierta != null)
            Card(
                color: AppTheme.naranja.withOpacity(0.1),
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Clase en curso',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.naranja)),
                          const SizedBox(height: 8),
                          Text(ctrl.sesionAbierta!.asignatura),
                          Text(ctrl.sesionAbierta!.laboratorio.nombre),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, children: [
                            ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/estudiantado',
                                    arguments: ctrl.sesionAbierta!.id),
                                icon: const Icon(Icons.people),
                                label: const Text('Estudiantado')),
                            ElevatedButton.icon(
                                onPressed: () => ctrl.registrarSalida(),
                                icon: const Icon(Icons.exit_to_app),
                                label: const Text('Salida'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red)),
                          ]),
                        ]))),
          const SizedBox(height: 16),
          const Text('Clases de hoy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<List<SesionLaboratorio>>(
            future: Almacen.getSesiones(),
            builder: (context, snap) {
              final sesiones = snap.data ?? [];
              final hoy = ctrl.misReservas
                  .where((r) => r.diaSemana == ahora.weekday)
                  .toList()
                ..sort((a, b) => a.bloqueInicio.compareTo(b.bloqueInicio));
              if (hoy.isEmpty) {
                return const Card(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Hoy no tienes clases programadas')));
              }
              return Column(
                  children: [for (final r in hoy) _claseHoy(ctrl, r, sesiones, ahora)]);
            },
          ),
          const SizedBox(height: 16),
          const Text('Accesos rápidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ActionChip(label: const Text('Elegir horario'), onPressed: () => irA(1)),
            ActionChip(label: const Text('Registro semanal'), onPressed: () => irA(2)),
            ActionChip(label: const Text('Documentos'), onPressed: () => irA(3)),
          ]),
        ]),
      );
    });
  }

  Widget _claseHoy(AppController ctrl, Reserva r,
      List<SesionLaboratorio> sesiones, DateTime ahora) {
    final bloque = BloquesHorario.bloqueActual(ahora);
    final registrada = sesiones.any((s) =>
        s.laboratorio.id == r.laboratorio.id &&
        s.docente.id == ctrl.docente?.id &&
        s.fecha.year == ahora.year &&
        s.fecha.month == ahora.month &&
        s.fecha.day == ahora.day);

    String estado;
    Color color;
    if (ctrl.sesionAbierta != null &&
        ctrl.sesionAbierta!.laboratorio.id == r.laboratorio.id) {
      estado = 'En curso';
      color = AppTheme.naranja;
    } else if (registrada) {
      estado = 'Registrada';
      color = Colors.green;
    } else if (bloque != null && r.bloqueFin < bloque.numero) {
      estado = 'Sin registro';
      color = Colors.red;
    } else {
      estado = 'Pendiente';
      color = AppTheme.azulMedio;
    }

    return Card(
        child: ListTile(
      title: Text(r.asignatura),
      subtitle:
          Text('${r.laboratorio.nombre} • Bloques ${r.bloqueInicio}-${r.bloqueFin}'),
      trailing: Chip(
          backgroundColor: color,
          label: Text(estado,
              style: const TextStyle(color: Colors.white, fontSize: 11))),
    ));
  }
}
