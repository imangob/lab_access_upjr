import 'package:flutter/material.dart';

// ================= CONFIGURACIÓN =================
class AppConfig {
  static const String appName = 'lab_access_upjr';
  static const String driveScriptUrl = 'TU_URL_DE_APPS_SCRIPT_AQUI/exec';
  static const String driveToken = 'TU_TOKEN_AQUI';
  static const bool modoPruebas = true;
  static const DateTime fechaInicioCuatrimestre = DateTime(2026, 9, 7);
  static const int totalSemanas = 15;
  static const int toleranciaMinutos = 15;
}

// ================= COLORES UPJR =================
class AppTheme {
  static const Color azulOscuro = Color(0xFF0B3C6E);
  static const Color azulMedio = Color(0xFF1565C0);
  static const Color azulClaro = Color(0xFF1B8FA6);
  static const Color naranja = Color(0xFFF58220);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: azulOscuro,
          primary: azulOscuro,
          secondary: naranja,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: azulOscuro,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: naranja,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
}

// ================= MODELOS =================
class Carrera {
  final String id;
  final String nombre;
  final String abreviatura;
  const Carrera({required this.id, required this.nombre, required this.abreviatura});

  Map<String, dynamic> toJson() =>
      {'id': id, 'nombre': nombre, 'abreviatura': abreviatura};
  factory Carrera.fromJson(Map<String, dynamic> j) => Carrera(
      id: j['id'] ?? '', nombre: j['nombre'] ?? '', abreviatura: j['abreviatura'] ?? '');
}

class Laboratorio {
  final String id;
  final String nombre;
  final String lectorId;
  final Carrera carrera;
  const Laboratorio(
      {required this.id,
      required this.nombre,
      required this.lectorId,
      required this.carrera});

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'lectorId': lectorId,
        'carrera': carrera.toJson()
      };
  factory Laboratorio.fromJson(Map<String, dynamic> j) => Laboratorio(
      id: j['id'] ?? '',
      nombre: j['nombre'] ?? '',
      lectorId: j['lectorId'] ?? '',
      carrera: Carrera.fromJson(j['carrera'] ?? {}));
}

class Docente {
  final String id;
  final String usuario;
  final String contrasena;
  final String? uidTarjeta;
  final String nombreCompleto;
  final String puesto;
  final Carrera carrera;
  const Docente(
      {required this.id,
      required this.usuario,
      required this.contrasena,
      this.uidTarjeta,
      required this.nombreCompleto,
      required this.puesto,
      required this.carrera});

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuario': usuario,
        'contrasena': contrasena,
        'uidTarjeta': uidTarjeta,
        'nombreCompleto': nombreCompleto,
        'puesto': puesto,
        'carrera': carrera.toJson()
      };
  factory Docente.fromJson(Map<String, dynamic> j) => Docente(
      id: j['id'] ?? '',
      usuario: j['usuario'] ?? '',
      contrasena: j['contrasena'] ?? '',
      uidTarjeta: j['uidTarjeta'],
      nombreCompleto: j['nombreCompleto'] ?? '',
      puesto: j['puesto'] ?? '',
      carrera: Carrera.fromJson(j['carrera'] ?? {}));
}

class Reserva {
  final String id;
  final Laboratorio laboratorio;
  final Docente docente;
  final int diaSemana;
  final int bloqueInicio;
  final int bloqueFin;
  final String asignatura;
  final String gradoGrupo;
  final String programaEducativo;
  const Reserva(
      {required this.id,
      required this.laboratorio,
      required this.docente,
      required this.diaSemana,
      required this.bloqueInicio,
      required this.bloqueFin,
      required this.asignatura,
      required this.gradoGrupo,
      required this.programaEducativo});

  Map<String, dynamic> toJson() => {
        'id': id,
        'laboratorio': laboratorio.toJson(),
        'docente': docente.toJson(),
        'diaSemana': diaSemana,
        'bloqueInicio': bloqueInicio,
        'bloqueFin': bloqueFin,
        'asignatura': asignatura,
        'gradoGrupo': gradoGrupo,
        'programaEducativo': programaEducativo
      };
  factory Reserva.fromJson(Map<String, dynamic> j) => Reserva(
      id: j['id'] ?? '',
      laboratorio: Laboratorio.fromJson(j['laboratorio'] ?? {}),
      docente: Docente.fromJson(j['docente'] ?? {}),
      diaSemana: j['diaSemana'] ?? 1,
      bloqueInicio: j['bloqueInicio'] ?? 1,
      bloqueFin: j['bloqueFin'] ?? 1,
      asignatura: j['asignatura'] ?? '',
      gradoGrupo: j['gradoGrupo'] ?? '',
      programaEducativo: j['programaEducativo'] ?? '');
}

class SesionLaboratorio {
  final String id;
  final Laboratorio laboratorio;
  final Docente docente;
  final DateTime fecha;
  final int bloqueInicio;
  final int bloqueFin;
  final String asignatura;
  final String gradoGrupo;
  final String programaEducativo;
  final DateTime? horaEntrada;
  final DateTime? horaSalida;
  final int estudiantesAtendidos;
  final List<String> matriculas;
  final bool esHoraProgramada;
  final String? observaciones;

