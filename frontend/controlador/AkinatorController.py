class AkinatorController:
    """ Coordina el servicio del juego (habla con Scheme) y el servicio de estadísticas
    (persistencia local en JSON), no toma decisiones de negocio."""

    def __init__(self, servicio, estadisticas_servicio):
        self.servicio = servicio
        self.estadisticas_servicio = estadisticas_servicio

    # --- Juego -------------------------------------------------------
    def iniciar_partida(self):
        return self.servicio.iniciar()

    def responder(self, respuesta):
        return self.servicio.responder(respuesta)

    def reiniciar_partida(self):
        return self.servicio.reiniciar()

    # --- Estadísticas --------------------------------------------------
    def obtener_estadisticas(self):
        return self.estadisticas_servicio.obtener()

    def registrar_acierto(self, numero_preguntas):
        return self.estadisticas_servicio.registrar_resultado(True, numero_preguntas)

    def registrar_fallo(self, numero_preguntas):
        return self.estadisticas_servicio.registrar_resultado(False, numero_preguntas)
