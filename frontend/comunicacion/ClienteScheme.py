import shutil
import subprocess
import json
from pathlib import Path


class ClienteScheme:
    """Lanza backend/servidor.rkt como subproceso y habla el protocolo
    JSON linea-por-linea descrito en servidor.rkt / README.md.
    """

    def __init__(self, comando_racket="racket"):
        ruta_proyecto = Path(__file__).resolve().parents[2]
        ruta_servidor = ruta_proyecto / "backend" / "servidor.rkt"

        if not ruta_servidor.exists():
            raise FileNotFoundError(
                f"No se encontró el backend en: {ruta_servidor}"
            )

        if shutil.which(comando_racket) is None:
            raise RuntimeError(
                f"No se encontró el ejecutable '{comando_racket}' en el PATH. "
                "Instala Racket (https://racket-lang.org/) o ajusta el "
                "comando en ClienteScheme(comando_racket=...)."
            )

        self.proceso = subprocess.Popen(
            [comando_racket, str(ruta_servidor)],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            bufsize=1,
        )

    def enviar(self, mensaje):
        if self.proceso.poll() is not None:
            error = self.proceso.stderr.read()
            raise RuntimeError(f"El servidor Scheme ya no está activo: {error}")

        self.proceso.stdin.write(json.dumps(mensaje) + "\n")
        self.proceso.stdin.flush()

        respuesta = self.proceso.stdout.readline()

        if not respuesta:
            error = self.proceso.stderr.read()
            raise RuntimeError(f"El servidor Scheme terminó la ejecución: {error}")

        return json.loads(respuesta)

    def cerrar(self):
        if self.proceso.poll() is None:
            try:
                self.proceso.stdin.close()
                self.proceso.terminate()
                self.proceso.wait(timeout=5)
            except Exception:
                self.proceso.kill()
