import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../base.dart';
import '../controller.dart';
import '../storage.dart';
import '../pdfs.dart';
import '../servicios.dart';

// ================= REGISTRO SEMANAL AF-RG-02 =================
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});
  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  String? _labId;
  int _semana = 1;

  Map<String, String> _kpis(List<SesionLaboratorio> ss) {
    final est = ss.fold<int>(0, (t, s) => t + s.estudiantesAtendidos);
    final prog =
        ss.where((s) => s.esHoraProgramada && s.horaEntrada != null).length;
    final noProg =
        ss.where((s) => !s.esHoraProgramada && s.horaEntrada != null).length;
    final total = prog + noProg;
    final pct = total > 0 ? (total / 13 * 100).toStringAsFixed(1) : '0.0';
    return {
      'Estudiantado atendido': '$est',
      'Horas programadas realizadas': '$prog',
      'Horas no programadas realizadas': '$noProg',
      'Horas de auto-acceso (AF-RG-03)': '0',
      'Horas de uso total': '$total',
      'Porcentaje de uso': '$pct%',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(builder: (context, ctrl, _) {
      _labId ??= ctrl.laboratorios.isNotEmpty ? ctrl.laboratorios.first.id : null;
      if (_labId == null) return const Center(child: Text('No hay laboratorios'));
      final lab = DatosSemilla.laboratorios.firstWhere((l) => l.id == _labId);
      final responsable = 'Coordinación de ${lab.carrera.abreviatura}';

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: DropdownButtonFormField<String>(
                    value: _labId,
                    items: [
                      for (final l in ctrl.laboratorios)
                        DropdownMenuItem(value: l.id, child: Text(l.nombre))
                    ],
                    onChanged: (v) => setState(() => _labId = v),
                    decoration: const InputDecoration(labelText: 'Laboratorio'))),
            const SizedBox(width: 16),
            Expanded(
                child: DropdownButtonFormField<int>(
                    value: _semana,
                    items: [
                      for (int i = 1; i <= AppConfig.totalSemanas; i++)
                        DropdownMenuItem(value: i, child: Text('Semana $i'))
                    ],
                    onChanged: (v) => setState(() => _semana = v!),
                    decoration: const InputDecoration(labelText: 'Semana'))),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 8, children: [
            ElevatedButton.icon(
                onPressed: () async {
                  final ss = await ctrl.sesionesDeSemana(_labId!, _semana);
                  final bytes = await Pdfs.afRg02(
                      lab: lab, sesiones: ss, semana: _semana, responsable: responsable);
                  await Printing.layoutPdf(onLayout: (_) async => bytes);
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Vista previa del PDF')),
            ElevatedButton.icon(
                onPressed: () => ctrl.generarPdfSemana(_labId!, _semana),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Generar y subir a Drive')),
          ]),
          const SizedBox(height: 24),
          FutureBuilder<List<SesionLaboratorio>>(
            future: ctrl.sesionesDeSemana(_labId!, _semana),
            builder: (context, snap) {
              final ss = snap.data ?? [];
              final kpis = _kpis(ss);
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Seguimiento a Indicadores clave de desempeño KPIs',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          for (final e in kpis.entries)
                            Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(e.key),
                                      Text(e.value,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ])),
                        ]))),
                const SizedBox(height: 16),
                Text('Sesiones de la semana: ${ss.length}'),
                for (final s in ss)
                  Card(
                      child: ListTile(
                    title: Text(s.asignatura),
                    subtitle: Text(
                        '${s.docente.nombreCompleto} • ${s.fecha.day}/${s.fecha.month} • Bloques ${s.bloqueInicio}-${s.bloqueFin}'),
                    trailing: Text('${s.estudiantesAtendidos} est.'),
                  )),
              ]);
            },
          ),
        ]),
      );
    });
  }
}

