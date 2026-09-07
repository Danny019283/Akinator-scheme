import base64
from pathlib import Path

import streamlit as st

from preguntas import texto_pregunta

# Etiqueta que ve el usuario en el botón.
RESPUESTAS = [
    ("si", "Sí"),
    ("no", "No"),
    ("no-se", "No lo sé"),
    ("probablemente", "Probablemente"),
    ("probablemente-no", "Probablemente no"),
]

# Mismo contenido que RESPUESTAS pero en el orden de la cuadrícula:
RESPUESTAS_GRID = [
    ("probablemente", "Probablemente"),
    ("probablemente-no", "Probablemente no"),
    ("si", "Sí"),
    ("no-se", "No lo sé"),
    ("no", "No"),
]

RUTA_GENIO = Path(__file__).resolve().parents[1] / "assets" / "genio.png"
RUTA_FUENTE_TITULO = Path(__file__).resolve().parents[1] / "assets" / "fonts" / "ChowFun.ttf"
RUTA_FUENTE_TEXTO = Path(__file__).resolve().parents[1] / "assets" / "fonts" / "Cheboygan.ttf"


def _fuente_base64(ruta):
    """Lee un .ttf del disco y lo devuelve codificado en base64, listo
    para incrustarlo directamente en el CSS."""
    if not ruta.exists():
        return None
    return base64.b64encode(ruta.read_bytes()).decode("utf-8")


