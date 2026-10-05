import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../base.dart';
import '../controller.dart';
import '../storage.dart';

class HorariosScreen extends StatefulWidget {
  const HorariosScreen({super.key});
  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  static const _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

  Laboratorio? _lab;
  DateTime? _dia;
  List<Reserva> _delLab = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final ctrl = context.read<AppController>();
    _lab ??= ctrl.laboratorios.isNotEmpty ? ctrl.laboratorios.first : null;
    _delLab =
        _lab == null ? [] : await Almacen.reservasDeLaboratorio(_lab!.id);
    if (mounted) setState(() {});
  }

  Reserva? _reservaEn(int dia, int bloque) {
    for (final r in _delLab) {
      if (r.diaSemana == dia &&
          bloque >= r.bloqueInicio &&
          bloque <= r.bloqueFin) return r;
    }
    return null;
  }

  void _nuevo(int dia, int bloque) {
    final ctrl = context.read<AppController>();
    final asignatura = TextEditingController();
    final grado = TextEditingController();
    final pe = TextEditingController(
        text: ctrl.docente?.carrera.abreviatura ?? '');
    int ini = bloque;
    int fin = bloque;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('Nuevo horario - ${_dias[dia - 1]}'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: asignatura,
                  decoration: const InputDecoration(labelText: 'Asignatura')),
              TextField(
                  controller: grado,
                  decoration:
                      const InputDecoration(labelText: 'Grado-Grupo (ej. 3-A)')),
              TextField(
                  controller: pe,
                  decoration: const InputDecoration(
                      labelText: 'Programa educativo (ej. ITIID)')),
              Row(children: [
                Expanded(
                    child: DropdownButtonFormField<int>(
                        value: ini,
                        items: [
                          for (int i = 1; i <= 13; i++)
                            DropdownMenuItem(value: i, child: Text('Bloque $i'))
                        ],
                        onChanged: (v) => setDlg(() {
                              ini = v!;
                              if (fin < ini) fin = ini;
                            }),
                        decoration: const InputDecoration(labelText: 'Inicio'))),
                const SizedBox(width: 8),
                Expanded(
                    child: DropdownButtonFormField<int>(
                        value: fin,
                        items: [
                          for (int i = 1; i <= 13; i++)
                            DropdownMenuItem(value: i, child: Text('Bloque $i'))
                        ],
                        onChanged: (v) => setDlg(() => fin = v!),
                        decoration: const InputDecoration(labelText: 'Fin'))),
              ]),
              const SizedBox(height: 8),
              const Text(
                  'Al guardar, este día queda apartado durante todo el cuatrimestre.',
                  style: TextStyle(fontSize: 11)),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () async {
                  if (asignatura.text.trim().isEmpty) return;
                  final ok = await ctrl.crearReserva(
                      laboratorio: _lab!,
                      diaSemana: dia,
                      bloqueInicio: ini,
                      bloqueFin: fin,
                      asignatura: asignatura.text.trim(),
                      gradoGrupo: grado.text.trim(),
                      programaEducativo: pe.text.trim());
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Choque de horario: ese bloque ya está ocupado')));
                  } else {
                    await _cargar();
                  }
                },
                child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }

  Future<void> _liberar(Reserva r) async {
    final seguro = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('¿Liberar horas?'),
              content: Text(
                  '${r.asignatura} - ${_dias[r.diaSemana - 1]} bloques ${r.bloqueInicio}-${r.bloqueFin}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Liberar')),
              ],
            ));
    if (seguro == true) {
      await context.read<AppController>().eliminarReserva(r.id);
      await _cargar();
    }
  }

  Widget _hdr(String t) => Container(
      color: AppTheme.azulOscuro,
      padding: const EdgeInsets.all(4),
      child: Text(t,
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)));

  Widget _rejilla(AppController ctrl) {
    final rows = <TableRow>[
      TableRow(children: [_hdr('Bloque'), for (final d in _dias) _hdr(d)])
    ];
    for (int b = 1; b <= 13; b++) {
      final bh = BloquesHorario.bloques[b - 1];
      final celdas = <Widget>[
        Padding(
            padding: const EdgeInsets.all(4),
            child: Text('${b}\n${bh.horaInicio}\n${bh.leyenda ?? ''}',
                style: const TextStyle(fontSize: 9)))
      ];
      for (int dia = 1; dia <= 5; dia++) {
        final r = _reservaEn(dia, b);
        if (r == null) {
          celdas.add(InkWell(
              onTap: () => _nuevo(dia, b),
              child: Container(
                  color: Colors.green.withOpacity(0.15),
                  padding: const EdgeInsets.all(4),
                  child: const Text('Libre', style: TextStyle(fontSize: 9)))));
        } else if (r.docente.id == ctrl.docente?.id) {
          celdas.add(Container(
              color: AppTheme.azulClaro.withOpacity(0.25),
              padding: const EdgeInsets.all(4),
              child: Text(r.asignatura, style: const TextStyle(fontSize: 9))));
        } else {
          celdas.add(Container(
              color: Colors.red.withOpacity(0.12),
              padding: const EdgeInsets.all(4),
              child: Text(r.docente.nombreCompleto,
                  style: const TextStyle(fontSize: 9))));
        }
      }
      rows.add(TableRow(children: celdas));
    }
    return Table(
        border: TableBorder.all(width: 0.5),
        columnWidths: const {
          0: FixedColumnWidth(52),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(),
          4: FlexColumnWidth(),
          5: FlexColumnWidth()
        },
        children: rows);
  }

  @override
  Widget build(BuildContext context) {
    if (_lab == null) return const Center(child: CircularProgressIndicator());
    final inicio = AppConfig.fechaInicioCuatrimestre;
    final fin =
        inicio.add(const Duration(days: AppConfig.totalSemanas * 7 - 1));
    var focused = _dia ?? Reloj.ahora();
    if (focused.isBefore(inicio)) focused = inicio;
    if (focused.isAfter(fin)) focused = fin;

    return Consumer<AppController>(builder: (context, ctrl, _) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<Laboratorio>(
              value: _lab,
              items: [
                for (final l in ctrl.laboratorios)
                  DropdownMenuItem(value: l, child: Text(l.nombre))
              ],
              onChanged: (v) {
                setState(() => _lab = v);
                _cargar();
              },
              decoration: const InputDecoration(labelText: 'Laboratorio')),
          const SizedBox(height: 16),
          TableCalendar(
            firstDay: inicio,
            lastDay: fin,
            focusedDay: focused,
            selectedDayPredicate: (d) => _dia != null && isSameDay(d, _dia),
            enabledDayPredicate: (d) => d.weekday >= 1 && d.weekday <= 5,
            onDaySelected: (sel, foc) => setState(() => _dia = sel),
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(titleCentered: true),
            calendarStyle: const CalendarStyle(outsideDaysVisible: false),
          ),
          if (_dia != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    'Día elegido: ${_dias[_dia!.weekday - 1]} (se aparta este día de la semana durante todo el cuatrimestre)',
                    style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),
          const Text('Rejilla semanal (toca una casilla libre para apartar)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _rejilla(ctrl),
          const SizedBox(height: 24),
          const Text('Mis horarios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (ctrl.misReservas.isEmpty)
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aún no has apartado horarios'))),
          for (final r in ctrl.misReservas)
            Card(
                child: ListTile(
              title: Text(r.asignatura),
              subtitle: Text(
                  '${r.laboratorio.nombre} • ${_dias[r.diaSemana - 1]} • Bloques ${r.bloqueInicio}-${r.bloqueFin}\n${r.gradoGrupo} / ${r.programaEducativo}'),
              trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Liberar horas',
                  onPressed: () => _liberar(r)),
            )),
        ]),
      );
    });
  }
}
