class EstadisticasServicio:
    """Traduce las acciones de estadisticas (consultar, registrar resultado)
    al protocolo JSON con el motor Scheme, que es quien las calcula y
    persiste; el frontend no guarda ni interpreta ese estado."""

    def __init__(self, cliente):
        self.cliente = cliente

    def obtener(self):
        return self.cliente.enviar({"cmd": "estadisticas"})

    def registrar_resultado(self, acierto, numero_preguntas):
        return self.cliente.enviar({
            "cmd": "registrar_resultado",
            "acierto": acierto,
            "numero_preguntas": numero_preguntas,
        })
