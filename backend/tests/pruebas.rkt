#lang racket

(require rackunit "../dominio.rkt" "../reglas.rkt" "../respuestas.rkt" "../motor.rkt")

; ======================================================================
; FASE 1: DOMINIO Y DATOS BASE
; ======================================================================

(test-case "conocimiento tiene exactamente 30 entidades"
  (check-equal? (length conocimiento) 30))

(test-case "cada entidad tiene 8 o mas caracteristicas"
  (for ([entidad conocimiento])
    (check-true (>= (length (cdr entidad)) 8)
                (format "~a tiene menos de 8 caracteristicas" (car entidad)))))

(test-case "hay 20 o mas caracteristicas distintas en todo el dominio"
  (define todas
    (remove-duplicates (append-map (lambda (e) (map car (cdr e))) conocimiento)))
  (check-true (>= (length todas) 20)
              (format "solo hay ~a caracteristicas distintas" (length todas))))

; ======================================================================
; FASE 2: HECHOS Y REGLAS (forward chaining con punto fijo)
; ======================================================================

(test-case "condiciones-cumplidas? exige que se cumplan TODAS las condiciones"
  (check-true (condiciones-cumplidas? '((mamifero si) (grande si)) '((mamifero si) (grande si) (rapido no))))
  (check-false (condiciones-cumplidas? '((mamifero si) (grande si)) '((mamifero si) (grande no)))))

