from EstadisticasServicio import EstadisticasServicio


class ClienteFalso:
    """Doble de ClienteScheme: registra el ultimo mensaje enviado y
    devuelve una respuesta programada, sin lanzar ningun subproceso."""

    def __init__(self, respuesta):
        self.respuesta = respuesta
        self.mensajes_enviados = []

    def enviar(self, mensaje):
        self.mensajes_enviados.append(mensaje)
        return self.respuesta


def test_obtener_pide_estadisticas_al_backend():
    cliente = ClienteFalso({"tipo": "estadisticas", "partidas": 5, "aciertos": 3,
                             "fallos": 2, "promedio_preguntas": 6.7})
    servicio = EstadisticasServicio(cliente)

    resultado = servicio.obtener()

    assert cliente.mensajes_enviados == [{"cmd": "estadisticas"}]
    assert resultado == cliente.respuesta


def test_registrar_resultado_con_acierto_manda_acierto_true():
    cliente = ClienteFalso({"tipo": "estadisticas", "partidas": 1, "aciertos": 1,
                             "fallos": 0, "promedio_preguntas": 8.0})
    servicio = EstadisticasServicio(cliente)

    resultado = servicio.registrar_resultado(True, 8)

    assert cliente.mensajes_enviados == [
        {"cmd": "registrar_resultado", "acierto": True, "numero_preguntas": 8}
    ]
    assert resultado == cliente.respuesta


def test_registrar_resultado_con_fallo_manda_acierto_false():
    cliente = ClienteFalso({"tipo": "estadisticas", "partidas": 1, "aciertos": 0,
                             "fallos": 1, "promedio_preguntas": 5.0})
    servicio = EstadisticasServicio(cliente)

    servicio.registrar_resultado(False, 5)

    assert cliente.mensajes_enviados == [
        {"cmd": "registrar_resultado", "acierto": False, "numero_preguntas": 5}
    ]
