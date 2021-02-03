(in-package "MP")

(defun cas-expander (symbol)
  (core:get-sysprop symbol 'cas-method))
(defun (setf cas-expander) (expander symbol)
  (core:put-sysprop symbol 'cas-method expander))

(defmacro cas (place old new &environment env)
  "(CAS place old new)
Atomically store NEW in PLACE if OLD matches the current value of PLACE.
Matching is as if by EQ.
Returns the previous value of PLACE; if it's EQ to OLD the swap happened.
Only the swap is atomic. Evaluation of PLACE's subforms, OLD, and NEW is
not guaranteed to be in any sense atomic with the swap, and likely won't be.
PLACE must be a CAS-able place. CAS-able places are either symbol macros,
special variables,
or accessor forms with a CAR of
SYMBOL-VALUE, SYMBOL-PLIST, SVREF, CLOS:STANDARD-INSTANCE-ACCESS, THE,
SLOT-VALUE, CLOS:SLOT-VALUE-USING-CLASS, CAR, CDR, FIRST, REST,
or macro forms that expand into CAS-able places,
or an accessor defined with DEFINE-CAS-EXPANDER.
Some CAS accessors have additional semantic constraints.
You can see their documentation with e.g. (documentation 'slot-value 'mp:cas)
This is planned to be expanded to include variables,
possibly other simple vectors, and slot accessors.
Experimental."
  (multiple-value-bind (temps values oldvar newvar cas read)
      (get-cas-expansion place env)
    (declare (ignore read))
    `(let* (,@(mapcar #'list temps values)
            (,oldvar ,old) (,newvar ,new))
       ,cas)))

(defmacro atomic-update (place update-fn &rest arguments &environment env)
  (multiple-value-bind (vars vals old new cas read)
      (get-cas-expansion place env)
    `(let* (,@(mapcar #'list vars vals)
            (,old ,read))
       (loop for ,new = (funcall ,update-fn ,@arguments ,old)
             until (eq ,old (setf ,old ,cas))
             finally (return ,new)))))

(defmacro atomic-incf (place &optional (delta 1))
  `(atomic-update ,place #'+ ,delta))

(defmacro atomic-decf (place &optional (delta 1))
  `(atomic-update ,place #'(lambda (y x) (- x y)) ,delta))

(defmacro atomic-push (item place &environment env)
  (multiple-value-bind (vars vals old new cas read)
      (get-cas-expansion place env)
    (let ((gitem (gensym "ITEM")))
      `(let* ((,gitem ,item) ; evaluate left-to-right (CLHS 5.1.1.1)
              ,@(mapcar #'list vars vals)
              (,old ,read)
              (,new (cons ,item ,old)))
         (loop until (eq ,old (setf ,old ,cas))
               do (setf (cdr ,new) ,old)
               finally (return ,new))))))

(defmacro atomic-pop (place &environment env)
  (multiple-value-bind (vars vals old new cas read)
      (get-cas-expansion place env)
    `(let* (,@(mapcar #'list vars vals)
            (,old ,read))
       (loop (let ((,new (cdr ,old)))
               (when (eq ,old (setf ,old ,cas))
                 (return (car ,old))))))))

(defmacro atomic-pushnew (item place &rest keys &key key test test-not
                          &environment env)
  (declare (ignore key test test-not))
  (multiple-value-bind (vars vals old new cas read)
      (get-cas-expansion place env)
    (let ((gitem (gensym "ITEM")) (bname (gensym "ATOMIC-PUSHNEW"))
          gkeybinds gkeys)
      ;; Ensuring CLHS 5.1.1.1 evaluation order is weird here. We'd like to
      ;; only evaluate the keys one time, but we want the adjoin to get
      ;; constant keywords the compiler transformations can work with.
      (loop for thing in keys
            if (constantp thing env)
              do (push (ext:constant-form-value thing env) gkeys)
            else
              do (let ((gkey (gensym "K")))
                   (push gkey gkeys)
                   (push `(,gkey ,thing) gkeybinds))
            finally (setf gkeys (nreverse gkeys)
                          gkeybinds (nreverse gkeybinds)))
      ;; Actual expansion
      `(let* ((,gitem ,item)
              ,@(mapcar #'list vars vals)
              ,@gkeybinds
              (,old ,read))
         (loop named ,bname
               for ,new = (adjoin ,gitem ,old ,@gkeys)
               until (eq ,old (setf ,old ,cas))
               finally (return-from ,bname ,new))))))

(defun get-cas-expansion (place &optional env)
  "Analogous to GET-SETF-EXPANSION. Returns the following six values:
* list of temporary variables, which will be bound as if by LET*
* list of forms, whose results will be bound to the variables
* variable for the old value of PLACE
* variable for the new value of PLACE
* A form to perform the swap, which can refer to the temporary variables
   and the variables for the old and new values
* A form to read a value from PLACE, which can refer to the temporary variables"
  (etypecase place
    (symbol
     ;; KLUDGE: This will not work in bclasp at all, and the cleavir interface
     ;; may not be great for this.
     #-cclasp
     (multiple-value-bind (expansion expanded)
         (macroexpand-1 place env)
       (if expanded
           (get-cas-expansion expansion env)
           (error "CAS on variables not supported yet")))
     #+cclasp
     (let ((info (cleavir-env:variable-info env place)))
       (etypecase info
         (cleavir-env:symbol-macro-info
          (get-cas-expansion (macroexpand-1 place env) env))
         (cleavir-env:special-variable-info
          (get-cas-expansion `(symbol-value ',place) env))
         (cleavir-env:lexical-variable-info
          (error "CAS on lexical variable (~a) not supported yet" place)
          #+(or)
          (lexical-cas-expansion place env))
         (null
          ;; FIXME?: Could assume special
          (error "Unknown variable to CAS: ~a" place)))))
    (cons
     (let* ((name (car place))
            (expander (cas-expander name)))
       (if expander
           (funcall expander place env)
           (multiple-value-bind (expansion expanded)
               (macroexpand-1 place env)
             (if expanded
                 (get-cas-expansion expansion env)
                 (default-cas-expansion place env))))))))

#+(or)
(defun lexical-cas-expansion (var &optional env)
  ;; So: For a regular local, cas is meaningless.
  ;; We can reasonably say it succeeds, i.e.
  ;; (cas x old new) = (prog1 old (setq x new))
  ;; For a closed over variable, we could do an
  ;; actual CAS. Closures are just objects, so
  ;; I think this is even reasonable. But to
  ;; support it we kind of need a special form
  ;; so that the compiler can determine the
  ;; closed-over-ness of the variable.
  ;; ...but none of this is supported right now.
  (let ((old (gensym "OLD")) (new (gensym "NEW")))
    (values nil nil old new
            `(casq ,var ,old ,new)
            var)))

(defun default-cas-expansion (place &optional env)
  (declare (ignore env))
  (error "~a is not a supported place to CAS" place)
  #+(or)
  (let* ((op (car place)) (args (cdr place))
         (temps (loop for form in args collect (gensym)))
         (new (gensym "NEW")) (old (gensym "OLD")))
    (values temps args old new
            `(funcall #'(cas ,op) ,@temps)
            `(,op ,@temps))))

(defmacro define-cas-expander (accessor lambda-list &body body
                               &environment env)
  "Analogous to DEFINE-SETF-EXPANDER, defines a CAS expander for ACCESSOR.
The body must return the six values for GET-CAS-EXPANSION.
It is up to you the definer to ensure the swap is performed atomically.
This means you will almost certainly need Clasp's synchronization operators
(e.g., CAS on some other place).

Docstrings are accessible with doc-type MP:CAS."
  `(eval-when (:compile-toplevel :load-toplevel :execute)
     (setf (cas-expander ',accessor)
           ,(ext:parse-macro accessor lambda-list body env))
     ',accessor))

;;; Internal, but kind of like DEFSETF.
(defmacro define-simple-cas-expander (name cas-op (&rest params)
                                      &optional documentation)
  (let ((scmp (gensym "CMP")) (snew (gensym "NEW"))
        (stemps (loop repeat (length params) collect (gensym))))
    `(define-cas-expander ,name (,@params)
       ,@(when documentation (list documentation))
       (let ((,scmp (gensym "CMP")) (,snew (gensym "NEW"))
             ,@(loop for st in stemps
                     collect `(,st (gensym "TEMP"))))
         (values (list ,@stemps) (list ,@params) ,scmp ,snew
                 (list ',cas-op ,scmp ,snew ,@stemps)
                 (list ',name ,@stemps))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Particular CAS expansions
;;;

(define-cas-expander the (type place &environment env)
  "(cas (the y x) o n) = (cas x (the y o) (the y n))"
  (multiple-value-bind (vars vals old new cas read)
      (get-cas-expansion place env)
    (values vars vals old new
            `(let ((,old (the ,type ,old))
                   (,new (the ,type ,new)))
               ,cas)
            `(the ,type ,read))))

(define-simple-cas-expander symbol-value core:cas-symbol-value (symbol)
  "Because special variable bindings are always thread-local, the symbol-value
of a symbol can only be used for synchronization through this accessor if there
are no bindings (in which case the global, thread-shared value is used.")
(define-simple-cas-expander symbol-plist core:cas-symbol-plist (symbol))

(define-simple-cas-expander car core::cas-car (cons))
(define-simple-cas-expander cdr core::cas-cdr (cons))

(define-cas-expander first (cons &environment env)
  (get-cas-expansion `(car ,cons) env))
(define-cas-expander rest (cons &environment env)
  (get-cas-expansion `(cdr ,cons) env))

#+(or)
(define-cas-expander svref (vector index)
  (let ((old (gensym "OLD")) (new (gensym "NEW"))
        (itemp (gensym "INDEX"))
        (vtemp1 (gensym "VECTOR")) (vtemp2 (gensym "VECTOR")))
    (values (list vtemp1 itemp vtemp2)
            (list vector index
                  `(if (simple-vector-p ,vtemp1)
                       ,vtemp1
                       (error 'type-error :datum ,vtemp1
                                          :expected-type 'simple-vector)))
            old new
            `(core::acas ,vtemp2 ,itemp ,old ,new t t t)
            ;; Two colons is a KLUDGE to allow loading this earlier.
            `(cleavir-primop::aref ,vtemp2 ,itemp t t t))))