  SesionLaboratorio(
      {required this.id,
      required this.laboratorio,
      required this.docente,
      required this.fecha,
      required this.bloqueInicio,
      required this.bloqueFin,
      required this.asignatura,
      this.gradoGrupo = '',
      this.programaEducativo = '',
      this.horaEntrada,
      this.horaSalida,
      this.estudiantesAtendidos = 0,
      this.matriculas = const [],
      this.esHoraProgramada = true,
      this.observaciones});

  SesionLaboratorio copiaCon({
    DateTime? horaEntrada,
    DateTime? horaSalida,
    int? estudiantesAtendidos,
    List<String>? matriculas,
    String? observaciones,
  }) {
    return SesionLaboratorio(
        id: id,
        laboratorio: laboratorio,
        docente: docente,
        fecha: fecha,
        bloqueInicio: bloqueInicio,
        bloqueFin: bloqueFin,
        asignatura: asignatura,
        gradoGrupo: gradoGrupo,
        programaEducativo: programaEducativo,
        horaEntrada: horaEntrada ?? this.horaEntrada,
        horaSalida: horaSalida ?? this.horaSalida,
        estudiantesAtendidos: estudiantesAtendidos ?? this.estudiantesAtendidos,
        matriculas: matriculas ?? this.matriculas,
        esHoraProgramada: esHoraProgramada,
        observaciones: observaciones ?? this.observaciones);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'laboratorio': laboratorio.toJson(),
        'docente': docente.toJson(),
        'fecha': fecha.toIso8601String(),
        'bloqueInicio': bloqueInicio,
        'bloqueFin': bloqueFin,
        'asignatura': asignatura,
        'gradoGrupo': gradoGrupo,
        'programaEducativo': programaEducativo,
        'horaEntrada': horaEntrada?.toIso8601String(),
        'horaSalida': horaSalida?.toIso8601String(),
        'estudiantesAtendidos': estudiantesAtendidos,
        'matriculas': matriculas,
        'esHoraProgramada': esHoraProgramada,
        'observaciones': observaciones
      };
  factory SesionLaboratorio.fromJson(Map<String, dynamic> j) => SesionLaboratorio(
      id: j['id'] ?? '',
      laboratorio: Laboratorio.fromJson(j['laboratorio'] ?? {}),
      docente: Docente.fromJson(j['docente'] ?? {}),
      fecha: DateTime.parse(j['fecha']),
      bloqueInicio: j['bloqueInicio'] ?? 1,
      bloqueFin: j['bloqueFin'] ?? 1,
      asignatura: j['asignatura'] ?? '',
      gradoGrupo: j['gradoGrupo'] ?? '',
      programaEducativo: j['programaEducativo'] ?? '',
      horaEntrada:
          j['horaEntrada'] != null ? DateTime.parse(j['horaEntrada']) : null,
      horaSalida:
          j['horaSalida'] != null ? DateTime.parse(j['horaSalida']) : null,
      estudiantesAtendidos: j['estudiantesAtendidos'] ?? 0,
      matriculas: List<String>.from(j['matriculas'] ?? []),
      esHoraProgramada: j['esHoraProgramada'] ?? true,
      observaciones: j['observaciones']);
}

class DocumentoGenerado {
  final String id;
  final String nombre;
  final String tipo;
  final String laboratorioId;
  final int? semana;
  final DateTime fechaGeneracion;
  final bool subido;
  final String? errorSubida;

  const DocumentoGenerado(
      {required this.id,
      required this.nombre,
      required this.tipo,
      required this.laboratorioId,
      this.semana,
      required this.fechaGeneracion,
      this.subido = false,
      this.errorSubida});

  DocumentoGenerado copiaCon({bool? subido, String? errorSubida}) {
    return DocumentoGenerado(
        id: id,
        nombre: nombre,
        tipo: tipo,
        laboratorioId: laboratorioId,
        semana: semana,
        fechaGeneracion: fechaGeneracion,
        subido: subido ?? this.subido,
        errorSubida: errorSubida ?? this.errorSubida);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'tipo': tipo,
        'laboratorioId': laboratorioId,
        'semana': semana,
        'fechaGeneracion': fechaGeneracion.toIso8601String(),
        'subido': subido,
        'errorSubida': errorSubida
      };
  factory DocumentoGenerado.fromJson(Map<String, dynamic> j) =>
      DocumentoGenerado(
          id: j['id'] ?? '',
          nombre: j['nombre'] ?? '',
          tipo: j['tipo'] ?? '',
          laboratorioId: j['laboratorioId'] ?? '',
          semana: j['semana'],
          fechaGeneracion: DateTime.parse(j['fechaGeneracion']),
          subido: j['subido'] ?? false,
          errorSubida: j['errorSubida']);
}

// ================= DATOS SEMILLA =================
class DatosSemilla {
  static const Carrera itiid = Carrera(
      id: 'c1',
      nombre:
          'Ingeniería en Tecnologías de la Información e Innovación Digital',
      abreviatura: 'ITIID');
  static const Carrera ima = Carrera(
      id: 'c2',
      nombre: 'Ingeniería en Manufactura Avanzada',
      abreviatura: 'IMA');