(test-case "aplicar-reglas-una-pasada encadena reglas dentro de la misma pasada (foldl acumula)"
  ; hechos sinteticos: insecto+nocturno. Como (insecto si)->(pequeno si) esta
  ; ANTES que (nocturno si)(pequeno si)->(sigiloso si) en la lista `reglas`,
  ; foldl ya ve el "pequeno" recien agregado al llegar a la regla de sigiloso:
  ; ambas disparan en la misma pasada. Esto es correcto (foldl acumula sobre
  ; la marcha) y es justamente por lo que hace falta la recursion de punto fijo
  ; en aplicar-reglas: para los casos en que el orden de las reglas NO
  ; favorece el encadenamiento en una sola pasada.
  (define hechos-base '((insecto si) (nocturno si)))
  (define tras-una-pasada (aplicar-reglas-una-pasada hechos-base))
  (check-equal? (valor-de 'pequeno tras-una-pasada) 'si)
  (check-equal? (valor-de 'sigiloso tras-una-pasada) 'si))

(test-case "aplicar-reglas alcanza un punto fijo real: una pasada mas no agrega nada"
  (define hechos-base '((insecto si) (nocturno si)))
  (define hechos-finales (aplicar-reglas hechos-base))
  (check-equal? (valor-de 'pequeno hechos-finales) 'si)
  (check-equal? (valor-de 'sigiloso hechos-finales) 'si)
  ; punto fijo genuino: aplicar una pasada extra sobre el resultado ya
  ; estabilizado no cambia nada (ni agrega hechos nuevos)
  (check-equal? (aplicar-reglas-una-pasada hechos-finales) hechos-finales))

(test-case "el encadenamiento respeta el orden real de recorrido de las reglas (2 disparos, no 1)"
  ; conteo de hechos nuevos: arranca con 2 hechos base y termina con 4
  ; (pequeno y sigiloso), lo que prueba que se dispararon 2 reglas en cadena
  ; y no solo 1 (si solo hubiera disparado la regla de "pequeno", el largo
  ; final seria 3, no 4).
  (define hechos-base '((insecto si) (nocturno si)))
  (define hechos-finales (aplicar-reglas hechos-base))
  (check-equal? (length hechos-finales) 4))

; ======================================================================
; FASE 3: MOTOR DE INFERENCIA CON FACTORES DE CERTEZA
; ======================================================================

(test-case "cf-regla distingue si / no / sin-evidencia (nunca 0)"
  (check-equal? (cf-regla 'mamifero '((mamifero si))) 1)
  (check-equal? (cf-regla 'mamifero '((mamifero no))) -1)
  (check-equal? (cf-regla 'mamifero '()) 'sin-evidencia))

(test-case "cf-evidencia combina CF_respuesta y CF_regla"
  (check-equal? (cf-evidencia 0.9 1) 0.9)
  (check-equal? (cf-evidencia 0.9 -1) -0.9)
  (check-equal? (cf-evidencia -0.6 -1) 0.6))

(test-case "combinar-cf: misma polaridad refuerza la creencia"
  (check-= (combinar-cf 0.6 0.6) (+ 0.6 (* 0.6 0.4)) 1e-9)
  (check-= (combinar-cf -0.6 -0.6) (- (+ 0.6 (* 0.6 0.4))) 1e-9))

(test-case "combinar-cf: polaridades opuestas se restan proporcionalmente"
  (check-= (combinar-cf 0.5 -0.3) (/ (+ 0.5 -0.3) (- 1 0.3)) 1e-9))

(test-case "combinar-cf: guarda de division por cero (evidencias opuestas de certeza total)"
  (check-equal? (combinar-cf 1.0 -1.0) 0.0)
  (check-equal? (combinar-cf -1.0 1.0) 0.0))

(test-case "filtrar-candidatos no toca un candidato sin evidencia real"
  (define candidatos (cargar-conocimiento))
  ; "no-se" nunca debe mover el CF de nadie, tenga o no el rasgo definido
  (define tras-no-se (filtrar-candidatos candidatos 'mamifero 0.0 'no-se))
  (check-true (andmap (lambda (c1 c2) (= (cadr c1) (cadr c2))) candidatos tras-no-se)))

(test-case "rango [-1,1]: ningun CF se sale de rango tras una partida completa (30 entidades)"
  (define violaciones
    (for*/list ([entidad conocimiento]
                [resultado
                 (in-value
                  (let ([respuestas (map (lambda (h) (cons (car h) (if (equal? (cadr h) 'si) 'si 'no))) (cdr entidad))])
                    (let loop ([candidatos (cargar-conocimiento)] [historial '()] [preguntas '()] [n 0] [malos '()])
                      (define nuevos-malos
                        (append malos (filter (lambda (c) (not (<= -1.0 (cadr c) 1.0))) candidatos)))
                      (if (>= n 40)
                          nuevos-malos
                          (let* ([r (inferir candidatos historial)])
                            (if (eq? (car r) 'prediccion)
                                nuevos-malos
                                (let ([siguiente (seleccionar-pregunta candidatos preguntas)])
                                  (if (not siguiente)
                                      nuevos-malos
                                      (let* ([resp (assoc siguiente respuestas)]
                                             [simbolo (if resp (cdr resp) 'no-se)]
                                             [cfr (respuesta->peso simbolo)]
                                             [nvos (filtrar-candidatos candidatos siguiente cfr simbolo)])
                                        (loop nvos
                                              (if (equal? simbolo 'no-se) historial (cons (cons siguiente cfr) historial))
                                              (cons siguiente preguntas) (+ n 1) nuevos-malos))))))))))]
                #:when (pair? resultado))
      (list (car entidad) resultado)))
  (check-equal? violaciones '()))

(test-case "demo tigre: converge en el candidato correcto"
  (define resultado
    (simular-partida (list (cons 'mamifero 'si) (cons 'domestico 'no) (cons 'salvaje 'si)
                            (cons 'carnivoro 'si) (cons 'grande 'si) (cons 'vive-en-sabana 'no)
                            (cons 'vive-en-selva 'si) (cons 'nocturno 'si) (cons 'rapido 'si))))
  (define veredicto (first resultado))
  (check-equal? (car veredicto) 'prediccion)
  (check-equal? (cadr veredicto) 'tigre)
  (check-true (<= -1.0 (caddr veredicto) 1.0)))

; ======================================================================
; FASE 4: SELECCION DINAMICA DE PREGUNTAS (sin cambios de logica; smoke test)
; ======================================================================

(test-case "seleccionar-pregunta elige una caracteristica no preguntada aun"
  (define candidatos (cargar-conocimiento))
  (define primera (seleccionar-pregunta candidatos '()))
  (check-true (symbol? primera))
  (define segunda (seleccionar-pregunta candidatos (list primera)))
  (check-not-equal? segunda primera))

; ======================================================================
; FASE 6: CASOS DE PRUEBA Y ROBUSTEZ
; ======================================================================

(test-case "todas las respuestas 'no-se': nunca converge"
  (define resultado (simular-partida '()))
  (check-equal? (car (first resultado)) 'continuar))

(test-case "entidad dificil: Ornitorrinco converge con sus propios hechos"
  (define hechos (cdr (assoc 'Ornitorrinco conocimiento)))
  (define respuestas (map (lambda (h) (cons (car h) (if (equal? (cadr h) 'si) 'si 'no))) hechos))
  (define resultado (simular-partida respuestas))
  (define veredicto (first resultado))
  (check-equal? (car veredicto) 'prediccion)
  (check-equal? (cadr veredicto) 'Ornitorrinco))

(test-case "empate tecnico: una sola respuesta compartida por varios candidatos no alcanza para predecir"
  (define candidatos (cargar-conocimiento))
  (define primera (seleccionar-pregunta candidatos '()))
  (define cfr (respuesta->peso 'si))
  (define tras-1 (filtrar-candidatos candidatos primera cfr 'si))
  (define historial (list (cons primera cfr)))
  (define resultado (inferir tras-1 historial))
  ; con una sola confirmacion generica, varios candidatos quedan empatados en
  ; CF y en coincidencias: el margen-minimo/desempate no debe alcanzar para predecir.
  (check-equal? (car resultado) 'continuar))

(test-case "division por cero forzada: CF llega a 0.0 sin crashear y el resto sigue jugando"
  (define candidatos (cargar-conocimiento))
  (define leon-hechos (caddr (assoc 'leon candidatos)))
  (define candidatos-seed
    (map (lambda (c) (if (equal? (car c) 'leon) (list 'leon 1.0 leon-hechos) c)) candidatos))
  ; leon tiene (vive-en-sabana si); forzamos una respuesta con CF_respuesta=-1.0
  ; (certeza total, "a mano" como pide el enunciado) para que cf-evidencia sea
  ; exactamente -1.0 y combinar-cf tenga que usar la guarda de division por cero.
  (define resultado (filtrar-candidatos candidatos-seed 'vive-en-sabana -1.0 'no))
  (check-equal? (cadr (assoc 'leon resultado)) 0.0)
  ; el resto de los candidatos no fue tocado por esta llamada
  (check-equal? (length resultado) (length candidatos)))

(test-case "el motor nunca predice una entidad incorrecta (sobre las 30 con sus propios hechos)"
  (define predicciones-incorrectas
    (for/list ([entidad conocimiento]
               #:do [(define respuestas
                       (map (lambda (h) (cons (car h) (if (equal? (cadr h) 'si) 'si 'no))) (cdr entidad)))
                     (define veredicto (first (simular-partida respuestas)))]
               #:when (and (eq? (car veredicto) 'prediccion) (not (equal? (cadr veredicto) (car entidad)))))
      (list (car entidad) veredicto)))
  (check-equal? predicciones-incorrectas '()))
