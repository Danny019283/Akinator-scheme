#lang racket

(require json "motor.rkt" "respuestas.rkt")

; PARTE 5: SERVIDOR DE COMUNICACION CON PYTHON
; Protocolo: subproceso persistente, un objeto JSON por linea en stdin/stdout.
; Python manda comandos, Racket responde y hace flush-output tras cada linea
; para que el readline() de Python no se quede bloqueado esperando buffer.
;
; Comandos que acepta (stdin, un JSON por linea):
;   {"cmd": "iniciar"}
;   {"cmd": "responder", "caracteristica": "mamifero", "respuesta": "si"}
;   {"cmd": "reiniciar"}
;
; Respuestas que emite (stdout, un JSON por linea):
;   {"tipo": "pregunta", "caracteristica": "mamifero", "numero_pregunta": 1, "candidatos_restantes": 25, "total_candidatos": 30}
;   {"tipo": "prediccion", "entidad": "tigre", "certeza": 0.999, "porcentaje": "100%", "explicacion": [...]}
;   {"tipo": "sin_preguntas", "mejor_candidato": "tigre", "certeza": 0.4}
;   {"tipo": "error", "mensaje": "..."}

(define estado-candidatos (box #f))
(define estado-historial (box '()))
(define estado-preguntas (box '()))
(define estado-contador (box 0))

(define (reiniciar-estado!)
  (set-box! estado-candidatos (cargar-conocimiento))
  (set-box! estado-historial '())
  (set-box! estado-preguntas '())
  (set-box! estado-contador 0))

(define (emitir obj)
  (displayln (jsexpr->string obj))
  (flush-output))

; no se acepta una prediccion antes de haber hecho al menos esta cantidad
; de preguntas, aunque el CF ya cumpla umbral-cf y margen-minimo. Evita
; "adivinar" con 2-3 respuestas genericas (mamifero=si, salvaje=si, etc.)
; que muchos candidatos comparten por igual.
(define minimo-preguntas 5)

(define (emitir-estado-actual)
  (define candidatos (unbox estado-candidatos))
  (define historial (unbox estado-historial))
  (define resultado (inferir candidatos historial))
  (cond
    ((and (eq? (car resultado) 'prediccion)
          (>= (unbox estado-contador) minimo-preguntas))
     (define nombre (cadr resultado))
     (define certeza (caddr resultado))
     (define ganador (assoc nombre candidatos))
     (emitir (hasheq 'tipo "prediccion"
                      'entidad (symbol->string nombre)
                      'certeza certeza
                      'porcentaje (format "~a%" (round (* 100 certeza)))
                      'explicacion (map (lambda (r) (symbol->string (car r))) (explicar ganador historial)))))
    (else
     (define siguiente (seleccionar-pregunta candidatos (unbox estado-preguntas)))
     (define candidatos-vivos (length (filter (lambda (c) (>= (cadr c) 0)) candidatos)))
     (if siguiente
         (begin
           (set-box! estado-contador (add1 (unbox estado-contador)))
           (emitir (hasheq 'tipo "pregunta"
                            'caracteristica (symbol->string siguiente)
                            'numero_pregunta (unbox estado-contador)
                            'candidatos_restantes candidatos-vivos
                            'total_candidatos (length candidatos))))

         (let ((top1 (car (mejores-dos candidatos historial))))
           (emitir (hasheq 'tipo "sin_preguntas"
                            'mejor_candidato (symbol->string (car top1))
                            'certeza (cadr top1))))))))

(define (procesar-responder obj)
  (define caracteristica (string->symbol (hash-ref obj 'caracteristica)))
  (define simbolo-respuesta (string->symbol (hash-ref obj 'respuesta)))
  (define cf-respuesta (respuesta->peso simbolo-respuesta))
  (set-box! estado-candidatos
            (filtrar-candidatos (unbox estado-candidatos) caracteristica cf-respuesta simbolo-respuesta))
  (unless (equal? simbolo-respuesta 'no-se)
    (set-box! estado-historial (cons (cons caracteristica cf-respuesta) (unbox estado-historial))))
  (set-box! estado-preguntas (cons caracteristica (unbox estado-preguntas))))

(define (procesar-linea linea)
  (with-handlers ([exn:fail? (lambda (e) (emitir (hasheq 'tipo "error" 'mensaje (exn-message e))))])
    (define obj (string->jsexpr linea))
    (define cmd (hash-ref obj 'cmd #f))
    (cond
      ((equal? cmd "iniciar") (reiniciar-estado!) (emitir-estado-actual))
      ((equal? cmd "reiniciar") (reiniciar-estado!) (emitir-estado-actual))
      ((equal? cmd "responder") (procesar-responder obj) (emitir-estado-actual))
      (else (emitir (hasheq 'tipo "error" 'mensaje (format "comando desconocido: ~a" cmd)))))))

(module+ main
  (reiniciar-estado!)
  (let loop ()
    (define linea (read-line (current-input-port) 'any))
    (unless (eof-object? linea)
      (unless (string=? (string-trim linea) "")
        (procesar-linea linea))
      (loop))))
