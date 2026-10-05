import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'base.dart';
import 'storage.dart';
import 'servicios.dart';
import 'pdfs.dart';

class AppController extends ChangeNotifier {
  static const _uuid = Uuid();

  Docente? get docente => AuthService.docenteActivo;
  List<Laboratorio> laboratorios = [];
  List<Reserva> misReservas = [];
  SesionLaboratorio? sesionAbierta;
  List<DocumentoGenerado> documentos = [];

  DateTime get ahora => Reloj.ahora();
  int get semanaActual => Reloj.semanaActual();

  Future<void> inicializar() async {
    await AuthService.inicializar();
    await _cargar();
    notifyListeners();
  }

  Future<void> _cargar() async {
    final d = docente;
    if (d == null) {
      laboratorios = []; misReservas = []; sesionAbierta = null;
    } else {
      laboratorios = DatosSemilla.labsDeCarrera(d.carrera.id);
      misReservas = await Almacen.reservasDeDocente(d.id);
      sesionAbierta = await Almacen.getSesionAbierta(d.id);
    }
    documentos = await Almacen.getDocumentos();
  }

  // ---------- SESIÓN ----------
  Future<bool> loginTarjeta(String uid) async {
    final d = await AuthService.loginTarjeta(uid);
    if (d != null) { await _cargar(); notifyListeners(); return true; }
    return false;
  }

  Future<bool> loginManual(String usuario, String contrasena) async {
    final d = await AuthService.loginManual(usuario, contrasena);
    if (d != null) { await _cargar(); notifyListeners(); return true; }
    return false;
  }

  Future<void> logout() async {
    await AuthService.salir();
    await _cargar();
    notifyListeners();
  }

  // ---------- RESERVAS (AF-RG-01) ----------
  Future<bool> crearReserva({
    required Laboratorio laboratorio, required int diaSemana,
    required int bloqueInicio, required int bloqueFin,
    required String asignatura, required String gradoGrupo,
    required String programaEducativo,
  }) async {
    final d = docente;
    if (d == null) return false;
    final todas = await Almacen.getReservas();
    final choque = todas.any((r) =>
        r.laboratorio.id == laboratorio.id &&
        r.diaSemana == diaSemana &&
        r.bloqueInicio < bloqueFin &&
        bloqueInicio < r.bloqueFin);
    if (choque) return false;

    final r = Reserva(
        id: _uuid.v4(), laboratorio: laboratorio, docente: d,
        diaSemana: diaSemana, bloqueInicio: bloqueInicio, bloqueFin: bloqueFin,
        asignatura: asignatura, gradoGrupo: gradoGrupo,
        programaEducativo: programaEducativo);
    await Almacen.guardarReserva(r);
    await _regenerarAfRg01(laboratorio);
    await _cargar();
    notifyListeners();
    return true;
  }

  Future<void> eliminarReserva(String id) async {
    final r = misReservas.firstWhere((x) => x.id == id);
    await Almacen.eliminarReserva(id);
    await _regenerarAfRg01(r.laboratorio);
    await _cargar();
    notifyListeners();
  }

  Future<void> _regenerarAfRg01(Laboratorio lab) async {
    final reservas = await Almacen.reservasDeLaboratorio(lab.id);
    final bytes = await Pdfs.afRg01(
        lab: lab, reservas: reservas,
        responsable: 'Coordinación de ${lab.carrera.abreviatura}');
    await DocumentosService.guardarYSubir(
        nombre: 'AF-RG-01_${lab.nombre}.pdf', tipo: 'AF-RG-01',
        laboratorioId: lab.id, bytes: bytes);
  }

  // ---------- ASISTENCIA ----------
  Future<void> registrarEntrada(Laboratorio lab) async {
    final d = docente;
    if (d == null) return;
    await AsistenciaService.registrarEntrada(d, lab);
    await _cargar();
    notifyListeners();
  }

  Future<void> registrarSalida() async {
    final d = docente;
    if (d == null) return;
    await AsistenciaService.registrarSalida(d);
    await _cargar();
    notifyListeners();
  }

  Future<void> registrarEstudiantes(String sesionId, int cantidad, List<String> matriculas) async {
    await AsistenciaService.actualizarEstudiantes(sesionId, cantidad, matriculas);
    await _cargar();
    notifyListeners();
  }

  // ---------- REGISTRO SEMANAL (AF-RG-02) ----------
  Future<List<SesionLaboratorio>> sesionesDeSemana(String labId, int semana) =>
      Almacen.sesionesDeLabYSemana(labId, semana);

  Future<void> generarPdfSemana(String labId, int semana) async {
    final lab = DatosSemilla.laboratorios.firstWhere((l) => l.id == labId);
    final sesiones = await Almacen.sesionesDeLabYSemana(labId, semana);
    final bytes = await Pdfs.afRg02(
        lab: lab, sesiones: sesiones, semana: semana,
        responsable: 'Coordinación de ${lab.carrera.abreviatura}');
    await DocumentosService.guardarYSubir(
        nombre: 'AF-RG-02_${lab.nombre}_Semana$semana.pdf', tipo: 'AF-RG-02',
        laboratorioId: labId, semana: semana, bytes: bytes);
    await _cargar();
    notifyListeners();
  }

  // ---------- MODO PRUEBAS ----------
  void simularFecha(DateTime f) { Reloj.simular(f); notifyListeners(); }
  void sumarMinutos(int m) { Reloj.sumarMinutos(m); notifyListeners(); }
  void sumarDias(int d) { Reloj.sumarDias(d); notifyListeners(); }
  void sumarSemanas(int s) { Reloj.sumarSemanas(s); notifyListeners(); }

  Future<void> reiniciarTodo() async {
    await Almacen.borrarTodo();
    Reloj.reiniciar();
    await AuthService.inicializar();
    await _cargar();
    notifyListeners();
  }
}
