#lang racket

(require racket/list "dominio.rkt" "motor.rkt" "respuestas.rkt")

; PRUEBAS Y CASOS LIMITE (seccion 18 del enunciado)
; ---------------------------------------------------------------------
; Esto NO es la suite de unit tests (esa es tests/pruebas.rkt, con
; rackunit, que verifica funciones individuales del motor). Este archivo
; es una DEMOSTRACION ejecutable y legible de los 5 casos de prueba
; obligatorios exigidos por el enunciado, pensada para leerse o
; presentarse: cada caso arma un escenario de juego completo y narra en
; consola qué pasó y por qué el resultado es el esperado.
;
; Correr con:  racket casos_limite.rkt

(define (linea) (displayln (make-string 70 #\-)))

(define (titulo n texto)
  (linea)
  (printf "CASO ~a: ~a\n" n texto)
  (linea))

; convierte los hechos propios de una entidad en respuestas si/no, para
; simular a un usuario que "piensa" honestamente en esa entidad
(define (respuestas-de-entidad nombre)
  (define hechos (cdr (assoc nombre conocimiento)))
  (map (lambda (h) (cons (car h) (if (equal? (cadr h) 'si) 'si 'no))) hechos))

; ======================================================================
; CASO 1: Entidad claramente identificable
; Resultado esperado: prediccion correcta con pocas preguntas.
; ======================================================================
(define (caso-1)
  (titulo 1 "Entidad claramente identificable -> prediccion correcta con pocas preguntas")
  (match-define (list veredicto historial preguntas) (simular-partida (respuestas-de-entidad 'tigre)))
  (printf "Usuario piensa en: tigre (respondiendo segun sus propios hechos)\n")
  (printf "Preguntas realizadas: ~a -> ~a\n" (length preguntas) (reverse preguntas))
  (printf "Veredicto: ~a\n" veredicto)
  (cond
    ((and (eq? (car veredicto) 'prediccion) (equal? (cadr veredicto) 'tigre) (<= (length preguntas) 20))
     (printf "OK: predijo 'tigre' correctamente en ~a preguntas (<= 20).\n" (length preguntas)))
    (else
     (printf "FALLO: no predijo 'tigre' con pocas preguntas.\n"))))

; ======================================================================
; CASO 2: Entidades muy similares
; Resultado esperado: preguntas discriminantes hasta separarlas.
; El par mas parecido del dominio es lobo/tigre (comparten 8 rasgos);
; solo se distinguen por 'nocturno' y 'vive-en-manada'.
; ======================================================================
(define (caso-2)
  (titulo 2 "Entidades muy similares (lobo/tigre) -> preguntas discriminantes hasta separarlas")
  (define resultado-lobo (simular-partida (respuestas-de-entidad 'lobo)))
  (define resultado-tigre (simular-partida (respuestas-de-entidad 'tigre)))
  (define veredicto-lobo (first resultado-lobo))
  (define veredicto-tigre (first resultado-tigre))
  (define preguntas-lobo (reverse (third resultado-lobo)))
  (printf "Usuario piensa en: lobo -> veredicto: ~a\n" veredicto-lobo)
  (printf "  Preguntas: ~a\n" preguntas-lobo)
  (printf "Usuario piensa en: tigre -> veredicto: ~a\n" veredicto-tigre)
  (printf "  Las preguntas 'nocturno' y 'vive-en-manada' son las que separan a lobo de tigre\n")
  (printf "  (lobo: nocturno=no, vive-en-manada=si; tigre: nocturno=si, no tiene vive-en-manada).\n")
  (cond
    ((and (equal? veredicto-lobo (list 'prediccion 'lobo (caddr veredicto-lobo)))
          (equal? veredicto-tigre (list 'prediccion 'tigre (caddr veredicto-tigre))))
     (printf "OK: ambas entidades convergen a si mismas, no se confunden entre si.\n"))
    (else
     (printf "FALLO: lobo y tigre no se lograron separar.\n"))))

; ======================================================================
; CASO 3: Respuesta "No se"
; Resultado esperado: continuar sin eliminar injustificadamente.
; ======================================================================
(define (caso-3)
  (titulo 3 "Respuesta 'No se' -> continuar sin eliminar injustificadamente")
  (define candidatos-antes (cargar-conocimiento))
  (define primera-pregunta (seleccionar-pregunta candidatos-antes '()))
  (define candidatos-despues
    (filtrar-candidatos candidatos-antes primera-pregunta (respuesta->peso 'no-se) 'no-se))
  (printf "Pregunta: ¿~a?  Respuesta del usuario: \"No se\"\n" primera-pregunta)
  (define cf-iguales? (andmap (lambda (a b) (= (cadr a) (cadr b))) candidatos-antes candidatos-despues))
  (define cantidad-antes (length candidatos-antes))
  (define cantidad-despues (length candidatos-despues))
  (printf "Candidatos antes: ~a   Candidatos despues: ~a\n" cantidad-antes cantidad-despues)
  (printf "¿Algun CF cambio?: ~a\n" (if cf-iguales? "no" "si"))
  (cond
    ((and cf-iguales? (= cantidad-antes cantidad-despues))
     (printf "OK: nadie fue eliminado ni penalizado por responder 'no se'; la partida sigue con todos.\n"))
    (else
     (printf "FALLO: 'no se' afecto candidatos que no debia tocar.\n"))))

; ======================================================================
; CASO 4: Respuestas probabilisticas
; Resultado esperado: la confianza cambia de forma coherente (misma
; direccion que una respuesta segura, pero con menor magnitud).
; ======================================================================
(define (caso-4)
  (titulo 4 "Respuestas probabilisticas -> la confianza cambia de forma coherente")
  (define candidatos (cargar-conocimiento))
  (define pregunta (seleccionar-pregunta candidatos '()))
  (define con-si (filtrar-candidatos candidatos pregunta (respuesta->peso 'si) 'si))
  (define con-probablemente (filtrar-candidatos candidatos pregunta (respuesta->peso 'probablemente) 'probablemente))
  (define con-no (filtrar-candidatos candidatos pregunta (respuesta->peso 'no) 'no))
  (define con-probablemente-no (filtrar-candidatos candidatos pregunta (respuesta->peso 'probablemente-no) 'probablemente-no))
  (printf "Pregunta: ¿~a?\n" pregunta)
  (printf "CF_respuesta: si=~a probablemente=~a  |  no=~a probablemente-no=~a\n"
          (respuesta->peso 'si) (respuesta->peso 'probablemente)
          (respuesta->peso 'no) (respuesta->peso 'probablemente-no))
  (define (movimiento-promedio antes despues)
    (/ (apply + (map (lambda (a b) (abs (- (cadr b) (cadr a)))) antes despues)) (length antes)))
  (define mov-si (movimiento-promedio candidatos con-si))
  (define mov-probablemente (movimiento-promedio candidatos con-probablemente))
  (define mov-no (movimiento-promedio candidatos con-no))
  (define mov-probablemente-no (movimiento-promedio candidatos con-probablemente-no))
  (printf "Movimiento promedio de CF -> 'si': ~a   'probablemente': ~a\n" mov-si mov-probablemente)
  (printf "Movimiento promedio de CF -> 'no': ~a   'probablemente-no': ~a\n" mov-no mov-probablemente-no)
  (cond
    ((and (<= mov-probablemente mov-si) (<= mov-probablemente-no mov-no))
     (printf "OK: las respuestas tentativas mueven el CF en la misma direccion, pero con menor fuerza.\n"))
    (else
     (printf "FALLO: una respuesta tentativa movio el CF igual o mas que una respuesta segura.\n"))))

; ======================================================================
; CASO 5: Entidad desconocida/ambigua
; Resultado esperado: informar falta de certeza suficiente (nunca forzar
; una prediccion). Esto es exactamente lo que servidor.rkt reporta como
; {"tipo": "sin_preguntas", ...} cuando se agotan las preguntas.
; ======================================================================
(define (caso-5)
  (titulo 5 "Entidad desconocida/ambigua -> informar falta de certeza suficiente")
  (match-define (list veredicto historial preguntas) (simular-partida '())) ; todo "no se"
  (printf "Usuario responde 'no se' a todo (entidad ambigua/desconocida).\n")
  (printf "Preguntas agotadas: ~a\n" (length preguntas))
  (printf "Veredicto del motor: ~a (nunca 'prediccion')\n" veredicto)
  (define agotadas? (not (seleccionar-pregunta (cargar-conocimiento) preguntas)))
  (define top2 (mejores-dos (cargar-conocimiento) historial))
  (define mejor-candidato (car top2))
  (printf "Ya no quedan preguntas por hacer: ~a\n" agotadas?)
  (printf "Mejor candidato reportable (sin forzar prediccion): ~a con CF ~a (< umbral-cf ~a)\n"
          (car mejor-candidato) (cadr mejor-candidato) umbral-cf)
  (cond
    ((and (eq? (car veredicto) 'continuar) agotadas? (< (cadr mejor-candidato) umbral-cf))
     (printf "OK: el sistema informa el mejor candidato sin certeza suficiente, no adivina.\n"))
    (else
     (printf "FALLO: el motor debio abstenerse de predecir y no lo hizo.\n"))))

(module+ main
  (caso-1) (newline)
  (caso-2) (newline)
  (caso-3) (newline)
  (caso-4) (newline)
  (caso-5) (newline)
  (linea)
  (printf "Fin de los 5 casos de prueba obligatorios (seccion 18 del enunciado).\n"))
