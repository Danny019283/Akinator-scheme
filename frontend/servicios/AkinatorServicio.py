class AkinatorServicio:
    """Traduce las acciones del juego (iniciar, responder, reiniciar) a
    mensajes del protocolo JSON y recuerda cuál es la característica que se está preguntando en este
    momento para poder anexarla en el siguiente 'responder'.
    """

    def __init__(self, cliente):
        self.cliente = cliente
        self.caracteristica_actual = None

    def iniciar(self):
        respuesta = self.cliente.enviar({"cmd": "iniciar"})
        self._actualizar_caracteristica(respuesta)
        return respuesta

    def responder(self, respuesta_usuario):
        mensaje = {
            "cmd": "responder",
            "caracteristica": self.caracteristica_actual,
            "respuesta": respuesta_usuario,
        }
        respuesta_scheme = self.cliente.enviar(mensaje)
        self._actualizar_caracteristica(respuesta_scheme)
        return respuesta_scheme

    def reiniciar(self):
        respuesta = self.cliente.enviar({"cmd": "reiniciar"})
        self._actualizar_caracteristica(respuesta)
        return respuesta

    def _actualizar_caracteristica(self, respuesta):
        if respuesta.get("tipo") == "pregunta":
            self.caracteristica_actual = respuesta["caracteristica"]
        else:
            self.caracteristica_actual = None
