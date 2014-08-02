#lang racket

(classdef (nameref System) (nameref Object))

(classdef (nameref Racket) (nameref List)
          (fielddef (nameref Head)
                    (classref (nameref System) (nameref Object)))
          (fielddef (nameref Queue)
                    (classref (nameref Racket) (nameref List))))
