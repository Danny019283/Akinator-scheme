#lang racket

; Cubre los puntos 8, 9, 10, 11 y 12 del enunciado del proyecto.
; PARTE 8: DOMINIO Y BASE DE CONOCIMIENTO

; Representacion dispersa: cada entidad solo lista los rasgos que le aplican
; (formato del ejemplo del enunciado). 30 animales, 25 caracteristicas
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
    (cocodrilo   (reptil si)(salvaje si)(carnivoro si)(tyiene-escamas si)(grande si)(vive-en-agua si)(tiene-cola si)(nada si))
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


; PARTE 9: HECHOS Y REGLAS
; hecho  = (caracteristica valor)
; regla  = (antecedentes . consecuente)  donde antecedentes es una lista de
;hechos que deben cumplirse todos, y consecuente es el hecho nuevo
; a derivar. Agregar una entidad NUNCA obliga a tocar el motor ni
;  las reglas: basta con añadir su entrada a `conocimiento`.

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



; PARTE 10: MOTOR DE INFERENCIA
; candidato = (nombre puntaje hechos)   -- hechos ya enriquecidos por las reglas
; cargar-conocimiento: candidatos iniciales, puntaje 0, reglas ya aplicadas
(define (cargar-conocimiento)
  (map (lambda (entidad) (list (car entidad) 0.0 (aplicar-reglas (cdr entidad))))
       conocimiento))

; contribucion de una respuesta al puntaje de UN candidato, segun su hecho real
(define (contribucion valor-candidato peso-respuesta)
  (cond ((equal? valor-candidato 'si) peso-respuesta)
        ((equal? valor-candidato 'no) (- peso-respuesta))
        (else 0)))   ; rasgo no definido para esa entidad: neutral, no se penaliza (caso "No se")

; filtrar-candidatos: recalcula el puntaje de todos los candidatos tras una respuesta
(define (filtrar-candidatos candidatos caracteristica peso-respuesta)
  (map (lambda (c)
         (let* ((hechos (caddr c))
                (valor (valor-de caracteristica hechos)))
           (list (car c) (+ (cadr c) (contribucion valor peso-respuesta)) hechos)))
       candidatos))

; calcular-confianza: normaliza el puntaje del mejor candidato contra la suma
; de los pesos realmente informativos aplicados hasta el momento (el "maximo
; puntaje posible" dado lo respondido). Las respuestas "No se" pesan 0, por lo
; que no diluyen la confianza aunque se sigan haciendo preguntas.
(define (calcular-confianza candidatos historial-pesos)
  (let ((maximo-posible (apply + (map abs historial-pesos))))
    (if (or (null? candidatos) (= maximo-posible 0))
        0.0
        (max 0.0 (min 1.0 (/ (apply max (map cadr candidatos)) maximo-posible))))))

; obtiene los dos candidatos con mayor puntaje (para exigir separacion entre 1ro y 2do)
(define (mejores-dos candidatos)
  (let ((ordenados (sort candidatos > #:key cadr)))
    (list (car ordenados)
          (if (> (length ordenados) 1) (cadr ordenados) (list 'nadie -inf.0 '())))))

; inferir: decide si ya se puede predecir o si hay que seguir preguntando
(define (inferir candidatos historial-pesos umbral-confianza)
  (let* ((top2 (mejores-dos candidatos))
         (confianza (calcular-confianza candidatos historial-pesos)))
    (if (and (>= confianza umbral-confianza)
             (> (- (cadr (car top2)) (cadr (cadr top2))) 0))
        (list 'prediccion (car (car top2)) confianza)
        (list 'continuar confianza))))

; explicar: de todo el historial de respuestas, cuales coinciden con los
; hechos reales del candidato ganador (esas son las que mas influyeron)
(define (explicar candidato-ganador historial-respuestas)
  (filter (lambda (r)
            (equal? (valor-de (car r) (caddr candidato-ganador))
                    (if (> (cdr r) 0) 'si 'no)))
          historial-respuestas))

;; reiniciar: vuelve a poner el juego en su estado inicial
(define (reiniciar) (cargar-conocimiento))

; PARTE 11: RESPUESTAS Y MANEJO DE INCERTIDUMBRE

(define pesos-respuesta
  '((si . 1.0)
    (probablemente . 0.7)
    (no-se . 0.0)
    (probablemente-no . -0.7)
    (no . -1.0)))

(define (respuesta->peso simbolo-respuesta)
  (let ((par (assoc simbolo-respuesta pesos-respuesta)))
    (if par (cdr par)
        (error 'respuesta->peso "respuesta invalida: ~a" simbolo-respuesta))))



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



; DEMOSTRACION: una partida simulada de principio a fin (pensando en "tigre")

(module+ main
  (define (jugar respuestas-usuario)
    ; respuestas-usuario: lista de (caracteristica . simbolo-respuesta), en el
    ; orden en que el usuario decide responder para esta prueba
    (let loop ((candidatos (cargar-conocimiento))
               (historial '())
               (preguntas '())
               (pendientes respuestas-usuario)
               (n 0))
      (define resultado (inferir candidatos (map cdr historial) 0.55))
      (cond
        ((eq? (car resultado) 'prediccion)
         (printf "\n=> PREDICCION: ~a (confianza ~a%)\n"
                 (cadr resultado) (round (* 100 (caddr resultado))))
         (printf "=> EXPLICACION: ~a\n"
                 (explicar (assoc (cadr resultado) candidatos) historial)))
        (else
         (define siguiente (seleccionar-pregunta candidatos preguntas))
         (define respuesta (assoc siguiente pendientes))
         ; si la prueba no programo una respuesta para esta caracteristica,
         ; se contesta "no-se" 
         (define simbolo-respuesta (if respuesta (cdr respuesta) 'no-se))
         (cond
           ((not siguiente) (printf "\n=> Sin mas preguntas posibles.\n"))
           (else
            (define peso (respuesta->peso simbolo-respuesta))
            (printf "Pregunta ~a: es-~a? -> usuario responde: ~a\n" (+ n 1) siguiente simbolo-respuesta)
            (loop (filtrar-candidatos candidatos siguiente peso)
                  (cons (cons siguiente peso) historial)
                  (cons siguiente preguntas)
                  (if respuesta (remove respuesta pendientes) pendientes)
                  (+ n 1))))))))

  (printf "=== PARTIDA DE PRUEBA: el usuario esta pensando en TIGRE ===\n")
  (jugar (list (cons 'mamifero 'si) (cons 'domestico 'no) (cons 'salvaje 'si)
               (cons 'carnivoro 'si) (cons 'grande 'si) (cons 'vive-en-sabana 'no)
               (cons 'vive-en-selva 'si) (cons 'nocturno 'si) (cons 'rapido 'si))))