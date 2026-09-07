import json
from pathlib import Path

from Estadisticas import Estadisticas

_RUTA_ARCHIVO = Path(__file__).resolve().parent / "estadisticas.json"


class EstadisticasRepositorio:
    """Lee y escribe datos/estadisticas.json. Es la única parte del
    proyecto que toca ese archivo, para mantener la persistencia
    encapsulada."""

    def __init__(self, ruta_archivo=_RUTA_ARCHIVO):
        self.ruta_archivo = Path(ruta_archivo)

    def cargar(self):
        if not self.ruta_archivo.exists():
            return Estadisticas()
        try:
            with open(self.ruta_archivo, "r", encoding="utf-8") as archivo:
                return Estadisticas.desde_diccionario(json.load(archivo))
        except (json.JSONDecodeError, OSError):
            return Estadisticas()

    def guardar(self, estadisticas):
        with open(self.ruta_archivo, "w", encoding="utf-8") as archivo:
            json.dump(estadisticas.a_diccionario(), archivo, indent=4, ensure_ascii=False)