  static const List<Laboratorio> laboratorios = [
    Laboratorio(id: 'lab1', nombre: 'Aplicaciones Móviles', lectorId: 'LECTOR-MOVILES', carrera: itiid),
    Laboratorio(id: 'lab2', nombre: 'Electrónica', lectorId: 'LECTOR-ELECTRONICA', carrera: itiid),
    Laboratorio(id: 'lab3', nombre: 'Telemática y Redes', lectorId: 'LECTOR-REDES', carrera: itiid),
    Laboratorio(id: 'lab4', nombre: 'Manufactura CNC', lectorId: 'LECTOR-CNC', carrera: ima),
  ];

  static const List<Docente> docentes = [
    Docente(id: 'd1', usuario: '270', contrasena: '027', uidTarjeta: '270',
        nombreCompleto: 'Juan Pérez García', puesto: 'Docente de Asignatura', carrera: itiid),
    Docente(id: 'd2', usuario: '150', contrasena: '051', uidTarjeta: '150',
        nombreCompleto: 'María López Hernández', puesto: 'Docente de Asignatura', carrera: itiid),
    Docente(id: 'd3', usuario: '320', contrasena: '023', uidTarjeta: '320',
        nombreCompleto: 'Roberto Sánchez Ruiz', puesto: 'Docente de Tiempo Completo', carrera: ima),
  ];

  static Docente? buscarPorUid(String uid) => docentes
      .cast<Docente?>()
      .firstWhere((d) => d?.uidTarjeta == uid, orElse: () => null);

  static Docente? buscarPorUsuario(String usuario, String contrasena) =>
      docentes.cast<Docente?>().firstWhere(
          (d) => d?.usuario == usuario && d?.contrasena == contrasena,
          orElse: () => null);

  static List<Laboratorio> labsDeCarrera(String carreraId) =>
      laboratorios.where((l) => l.carrera.id == carreraId).toList();
}

// ================= BLOQUES DE HORARIO =================
class BloqueHorario {
  final int numero;
  final String horaInicio;
  final String horaFin;
  final String? leyenda;
  const BloqueHorario(this.numero, this.horaInicio, this.horaFin, [this.leyenda]);

  bool contiene(DateTime hora) {
    final ini = Reloj.parseHora(horaInicio);
    final fin = Reloj.parseHora(horaFin);
    return !hora.isBefore(ini) && hora.isBefore(fin);
  }
}

class BloquesHorario {
  static const List<BloqueHorario> bloques = [
    BloqueHorario(1, '07:10', '08:00'),
    BloqueHorario(2, '08:00', '08:50'),
    BloqueHorario(3, '08:50', '09:40'),
    BloqueHorario(4, '09:40', '10:30'),
    BloqueHorario(5, '10:30', '11:20'),
    BloqueHorario(6, '11:20', '12:10'),
    BloqueHorario(7, '12:10', '13:00'),
    BloqueHorario(8, '13:00', '13:50'),
    BloqueHorario(9, '13:50', '14:40'),
    BloqueHorario(10, '14:40', '15:30', 'Cierre'),
    BloqueHorario(11, '15:30', '16:20'),
    BloqueHorario(12, '16:20', '17:10'),
    BloqueHorario(13, '17:10', '18:00'),
  ];

  static BloqueHorario? bloqueActual(DateTime ahora) {
    for (final b in bloques) {
      if (b.contiene(ahora)) return b;
    }
    return null;
  }
}

// ================= RELOJ (REAL O SIMULADO) =================
class Reloj {
  static DateTime? _simulada;

  static DateTime ahora() {
    if (AppConfig.modoPruebas && _simulada != null) return _simulada!;
    return DateTime.now();
  }

  static void simular(DateTime f) {
    if (AppConfig.modoPruebas) _simulada = f;
  }

  static void reiniciar() {
    _simulada = null;
  }

  static void sumarMinutos(int m) {
    if (_simulada != null) _simulada = _simulada!.add(Duration(minutes: m));
  }

  static void sumarDias(int d) {
    if (_simulada != null) _simulada = _simulada!.add(Duration(days: d));
  }

  static void sumarSemanas(int s) {
    sumarDias(s * 7);
  }

  static DateTime parseHora(String hora) {
    final p = hora.split(':');
    final a = ahora();
    return DateTime(a.year, a.month, a.day, int.parse(p[0]), int.parse(p[1]));
  }

  static int semanaActual() {
    final dias = ahora().difference(AppConfig.fechaInicioCuatrimestre).inDays;
    return ((dias / 7).floor() + 1).clamp(1, AppConfig.totalSemanas);
  }

  static DateTime inicioSemana(int semana) =>
      AppConfig.fechaInicioCuatrimestre.add(Duration(days: (semana - 1) * 7));

  static String fecha(DateTime f) {
    const dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    const meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return '${dias[f.weekday % 7]} ${f.day} de ${meses[f.month - 1]} de ${f.year}';
  }

  static String hora(DateTime f) =>
      '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
}  
