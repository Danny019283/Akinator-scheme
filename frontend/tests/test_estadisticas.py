from Estadisticas import Estadisticas


def test_estadisticas_arrancan_en_cero():
    estadisticas = Estadisticas()
    assert estadisticas.partidas == 0
    assert estadisticas.aciertos == 0
    assert estadisticas.fallos == 0
    assert estadisticas.total_preguntas == 0
    assert estadisticas.promedio_preguntas == 0.0


def test_registrar_partida_con_acierto_suma_partidas_aciertos_y_preguntas():
    estadisticas = Estadisticas(partidas=2, aciertos=1, fallos=1, total_preguntas=20)

    estadisticas.registrar_partida(acierto=True, numero_preguntas=8)

    assert estadisticas.partidas == 3
    assert estadisticas.aciertos == 2
    assert estadisticas.fallos == 1
    assert estadisticas.total_preguntas == 28


def test_registrar_partida_sin_acierto_suma_fallos_no_aciertos():
    estadisticas = Estadisticas()

    estadisticas.registrar_partida(acierto=False, numero_preguntas=5)

    assert estadisticas.aciertos == 0
    assert estadisticas.fallos == 1


def test_promedio_preguntas_redondea_a_un_decimal():
    estadisticas = Estadisticas(partidas=3, aciertos=2, fallos=1, total_preguntas=20)

    assert estadisticas.promedio_preguntas == 6.7


def test_a_diccionario_y_desde_diccionario_hacen_roundtrip():
    original = Estadisticas(partidas=5, aciertos=3, fallos=2, total_preguntas=40)

    restaurada = Estadisticas.desde_diccionario(original.a_diccionario())

    assert restaurada.partidas == 5
    assert restaurada.aciertos == 3
    assert restaurada.fallos == 2
    assert restaurada.total_preguntas == 40


def test_desde_diccionario_con_campos_faltantes_usa_cero():
    restaurada = Estadisticas.desde_diccionario({})

    assert restaurada.partidas == 0
    assert restaurada.total_preguntas == 0
