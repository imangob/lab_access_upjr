import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'base.dart';

class Almacen {
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Map<String, dynamic> _mapa(dynamic j) =>
      Map<String, dynamic>.from(j as Map);

  // ---------- DOCENTE ACTIVO ----------
  static Future<void> guardarDocenteActivo(Docente d) async {
    final p = await _prefs;
    await p.setString('docente_activo', json.encode(d.toJson()));
  }

  static Future<Docente?> getDocenteActivo() async {
    final p = await _prefs;
    final s = p.getString('docente_activo');
    if (s == null) return null;
    return Docente.fromJson(_mapa(json.decode(s)));
  }

  static Future<void> borrarDocenteActivo() async {
    final p = await _prefs;
    await p.remove('docente_activo');
  }

  // ---------- RESERVAS (AF-RG-01) ----------
  static Future<List<Reserva>> getReservas() async {
    final p = await _prefs;
    final s = p.getString('reservas');
    if (s == null) return [];
    return (json.decode(s) as List)
        .map((j) => Reserva.fromJson(_mapa(j)))
        .toList();
  }

  static Future<void> guardarReserva(Reserva r) async {
    final lista = await getReservas();
    lista.removeWhere((x) => x.id == r.id);
    lista.add(r);
    final p = await _prefs;
    await p.setString(
        'reservas', json.encode(lista.map((x) => x.toJson()).toList()));
  }

  static Future<void> eliminarReserva(String id) async {
    final lista = await getReservas();
    lista.removeWhere((x) => x.id == id);
    final p = await _prefs;
    await p.setString(
        'reservas', json.encode(lista.map((x) => x.toJson()).toList()));
  }

  static Future<List<Reserva>> reservasDeDocente(String docenteId) async =>
      (await getReservas()).where((r) => r.docente.id == docenteId).toList();

  static Future<List<Reserva>> reservasDeLaboratorio(String labId) async =>
      (await getReservas()).where((r) => r.laboratorio.id == labId).toList();

  // ---------- SESIONES (AF-RG-02) ----------
  static Future<List<SesionLaboratorio>> getSesiones() async {
    final p = await _prefs;
    final s = p.getString('sesiones');
    if (s == null) return [];
    return (json.decode(s) as List)
        .map((j) => SesionLaboratorio.fromJson(_mapa(j)))
        .toList();
  }

  static Future<void> guardarSesion(SesionLaboratorio s) async {
    final lista = await getSesiones();
    lista.removeWhere((x) => x.id == s.id);
    lista.add(s);
    final p = await _prefs;
    await p.setString(
        'sesiones', json.encode(lista.map((x) => x.toJson()).toList()));
  }

  static Future<SesionLaboratorio?> getSesionAbierta(String docenteId) async {
    final lista = await getSesiones();
    final abiertas = lista.where((s) =>
        s.docente.id == docenteId &&
        s.horaEntrada != null &&
        s.horaSalida == null).toList();
    return abiertas.isEmpty ? null : abiertas.first;
  }

  static Future<List<SesionLaboratorio>> sesionesDeLabYSemana(
      String labId, int semana) async {
    final inicio = Reloj.inicioSemana(semana);
    final fin = inicio.add(const Duration(days: 4, hours: 23, minutes: 59));
    return (await getSesiones()).where((s) =>
        s.laboratorio.id == labId &&
        !s.fecha.isBefore(inicio) &&
        !s.fecha.isAfter(fin)).toList();
  }

  // ---------- DOCUMENTOS ----------
  static Future<List<DocumentoGenerado>> getDocumentos() async {
    final p = await _prefs;
    final s = p.getString('documentos');
    if (s == null) return [];
    return (json.decode(s) as List)
        .map((j) => DocumentoGenerado.fromJson(_mapa(j)))
        .toList();
  }

  static Future<void> guardarDocumento(DocumentoGenerado d) async {
    final lista = await getDocumentos();
    lista.removeWhere((x) => x.id == d.id);
    lista.add(d);
    final p = await _prefs;
    await p.setString(
        'documentos', json.encode(lista.map((x) => x.toJson()).toList()));
  }

  // ---------- BORRAR TODO ----------
  static Future<void> borrarTodo() async {
    final p = await _prefs;
    await p.clear();
  }
}
