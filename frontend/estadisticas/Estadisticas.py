class Estadisticas:
    """Estadísticas acumuladas de todas las partidas jugadas en esta
    máquina: cuántas, cuántos aciertos/fallos y el promedio de preguntas
    necesarias para llegar a una predicción."""

    def __init__(self, partidas=0, aciertos=0, fallos=0, total_preguntas=0):
        self.partidas = partidas
        self.aciertos = aciertos
        self.fallos = fallos
        self.total_preguntas = total_preguntas

    @property
    def promedio_preguntas(self):
        if self.partidas == 0:
            return 0.0
        return round(self.total_preguntas / self.partidas, 1)

    def registrar_partida(self, acierto, numero_preguntas):
        self.partidas += 1
        self.total_preguntas += numero_preguntas
        if acierto:
            self.aciertos += 1
        else:
            self.fallos += 1

    def a_diccionario(self):
        return {
            "partidas": self.partidas,
            "aciertos": self.aciertos,
            "fallos": self.fallos,
            "total_preguntas": self.total_preguntas,
        }

    @staticmethod
    def desde_diccionario(datos):
        return Estadisticas(
            partidas=datos.get("partidas", 0),
            aciertos=datos.get("aciertos", 0),
            fallos=datos.get("fallos", 0),
            total_preguntas=datos.get("total_preguntas", 0),
        )
