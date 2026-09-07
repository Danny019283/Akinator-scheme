#lang racket

(require json racket/runtime-path)

(provide cargar-estadisticas guardar-estadisticas registrar-resultado
         estadisticas->jsexpr ruta-estadisticas-por-defecto)

; ESTADISTICAS PERSISTENTES
; Cuenta partidas jugadas, aciertos, fallos y total de preguntas hechas,
; y las persiste en un JSON en disco. Vive en Racket para que el frontend
; nunca tenga que guardar ni interpretar este estado: solo pide
; "estadisticas" o manda "registrar_resultado" por el protocolo.

(define-runtime-path ruta-estadisticas-por-defecto "estadisticas.json")

(define estadisticas-vacias
  (hasheq 'partidas 0 'aciertos 0 'fallos 0 'total_preguntas 0))

(define (cargar-estadisticas [ruta ruta-estadisticas-por-defecto])
  (if (file-exists? ruta)
      (with-handlers ([exn:fail? (lambda (_) estadisticas-vacias)])
        (call-with-input-file ruta read-json))
      estadisticas-vacias))

(define (guardar-estadisticas estadisticas [ruta ruta-estadisticas-por-defecto])
  (call-with-output-file ruta #:exists 'replace
    (lambda (salida) (write-json estadisticas salida))))

(define (registrar-resultado estadisticas acierto? numero-preguntas)
  (hasheq 'partidas (add1 (hash-ref estadisticas 'partidas 0))
          'aciertos (+ (hash-ref estadisticas 'aciertos 0) (if acierto? 1 0))
          'fallos (+ (hash-ref estadisticas 'fallos 0) (if acierto? 0 1))
          'total_preguntas (+ (hash-ref estadisticas 'total_preguntas 0) numero-preguntas)))

(define (promedio-preguntas estadisticas)
  (define partidas (hash-ref estadisticas 'partidas 0))
  (if (zero? partidas)
      0.0
      (/ (round (* 10.0 (/ (hash-ref estadisticas 'total_preguntas 0) partidas))) 10.0)))

(define (estadisticas->jsexpr estadisticas)
  (hasheq 'tipo "estadisticas"
          'partidas (hash-ref estadisticas 'partidas 0)
          'aciertos (hash-ref estadisticas 'aciertos 0)
          'fallos (hash-ref estadisticas 'fallos 0)
          'promedio_preguntas (promedio-preguntas estadisticas)))
