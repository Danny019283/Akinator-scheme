class EstadisticasServicio:
    """Mantiene en memoria las estadísticas de la sesión y las persiste
    en disco a través del repositorio en cada cambio."""

    def __init__(self, repositorio):
        self.repositorio = repositorio
        self.estadisticas = self.repositorio.cargar()

    def obtener(self):
        return self.estadisticas

    def registrar_resultado(self, acierto, numero_preguntas):
        self.estadisticas.registrar_partida(acierto, numero_preguntas)
        self.repositorio.guardar(self.estadisticas)
        return self.estadisticas