// ================= DOCUMENTOS =================
class DocumentosScreen extends StatefulWidget {
  const DocumentosScreen({super.key});
  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  List<DocumentoGenerado> _docs = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    _docs = await Almacen.getDocumentos();
    if (mounted) setState(() {});
  }

  Future<void> _reintentar(DocumentoGenerado doc) async {
    final lab = DatosSemilla.laboratorios
        .firstWhere((l) => l.id == doc.laboratorioId);
    final responsable = 'Coordinación de ${lab.carrera.abreviatura}';
    List<int> bytes;
    if (doc.tipo == 'AF-RG-01') {
      final reservas = await Almacen.reservasDeLaboratorio(lab.id);
      bytes = await Pdfs.afRg01(
          lab: lab, reservas: reservas, responsable: responsable);
    } else {
      final ss = await Almacen.sesionesDeLabYSemana(lab.id, doc.semana ?? 1);
      bytes = await Pdfs.afRg02(
          lab: lab, sesiones: ss, semana: doc.semana ?? 1, responsable: responsable);
    }
    final nuevo = await DocumentosService.guardarYSubir(
        nombre: doc.nombre,
        tipo: doc.tipo,
        laboratorioId: doc.laboratorioId,
        semana: doc.semana,
        bytes: bytes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(nuevo.subido
              ? 'Subido a Drive correctamente'
              : 'Sigue pendiente: configura Drive en app_config')));
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_docs.isEmpty) {
      return const Center(child: Text('Aún no hay documentos generados'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _docs.length,
      itemBuilder: (ctx, i) {
        final d = _docs[i];
        return Card(
            child: ListTile(
          leading: Icon(d.subido ? Icons.cloud_done : Icons.cloud_off,
              color: d.subido ? Colors.green : Colors.orange),
          title: Text(d.nombre),
          subtitle: Text(
              '${d.tipo}${d.semana != null ? ' • Semana ${d.semana}' : ''} • ${d.fechaGeneracion.day}/${d.fechaGeneracion.month}/${d.fechaGeneracion.year}'),
          trailing: d.subido
              ? const Icon(Icons.check_circle, color: Colors.green)
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reintentar subida',
                  onPressed: () => _reintentar(d)),
        ));
      },
    );
  }
}

// ================= MODO PRUEBAS =================
class PruebasScreen extends StatefulWidget {
  const PruebasScreen({super.key});
  @override
  State<PruebasScreen> createState() => _PruebasScreenState();
}

class _PruebasScreenState extends State<PruebasScreen> {
  String _labId = DatosSemilla.laboratorios.first.id;

