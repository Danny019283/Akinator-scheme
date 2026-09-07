from Estadisticas import Estadisticas
from EstadisticasRepositorio import EstadisticasRepositorio


def test_cargar_sobre_archivo_inexistente_devuelve_estadisticas_en_cero(tmp_path):
    repositorio = EstadisticasRepositorio(ruta_archivo=tmp_path / "no-existe.json")

    estadisticas = repositorio.cargar()

    assert estadisticas.partidas == 0
    assert estadisticas.total_preguntas == 0


def test_guardar_y_cargar_hacen_roundtrip_completo(tmp_path):
    ruta = tmp_path / "estadisticas.json"
    repositorio = EstadisticasRepositorio(ruta_archivo=ruta)
    original = Estadisticas(partidas=5, aciertos=3, fallos=2, total_preguntas=40)

    repositorio.guardar(original)
    leida = repositorio.cargar()

    assert leida.partidas == 5
    assert leida.aciertos == 3
    assert leida.fallos == 2
    assert leida.total_preguntas == 40


def test_cargar_sobre_archivo_corrupto_devuelve_estadisticas_en_cero(tmp_path):
    ruta = tmp_path / "corrupto.json"
    ruta.write_text("esto no es json valido", encoding="utf-8")
    repositorio = EstadisticasRepositorio(ruta_archivo=ruta)

    estadisticas = repositorio.cargar()

    assert estadisticas.partidas == 0