class AkinatorVista:
    """Dibuja el estado actual del juego. La partida en curso vive en st.session_state. Las
    estadísticas acumuladas viven en el controlador/servicio, que a su
    vez las persiste en datos/estadisticas.json.
    """

    def __init__(self, controlador):
        self.controlador = controlador

    # ------------------------------------------------------------------ 
    # Entrada principal
    # ------------------------------------------------------------------ 
    def mostrar(self):
        self._inyectar_estilos()
        self._inicializar_estado_partida()

        self._barra_lateral()
        self._encabezado()
        self._render_tarjeta(st.session_state.resultado_actual)

    def _inicializar_estado_partida(self):
        if "resultado_actual" not in st.session_state:
            st.session_state.resultado_actual = self.controlador.iniciar_partida()
        if "historial" not in st.session_state:
            st.session_state.historial = []

    # ------------------------------------------------------------------ 
    # Barra lateral: estadísticas acumuladas e historial de esta partida
    # ------------------------------------------------------------------ 
    def _barra_lateral(self):
        with st.sidebar:
            st.markdown("### Estadísticas")
            stats = self.controlador.obtener_estadisticas()
            col1, col2 = st.columns(2)
            col1.metric("Partidas", stats.partidas)
            col2.metric("Prom. preguntas", stats.promedio_preguntas)
            col1.metric("Aciertos", stats.aciertos)
            col2.metric("Fallos", stats.fallos)

            st.markdown("---")
            st.markdown("### Historial de esta partida")
            if not st.session_state.historial:
                st.caption("Todavía no has respondido ninguna pregunta.")
            else:
                for i, item in enumerate(st.session_state.historial, start=1):
                    st.write(f"**{i}.** {item['pregunta']} → *{item['respuesta']}*")

    # ------------------------------------------------------------------ 
    # Encabezado
    # ------------------------------------------------------------------ 
    def _encabezado(self):
        st.markdown(
            '<div class="akinator-titulo">AKINATOR</div>',
            unsafe_allow_html=True,
        )

    # ------------------------------------------------------------------ 
    # Router según el tipo de mensaje que mandó el backend
    # ------------------------------------------------------------------ 
    def _render_tarjeta(self, resultado):
        tipo = resultado.get("tipo")

        if tipo == "pregunta":
            self._vista_pregunta(resultado)
        elif tipo == "prediccion":
            self._vista_prediccion(resultado)
        elif tipo == "sin_preguntas":
            self._vista_sin_preguntas(resultado)
        elif tipo == "error":
            self._vista_error(resultado)
        else:
            st.warning(f"Respuesta inesperada del backend: {resultado}")

    # ------------------------------------------------------------------ 
    # Pregunta en curso
    # ------------------------------------------------------------------ 
    def _vista_pregunta(self, resultado):
        numero = resultado.get("numero_pregunta", "?")
        texto = texto_pregunta(resultado.get("caracteristica", ""))
        candidatos_restantes = resultado.get("candidatos_restantes")
        total_candidatos = resultado.get("total_candidatos")

        col_genio, col_globo = st.columns([1, 2])
        with col_genio:
            self._genio()
        with col_globo:
            st.markdown(
                f"""
                <div class="globo-pregunta">
                    <div class="globo-numero">{numero}</div>
                    <div class="globo-texto">{texto}</div>
                </div>
                """,
                unsafe_allow_html=True,
            )
            if candidatos_restantes is not None and total_candidatos:
                st.caption(f"Candidatos posibles: {candidatos_restantes} de {total_candidatos}")
                st.progress(candidatos_restantes / total_candidatos)

        st.markdown('<div class="caja-respuestas">', unsafe_allow_html=True)

        fila_arriba = st.columns(2)
        fila_abajo = st.columns(3)
        columnas = [fila_arriba[0], fila_arriba[1], fila_abajo[0], fila_abajo[1], fila_abajo[2]]

        for columna, (simbolo, etiqueta) in zip(columnas, RESPUESTAS_GRID):
            with columna:
                if st.button(etiqueta, key=f"resp_{simbolo}_{numero}", use_container_width=True):
                    st.session_state.historial.append({"pregunta": texto, "respuesta": etiqueta})
                    st.session_state.resultado_actual = self.controlador.responder(simbolo)
                    st.rerun()

        st.markdown("</div>", unsafe_allow_html=True)

    # ------------------------------------------------------------------ 
    # Predicción con alta certeza
    # ------------------------------------------------------------------ 
    def _vista_prediccion(self, resultado):
        entidad = resultado.get("entidad", "?").capitalize()
        porcentaje = resultado.get("porcentaje", "")
        explicacion = resultado.get("explicacion", [])

        col_genio, col_globo = st.columns([1, 2])
        with col_genio:
            self._genio()
        with col_globo:
            st.markdown(
                f"""
                <div class="globo-pregunta globo-final">
                    <div class="globo-texto">
                        ¡Creo que estás pensando en...<br>
                        <span class="resultado-nombre">{entidad}</span>!<br>
                        <span class="resultado-certeza">Certeza: {porcentaje}</span>
                    </div>
                </div>
                """,
                unsafe_allow_html=True,
            )
            if explicacion:
                rasgos = ", ".join(explicacion)
                st.caption(f"Me basé en: {rasgos}")

        self._botones_confirmacion()

    # ------------------------------------------------------------------ 
    # Se acabaron las preguntas útiles, pero sin certeza suficiente
    # ------------------------------------------------------------------ 
    def _vista_sin_preguntas(self, resultado):
        candidato = resultado.get("mejor_candidato", "?").capitalize()

        col_genio, col_globo = st.columns([1, 2])
        with col_genio:
            self._genio()
        with col_globo:
            st.markdown(
                f"""
                <div class="globo-pregunta globo-final">
                    <div class="globo-texto">
                        No estoy del todo seguro, pero mi mejor opción es...<br>
                        <span class="resultado-nombre">{candidato}</span>
                    </div>
                </div>
                """,
                unsafe_allow_html=True,
            )

        self._botones_confirmacion()

    # ------------------------------------------------------------------ 
    # Error de comunicación con el backend
    # ------------------------------------------------------------------ 
    def _vista_error(self, resultado):
        st.error(resultado.get("mensaje", "Ocurrió un error inesperado."))
        st.markdown('<div class="caja-respuestas">', unsafe_allow_html=True)
        if st.button("Nueva partida", key="reiniciar_error", use_container_width=True):
            self._reiniciar_partida()
        st.markdown("</div>", unsafe_allow_html=True)

    # ------------------------------------------------------------------ 
    # Botones de cierre de partida: Correcto / Incorrecto / Nueva partida
    # ------------------------------------------------------------------ 
    def _botones_confirmacion(self):
        numero_preguntas = len(st.session_state.historial)

        st.markdown('<div class="caja-respuestas">', unsafe_allow_html=True)
        col1, col2, col3 = st.columns(3)

        with col1:
            if st.button("Correcto", key="correcto", use_container_width=True):
                self.controlador.registrar_acierto(numero_preguntas)
                st.session_state.mensaje_cierre = "¡Genial! Se registró como acierto."
                self._reiniciar_partida()

        with col2:
            if st.button("Incorrecto", key="incorrecto", use_container_width=True):
                self.controlador.registrar_fallo(numero_preguntas)
                st.session_state.mensaje_cierre = "Vaya, fallé esta vez. Se registró el resultado."
                self._reiniciar_partida()

        with col3:
            if st.button("Nueva partida", key="nueva_partida", use_container_width=True):
                st.session_state.mensaje_cierre = None
                self._reiniciar_partida()

        st.markdown("</div>", unsafe_allow_html=True)

        if st.session_state.get("mensaje_cierre"):
            st.success(st.session_state.mensaje_cierre)

    def _reiniciar_partida(self):
        st.session_state.resultado_actual = self.controlador.reiniciar_partida()
        st.session_state.historial = []
        st.rerun()

    # ------------------------------------------------------------------ 
    # Genio: usa assets/genio.png si existe, si no cae a un emoji grande
    # ------------------------------------------------------------------ 
    def _genio(self):
        if RUTA_GENIO.exists():
            st.image(str(RUTA_GENIO), use_container_width=True)
        else:
            st.markdown(
                '<div class="genio-emoji">🧞‍♂️</div>',
                unsafe_allow_html=True,
            )

    # ------------------------------------------------------------------ 
    # CSS para que la app se parezca a akinator.com
    # ------------------------------------------------------------------ 
    def _inyectar_estilos(self):
        fuente_titulo_b64 = _fuente_base64(RUTA_FUENTE_TITULO)
        fuente_texto_b64 = _fuente_base64(RUTA_FUENTE_TEXTO)

        font_faces = ""
        if fuente_titulo_b64:
            font_faces += f"""
            @font-face {{
                font-family: 'Chow Fun';
                src: url(data:font/ttf;base64,{fuente_titulo_b64}) format('truetype');
            }}
            """
        if fuente_texto_b64:
            font_faces += f"""
            @font-face {{
                font-family: 'Cheboygan';
                src: url(data:font/ttf;base64,{fuente_texto_b64}) format('truetype');
            }}
            """

        st.markdown(
            f"""
            <style>
            {font_faces}
            .stApp {{
                background: radial-gradient(circle at top, #4a6fb5 0%, #1c2f52 100%);
                font-family: 'Cheboygan', serif;
            }}
            .akinator-titulo {{
                text-align: center;
                color: white;
                font-family: 'Chow Fun', cursive;
                font-size: 2.6rem;
                font-weight: 800;
                letter-spacing: 0.15rem;
                margin-bottom: 1.5rem;
                text-shadow: 0 2px 6px rgba(0,0,0,0.4);
            }}
            .genio-emoji {{
                font-size: 9rem;
                text-align: center;
                line-height: 1;
                filter: drop-shadow(0 6px 10px rgba(0,0,0,0.35));
            }}
            .globo-pregunta {{
                position: relative;
                background: linear-gradient(180deg, #f4f6fa 0%, #d9dee8 100%);
                border-radius: 14px;
                padding: 1.4rem 1.8rem;
                margin-top: 2.2rem;
                box-shadow: 0 6px 14px rgba(0,0,0,0.35);
                display: flex;
                align-items: center;
                gap: 1rem;
                min-height: 70px;
            }}
            .globo-pregunta::before {{
                content: "";
                position: absolute;
                left: -18px;
                top: 50%;
                transform: translateY(-50%);
                border-width: 12px 18px 12px 0;
                border-style: solid;
                border-color: transparent #1c2f52 transparent transparent;
            }}
            .globo-numero {{
                background: #1c2f52;
                color: white;
                font-weight: 700;
                border-radius: 8px;
                padding: 0.4rem 0.8rem;
                flex-shrink: 0;
            }}
            .globo-texto {{
                color: #1c2f52;
                font-size: 1.15rem;
                font-weight: 600;
            }}
            .globo-final {{ justify-content: center; text-align: center; }}
            .resultado-nombre {{
                font-size: 1.6rem;
                color: #b8471f;
            }}
            .resultado-certeza {{
                font-size: 0.95rem;
                color: #445;
                font-weight: 400;
            }}
            .caja-respuestas {{
                background: #e3e7ee;
                border-radius: 4px;
                padding: 0.6rem 0.6rem 0.2rem 0.6rem;
                margin-top: 1.4rem;
                box-shadow: 0 4px 10px rgba(0,0,0,0.25);
            }}
            .stButton > button {{
                width: 100%;
                background: linear-gradient(180deg, #fff4b0 0%, #f0c419 55%, #dda600 100%);
                border: 2px solid #6b4e00;
                border-radius: 10px;
                color: black !important;
                font-family: 'Cheboygan', serif;
                font-weight: 700;
                padding: 0.6rem 0.4rem;
                font-size: 0.95rem;
                box-shadow: 0 2px 4px rgba(0,0,0,0.35);
                margin-bottom: 0.6rem;
            }}
            .stButton > button p {{
                color: black !important;
                font-family: 'Cheboygan', serif;
            }}
            .stButton > button:hover {{
                background: linear-gradient(180deg, #ffe97a 0%, #e0a800 55%, #b98900 100%);
                border-color: #4a3600;
            }}
            .stButton > button:hover p {{
                color: black !important;
            }}
            [data-testid="stSidebar"] .stButton > button {{
                border-bottom: none;
            }}
            </style>
            """,
            unsafe_allow_html=True,
        )