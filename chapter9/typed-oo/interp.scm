(module interp (lib "eopl.ss" "eopl")
  
  (require "drscheme-init.scm")

  (require "lang.scm")
  (require "data-structures.scm")
  (require "environments.scm")
  (require "store.scm")
  (require "classes.scm")
  
  (provide value-of-program value-of instrument-let instrument-newref)

;;;;;;;;;;;;;;;; switches for instrument-let ;;;;;;;;;;;;;;;;

  (define instrument-let (make-parameter #f))

  ;; say (instrument-let #t) to turn instrumentation on.
  ;;     (instrument-let #f) to turn it off again.

;;;;;;;;;;;;;;;; the interpreter ;;;;;;;;;;;;;;;;

  ;; value-of-program : Program -> ExpVal
  ;; Page: 336
  (define value-of-program 
    (lambda (pgm)
      (initialize-store!)             
      (cases program pgm
        (a-program (class-decls body)
          (initialize-class-env! class-decls)
          (value-of body (init-env))))))

  ;; value-of : Exp * Env -> ExpVal
  ;; Page: 356
  (define value-of
    (lambda (exp env)
      (cases expression exp

        (const-exp (num) (num-val num))

        (var-exp (var) (deref (apply-env env var)))

        (diff-exp (exp1 exp2)
          (let ((val1
		  (expval->num
		    (value-of exp1 env)))
                (val2
		  (expval->num
		    (value-of exp2 env))))
            (num-val
	      (- val1 val2))))
        
        (sum-exp (exp1 exp2)
          (let ((val1
		  (expval->num
		    (value-of exp1 env)))
                (val2
		  (expval->num
		    (value-of exp2 env))))
            (num-val
	      (+ val1 val2))))

        (zero?-exp (exp1)
	  (let ((val1 (expval->num (value-of exp1 env))))
	    (if (zero? val1)
	      (bool-val #t)
	      (bool-val #f))))

        (if-exp (exp0 exp1 exp2) 
          (if (expval->bool (value-of exp0 env))
            (value-of exp1 env)
            (value-of exp2 env)))

        (let-exp (vars exps body)       
	  (when (instrument-let)
	    (eopl:printf "entering let ~s~%" vars))
          (let ((new-env 
                  (extend-env 
                    vars
                    (map newref (values-of-exps exps env))
                    env)))
            (when (instrument-let)
              (begin
                (eopl:printf "entering body of let ~s with env =~%" vars)
                (pretty-print (env->list new-env))
                (eopl:printf "store =~%")
                (pretty-print (store->readable (get-store-as-list)))
                (eopl:printf "~%")
                ))
            (value-of body new-env)))

        (proc-exp (bvars types body)
	  (proc-val
	    (procedure bvars body env)))

        (call-exp (rator rands)          
          (let ((proc (expval->proc (value-of rator env)))
                (args (values-of-exps rands env)))
	    (apply-procedure proc args)))

        (letrec-exp (result-types p-names b-varss b-vartypess p-bodies letrec-body)
          (value-of letrec-body
            (extend-env-rec** p-names b-varss p-bodies env)))

        (begin-exp (exp1 exps)
          (letrec 
            ((value-of-begins
               (lambda (e1 es)
                 (let ((v1 (value-of e1 env)))
                   (if (null? es)
                     v1
                     (value-of-begins (car es) (cdr es)))))))
            (value-of-begins exp1 exps)))

        (assign-exp (x e)
          (begin
            (setref!
              (apply-env env x)
              (value-of e env))
            (num-val 27)))

        ;; args need to be non-empty for type checker
        (list-exp (exp exps)
          (list-val
            (cons (value-of exp env)
              (values-of-exps exps env))))

        (new-object-exp (class-name rands)
          (let ((args (values-of-exps rands env))
                (obj (new-object class-name)))
            (apply-method
              (find-method class-name 'initialize)
              obj
              args)
            obj))

        (self-exp ()
          (apply-env env '%self))

        (method-call-exp (obj-exp method-name rands)
          (let ((args (values-of-exps rands env))
                (obj (value-of obj-exp env)))
            (apply-method
              (find-method (object->class-name obj) method-name)
              obj
              args)))

        (super-call-exp (method-name rands)
          (let ((args (values-of-exps rands env))
                (obj (apply-env env '%self)))
            (apply-method
              (find-method (apply-env env '%super) method-name)
              obj
              args)))

        ;; new cases for typed-oo

        (cast-exp (exp c-name)
          (let ((obj (value-of exp env)))
            (if (is-subclass? (object->class-name obj) c-name)
              obj
              (report-cast-error c-name obj))))

        (instanceof-exp (exp c-name)
          (let ((obj (value-of exp env)))
            (if (is-subclass? (object->class-name obj) c-name)
              (bool-val #t)
              (bool-val #f))))

        )))

  (define report-cast-error
    (lambda (c-name obj)
      (eopl:error 'value-of "Can't cast object to type ~s:~%~s" c-name obj)))

  ;; apply-procedure : Proc * Listof(ExpVal) -> ExpVal
  (define apply-procedure
    (lambda (proc1 args)
      (cases proc proc1
        (procedure (vars body saved-env)
          (let ((new-env
                  (extend-env
                    vars
                    (map newref args)
                    saved-env)))
            (when (instrument-let)
              (begin
                (eopl:printf
                  "entering body of proc ~s with env =~%"
                  vars)
                (pretty-print (env->list new-env)) 
                (eopl:printf "store =~%")
                (pretty-print (store->readable (get-store-as-list)))
                (eopl:printf "~%")))
            (value-of body new-env))))))
  
  ;; apply-method : Method * Obj * Listof(ExpVal) -> ExpVal
  (define apply-method                    
    (lambda (m self args)
      (cases method m
        (a-method (vars body super-name field-names)
          (value-of body
            (extend-env vars (map newref args)
              (extend-env-with-self-and-super
                self super-name
                (extend-env field-names (object->fields self)
                  (empty-env)))))))))
  ;; exercise: add instrumentation to apply-method, like that for
  ;; apply-procedure. 

  (define values-of-exps
    (lambda (exps env)
      (map
        (lambda (exp) (value-of exp env))
        exps)))

  ;; is-subclass? : ClassName * ClassName -> Bool
  ;; Page: 357
  (define is-subclass?
    (lambda (c-name1 c-name2)
      (if (eqv? c-name1 c-name2)
        #t
        (let ((s-name (class->super-name (lookup-class c-name1))))
          (if s-name
            (is-subclass? s-name c-name2)
            #f)))))

  ;; store->readable : Listof(List(Ref,Expval)) 
  ;;                    -> Listof(List(Ref,Something-Readable))
  (define store->readable
    (lambda (l)
      (map
        (lambda (p)
          (cons
            (car p)
            (expval->printable (cadr p))))
        l)))
       
  )
  


  
