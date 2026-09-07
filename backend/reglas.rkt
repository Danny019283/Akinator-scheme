#lang racket

(provide valor-de reglas condiciones-cumplidas? aplicar-reglas-una-pasada aplicar-reglas)

; PARTE 9: HECHOS Y REGLAS
; hecho  = (caracteristica valor)
; regla  = (antecedentes . consecuente)  donde antecedentes es una lista de
; hechos que deben cumplirse todos, y consecuente es el hecho nuevo
; a derivar. Agregar una entidad NUNCA obliga a tocar el motor ni
; las reglas: basta con anadir su entrada a `conocimiento`.

(define (valor-de caracteristica hechos)
  (let ((par (assoc caracteristica hechos)))
    (if par (cadr par) 'desconocido)))

(define reglas
  (list
   (cons '((tiene-plumas si))                          '(ave si))
   (cons '((vuela si) (tiene-pelo si))                 '(mamifero si))
   (cons '((carnivoro si) (grande si) (salvaje si))    '(peligroso si))
   (cons '((venenoso si))                              '(peligroso si))
   (cons '((nada si) (vive-en-agua si) (tiene-pelo no)) '(acuatico si))
   (cons '((insecto si))                               '(pequeno si))
   (cons '((reptil si))                                '(tiene-escamas si))
   (cons '((domestico si))                             '(salvaje no))
   (cons '((mamifero si) (nada si))                    '(cetaceo si))
   (cons '((nocturno si) (pequeno si))                 '(sigiloso si))))

; ¿se cumplen TODAS las condiciones de una regla sobre una lista de hechos?
(define (condiciones-cumplidas? antecedentes hechos)
  (andmap (lambda (condicion) (equal? (valor-de (car condicion) hechos) (cadr condicion)))
          antecedentes))

; una pasada: agrega los consecuentes de las reglas cuyas condiciones se cumplen
; y cuyo hecho aun no esta presente (para no duplicar ni sobrescribir)
(define (aplicar-reglas-una-pasada hechos)
  (foldl (lambda (r hechos-acum)
           (let ((antecedentes (car r)) (consecuente (cdr r)))
             (if (and (condiciones-cumplidas? antecedentes hechos-acum)
                      (equal? (valor-de (car consecuente) hechos-acum) 'desconocido))
                 (append hechos-acum (list consecuente))
                 hechos-acum)))
         hechos
         reglas))

; aplica reglas repetidamente (recursion) hasta llegar a un punto fijo:
; ya no aparecen hechos nuevos en una pasada completa
(define (aplicar-reglas hechos)
  (let ((hechos-nuevos (aplicar-reglas-una-pasada hechos)))
    (if (= (length hechos-nuevos) (length hechos))
        hechos
        (aplicar-reglas hechos-nuevos))))
