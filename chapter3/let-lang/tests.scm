(module tests mzscheme
  
  (provide test-list)

  ;;;;;;;;;;;;;;;; tests ;;;;;;;;;;;;;;;;
  
  (define test-list
    '(
  
      ;; simple arithmetic
      (positive-const "11" 11)
      (negative-const "-33" -33)
      (simple-arith-1 "-(44,33)" 11)
      (simple-arith-2 "+(1,2)" 3)
      (simple-arith-3 "*(-9,11)" -99)
      (simple-arith-4 "quot(10,5)" 2)
      (simple-arith-5 "quot(4,5)" 0)
  
      ;; arith with minus
      (arith-with-minus "-(minus(5),minus(10))" 5)
      (arith-with-nested-minus "minus(-(5,minus(10)))" -15)

      ;; nested arithmetic
      (nested-arith-left "-(-(44,33),22)" -11)
      (nested-arith-right "-(55, -(22,11))" 44)
      (nested-arith-1 "-(55, +(22,11))" 22)
      (nested-arith-2 "-(minus(55), +(22,11))" -88)
      (nested-arith-3 "*(-(55,50), +(2,2))" 20)
      (nested-arith-4 "quot(-(5,20), +(2,2))" -3)
  
      ;; simple variables
      (test-var-1 "x" 10)
      (test-var-2 "-(x,1)" 9)
      (test-var-3 "-(1,x)" -9)
      
      ;; simple unbound variables
      (test-unbound-var-1 "foo" error)
      (test-unbound-var-2 "-(x,foo)" error)
  
      ;; simple conditionals
      (if-true "if zero?(0) then 3 else 4" 3)
      (if-false "if zero?(1) then 3 else 4" 4)
      
      ;; test equal?
      (test-equal?-1 "equal?(1, 1)" #t)
      (test-equal?-2 "equal?(1, 2)" #f)
      (test-equal?-3 "equal?(+(1,1), 2)" #t)

      ;; test greater? & less?
      (test-greater?-1 "greater?(1, 0)" #t)
      (test-greater?-2 "greater?(10, 11)" #f)
      (test-greater?-3 "greater?(10, -(11,1))" #f)
      (test-less?-1 "less?(1, 2)" #t)
      (test-less?-2 "less?(1, -1)" #f)
      (test-less?-3 "less?(1, +(-1,2))" #f)

      ;; test dynamic typechecking
      (no-bool-to-diff-1 "-(zero?(0),1)" error)
      (no-bool-to-diff-2 "-(1,zero?(0))" error)
      (no-int-to-if "if 1 then 2 else 3" error)

      ;; make sure that the test and both arms get evaluated
      ;; properly. 
      (if-eval-test-true "if zero?(-(11,11)) then 3 else 4" 3)
      (if-eval-test-false "if zero?(-(11, 12)) then 3 else 4" 4)
      
      ;; and make sure the other arm doesn't get evaluated.
      (if-eval-test-true-2 "if zero?(-(11, 11)) then 3 else foo" 3)
      (if-eval-test-false-2 "if zero?(-(11,12)) then foo else 4" 4)

      ;; simple let
      (simple-let-1 "let x = 3 in x" 3)

      ;; make sure the body and rhs get evaluated
      (eval-let-body "let x = 3 in -(x,1)" 2)
      (eval-let-rhs "let x = -(4,1) in -(x,1)" 2)

      ;; check nested let and shadowing
      (simple-nested-let "let x = 3 in let y = 4 in -(x,y)" -1)
      (check-shadowing-in-body "let x = 3 in let x = 4 in x" 4)
      (check-shadowing-in-rhs "let x = 3 in let x = -(x,1) in x" 2)

      ;; test list operations
      (test-emptylist "emptylist" ())
      (test-null?-t "null?(emptylist)" #t)
      
      (test-cons-1 "cons(1,emptylist)" (1))
      (test-cons-2 "cons(1,cons(2,emptylist))" (1 2))
      (test-cons-3 "cons(cons(1,emptylist),cons(2,emptylist))" ((1) 2))
      (test-cons-4 "cons(cons(1,emptylist),cons(cons(2,emptylist),emptylist))" ((1) (2)))
      (test-cons-5 "cons(zero?(1),emptylist)" (#f))

      (test-null?-f "null?(cons(1,emptylist))" #f)

      (test-car-1 "car(cons(1,emptylist))" 1)
      (test-car-2 "car(cons(zero?(0),emptylist))" #t)
      (test-car-3 "car(cons(cons(1,emptylist),emptylist))" (1))

      (test-cdr-1 "cdr(cons(1,emptylist))" ())
      (test-cdr-2 "cdr(cons(1,cons(2,emptylist)))" (2))

      ))
  )
