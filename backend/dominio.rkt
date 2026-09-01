#lang racket

(provide conocimiento)

; PARTE 8: DOMINIO Y BASE DE CONOCIMIENTO
; Representacion dispersa: cada entidad solo lista los rasgos que le aplican
; (formato del ejemplo del enunciado). 30 animales, 26 caracteristicas
; distintas en total, minimo 8 rasgos relevantes por animal.

(define conocimiento
  '((leon        (mamifero si)(salvaje si)(carnivoro si)(tiene-pelo si)(grande si)(vive-en-sabana si)(rapido si)(tiene-cola si))
    (tigre       (mamifero si)(salvaje si)(carnivoro si)(tiene-pelo si)(grande si)(vive-en-selva si)(rapido si)(tiene-cola si)(nocturno si))
    (elefante    (mamifero si)(salvaje si)(herbivoro si)(grande si)(vive-en-sabana si)(tiene-cola si)(tiene-pelo no)(rapido no))
    (perro       (mamifero si)(domestico si)(omnivoro si)(tiene-pelo si)(pequeno si)(tiene-cola si)(rapido si)(nocturno no))
    (gato        (mamifero si)(domestico si)(carnivoro si)(tiene-pelo si)(pequeno si)(tiene-cola si)(nocturno si)(rapido si))
    (aguila      (ave si)(salvaje si)(carnivoro si)(tiene-plumas si)(vuela si)(grande si)(rapido si)(tiene-cola si))
    (loro        (ave si)(domestico si)(omnivoro si)(tiene-plumas si)(vuela si)(pequeno si)(vive-en-selva si)(tiene-cola si))
    (pinguino    (ave si)(salvaje si)(carnivoro si)(tiene-plumas si)(nada si)(vuela no)(vive-en-agua si)(grande no))
    (serpiente   (reptil si)(salvaje si)(carnivoro si)(tiene-escamas si)(venenoso si)(tiene-cola si)(vive-en-selva si)(rapido no))
    (cocodrilo   (reptil si)(salvaje si)(carnivoro si)(tiene-escamas si)(grande si)(vive-en-agua si)(tiene-cola si)(nada si))
    (tortuga     (reptil si)(salvaje si)(herbivoro si)(tiene-escamas si)(rapido no)(tiene-cola si)(vive-en-agua si)(pequeno si))
    (iguana      (reptil si)(salvaje si)(herbivoro si)(tiene-escamas si)(tiene-cola si)(vive-en-selva si)(pequeno si)(rapido no))
    (tiburon     (pez si)(salvaje si)(carnivoro si)(tiene-escamas si)(nada si)(grande si)(vive-en-agua si)(rapido si))
    (delfin      (mamifero si)(salvaje si)(carnivoro si)(nada si)(vive-en-agua si)(grande si)(tiene-cola si)(rapido si)(tiene-pelo no))
    (ballena     (mamifero si)(salvaje si)(carnivoro si)(nada si)(vive-en-agua si)(grande si)(tiene-cola si)(rapido no))
    (rana        (anfibio si)(salvaje si)(carnivoro si)(vive-en-agua si)(pequeno si)(nada si)(tiene-cola no)(rapido si))
    (sapo        (anfibio si)(salvaje si)(carnivoro si)(vive-en-agua si)(pequeno si)(nocturno si)(venenoso si)(rapido no))
    (abeja       (insecto si)(salvaje si)(herbivoro si)(vuela si)(pequeno si)(venenoso si)(rapido si)(tiene-cola no))
    (mariposa    (insecto si)(salvaje si)(herbivoro si)(vuela si)(pequeno si)(rapido no)(vive-en-selva si)(tiene-cola no))
    (hormiga     (insecto si)(salvaje si)(omnivoro si)(pequeno si)(vuela no)(rapido no)(domestico no)(tiene-cola no))
    (caballo     (mamifero si)(domestico si)(herbivoro si)(tiene-pelo si)(grande si)(rapido si)(tiene-cola si)(vive-en-sabana si))
    (Ornitorrinco (mamifero si)(domestico no)(carnivoro si)(tiene-pelo si)(grande no)(tiene-cola si)(vive-en-australia si)(venenoso si)(nada si))
    (oveja       (mamifero si)(domestico si)(herbivoro si)(tiene-pelo si)(pequeno si)(tiene-cola si)(rapido no)(vive-en-sabana si))
    (cerdo       (mamifero si)(domestico si)(omnivoro si)(tiene-pelo si)(pequeno si)(tiene-cola si)(rapido no)(vive-en-sabana si))
    (lobo        (mamifero si)(salvaje si)(carnivoro si)(tiene-pelo si)(grande si)(tiene-cola si)(rapido si)(vive-en-selva si))
    (zorro       (mamifero si)(salvaje si)(omnivoro si)(tiene-pelo si)(pequeno si)(tiene-cola si)(rapido si)(nocturno si))
    (oso         (mamifero si)(salvaje si)(omnivoro si)(tiene-pelo si)(grande si)(tiene-cola si)(vive-en-selva si)(nocturno no))
    (panda       (mamifero si)(salvaje si)(herbivoro si)(tiene-pelo si)(grande si)(tiene-cola si)(vive-en-selva si)(rapido no))
    (canguro     (mamifero si)(salvaje si)(herbivoro si)(tiene-pelo si)(grande si)(tiene-cola si)(rapido si)(vive-en-sabana si))
    (murcielago  (mamifero si)(salvaje si)(carnivoro si)(vuela si)(nocturno si)(pequeno si)(tiene-cola si)(tiene-pelo si))))
