"""Cliente Python para el motor Akinator en Racket.

Protocolo: subproceso persistente ("racket servidor.rkt"), un objeto JSON por
linea en stdin/stdout. Cada comando enviado produce exactamente una linea de
respuesta, que se lee con readline() (bloqueante) porque Racket hace
flush-output despues de cada mensaje.

No implementa el frontend (sera Tkinter, en un modulo aparte); esto es solo
el canal de comunicacion, mas un smoke test cuando se ejecuta directamente.
"""

import json
import subprocess


class MotorAkinator:
    def __init__(self, racket_cmd, servidor_path):
        """racket_cmd: lista con el comando para invocar racket, ej.
        ["flatpak", "run", "--command=racket", "org.racket_lang.Racket"]
        o simplemente ["racket"] si esta en el PATH.
        servidor_path: ruta a servidor.rkt.
        """
        self._proceso = subprocess.Popen(
            racket_cmd + [servidor_path],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
        )

    def _enviar(self, comando):
        self._proceso.stdin.write(json.dumps(comando) + "\n")
        self._proceso.stdin.flush()
        linea = self._proceso.stdout.readline()
        if linea == "":
            error = self._proceso.stderr.read()
            raise RuntimeError(f"el proceso Racket termino inesperadamente: {error}")
        return json.loads(linea)

    def iniciar(self):
        return self._enviar({"cmd": "iniciar"})

    def responder(self, caracteristica, respuesta):
        return self._enviar({"cmd": "responder", "caracteristica": caracteristica, "respuesta": respuesta})

    def reiniciar(self):
        return self._enviar({"cmd": "reiniciar"})

    def cerrar(self):
        self._proceso.stdin.close()
        self._proceso.terminate()
        self._proceso.wait(timeout=5)


if __name__ == "__main__":
    import os

    racket_cmd = ["flatpak", "run", "--command=racket", "org.racket_lang.Racket"]
    servidor_path = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "backend", "servidor.rkt"
    )

    motor = MotorAkinator(racket_cmd, servidor_path)
    try:
        respuestas_tigre = {
            "mamifero": "si", "domestico": "no", "salvaje": "si", "carnivoro": "si",
            "grande": "si", "vive-en-sabana": "no", "vive-en-selva": "si",
            "nocturno": "si", "rapido": "si",
        }
        mensaje = motor.iniciar()
        while mensaje["tipo"] == "pregunta":
            caracteristica = mensaje["caracteristica"]
            respuesta = respuestas_tigre.get(caracteristica, "no-se")
            print(f"Pregunta {mensaje['numero_pregunta']}: es-{caracteristica}? -> {respuesta}")
            mensaje = motor.responder(caracteristica, respuesta)
        if mensaje["tipo"] == "prediccion":
            print(f"\n=> PREDICCION: {mensaje['entidad']} ({mensaje['porcentaje']} de certeza)")
            print(f"=> EXPLICACION: {mensaje['explicacion']}")
        else:
            print(f"\n=> {mensaje}")
    finally:
        motor.cerrar()
