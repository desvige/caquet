caquet
======

Racket-to-CIL compiler. This prototype outlined the challenges below.

### Dynamic types

Racket is dynamically typed and CIL is statically typed. Caquet does not infer types yet, so most things are considered as Object in the target CIL code. That leads to poor numerical performance.

### Late binding

In Racket, during run-time, any function name can be dynamically bound to any lambda expression. This is not supported yet in Caquet. Generating CIL delegates (function pointers) might be a solution to support this feature.

### Usage

    > (compile-expr '(define (fact n) (if (< n 2) 1 (* n (fact (- n 1))))))

    > racket-env-def
    '(classdef
      (nameref Racket)
      (nameref Environment)
      (methoddef
       (nameref fact)
       (methodspec (n (classref (nameref System) (nameref Object))))
       (methodbody
        (ldarg n)
        (ldc.i4 2)
        (clt)
        (ldc.i4 1)
        (beq (labelref 2))
        (ldarg n)
        (ldarg n)
        (ldc.i4 1)
        (sub)
        (call
         (methodref
          (nameref fact)
          (classref (nameref Racket) (nameref Environment))
          (methodspec (classref (nameref System) (nameref Object)))))
        (mul)
        (beq (labelref 3))
        (labeldef 2)
        (ldc.i4 1)
        (labeldef 3)
        (ret))))
