import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'base.dart';
import 'storage.dart';

// ================= AUTENTICACIÓN =================
class AuthService {
  static Docente? docenteActivo;

  static Future<void> inicializar() async {
    docenteActivo = await Almacen.getDocenteActivo();
  }

  static Future<Docente?> loginTarjeta(String uid) async {
    final d = DatosSemilla.buscarPorUid(uid);
    if (d != null) {
      docenteActivo = d;
      await Almacen.guardarDocenteActivo(d);
    }
    return d;
  }

  static Future<Docente?> loginManual(String usuario, String contrasena) async {
    final d = DatosSemilla.buscarPorUsuario(usuario, contrasena);
    if (d != null) {
      docenteActivo = d;
      await Almacen.guardarDocenteActivo(d);
    }
    return d;
  }

  static Future<void> salir() async {
    docenteActivo = null;
    await Almacen.borrarDocenteActivo();
  }
}

// ================= ASISTENCIA (ENTRADA / SALIDA) =================
class AsistenciaService {
  static const _uuid = Uuid();

  static Future<SesionLaboratorio?> registrarEntrada(
      Docente docente, Laboratorio lab) async {
    final ahora = Reloj.ahora();
    if (ahora.weekday > 5) return null; // fin de semana
    final bloque = BloquesHorario.bloqueActual(ahora);
    if (bloque == null) return null;

    final reservas = (await Almacen.getReservas())
        .where((r) =>
            r.docente.id == docente.id &&
            r.laboratorio.id == lab.id &&
            r.diaSemana == ahora.weekday)
        .toList();

    // 1) ¿Tiene clase en este bloque?
    Reserva? coincidente;
    for (final r in reservas) {
      if (bloque.numero >= r.bloqueInicio && bloque.numero <= r.bloqueFin) {
        coincidente = r;
        break;
      }
    }

    // 2) ¿Llega con tolerancia de 15 min antes de su clase?
    if (coincidente == null) {
      for (final r in reservas) {
        final inicioReal = Reloj
            .parseHora(BloquesHorario.bloques[r.bloqueInicio - 1].horaInicio);
        final conTolerancia = inicioReal
            .subtract(const Duration(minutes: AppConfig.toleranciaMinutos));
        if (!ahora.isBefore(conTolerancia) && bloque.numero <= r.bloqueFin) {
          coincidente = r;
          break;
        }
      }
    }

    final sesion = SesionLaboratorio(
      id: _uuid.v4(),
      laboratorio: lab,
      docente: docente,
      fecha: DateTime(ahora.year, ahora.month, ahora.day),
      bloqueInicio: coincidente?.bloqueInicio ?? bloque.numero,
      bloqueFin: coincidente?.bloqueFin ?? bloque.numero,
      asignatura: coincidente?.asignatura ?? 'Hora no programada',
      gradoGrupo: coincidente?.gradoGrupo ?? '',
      programaEducativo: coincidente?.programaEducativo ?? '',
      horaEntrada: ahora,
      esHoraProgramada: coincidente != null,
    );
    await Almacen.guardarSesion(sesion);
    return sesion;
  }

  static Future<SesionLaboratorio?> registrarSalida(Docente docente) async {
    final abierta = await Almacen.getSesionAbierta(docente.id);
    if (abierta == null) return null;
    final cerrada = abierta.copiaCon(horaSalida: Reloj.ahora());
    await Almacen.guardarSesion(cerrada);
    return cerrada;
  }

  static Future<void> actualizarEstudiantes(
      String sesionId, int cantidad, List<String> matriculas) async {
    final sesiones = await Almacen.getSesiones();
    final s = sesiones.firstWhere((x) => x.id == sesionId);
    await Almacen.guardarSesion(
        s.copiaCon(estudiantesAtendidos: cantidad, matriculas: matriculas));
  }
}

// ================= GOOGLE DRIVE =================
class DriveService {
  static Future<bool> subir(DocumentoGenerado doc, List<int> bytes) async {
    if (AppConfig.driveScriptUrl.contains('TU_URL')) return false;
    try {
      final payload = {
        'token': AppConfig.driveToken,
        'nombre': doc.nombre,
        'carpeta': doc.tipo == 'AF-RG-01'
            ? 'AF-RG-01 Horarios de laboratorio/${doc.laboratorioId}/'
            : 'AF-RG-02 Registro semanal/${doc.laboratorioId}/Semana ${doc.semana}/',
        'mimeType': 'application/pdf',
        'contenidoBase64': base64Encode(bytes),
      };
      final resp = await http.post(
        Uri.parse(AppConfig.driveScriptUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: json.encode(payload),
      );
      if (resp.statusCode == 302 && resp.headers['location'] != null) {
        final r2 = await http.get(Uri.parse(resp.headers['location']!));
        return json.decode(r2.body)['ok'] == true;
      }
      if (resp.statusCode == 200) return json.decode(resp.body)['ok'] == true;
      return false;
    } catch (e) {
      return false;
    }
  }
}

// ================= DOCUMENTOS (PDF + DRIVE) =================
class DocumentosService {
  static const _uuid = Uuid();

  static Future<DocumentoGenerado> guardarYSubir({
    required String nombre,
    required String tipo,
    required String laboratorioId,
    int? semana,
    required List<int> bytes,
  }) async {
    final doc = DocumentoGenerado(
      id: _uuid.v4(),
      nombre: nombre,
      tipo: tipo,
      laboratorioId: laboratorioId,
      semana: semana,
      fechaGeneracion: Reloj.ahora(),
    );
    final exito = await DriveService.subir(doc, bytes);
    final fin = doc.copiaCon(subido: exito, errorSubida: exito ? null : 'No se pudo subir');
    await Almacen.guardarDocumento(fin);
    return fin;
  }
}
