#lang racket

(define system-object-ref
  '(classref (nameref System) (nameref Object)))

(define racket-env-ref
  '(classref (nameref Racket) (nameref Environment)))

(define racket-env-def
  '(classdef (nameref Racket) (nameref Environment)))

(define (racket-env-add-field name)
   (begin
     (set! racket-env-def
           (append racket-env-def
                   (quasiquote 
                    ((fielddef
                      (nameref (unquote name))
                      (unquote system-object-ref))))))
     (set! racket-env-fields
           (cons name racket-env-fields))))

(define (racket-env-add-method name parameters code)
  (set! racket-env-def
        (append racket-env-def
                (quasiquote 
                 ((methoddef
                   (nameref (unquote name))
                   (unquote (append '(methodspec)
                                    (map
                                     (lambda (parameter)
                                       (quasiquote
                                        ((unquote parameter)
                                         (unquote system-object-ref))))
                                     parameters)))
                   (unquote (append '(methodbody)
                                    (begin
                                      (set! racket-env-parameters parameters)
                                      (compile-expr code))
                                    (begin                                      
                                      (set! racket-env-parameters null)
                                      '((ret)))))))))))

(define racket-env-fields null)
(define racket-env-parameters null)
(define racket-env-ifs 0)

(define (compile-expr expr)
  (cond ((boolean? expr) (compile-boolean expr))
        ((number? expr) (compile-number expr))
        ((string? expr) (compile-string expr))
        ((symbol? expr) (compile-symbol expr))
        ((pair? expr) (compile-pair expr))
        (#t (error "unknown syntax:" expr))))

(define (compile-boolean expr)
  (if expr
      (quote ((ldc.i4 1)))
      (quote ((ldc.i4 0)))))

(define (compile-number expr)
  (if (exact-integer? expr)
      (compile-integer expr)
      (if (real? expr)
          (compile-real expr)
          (error "unsupported number type:" expr))))

(define (compile-integer expr)
  (if (and (>= expr -2147483648)
           (<= expr +2147483647))
      (quasiquote ((ldc.i4 (unquote expr))))
      (if (and (>= expr -9223372036854775808)
               (<= expr +9223372036854775807))
          (quasiquote ((ldc.i8 (unquote expr))))
          (error "cannot encode on 64 bits:" expr))))

(define (compile-real expr)
  (if (and (>= expr (* -3.4 (expt 10 38)))
           (<= expr (* +3.4 (expt 10 38))))
      (quasiquote ((ldc.r4 (unquote expr))))
      (if (or (and (>= expr (* +5.0 (expt 10 -324)))
                   (<= expr (* +1.7 (expt 10 +308))))
              (and (<= expr (* -5.0 (expt 10 -324)))
                   (>= expr (* -1.7 (expt 10 +308)))))
          (quasiquote ((ldc.r8 (unquote expr))))
          (error "cannot encode on 64 bits:" expr))))

(define (compile-string expr)
  (quasiquote ((ldstr (unquote expr)))))

(define (compile-symbol expr)
  (if (contains? racket-env-parameters
                 expr)
      (quasiquote ((ldarg (unquote expr))))
      (quasiquote
       ((ldsfld (fieldref
                 (nameref (unquote expr))
                 (unquote racket-env-ref)
                 (unquote system-object-ref)))))))

(define (compile-pair expr)
  (case (car expr)
    ('define (compile-define expr))
    ('set! (compile-set! expr))
    ('if (compile-if expr))
    ('< (compile-less-than expr))
    ('> (compile-greater-than expr))
    ('<= (compile-less-eq expr))
    ('>= (compile-greater-eq expr))
    ('+ (compile-add expr))
    ('- (compile-sub expr))
    ('* (compile-mul expr))
    ('/ (compile-div expr))
    (else (compile-call expr))))

(define (compile-define expr)
  (let ((identifier (cadr expr)))
    (if (pair? identifier)
        (compile-define-lambda expr)
        (compile-define-symbol expr))))

(define (compile-define-lambda expr)
  (let ((name (caadr expr))
        (parameters (cdadr expr))
        (code (caddr expr)))
    (racket-env-add-method name parameters code)))

(define (compile-define-symbol expr)
  (let ((identifier (cadr expr))
        (code (caddr expr)))
    (begin
      (if (contains? racket-env-fields identifier) null
          (racket-env-add-field identifier))  
      (compile-set! expr))))

(define (compile-set! expr)
  (append (compile-expr (caddr expr))
          (quasiquote 
           ((stsfld (fieldref 
                     (nameref (unquote (cadr expr)))
                     (unquote racket-env-ref)
                     (unquote system-object-ref)))))))

(define (compile-call expr )
  (append (apply append
                 (map (lambda (parameter) (compile-expr parameter))
                      (cdr expr)))
          (quasiquote
           ((call (methodref
                   (nameref (unquote (car expr)))
                   (unquote racket-env-ref)
                   (methodspec (unquote system-object-ref))))))))

(define (compile-if expr)
  (begin
    (set! racket-env-ifs (+ racket-env-ifs 2))
    (append (compile-expr (cadr expr))
            (compile-expr #t)
            (quasiquote ((beq (labelref (unquote racket-env-ifs)))))
            (compile-expr (cadddr expr))
            (quasiquote ((beq (labelref (unquote ( + racket-env-ifs 1))))))
            (quasiquote ((labeldef (unquote racket-env-ifs))))
            (compile-expr (caddr expr))
            (quasiquote ((labeldef (unquote (+ racket-env-ifs 1))))))))

(define (compile-less-than expr)
  (compile-binary-op (quote clt) expr))

(define (compile-greater-than expr)
  (compile-binary-op (quote cgt) expr))

(define (compile-less-eq expr)
  (compile-binary-op (quote cle) expr))

(define (compile-greater-eq expr)
  (compile-binary-op (quote cge) expr))

(define (compile-add expr)
  (compile-binary-op (quote add) expr))

(define (compile-sub expr)
  (compile-binary-op (quote sub) expr))

(define (compile-mul expr)
  (compile-binary-op (quote mul) expr))

(define (compile-div expr)
  (compile-binary-op (quote div) expr))

(define (compile-binary-op op expr)
  (append (compile-expr (cadr expr))
          (compile-expr (caddr expr))
          (quasiquote (((unquote op))))))

(define (contains? list item)
  (if (eq? list null)
      #f
      (if (eq? (car list) item)
          #t
          (contains? (cdr list) item))))
