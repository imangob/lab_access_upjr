import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'base.dart';

class Pdfs {
  static const PdfColor _azul = PdfColor.fromInt(0xFF0B3C6E);
  static const PdfColor _azulClaro = PdfColor.fromInt(0xFF1B8FA6);

  static const List<List<String>> _horas = [
    ['7:10', '8:00'], ['8:00', '8:50'], ['8:50', '9:40'], ['9:40', '10:30'],
    ['10:30', '11:20'], ['11:20', '12:10'], ['12:10', '13:00'], ['13:00', '13:50'],
    ['13:50', '14:40'], ['14:40', '15:30'], ['15:30', '16:20'], ['16:20', '17:10'],
    ['17:10', '18:00'],
  ];

  static const List<String> _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

  static const pw.TextStyle _e8 = pw.TextStyle(fontSize: 8);
  static const pw.TextStyle _e7 = pw.TextStyle(fontSize: 7);
  static const pw.TextStyle _e8n = pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 8);

  // ---------- PARTES COMPARTIDAS ----------
  static pw.Widget _th(String t) => pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(2),
        decoration: const pw.BoxDecoration(color: _azul),
        child: pw.Text(t, style: const pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 8, color: PdfColors.white)),
      );

  static pw.Widget _td(String t, {bool tachar = false, bool centrado = false}) => pw.Container(
        padding: const pw.EdgeInsets.all(2),
        child: tachar
            ? pw.Center(child: pw.Text('X', style: _e8))
            : (centrado ? pw.Center(child: pw.Text(t, style: _e7)) : pw.Text(t, style: _e7)),
      );

  static pw.Widget _encabezadoOficial({
    required String titulo,
    required String laboratorio,
    required String responsable,
    required String anio,
    String? semana,
  }) {
    return pw.Column(children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Container(
          width: 50, height: 50,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: _azul)),
          child: pw.Center(child: pw.Text('UPJR',
              style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 12, color: _azul))),
        ),
        pw.Expanded(child: pw.Column(children: [
          pw.Text('Universidad Politécnica de Juventino Rosas',
              style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 11, color: _azul)),
          pw.Text(titulo,
              style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 10, color: _azulClaro)),
        ])),
        pw.SizedBox(width: 50, height: 50),
      ]),
      pw.SizedBox(height: 4),
      pw.Row(children: [
        pw.Expanded(child: pw.Text('Nombre del laboratorio: $laboratorio', style: _e8)),
        pw.Expanded(child: pw.Text('Nombre de la persona responsable: $responsable', style: _e8)),
      ]),
      pw.SizedBox(height: 2),
      pw.Row(children: [
        pw.Text('Cuatrimestre: 1', style: _e8),
        pw.SizedBox(width: 30),
        pw.Text('Año: $anio', style: _e8),
        if (semana != null) ...[
          pw.SizedBox(width: 30),
          pw.Text(semana, style: _e8),
        ],
      ]),
      pw.Divider(color: _azul),
      pw.SizedBox(height: 6),
    ]);
  }

  static pw.Widget _pie() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Text(
          'Documento controlado por medios electrónicos. Para uso exclusivo de la Universidad Politécnica de Juventino Rosas',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _firma(String titulo, String nombre, String puesto) {
    return pw.Column(children: [
      pw.Text(titulo, style: _e8n),
      pw.SizedBox(height: 24),
      pw.Container(width: 200,
          decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.black)))),
      pw.Text(nombre, style: _e8),
      pw.Text(puesto, style: _e8),
    ]);
  }

  static String _iniciales(String nombre) =>
      nombre.split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).join().toUpperCase();

  static String _rubrica(SesionLaboratorio s) {
    final e = s.horaEntrada != null ? Reloj.hora(s.horaEntrada!) : '--:--';
    final sal = s.horaSalida != null ? Reloj.hora(s.horaSalida!) : '--:--';
    return '${_iniciales(s.docente.nombreCompleto)} $e-$sal';
  }

  // ================= AF-RG-01 =================
  static Future<Uint8List> afRg01(
      {required Laboratorio lab, required List<Reserva> reservas, required String responsable}) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter.landscape,
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) => [
        _encabezadoOficial(
            titulo: 'AF-RG-01 Horario de Laboratorio (Rev. 07)',
            laboratorio: lab.nombre,
            responsable: responsable,
            anio: '${Reloj.ahora().year}'),
        _tablaAfRg01(reservas),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly, children: [
          _firma('Elaborado por:', responsable, 'Coordinación de Carrera'),
          _firma('Aprobado por:', 'Nombre completo', 'Puesto'),
        ]),
        pw.SizedBox(height: 8),
        _pie(),
      ],
    ));
    return pdf.save();
  }

  static pw.Widget _tablaAfRg01(List<Reserva> reservas) {
    final rows = <pw.TableRow>[];
    rows.add(pw.TableRow(children: [_th('Horario'), _th('Horario'), ..._dias.map(_th)]));

    for (int i = 0; i < _horas.length; i++) {
      final num = i + 1;
      final esCierre = i == 9;

      // Renglón 1: Asignatura (Grado-Grupo / PE)
      final r1 = <pw.Widget>[_td(_horas[i][0], centrado: true), _td(_horas[i][1], centrado: true)];
      // Renglón 2: Nombre del docente (o "Cierre")
      final r2 = <pw.Widget>[_td(''), _td(esCierre ? 'Cierre' : '', centrado: true)];

      for (int dia = 1; dia <= 5; dia++) {
        Reserva? r;
        for (final x in reservas) {
          if (x.diaSemana == dia && num >= x.bloqueInicio && num <= x.bloqueFin) { r = x; break; }
        }
        if (r == null) {
          r1.add(_td('', tachar: true));
          r2.add(_td('', tachar: true));
        } else if (num == r.bloqueInicio) {
          r1.add(_td('${r.asignatura} (${r.gradoGrupo} / ${r.programaEducativo})'));
          r2.add(_td(r.docente.nombreCompleto));
        } else {
          r1.add(_td(''));
          r2.add(_td(''));
        }
      }
      rows.add(pw.TableRow(children: r1));
      rows.add(pw.TableRow(children: r2));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(38), 1: pw.FixedColumnWidth(38),
        2: pw.FixedColumnWidth(134), 3: pw.FixedColumnWidth(134),
        4: pw.FixedColumnWidth(134), 5: pw.FixedColumnWidth(134), 6: pw.FixedColumnWidth(134),
      },
      children: rows,
    );
  }

  // ================= AF-RG-02 =================
  static Future<Uint8List> afRg02(
      {required Laboratorio lab, required List<SesionLaboratorio> sesiones,
      required int semana, required String responsable}) async {
    final inicio = Reloj.inicioSemana(semana);
    final fechas = List.generate(5, (i) => inicio.add(Duration(days: i)));
    final ahora = Reloj.ahora();

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter.landscape,
      margin: const pw.EdgeInsets.all(15),
      build: (ctx) => [
        _encabezadoOficial(
            titulo: 'AF-RG-02 Registro de uso de horas programadas de laboratorio (Rev. 09)',
            laboratorio: lab.nombre,
            responsable: responsable,
            anio: '${ahora.year}',
            semana: 'Semana $semana de ${AppConfig.totalSemanas}'),
        _tablaAfRg02(sesiones, fechas, ahora),
        pw.SizedBox(height: 8),
        _kpis(sesiones),
        pw.SizedBox(height: 8),
        _pie(),
      ],
    ));
    return pdf.save();
  }

  static pw.Widget _tablaAfRg02(List<SesionLaboratorio> sesiones, List<DateTime> fechas, DateTime ahora) {
    final rows = <pw.TableRow>[];
    rows.add(pw.TableRow(children: [_th('Horario'), _th('Horario'), ..._dias.map(_th)]));
    rows.add(pw.TableRow(children: [
      _td(''), _td(''),
      for (final f in fechas) _td('Fecha: ${f.day}/${f.month}/${f.year}', centrado: true),
    ]));

    for (int i = 0; i < _horas.length; i++) {
      final num = i + 1;
      final esCierre = i == 9;

      final r1 = <pw.Widget>[_td(_horas[i][0], centrado: true), _td(_horas[i][1], centrado: true)];
      final r2 = <pw.Widget>[_td(''), _td(esCierre ? 'Cierre' : '', centrado: true)];
      final r3 = <pw.Widget>[_td(''), _td('')];

      for (int d = 0; d < 5; d++) {
        final fechaDia = fechas[d];
        SesionLaboratorio? s;
        for (final x in sesiones) {
          if (x.fecha.year == fechaDia.year && x.fecha.month == fechaDia.month &&
              x.fecha.day == fechaDia.day && num >= x.bloqueInicio && num <= x.bloqueFin) {
            s = x; break;
          }
        }
        final finBloque = Reloj.parseHora(_horas[i][1]);
        final yaPaso = fechaDia.isBefore(ahora) || finBloque.isBefore(ahora);

        if (s != null && num == s.bloqueInicio) {
          r1.add(_td('${s.asignatura} (${s.gradoGrupo} / ${s.programaEducativo})'));
          r2.add(_td(s.docente.nombreCompleto));
          r3.add(_td('Estudiantado: ${s.estudiantesAtendidos} | Rúbrica: ${_rubrica(s)}'));
        } else if (s != null) {
          r1.add(_td('')); r2.add(_td('')); r3.add(_td(''));
        } else if (yaPaso) {
          r1.add(_td('', tachar: true));
          r2.add(_td('', tachar: true));
          r3.add(_td('', tachar: true));
        } else {
          r1.add(_td('')); r2.add(_td('')); r3.add(_td(''));
        }
      }
      rows.add(pw.TableRow(children: r1));
      rows.add(pw.TableRow(children: r2));
      rows.add(pw.TableRow(children: r3));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(38), 1: pw.FixedColumnWidth(38),
        2: pw.FixedColumnWidth(137), 3: pw.FixedColumnWidth(137),
        4: pw.FixedColumnWidth(137), 5: pw.FixedColumnWidth(137), 6: pw.FixedColumnWidth(137),
      },
      children: rows,
    );
  }

  static pw.Widget _kpis(List<SesionLaboratorio> sesiones) {
    final est = sesiones.fold<int>(0, (t, s) => t + s.estudiantesAtendidos);
    final prog = sesiones.where((s) => s.esHoraProgramada && s.horaEntrada != null).length;
    final noProg = sesiones.where((s) => !s.esHoraProgramada && s.horaEntrada != null).length;
    final total = prog + noProg;
    final pct = total > 0 ? (total / 13 * 100).toStringAsFixed(1) : '0.0';
    final obs = sesiones
        .where((s) => s.observaciones != null)
        .map((s) => s.observaciones)
        .join(' | ');

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Seguimiento a Indicadores clave de desempeño KPIs (Key Performance Indicators)',
          style: const pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9, color: _azul)),
      pw.SizedBox(height: 3),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(2)},
        children: [
          _kpiRow('Estudiantado atendido', '$est'),
          _kpiRow('Horas programadas realizadas', '$prog'),
          _kpiRow('Horas no programadas realizadas', '$noProg'),
          _kpiRow('Horas de auto-acceso (AF-RG-03)', '0'),
          _kpiRow('Horas de uso total', '$total'),
          _kpiRow('Porcentaje de uso', '$pct%'),
          _kpiRow('Observaciones', obs.isEmpty ? 'N/A' : obs),
        ],
      ),
    ]);
  }

  static pw.TableRow _kpiRow(String label, String valor) => pw.TableRow(children: [
        pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(label, style: _e8)),
        pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(valor, style: _e8)),
      ]);
}
