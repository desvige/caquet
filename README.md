caquet
======

Racket-to-CIL compiler written in Racket. CIL is the Common Intermediate Language (ECMA 335) powering the .NET framework. The goal is to support basic features without doing any rocket science. This initial implementation outlined the issues discussed below.

### Dynamic types

Racket is dynamically typed whereas CIL is statically typed. The compiler types most things with Object, therefore boxing/unboxing will alter the efficiency of numerical operations. Type inference can partially address this issue.

### Late binding

A given function name can be dynamically bound to any lambda expression. A naive implementation would be to use CIL delegates, which are equivalent to function pointers.

### Example

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