  Future<void> _pasada() async {
    final ctrl = context.read<AppController>();
    final lab = DatosSemilla.laboratorios.firstWhere((l) => l.id == _labId);
    if (ctrl.sesionAbierta == null) {
      await ctrl.registrarEntrada(lab);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Entrada registrada en ${lab.nombre}')));
      }
    } else {
      await ctrl.registrarSalida();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Salida registrada')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.modoPruebas) {
      return const Center(child: Text('Modo pruebas desactivado'));
    }
    return Consumer<AppController>(builder: (context, ctrl, _) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reloj simulado',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Ahora: ${Reloj.fecha(ctrl.ahora)} ${Reloj.hora(ctrl.ahora)}'),
                        Text('Semana ${ctrl.semanaActual} de ${AppConfig.totalSemanas}'),
                      ]))),
          const SizedBox(height: 16),
          const Text('Ajustes rápidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ElevatedButton(
                onPressed: () => ctrl.sumarMinutos(50),
                child: const Text('+50 min')),
            ElevatedButton(
                onPressed: () => ctrl.sumarDias(1), child: const Text('+1 día')),
            ElevatedButton(
                onPressed: () => ctrl.sumarSemanas(1),
                child: const Text('+1 semana')),
            ElevatedButton(
                onPressed: () => ctrl.simularFecha(DateTime(2026, 9, 7, 7, 5)),
                child: const Text('Lunes 7:05 sem 1')),
            ElevatedButton(
                onPressed: () => ctrl.simularFecha(DateTime(2026, 9, 11, 17, 55)),
                child: const Text('Viernes 17:55 sem 1')),
            ElevatedButton(
                onPressed: () => ctrl.simularFecha(DateTime(2026, 12, 18, 17, 55)),
                child: const Text('Fin del cuatrimestre')),
          ]),
          const SizedBox(height: 16),
          TextField(
              decoration:
                  const InputDecoration(labelText: 'Fijar fecha (AAAA-MM-DD HH:MM)'),
              onSubmitted: (v) {
                try {
                  ctrl.simularFecha(DateTime.parse(v));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Formato inválido')));
                }
              }),
          const SizedBox(height: 24),
          const Text('Simulador de credencial',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
              value: _labId,
              items: [
                for (final l in DatosSemilla.laboratorios)
                  DropdownMenuItem(value: l.id, child: Text('${l.nombre} (${l.lectorId})'))
              ],
              onChanged: (v) => setState(() => _labId = v!),
              decoration: const InputDecoration(labelText: 'Lector')),
          const SizedBox(height: 8),
          ElevatedButton.icon(
              onPressed: _pasada,
              icon: const Icon(Icons.contactless),
              label: const Text('Simular pasada de credencial')),
          const SizedBox(height: 24),
          const Text('Usuarios de prueba',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final d in DatosSemilla.docentes)
            Card(
                child: ListTile(
              title: Text(d.nombreCompleto),
              subtitle: Text(
                  'Usuario: ${d.usuario} • Contraseña: ${d.contrasena} • UID: ${d.uidTarjeta} • ${d.carrera.abreviatura}'),
            )),
          const SizedBox(height: 24),
          ElevatedButton.icon(
              onPressed: () async {
                final seguro = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                          title: const Text('¿Reiniciar todos los datos?'),
                          content: const Text(
                              'Se borrarán reservas, sesiones y documentos.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Reiniciar')),
                          ],
                        ));
                if (seguro == true) await ctrl.reiniciarTodo();
              },
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Reiniciar todos los datos'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red)),
        ]),
      );
    });
  }
}

// ================= ESTUDIANTADO =================
class EstudiantadoScreen extends StatefulWidget {
  const EstudiantadoScreen({super.key});
  @override
  State<EstudiantadoScreen> createState() => _EstudiantadoScreenState();
}

class _EstudiantadoScreenState extends State<EstudiantadoScreen> {
  final _cantidad = TextEditingController();
  final _matricula = TextEditingController();
  final List<String> _matriculas = [];

  @override
  void dispose() {
    _cantidad.dispose();
    _matricula.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sesionId = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      appBar: AppBar(title: const Text('Apartado de estudiantado')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
              controller: _cantidad,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Número de estudiantes atendidos')),
          const SizedBox(height: 16),
          const Text('Matrículas (opcional, escritas o escaneadas con el lector)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _matricula,
                    decoration: const InputDecoration(labelText: 'Matrícula'))),
            IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_matricula.text.trim().isEmpty) return;
                  setState(() {
                    _matriculas.add(_matricula.text.trim());
                    _matricula.clear();
                  });
                }),
          ]),
          Expanded(
              child: ListView(
                  children: [
            for (int i = 0; i < _matriculas.length; i++)
              ListTile(
                  title: Text(_matriculas[i]),
                  trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () =>
                          setState(() => _matriculas.removeAt(i)))),
          ])),
          ElevatedButton(
              onPressed: () async {
                if (sesionId == null) return;
                await context.read<AppController>().registrarEstudiantes(
                    sesionId, int.tryParse(_cantidad.text) ?? 0, _matriculas);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Estudiantado registrado')));
                }
              },
              child: const Text('Guardar')),
        ]),
      ),
    );
  }
}
