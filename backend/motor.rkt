#lang racket

(require racket/list "dominio.rkt" "reglas.rkt" "respuestas.rkt")

(provide cargar-conocimiento cf-regla cf-evidencia combinar-cf filtrar-candidatos
         mejores-dos inferir explicar contar-coincidencias reiniciar
         umbral-cf margen-minimo
         todas-las-caracteristicas contar-particion puntaje-discriminacion seleccionar-pregunta
         simular-partida)

; PARTE 10: MOTOR DE INFERENCIA CON FACTORES DE CERTEZA (CF)
; candidato = (nombre CF-actual hechos)   -- hechos ya enriquecidos por las reglas
; CF-actual in [-1, 1]: -1 certeza total de que NO es, +1 certeza total de que SI es,
; 0 sin evidencia acumulada todavia.

; cargar-conocimiento: candidatos iniciales, CF 0.0 (sin evidencia), reglas ya aplicadas
(define (cargar-conocimiento)
  (map (lambda (entidad) (list (car entidad) 0.0 (aplicar-reglas (cdr entidad))))
       conocimiento))

; cf-regla: que dice el HECHO PROPIO de la entidad sobre esta caracteristica,
; independientemente de lo que haya respondido el usuario.
; +1  -> la entidad tiene el rasgo (hecho = si)
; -1  -> la entidad NO tiene el rasgo (hecho = no)
; 'sin-evidencia -> la entidad no tiene ese rasgo definido (no aporta, distinto de aportar 0)
(define (cf-regla caracteristica hechos)
  (let ((v (valor-de caracteristica hechos)))
    (cond ((equal? v 'si) 1)
          ((equal? v 'no) -1)
          (else 'sin-evidencia))))

; cf-evidencia: combina la certeza de la respuesta del usuario (CF_respuesta) con
; lo que dice el hecho de la entidad (cf-regla, ya numerico). El llamador debe
; garantizar que ambos lados tienen evidencia real antes de invocar esta funcion.
(define (cf-evidencia cf-respuesta cf-regla-num)
  (* cf-respuesta cf-regla-num))

; combinar-cf: formula de combinacion incremental de MYCIN para dos CF en [-1,1].
; Guarda: si la rama de signos opuestos da denominador 0 (evidencias de certeza
; total y signo contrario, ej. CF1=1.0 CF2=-1.0), devuelve 0 en vez de dividir.
(define (combinar-cf cf1 cf2)
  (cond
    ((and (>= cf1 0) (>= cf2 0)) (+ cf1 (* cf2 (- 1 cf1))))
    ((and (<= cf1 0) (<= cf2 0)) (+ cf1 (* cf2 (+ 1 cf1))))
    (else
     (let ((denominador (- 1 (min (abs cf1) (abs cf2)))))
       (if (= denominador 0) 0.0 (/ (+ cf1 cf2) denominador))))))

; filtrar-candidatos: recalcula el CF de todos los candidatos tras una respuesta.
; Solo combina cuando hay evidencia real en AMBOS lados: el hecho de la entidad
; esta definido (cf-regla no es 'sin-evidencia) Y la respuesta no fue "no-se".
; Si falta cualquiera de los dos, el candidato no se toca esta ronda.
(define (filtrar-candidatos candidatos caracteristica cf-respuesta simbolo-respuesta)
  (map (lambda (c)
         (let* ((hechos (caddr c))
                (cf-actual (cadr c))
                (cfr (cf-regla caracteristica hechos)))
           (if (or (equal? cfr 'sin-evidencia) (equal? simbolo-respuesta 'no-se))
               c
               (list (car c) (combinar-cf cf-actual (cf-evidencia cf-respuesta cfr)) hechos))))
       candidatos))

; explicar: de todo el historial de respuestas, cuales coinciden con los
; hechos reales del candidato ganador (esas son las que mas influyeron)
(define (explicar candidato-ganador historial-respuestas)
  (filter (lambda (r)
            (equal? (valor-de (car r) (caddr candidato-ganador))
                    (if (> (cdr r) 0) 'si 'no)))
          historial-respuestas))

; contar-coincidencias: cuantas respuestas del historial son consistentes con
; los hechos propios de un candidato. Con muchos rasgos compartidos (mamifero,
; carnivoro, grande...) varios candidatos pueden saturar su CF muy cerca de 1.0
; al mismo tiempo (la combinacion de MYCIN converge asintoticamente a 1 con
; cada confirmacion, sin importar cuan generico sea el rasgo). Esta cuenta
; sirve como desempate: entre dos candidatos con el mismo CF, gana el que
; efectivamente coincide con mas respuestas dadas.
(define (contar-coincidencias candidato historial-respuestas)
  (length (explicar candidato historial-respuestas)))

; obtiene los dos candidatos con mayor CF (y, en caso de empate de CF, mayor
; cantidad de coincidencias con el historial) para exigir separacion entre
; 1ro y 2do.
(define (mejores-dos candidatos historial-respuestas)
  (let ((ordenados
         (sort candidatos
               (lambda (a b)
                 (or (> (cadr a) (cadr b))
                     (and (= (cadr a) (cadr b))
                          (> (contar-coincidencias a historial-respuestas)
                             (contar-coincidencias b historial-respuestas))))))))
    (list (car ordenados)
          (if (> (length ordenados) 1) (cadr ordenados) (list 'nadie -inf.0 '())))))

; umbral-cf: CF minimo del candidato lider para animarse a predecir (0.6 = valor
; estandar de MYCIN para considerar una hipotesis "confirmada").
(define umbral-cf 0.6)
; margen-minimo: separacion minima entre el CF del 1ro y el del 2do para evitar
; predicciones apresuradas en un casi-empate.
(define margen-minimo 0.15)

; inferir: decide si ya se puede predecir o si hay que seguir preguntando,
; usando directamente el CF combinado como confianza (no hace falta normalizar).
; La separacion exigida es o bien un margen de CF real (> margen-minimo), o
; bien -cuando el CF esta practicamente empatado por saturacion, algo comun
; cuando varios candidatos comparten los rasgos generales preguntados primero-
; que el lider (que `mejores-dos` ya garantiza con CF >= al del segundo) tenga
; estrictamente mas coincidencias reales con el historial que el segundo.
(define (inferir candidatos historial-respuestas)
  (let* ((top2 (mejores-dos candidatos historial-respuestas))
         (lider (car top2)) (segundo (cadr top2))
         (cf1 (cadr lider)) (cf2 (cadr segundo)))
    (if (and (>= cf1 umbral-cf)
             (or (> (- cf1 cf2) margen-minimo)
                 (> (contar-coincidencias lider historial-respuestas)
                    (contar-coincidencias segundo historial-respuestas))))
        (list 'prediccion (car lider) cf1)
        (list 'continuar cf1))))

;; reiniciar: vuelve a poner el juego en su estado inicial
(define (reiniciar) (cargar-conocimiento))

; PARTE 12: SELECCION INTELIGENTE DE PREGUNTAS

; todas las caracteristicas presentes en los candidatos actuales, sin duplicados
(define (todas-las-caracteristicas candidatos)
  (remove-duplicates
   (foldl (lambda (c acc) (append acc (map car (caddr c)))) '() candidatos)))

; cuenta cuantos candidatos tienen 'si (n-si) contra el resto -no o desconocido- (n-resto)
; para una caracteristica dada
(define (contar-particion caracteristica candidatos)
  (let* ((valores (map (lambda (c) (valor-de caracteristica (caddr c))) candidatos))
         (n-si (length (filter (lambda (v) (equal? v 'si)) valores))))
    (cons n-si (- (length candidatos) n-si))))

; puntaje de discriminacion = tamano del lado mas chico de la particion.
; mientras mas alto, mas pareja es la particion => mejor pregunta (heuristica
; de balance de particiones sugerida en el enunciado)
(define (puntaje-discriminacion caracteristica candidatos)
  (let ((particion (contar-particion caracteristica candidatos)))
    (min (car particion) (cdr particion))))

; seleccionar-pregunta: elige la caracteristica no preguntada aun que mejor
; discrimina entre los candidatos restantes. Devuelve #f si no queda ninguna.
(define (seleccionar-pregunta candidatos preguntas-realizadas)
  (let* ((disponibles (filter (lambda (c) (not (member c preguntas-realizadas)))
                               (todas-las-caracteristicas candidatos)))
         (con-puntaje (map (lambda (c) (cons c (puntaje-discriminacion c candidatos))) disponibles)))
    (if (null? con-puntaje)
        #f
        (car (argmax cdr con-puntaje)))))

; simular-partida: motor de juego reutilizable por la demo y por los tests.
; respuestas-usuario: lista de (caracteristica . simbolo-respuesta), en el orden
; en que el usuario decide responder para esta prueba. Caracteristicas no
; cubiertas por respuestas-usuario se contestan "no-se" automaticamente.
; Devuelve (list resultado historial preguntas) donde resultado es lo que
; devuelve `inferir` en la ultima ronda ('prediccion nombre cf) o ('continuar cf).
(define (simular-partida respuestas-usuario #:max-preguntas [max-preguntas 40])
  (let loop ((candidatos (cargar-conocimiento))
             (historial '())
             (preguntas '())
             (pendientes respuestas-usuario)
             (n 0))
    (define resultado (inferir candidatos historial))
    (cond
      ((eq? (car resultado) 'prediccion) (list resultado historial preguntas))
      ((>= n max-preguntas) (list resultado historial preguntas))
      (else
       (define siguiente (seleccionar-pregunta candidatos preguntas))
       (cond
         ((not siguiente) (list resultado historial preguntas))
         (else
          (define respuesta (assoc siguiente pendientes))
          (define simbolo-respuesta (if respuesta (cdr respuesta) 'no-se))
          (define cf-respuesta (respuesta->peso simbolo-respuesta))
          (loop (filtrar-candidatos candidatos siguiente cf-respuesta simbolo-respuesta)
                (if (equal? simbolo-respuesta 'no-se)
                    historial
                    (cons (cons siguiente cf-respuesta) historial))
                (cons siguiente preguntas)
                (if respuesta (remove respuesta pendientes) pendientes)
                (+ n 1))))))))

; DEMOSTRACION: una partida simulada de principio a fin (pensando en "tigre")
(module+ main
  (define resultado
    (simular-partida (list (cons 'mamifero 'si) (cons 'domestico 'no) (cons 'salvaje 'si)
                            (cons 'carnivoro 'si) (cons 'grande 'si) (cons 'vive-en-sabana 'no)
                            (cons 'vive-en-selva 'si) (cons 'nocturno 'si) (cons 'rapido 'si))))
  (printf "=== PARTIDA DE PRUEBA: el usuario esta pensando en TIGRE ===\n")
  (match-define (list veredicto historial preguntas) resultado)
  (printf "Preguntas realizadas (~a): ~a\n" (length preguntas) (reverse preguntas))
  (cond
    ((eq? (car veredicto) 'prediccion)
     (printf "\n=> PREDICCION: ~a (CF ~a, ~a% de certeza)\n"
             (cadr veredicto) (caddr veredicto) (round (* 100 (caddr veredicto))))
     (printf "=> EXPLICACION: ~a\n"
             (explicar (assoc (cadr veredicto) (cargar-conocimiento)) historial)))
    (else (printf "\n=> Sin prediccion suficientemente segura (CF ~a)\n" (cadr veredicto)))))
