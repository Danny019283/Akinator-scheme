"""Punto de entrada de la aplicación Akinator (Streamlit).

Ejecutar con:
    cd frontend
    streamlit run app.py
"""
import sys
import os

_PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_PROJECT_ROOT, "comunicacion"))
sys.path.insert(0, os.path.join(_PROJECT_ROOT, "servicios"))
sys.path.insert(0, os.path.join(_PROJECT_ROOT, "vista"))

import streamlit as st

from ClienteScheme import ClienteScheme
from AkinatorServicio import AkinatorServicio
from EstadisticasServicio import EstadisticasServicio
from AkinatorVista import AkinatorVista


def _inicializar_sistema():
    """Crea el cliente Racket y los servicios una sola vez por sesión de
    navegador. El motor Scheme calcula y persiste las estadísticas; si
    falla al iniciar, la app queda sin poder consultarlas ni jugar."""
    if "inicializado" in st.session_state:
        return

    try:
        cliente = ClienteScheme()
    except (FileNotFoundError, RuntimeError) as error:
        st.session_state.error_inicio = str(error)
        st.session_state.inicializado = True
        return

    st.session_state.servicio = AkinatorServicio(cliente)
    st.session_state.estadisticas_servicio = EstadisticasServicio(cliente)
    st.session_state.error_inicio = None
    st.session_state.inicializado = True


def main():
    st.set_page_config(
        page_title="Akinator",
        page_icon="🧞",
        layout="centered",
    )

    _inicializar_sistema()

    if st.session_state.get("error_inicio"):
        st.error(
            "No se pudo iniciar el motor del juego:\n\n"
            f"{st.session_state.error_inicio}"
        )
        st.info(
            "Verifica que Racket esté instalado y disponible en el PATH "
            "(`racket --version` debe funcionar en una terminal)."
        )
        return

    vista = AkinatorVista(st.session_state.servicio, st.session_state.estadisticas_servicio)
    vista.mostrar()


if __name__ == "__main__":
    main()
