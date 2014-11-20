caquet
======

Racket-to-CIL compiler written in Racket. CIL is the Common Intermediate Language (ECMA 335) powering the .NET framework. The goal is to support basic features without doing any rocket science. The initial implementation outlined some issues:

- Dynamic types. Racket is dynamically typed whereas CIL is statically typed. The compiler types most things with Object, therefore boxing/unboxing will alter the efficiency of functions manipulating numbers. Type inference can partially address this issue.

- Late binding. A given function name can be dynamically bound to any lambda expression. A naive implementation would be to use CIL delegates, which are equivalent to function pointers.
