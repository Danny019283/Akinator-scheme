# Akinator-scheme

Un "Akinator" de animales implementado como sistema experto en **Racket**,
con un motor de inferencia basado en **Factores de Certeza** (estilo
MYCIN) en vez de un puntaje simple. Incluye encadenamiento hacia adelante
de reglas, selección dinámica de preguntas por balance de partición, y un
protocolo de comunicación con Python para un futuro frontend.

Documento técnico completo (arquitectura, conocimiento, inferencia,
heurística, comunicación, pruebas y conclusiones, con diagramas):
[`docs/documento_tecnico.docx`](docs/documento_tecnico.docx).

## Estructura del proyecto

```
backend/            Motor de inferencia en Racket
  dominio.rkt          Base de conocimiento: 30 animales, representación dispersa de rasgos
  reglas.rkt            Motor de reglas (forward chaining con punto fijo)
  respuestas.rkt        Tabla de Factores de Certeza por tipo de respuesta del usuario
  motor.rkt              Motor CF: combinación de MYCIN, selección de preguntas, simulación de partidas
  servidor.rkt           Servidor JSON linea-por-linea para hablar con el cliente Python
  tests/pruebas.rkt   Suite de pruebas (rackunit)

frontend/            Frontend web en Streamlit (proyecto uv)
  app.py                 Punto de entrada: `streamlit run app.py`
  comunicacion/          ClienteScheme.py: lanza servidor.rkt como subproceso y habla el protocolo JSON
  servicios/             AkinatorServicio.py: traduce iniciar/responder/reiniciar al protocolo del juego
  estadisticas/           Estadisticas.py (modelo), EstadisticasRepositorio.py (persistencia en
                          estadisticas.json, no versionado) y EstadisticasServicio.py — partidas,
                          aciertos, fallos y promedio de preguntas, 100% en Python
  vista/                 AkinatorVista.py + preguntas.py: interfaz Streamlit con estilo tipo akinator.com
  assets/                Coloca aquí tu propio genio.png (opcional, ver LEEME_IMAGEN.txt)
  tests/                 Suite de pruebas (pytest) de servicios y estadísticas, con dobles de prueba
  pyproject.toml         Manifiesto del proyecto (gestionado con uv)
```

El razonamiento (conocimiento, reglas, inferencia, selección de preguntas,
confianza, explicación) vive enteramente en Racket. Las estadísticas de
uso de la app (partidas, aciertos, fallos, promedio de preguntas) viven
en Python, en `frontend/estadisticas/` — es interacción/telemetría de la
capa de presentación, no razonamiento simbólico, así que no necesita
pasar por el motor. Ver el documento técnico para la justificación
completa de este reparto.

## Cómo correr el frontend web

```bash
cd frontend
uv sync
uv run streamlit run app.py
```

(o, sin `uv`: `pip install streamlit` y luego `streamlit run app.py`)

Esto abre el navegador en `http://localhost:8501`. La app lanza
`backend/servidor.rkt` como subproceso la primera vez que cargas la
página (una sola vez por sesión de navegador) y a partir de ahí solo
intercambia mensajes JSON con él en cada clic.

## Requisitos y dependencias

- **Racket 8.x/9.x** (probado con 9.2 y 9.3), con el paquete **`rackunit-lib`**
  para correr `tests/pruebas.rkt` (`raco pkg install rackunit-lib` si no
  viene incluido en tu instalación). No se necesita ningún otro paquete
  de Racket: `json` y `racket/runtime-path` son parte de la distribución
  base.
