"""Traducción de cada característica (símbolo que manda el backend) a una
pregunta en español natural.
"""

PREGUNTAS = {
    "mamifero": "¿Es un mamífero?",
    "ave": "¿Es un ave?",
    "reptil": "¿Es un reptil?",
    "pez": "¿Es un pez?",
    "anfibio": "¿Es un anfibio?",
    "insecto": "¿Es un insecto?",
    "salvaje": "¿Es un animal salvaje?",
    "domestico": "¿Es un animal doméstico?",
    "carnivoro": "¿Es carnívoro?",
    "herbivoro": "¿Es herbívoro?",
    "omnivoro": "¿Es omnívoro?",
    "tiene-pelo": "¿Tiene pelo?",
    "tiene-plumas": "¿Tiene plumas?",
    "tiene-escamas": "¿Tiene escamas?",
    "tiene-cola": "¿Tiene cola?",
    "grande": "¿Es de tamaño grande?",
    "pequeno": "¿Es de tamaño pequeño?",
    "rapido": "¿Es rápido?",
    "vuela": "¿Puede volar?",
    "nada": "¿Puede nadar?",
    "nocturno": "¿Es un animal nocturno?",
    "venenoso": "¿Es venenoso?",
    "vive-en-sabana": "¿Vive en la sabana?",
    "vive-en-selva": "¿Vive en la selva?",
    "vive-en-agua": "¿Vive principalmente en el agua?",
    "vive-en-australia": "¿Es originario de Australia?",
}


def texto_pregunta(caracteristica):
    return PREGUNTAS.get(
        caracteristica,
        f"¿Tu animal tiene la característica «{caracteristica}»?",
    )
