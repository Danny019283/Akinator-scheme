# Akinator-scheme

Un "Akinator" de animales implementado como sistema experto en **Racket**,
con un motor de inferencia basado en **Factores de Certeza** (estilo
MYCIN) en vez de un puntaje simple. Incluye encadenamiento hacia adelante
de reglas, selección dinámica de preguntas por balance de partición, y un
protocolo de comunicación con Python para un futuro frontend.

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
  servicios/             AkinatorServicio.py: traduce iniciar/responder/reiniciar al protocolo
  controlador/           AkinatorController.py: capa fina entre la vista y el servicio
  vista/                 AkinatorVista.py + preguntas.py: interfaz Streamlit con estilo tipo akinator.com
  assets/                Coloca aquí tu propio genio.png (opcional, ver LEEME_IMAGEN.txt)
  pyproject.toml         Manifiesto del proyecto (gestionado con uv)
```

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

## Requisitos

- **Racket** (probado con 9.3). Si no está en el `PATH`, cualquier
  invocación de `racket`/`raco` en los comandos de abajo puede
  reemplazarse por como esté instalado en tu sistema (por ejemplo, vía
  flatpak: `flatpak run --command=racket org.racket_lang.Racket`).
- **Python 3.11+** con [`uv`](https://docs.astral.sh/uv/) para manejar el
  entorno y las dependencias del frontend.

## Cómo correr las pruebas del motor

```bash
cd backend
raco test tests/pruebas.rkt
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
  (`0.6`) con un margen mínimo (`0.15`) sobre el segundo.

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

Con esto, la demo de "tigre" converge en 17 preguntas con ~100% de
certeza, y sobre las 30 entidades del dominio (respondiendo según sus
propios hechos) 29/30 convergen a la entidad correcta — la única
excepción (*lobo*) no tiene, en los datos actuales, ningún rasgo que lo
distinga de *tigre*. El motor nunca predice una entidad incorrecta
(verificado en `tests/pruebas.rkt`).