- **Python 3.11+** con [`uv`](https://docs.astral.sh/uv/) para manejar el
  entorno y las dependencias del frontend. Las dependencias de Python
  están fijadas en `frontend/pyproject.toml`/`uv.lock` (`streamlit>=1.35`
  como dependencia de la app, `pytest` como dependencia de desarrollo) y
  `uv sync` las instala automáticamente — no hace falta `pip install`
  manual salvo que no uses `uv` (ver más abajo).

### Instalación

**Linux / macOS:**

```bash
# Racket (Fedora/Nobara: sudo dnf install racket · Debian/Ubuntu: sudo apt install racket · macOS: brew install racket)
raco pkg install rackunit-lib

# uv (gestor de Python)
curl -LsSf https://astral.sh/uv/install.sh | sh

cd frontend
uv sync
```

**Windows (PowerShell):**

```powershell
# Racket: instalar desde https://racket-lang.org/download/ (incluye raco)
raco pkg install rackunit-lib

# uv (gestor de Python)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

cd frontend
uv sync
```

Si `racket`/`raco` no quedan en el `PATH` tras instalar, cualquier
invocación de esos comandos en este README puede reemplazarse por como
esté instalado en tu sistema (por ejemplo, vía flatpak en Linux:
`flatpak run --command=racket org.racket_lang.Racket`).

Sin `uv`, el frontend también puede correrse con `pip`:
`pip install streamlit pytest && streamlit run app.py` desde `frontend/`.

## Cómo correr las pruebas del motor

```bash
cd backend
raco test tests/pruebas.rkt
```

## Cómo correr las pruebas del frontend

```bash
cd frontend
uv run pytest
```

## Cómo correr la demo standalone (sin Python)

```bash
cd backend
racket motor.rkt
```

Corre una partida simulada donde el usuario está pensando en "tigre" y
muestra la predicción final con su explicación.

## Cómo correr el cliente Python

```bash
cd frontend
uv run cliente.py
```

Levanta `../backend/servidor.rkt` como subproceso, juega la misma partida
de demo a través del protocolo JSON, y termina el proceso al finalizar.

## Protocolo de comunicación (Racket ↔ Python)

Subproceso persistente + un objeto JSON por línea sobre stdin/stdout.
Racket hace `flush-output` después de cada respuesta para que el
`readline()` bloqueante del lado Python nunca se quede esperando.

**Comandos (Python → Racket):**

```json
{"cmd": "iniciar"}
{"cmd": "responder", "caracteristica": "mamifero", "respuesta": "si"}
{"cmd": "reiniciar"}
```

`respuesta` acepta `"si"`, `"probablemente"`, `"no-se"`,
`"probablemente-no"` o `"no"`.

**Respuestas (Racket → Python):**

```json
{"tipo": "pregunta", "caracteristica": "mamifero", "numero_pregunta": 1}
{"tipo": "prediccion", "entidad": "tigre", "certeza": 0.999, "porcentaje": "100%", "explicacion": ["nocturno", "salvaje", "..."]}
{"tipo": "sin_preguntas", "mejor_candidato": "tigre", "certeza": 0.4}
{"tipo": "error", "mensaje": "..."}
```

Las estadísticas (partidas, aciertos, fallos, promedio de preguntas) no
pasan por este protocolo: Python las calcula y persiste directamente en
`frontend/estadisticas/estadisticas.json` a partir del número de preguntas
que ya contó al mostrar la partida y del botón Correcto/Incorrecto que
pulsa el usuario.

## Diseño del motor de Factores de Certeza

Cada candidato tiene un CF en `[-1, 1]` que se combina con la fórmula
incremental de MYCIN a medida que llegan respuestas:

- **`cf-regla`** consulta el hecho propio del candidato para el rasgo
  preguntado y devuelve `+1`, `-1`, o `'sin-evidencia` (nunca `0`, para
  distinguir "no aporta" de "aporta evidencia neutra").
- **`cf-evidencia`** multiplica el CF de la respuesta del usuario por
  `cf-regla`, y solo se usa cuando ambos lados tienen evidencia real.
- **`combinar-cf`** implementa las tres ramas de MYCIN (misma polaridad,
  polaridad opuesta, y una guarda explícita de división por cero cuando
  dos evidencias de certeza total y signo contrario se combinan).
- El motor predice cuando el candidato líder supera un umbral de CF
  (`0.6`) con un margen mínimo (`0.3`) sobre el segundo, o —cuando el CF
  está prácticamente empatado por saturación— con estrictamente más
  coincidencias reales con el historial que el segundo lugar.

Dos ajustes respecto a una implementación literal de MYCIN, necesarios
para que el motor converja con este dominio de datos:

1. **Las respuestas `si`/`no` no valen `±1.0` sino `±0.9`.** La
   combinación de MYCIN es absorbente en `±1.0`: una sola respuesta
   coincidente satura instantáneamente a `CF=1.0` a *todos* los
   candidatos que comparten ese rasgo (por ejemplo, todos los mamíferos
   grandes y salvajes), y ya no se pueden volver a separar. Bajar la
   magnitud evita la saturación de un solo golpe.
2. **Desempate por coincidencias reales.** Aun con `±0.9`, varios
   candidatos muy similares pueden converger al mismo CF (con más
   decimales de 9 en cada confirmación compartida). Cuando el CF queda
   prácticamente empatado, el motor desempata a favor del candidato con
   más respuestas del historial consistentes con sus propios hechos.

Con esto, la demo de "tigre" converge en 15 preguntas con ~100% de
certeza, y sobre las 30 entidades del dominio (respondiendo según sus
propios hechos) las 30 convergen a la entidad correcta — incluyendo el
par más parecido del dominio, *lobo* y *tigre*, que solo se distinguen
por `nocturno` y `vive-en-manada`. El motor nunca predice una entidad
incorrecta y siempre converge a la propia cuando hay evidencia completa
(verificado en `tests/pruebas.rkt`, caso obligatorio 2 del enunciado).
