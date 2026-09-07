from AkinatorServicio import AkinatorServicio


class ClienteFalso:
    """Doble de ClienteScheme: devuelve, en orden, una respuesta por cada
    llamada a enviar() y registra los mensajes recibidos."""

    def __init__(self, respuestas):
        self._respuestas = list(respuestas)
        self.mensajes_enviados = []

    def enviar(self, mensaje):
        self.mensajes_enviados.append(mensaje)
        return self._respuestas.pop(0)


def test_iniciar_manda_el_comando_iniciar():
    cliente = ClienteFalso([{"tipo": "pregunta", "caracteristica": "mamifero"}])
    servicio = AkinatorServicio(cliente)

    resultado = servicio.iniciar()

    assert cliente.mensajes_enviados == [{"cmd": "iniciar"}]
    assert resultado == {"tipo": "pregunta", "caracteristica": "mamifero"}


def test_responder_reenvia_la_caracteristica_de_la_ultima_pregunta():
    cliente = ClienteFalso([
        {"tipo": "pregunta", "caracteristica": "mamifero"},
        {"tipo": "pregunta", "caracteristica": "salvaje"},
    ])
    servicio = AkinatorServicio(cliente)
    servicio.iniciar()

    servicio.responder("si")

    assert cliente.mensajes_enviados[1] == {
        "cmd": "responder", "caracteristica": "mamifero", "respuesta": "si",
    }


def test_responder_actualiza_la_caracteristica_para_la_siguiente_pregunta():
    cliente = ClienteFalso([
        {"tipo": "pregunta", "caracteristica": "mamifero"},
        {"tipo": "pregunta", "caracteristica": "salvaje"},
        {"tipo": "pregunta", "caracteristica": "grande"},
    ])
    servicio = AkinatorServicio(cliente)
    servicio.iniciar()
    servicio.responder("si")

    servicio.responder("no")

    assert cliente.mensajes_enviados[2] == {
        "cmd": "responder", "caracteristica": "salvaje", "respuesta": "no",
    }


def test_una_prediccion_deja_de_rastrear_caracteristica():
    cliente = ClienteFalso([
        {"tipo": "pregunta", "caracteristica": "mamifero"},
        {"tipo": "prediccion", "entidad": "tigre"},
    ])
    servicio = AkinatorServicio(cliente)
    servicio.iniciar()

    servicio.responder("si")

    assert servicio.caracteristica_actual is None


def test_reiniciar_manda_el_comando_reiniciar():
    cliente = ClienteFalso([{"tipo": "pregunta", "caracteristica": "mamifero"}])
    servicio = AkinatorServicio(cliente)

    servicio.reiniciar()

    assert cliente.mensajes_enviados == [{"cmd": "reiniciar"}]
