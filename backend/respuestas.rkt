#lang racket

(provide pesos-respuesta respuesta->peso)

; PARTE 11: RESPUESTAS Y MANEJO DE INCERTIDUMBRE
; pesos-respuesta ahora se interpreta como CF_respuesta in [-1, 1]: el factor
; de certeza que aporta cada tipo de respuesta del usuario, en la escala de
; MYCIN. "no-se" vale 0.0 aqui solo a fines informativos/log: el motor NUNCA
; usa este 0.0 para combinar CF, porque filtrar-candidatos trata "no-se" como
; ausencia de evidencia (guarda explicita), no como evidencia neutra de cero.
(define pesos-respuesta
  '((si . 0.9)
    (probablemente . 0.6)
    (no-se . 0.0)
    (probablemente-no . -0.6)
    (no . -0.9)))

(define (respuesta->peso simbolo-respuesta)
  (let ((par (assoc simbolo-respuesta pesos-respuesta)))
    (if par (cdr par)
        (error 'respuesta->peso "respuesta invalida: ~a" simbolo-respuesta))))
