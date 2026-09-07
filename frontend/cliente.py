"""Smoke test del protocolo Python-Scheme, sin la interfaz Streamlit.

Reutiliza el mismo ClienteScheme que usa la app real (comunicacion/) para
levantar backend/servidor.rkt como subproceso y jugar una partida de
demostracion (pensando en "tigre"), imprimiendo cada pregunta y la
prediccion final. Util para verificar que el backend responde bien al
protocolo sin depender de Streamlit ni del navegador.

Ejecutar con:
    cd frontend
    uv run cliente.py
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "comunicacion"))

from ClienteScheme import ClienteScheme

RESPUESTAS_TIGRE = {
    "mamifero": "si", "domestico": "no", "salvaje": "si", "carnivoro": "si",
    "grande": "si", "vive-en-sabana": "no", "vive-en-selva": "si",
    "nocturno": "si", "rapido": "si",
}


def main():
    cliente = ClienteScheme()
    try:
        mensaje = cliente.enviar({"cmd": "iniciar"})
        while mensaje["tipo"] == "pregunta":
            caracteristica = mensaje["caracteristica"]
            respuesta = RESPUESTAS_TIGRE.get(caracteristica, "no-se")
            print(f"Pregunta {mensaje['numero_pregunta']}: es-{caracteristica}? -> {respuesta}")
            mensaje = cliente.enviar({
                "cmd": "responder", "caracteristica": caracteristica, "respuesta": respuesta,
            })

        if mensaje["tipo"] == "prediccion":
            print(f"\n=> PREDICCION: {mensaje['entidad']} ({mensaje['porcentaje']} de certeza)")
            print(f"=> EXPLICACION: {mensaje['explicacion']}")
        else:
            print(f"\n=> {mensaje}")
    finally:
        cliente.cerrar()


if __name__ == "__main__":
    main()
