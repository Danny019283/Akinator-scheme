from Estadisticas import Estadisticas
from EstadisticasServicio import EstadisticasServicio


class RepositorioFalso:
    def __init__(self, estadisticas=None):
        self.estadisticas = estadisticas or Estadisticas()
        self.guardados = []

    def cargar(self):
        return self.estadisticas

    def guardar(self, estadisticas):
        self.guardados.append(estadisticas.a_diccionario())


def test_obtener_devuelve_lo_que_carga_el_repositorio():
    repositorio = RepositorioFalso(Estadisticas(partidas=5, aciertos=3, fallos=2, total_preguntas=40))
    servicio = EstadisticasServicio(repositorio)

    estadisticas = servicio.obtener()

    assert estadisticas.partidas == 5
    assert estadisticas.promedio_preguntas == 8.0


def test_registrar_resultado_actualiza_y_persiste():
    repositorio = RepositorioFalso(Estadisticas())
    servicio = EstadisticasServicio(repositorio)

    resultado = servicio.registrar_resultado(True, 8)

    assert resultado.partidas == 1
    assert resultado.aciertos == 1
    assert repositorio.guardados == [{"partidas": 1, "aciertos": 1, "fallos": 0, "total_preguntas": 8}]


def test_registrar_resultado_con_fallo_no_suma_aciertos():
    repositorio = RepositorioFalso(Estadisticas())
    servicio = EstadisticasServicio(repositorio)

    resultado = servicio.registrar_resultado(False, 5)

    assert resultado.aciertos == 0
    assert resultado.fallos == 1
