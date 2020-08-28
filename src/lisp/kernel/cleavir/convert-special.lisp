(in-package :cc-generate-ast)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Define a "macro" for the Cleavir compiler.
;;; This shouldn't be necessary, but I'd like to
;;; avoid overwriting any bclasp definitions.
;;; Don't use &environment or &whole.

#-cst
(defmacro def-ast-macro (name lambda-list &body body)
  (let ((head (gensym "HEAD"))
        (form (gensym "FORM"))
        (environment (gensym "ENVIRONMENT"))
        (system (gensym "SYSTEM")))
    `(defmethod cleavir-generate-ast:convert-special
         ((,head (eql ',name)) ,form ,environment (,system clasp-cleavir:clasp))
       (cleavir-generate-ast:convert
        (destructuring-bind ,lambda-list (rest ,form) ,@body)
        ,environment ,system))))

#+cst
(defmacro def-cst-macro (name lambda-list &body body)
  (let ((head (gensym "HEAD"))
        (cst (gensym "CST"))
        (environment (gensym "ENVIRONMENT"))
        (system (gensym "SYSTEM")))
    `(defmethod cleavir-cst-to-ast:convert-special
         ((,head (eql ',name)) ,cst ,environment (,system clasp-cleavir:clasp))
       (cleavir-cst-to-ast:convert
        (destructuring-bind ,lambda-list (cst:raw (cst:rest ,cst))
          (cst:reconstruct (progn ,@body) ,cst ,system))
        ,environment ,system))))

(defmacro def-convert-macro (name lambda-list &body body)
  `(progn #-cst(def-ast-macro ,name ,lambda-list ,@body)
          #+cst(def-cst-macro ,name ,lambda-list ,@body)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Define how to convert a special form that's "functionlike".
;;; This means it evaluates all its arguments normally, and
;;; left to right.
;;; NAME is the operator. AST is the name of the AST class.
;;; INITARGS is a list of initargs to make-instance that class.

(defmacro define-functionlike-special-form (name ast (&rest initargs))
  (let ((nargs (length initargs))
        (syms (loop for i in initargs collect (gensym (symbol-name i)))))
    `(progn
       #-cst
       (defmethod cleavir-generate-ast:convert-special
           ((head (eql ',name)) form env (system clasp-cleavir:clasp))
         (destructuring-bind (,@syms) (rest form)
           (make-instance
            ',ast
            ,@(loop for i in initargs
                    for s in syms
                    collect i
                    collect `(cleavir-generate-ast:convert ,s env system)))))
       #+cst
       (defmethod cleavir-cst-to-ast:convert-special
           ((head (eql ',name)) cst env (system clasp-cleavir:clasp))
         (cst:db origin (op ,@syms) cst
           (declare (ignore op))
           (make-instance
            ',ast
            ,@(loop for i in initargs
                    for s in syms
                    collect i
                    collect `(cleavir-cst-to-ast:convert ,s env system))
            :origin origin)))
       #-cst
       (defmethod cleavir-generate-ast:check-special-form-syntax
           ((head (eql ',name)) form)
         (cleavir-code-utilities:check-form-proper-list form)
         (cleavir-code-utilities:check-argcount form ,nargs ,nargs)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting MULTIPLE-VALUE-CALL.
;;;
;;; In the case where there is one multiple-value form this gets converted
;;; into a multiple-value-call-ast.  In the general case with multiple forms
;;; it gets converted into a function call to CORE:MULTIPLE-VALUE-FUNCALL.
;;;

(def-convert-macro multiple-value-call (function-form &rest forms)
  ;;; Technically we could convert the 0-forms case to FUNCALL, but it's
  ;;; probably not a big deal.
  (if (eql (length forms) 1)
      `(cleavir-primop:multiple-value-call (core:coerce-fdesignator ,function-form) ,@forms)
      `(core:multiple-value-funcall
        (core:coerce-fdesignator ,function-form)
        ,@(mapcar (lambda (x)
                    `#'(lambda ()
                         (declare (core:lambda-name core::mvc-argument-lambda))
                         (progn ,x)))
                  forms))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Dealing with type checks.

;;; Convert a type spec to something acceptable to typep.
;;; Which just means reducing (function ...) to function.
;;; TODO: Move to cleavir?
(defun discrimination-type (ctype)
  (etypecase ctype
    ((or symbol class) ctype)
    (cons
     (case (first ctype)
       ((function) 'function)
       ((and complex cons not or)
        `(,(first ctype)
          ,@(mapcar #'discrimination-type (rest ctype))))
       (t ctype)))))

(defmethod cleavir-cst-to-ast:type-wrap
    (ast ctype origin env (system clasp-cleavir:clasp))
  ;; We unconditionally insert a declaration,
  ;; and insert a type check as well on high safety,
  ;; unless the type is top in which case we do nothing.
  ;; NOTE that the type check doesn't check &optional and &rest. FIXME?
  (let ((insert-type-checks
          (cleavir-policy:policy-value
           (cleavir-env:policy (cleavir-env:optimize-info env))
           'clasp-cleavir::insert-type-checks))
        (required (cleavir-ctype:required ctype system)))
    (if (or (every (lambda (ty) (cleavir-ctype:top-p ty system)) required)
            (null required)) ; nothing to check/top type
        ;; We don't even generate an m-v-extract, because while semantically
        ;; meaningless, saving and loading values constantly slows things down
        ;; very hard.
        ast
        (cleavir-cst-to-ast:convert
         (cst:cst-from-expression
          (let ((vars (loop repeat (length required) collect (gensym "CHECKED"))))
            `(cleavir-primop:let-uninitialized (,@vars)
               (cleavir-primop:multiple-value-extract (,@vars)
                 (cleavir-primop:ast ,ast)
                 ,@(loop for var in vars
                         for ty in required
                         unless (cleavir-ctype:top-p ty system)
                           collect (if insert-type-checks
                                       `(if (cleavir-primop:typew
                                             ,var ,ty
                                             (typep ,var ',(discrimination-type ty)))
                                            nil
                                            (error 'type-error
                                                   :datum ,var
                                                   :expected-type ',ty))
                                       `(cleavir-primop:the-typew
                                         ,var ,ty
                                         (error 'type-error
                                                :datum ,var
                                                :expected-type ',ty))))))))
         env system))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting CORE:DEBUG-MESSAGE
;;;
;;; This is converted into a call to print a message
;;;
#-cst
(defmethod cleavir-generate-ast:convert-special
    ((symbol (eql 'core:debug-message)) form environment (system clasp-cleavir:clasp))
  (make-instance 'clasp-cleavir-ast:debug-message-ast :debug-message (cadr form)))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
    ((symbol (eql 'core:debug-message)) cst environment (system clasp-cleavir:clasp))
  (assert (typep (cst:raw (cst:second cst)) 'string))
  (make-instance 'clasp-cleavir-ast:debug-message-ast
                 :debug-message (cst:raw (cst:second cst))
                 :origin (cst:source cst)))

#-cst
(defmethod cleavir-generate-ast:check-special-form-syntax ((head (eql 'core:debug-message)) form)
  (cleavir-code-utilities:check-form-proper-list form)
  (cleavir-code-utilities:check-argcount form 1 1))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting CORE:DEBUG-BREAK
;;;
;;; This is converted into a call to invoke the debugger
;;;
#-cst
(defmethod cleavir-generate-ast:convert-special
    ((symbol (eql 'core:debug-break)) form environment (system clasp-cleavir:clasp))
  (make-instance 'clasp-cleavir-ast:debug-break-ast))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
    ((symbol (eql 'core:debug-break)) cst environment (system clasp-cleavir:clasp))
  (make-instance 'clasp-cleavir-ast:debug-break-ast
                 :origin (cst:source cst)))

#-cst
(defmethod cleavir-generate-ast:check-special-form-syntax ((head (eql 'core:debug-break)) form)
  (cleavir-code-utilities:check-form-proper-list form)
  (cleavir-code-utilities:check-argcount form 0 0))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting CORE:multiple-value-foreign-CALL
;;;
;;; This is converted into an intrinsic call
;;;
#-cst
(defmethod cleavir-generate-ast:convert-special
    ((symbol (eql 'core:multiple-value-foreign-call)) form environment (system clasp-cleavir:clasp))
  (assert (typep (second form) 'string))
  (make-instance 'clasp-cleavir-ast:multiple-value-foreign-call-ast
                 :function-name (second form)
                 :argument-asts (cleavir-generate-ast:convert-sequence (cddr form) environment system)))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
    ((symbol (eql 'core:multiple-value-foreign-call)) cst environment (system clasp-cleavir:clasp))
  (assert (stringp (cst:raw (cst:second cst))))
  (make-instance 'clasp-cleavir-ast:multiple-value-foreign-call-ast
                 :function-name (cst:raw (cst:second cst))
                 :argument-asts (cleavir-cst-to-ast::convert-sequence (cst:rest (cst:rest cst)) environment system)
                 :origin (cst:source cst)))

#-cst
(defmethod cleavir-generate-ast:check-special-form-syntax ((head (eql 'core:multiple-value-foreign-call)) form)
  (cleavir-code-utilities:check-form-proper-list form)
  (cleavir-code-utilities:check-argcount form 1 nil))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting CORE:FOREIGN-call
;;;
;;; This is converted into a pointer call
;;;
#-cst
(defmethod cleavir-generate-ast:convert-special
    ((symbol (eql 'core:foreign-call)) form environment (system clasp-cleavir:clasp))
                                        ;  (format t "convert-special form: ~a~%"  form)
  (assert (typep (second form) 'list))
  (assert (typep (third form) 'string))
  (make-instance 'clasp-cleavir-ast:foreign-call-ast
                 :foreign-types (second form)
                 :function-name (third form)
                 :argument-asts (cleavir-generate-ast:convert-sequence (cdddr form) environment system)))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
    ((symbol (eql 'core:foreign-call)) cst environment (system clasp-cleavir:clasp))
                                        ;  (format t "convert-special form: ~a~%"  cst)
  (assert (listp (cst:raw (cst:second cst))))
  (assert (stringp (cst:raw (cst:third cst))))
  (make-instance 'clasp-cleavir-ast:foreign-call-ast
                 :foreign-types (cst:raw (cst:second cst))
                 :function-name (cst:raw (cst:third cst))
                 :argument-asts (cleavir-cst-to-ast::convert-sequence (cst:rest (cst:rest (cst:rest cst))) environment system)
                 :origin (cst:source cst)))

#-cst
(defmethod cleavir-generate-ast:check-special-form-syntax ((head (eql 'core:foreign-call)) form)
  (cleavir-code-utilities:check-form-proper-list form)
  (cleavir-code-utilities:check-argcount form 2 nil))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting CORE:foreign-call-pointer
;;;
;;; This is converted into a pointer call
;;;
#-cst
(defmethod cleavir-generate-ast:convert-special
    ((symbol (eql 'core:foreign-call-pointer)) form environment (system clasp-cleavir:clasp))
  (assert (typep (second form) 'list))
  (make-instance 'clasp-cleavir-ast:foreign-call-pointer-ast
                 :foreign-types (second form)
                 :argument-asts (cleavir-generate-ast:convert-sequence (cddr form) environment system)))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
    ((symbol (eql 'core:foreign-call-pointer)) cst environment (system clasp-cleavir:clasp))
  (assert (listp (cst:raw (cst:second cst))))
  (make-instance 'clasp-cleavir-ast:foreign-call-pointer-ast
                 :foreign-types (cst:raw (cst:second cst))
                 :argument-asts (cleavir-cst-to-ast::convert-sequence (cst:rest (cst:rest cst)) environment system)
                 :origin (cst:source cst)))

#-cst
(defmethod cleavir-generate-ast:check-special-form-syntax ((head (eql 'core:foreign-call-pointer)) form)
  (cleavir-code-utilities:check-form-proper-list form)
  (cleavir-code-utilities:check-argcount form 2 nil))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting CORE:DEFCALLBACK
;;;
#-cst
(defmethod cleavir-generate-ast:convert-special
    ((symbol (eql 'core:defcallback)) form env (system clasp-cleavir:clasp))
  (let* ((args (butlast (rest form)))
         (lisp-callback (first (last form))))
    (make-instance 'cc-ast:defcallback-ast
                   :args args
                   :callee (cleavir-generate-ast:convert lisp-callback env system))))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
    ((symbol (eql 'core:defcallback)) form env (system clasp-cleavir:clasp))
  (cst:db origin (name convention rtype rtrans atypes atrans params placeholder lisp-callback)
      (cst:rest form)
    (let ((args (list (cst:raw name) (cst:raw convention)
                      (cst:raw rtype) (cst:raw rtrans)
                      (cst:raw atypes) (cst:raw atrans)
                      (cst:raw params) (cst:raw placeholder))))
      (make-instance 'cc-ast:defcallback-ast
                     :args args
                     :callee (cleavir-cst-to-ast:cst-to-ast lisp-callback env system)))))

#-cst
(defmethod cleavir-generate-ast:check-special-form-syntax ((head (eql 'core:defcallback)) form)
  (cleavir-code-utilities:check-form-proper-list form)
  (cleavir-code-utilities:check-argcount form 9 9)
  (destructuring-bind (name convention return-type return-translator
                       argument-types argument-translators
                       params placeholder function)
      (rest form)
    (assert (stringp name))
    (assert (keywordp convention))
    (assert (typep return-type 'llvm-sys:type))
    (assert (stringp return-translator))
    (assert (symbolp placeholder))
    (assert (and (core:proper-list-p argument-types)
                 (every (lambda (ty) (typep ty 'llvm-sys:type)) argument-types)))
    (assert (and (core:proper-list-p argument-translators)
                 (every #'stringp argument-translators)))
    (assert (and (core:proper-list-p params)
                 (every #'symbolp params)))
    #+(or)
    (assert (and (core:proper-list-p lambda-expression)
                 (>= (length lambda-expression) 2)
                 (eq (car lambda-expression) 'lambda)
                 (core:proper-list-p (second lambda-expression))))
    (assert (= (length argument-types)
               (length argument-translators)
               (length params)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Functionlikes
;;; See their AST classes for more info probably
;;;

(define-functionlike-special-form core::vector-length cc-ast:vector-length-ast
  (:vector))
(define-functionlike-special-form core::%displacement cc-ast:displacement-ast
  (:mdarray))
(define-functionlike-special-form core::%displaced-index-offset
  cc-ast:displaced-index-offset-ast
  (:mdarray))
(define-functionlike-special-form core::%array-total-size
  cc-ast:array-total-size-ast
  (:mdarray))
(define-functionlike-special-form core::%array-rank cc-ast:array-rank-ast
  (:mdarray))
(define-functionlike-special-form core::%array-dimension cc-ast:array-dimension-ast
  (:mdarray :axis))
(define-functionlike-special-form core:vaslist-pop cc-ast:vaslist-pop-ast
  (:vaslist))
(define-functionlike-special-form core:vaslist-length cc-ast:vaslist-length-ast
  (:vaslist))

(define-functionlike-special-form core::header-stamp cc-ast:header-stamp-ast (:arg))
(define-functionlike-special-form core::rack-stamp cc-ast:rack-stamp-ast (:arg))
(define-functionlike-special-form core::wrapped-stamp cc-ast:wrapped-stamp-ast (:arg))
(define-functionlike-special-form core::derivable-stamp cc-ast:derivable-stamp-ast (:arg))

(define-functionlike-special-form core:cas-car cc-ast:cas-car-ast
  (:cmp-ast :value-ast :cons-ast))
(define-functionlike-special-form core:cas-cdr cc-ast:cas-cdr-ast
  (:cmp-ast :value-ast :cons-ast))
(define-functionlike-special-form core::instance-cas cc-ast:slot-cas-ast
  (:cmp-ast :value-ast :object-ast :slot-number-ast))
(define-functionlike-special-form core:instance-rack cc-ast:instance-rack-ast
  (:object-ast))
(define-functionlike-special-form core:instance-rack-set cc-ast:instance-rack-set-ast
  (:object-ast :value-ast))
(define-functionlike-special-form core:rack-ref cc-ast:rack-read-ast
  (:object-ast :slot-number-ast))
(define-functionlike-special-form core:rack-set cc-ast:rack-write-ast
  (:object-ast :slot-number-ast :value-ast))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting CORE::ACAS
;;;

(defmethod cleavir-cst-to-ast:convert-special
    ((symbol (eql 'core::acas)) cst env (system clasp-cleavir:clasp))
  (cst:db origin (acas array index cmp value type simple-p boxed-p) cst
    (declare (ignore acas))
    (make-instance 'cc-ast:acas-ast
      :array-ast (cleavir-cst-to-ast:convert array env system)
      :index-ast (cleavir-cst-to-ast:convert index env system)
      :cmp-ast   (cleavir-cst-to-ast:convert cmp env system)
      :value-ast (cleavir-cst-to-ast:convert value env system)
      :element-type (cst:raw type)
      :simple-p (cst:raw simple-p)
      :boxed-p (cst:raw boxed-p)
      :origin origin)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting CORE::HEADER-STAMP-CASE
;;;

#-cst
(defmethod cleavir-generate-ast:convert-special
    ((symbol (eql 'core::header-stamp-case)) form env (system clasp-cleavir:clasp))
  (destructuring-bind (stamp derivable rack wrapped header) (rest form)
    (clasp-cleavir-ast:make-header-stamp-case-ast
     (cleavir-generate-ast:convert stamp env system)
     (cleavir-generate-ast:convert derivable env system)
     (cleavir-generate-ast:convert rack env system)
     (cleavir-generate-ast:convert wrapped env system)
     (cleavir-generate-ast:convert header env system))))

#-cst
(defmethod cleavir-generate-ast:check-special-form-syntax ((head (eql 'core::header-stamp-case)) form)
  (cleavir-code-utilities:check-form-proper-list form)
  (cleavir-code-utilities:check-argcount form 5 5))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
    ((symbol (eql 'core::header-stamp-case)) cst env (system clasp-cleavir:clasp))
  (cst:db origin (stamp derivable rack wrapped header) (cst:rest cst)
    (clasp-cleavir-ast:make-header-stamp-case-ast
     (cleavir-cst-to-ast:convert stamp env system)
     (cleavir-cst-to-ast:convert derivable env system)
     (cleavir-cst-to-ast:convert rack env system)
     (cleavir-cst-to-ast:convert wrapped env system)
     (cleavir-cst-to-ast:convert header env system)
     origin)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting core::local-tagbody to tagbody
;;;        and core::local-block to block
;;;

#-cst
(defmethod cleavir-generate-ast:convert-special
    ((symbol (eql 'core::local-tagbody)) form environment (system clasp-cleavir:clasp))
  (cleavir-generate-ast:convert-special 'tagbody form environment system))

#-cst
(defmethod cleavir-generate-ast:check-special-form-syntax ((head (eql 'core::local-tagbody)) form)
  (cleavir-generate-ast:check-special-form-syntax 'tagbody form))

#-cst
(defmethod cleavir-generate-ast:convert-special
    ((symbol (eql 'core::local-block)) form environment (system clasp-cleavir:clasp))
  (cleavir-generate-ast:convert-special 'block form environment system))

#-cst
(defmethod cleavir-generate-ast:check-special-form-syntax ((head (eql 'core::local-block)) form)
  (cleavir-generate-ast:check-special-form-syntax 'block form))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
    ((symbol (eql 'core::local-tagbody)) cst environment (system clasp-cleavir:clasp))
  (cleavir-cst-to-ast:convert-special 'tagbody cst environment system))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
    ((symbol (eql 'core::local-block)) cst environment (system clasp-cleavir:clasp))
  (cleavir-cst-to-ast:convert-special 'block cst environment system))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
  ((symbol (eql 'clasp-cleavir::block-sjlj))
   cst environment (system clasp-cleavir:clasp))
  (let ((r (cleavir-cst-to-ast:convert-special
            'block cst environment system)))
    (check-type r cleavir-ast:block-ast)
    (change-class r 'clasp-cleavir-ast::block-sjlj-ast)))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
  ((symbol (eql 'clasp-cleavir::return-from-sjlj))
   cst environment (system clasp-cleavir:clasp))
  (let ((r (cleavir-cst-to-ast:convert-special
            'return-from cst environment system)))
    (check-type r cleavir-ast:return-from-ast)
    (change-class r 'clasp-cleavir-ast::return-from-sjlj-ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting THROW
;;;
;;; Convert throw into a call
#-cst
(defmethod cleavir-generate-ast:convert-special
    ((symbol (eql 'cl:throw)) form environment (system clasp-cleavir:clasp))
  (destructuring-bind (tag result-form) 
      (rest form)
    ;; If I don't use a throw-ast node use the following
    #+(or)
    (cleavir-generate-ast::convert `(core:throw-function ,tag ,result-form) environment system)
    ;; If I decide to go with a throw-ast node use the following
    (clasp-cleavir-ast:make-throw-ast
     (cleavir-generate-ast::convert tag environment system)
     (cleavir-generate-ast::convert result-form environment system))))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
    ((symbol (eql 'cl:throw)) cst environment (system clasp-cleavir:clasp))
  (cst:db origin (tag result-cst) 
      (cst:rest cst)
    ;; If I don't use a throw-ast node use the following
    #+(or)
    (cleavir-cst-to-ast::convert `(core:throw-function ,tag ,result-cst) environment system)
    ;; If I decide to go with a throw-ast node use the following
    (clasp-cleavir-ast:make-throw-ast
     (cleavir-cst-to-ast:convert tag environment system)
     (cleavir-cst-to-ast:convert result-cst environment system)
     origin)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting UNWIND-PROTECT
;;;

#-cst
(defmethod cleavir-generate-ast:convert-special
    ((symbol (eql 'cl:unwind-protect)) form env (system clasp-cleavir:clasp))
  (destructuring-bind (protected &rest cleanup) (rest form)
    (make-instance 'cc-ast:unwind-protect-ast
      :body-ast (cleavir-generate-ast:convert protected env system)
      :cleanup-ast (cleavir-generate-ast:convert
                    `(lambda ()
                       (declare (core:lambda-name core::unwind-cleanup-lambda))
                       (progn ,@cleanup))
                    env system))))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
    ((symbol (eql 'cl:unwind-protect)) cst env (system clasp-cleavir:clasp))
  (cst:db origin (protected . cleanup) (cst:rest cst)
    (make-instance 'cc-ast:unwind-protect-ast
      :body-ast (cleavir-cst-to-ast:convert protected env system)
      :cleanup-ast (let ((cleanup-source (cst:source cleanup)))
                     (cleavir-cst-to-ast:convert
                      (cst:cons
                       (make-instance 'cst:atom-cst
                         :raw 'lambda :source cleanup-source)
                       (cst:cons (make-instance 'cst:atom-cst
                                   :raw nil :source cleanup-source)
                                 cleanup
                                 :source cleanup-source)
                       :source cleanup-source)
                      env system)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting CORE::BIND-VA-LIST
;;;

#-cst
(defmethod cleavir-generate-ast:convert-special
    ((symbol (eql 'core::bind-va-list)) form environment (system clasp-cleavir:clasp))
  (cleavir-generate-ast:db origin (op lambda-list va-list-form . body) form
    (declare (ignore op origin))
    (let* ((parsed-lambda-list
             (cleavir-code-utilities:parse-ordinary-lambda-list lambda-list))
           (semi-rest (cleavir-code-utilities:rest-body parsed-lambda-list))
           (rest (if (eq semi-rest :none) nil semi-rest)))
      (multiple-value-bind (declarations documentation forms)
          (cleavir-code-utilities:separate-function-body body)
        (declare (ignore documentation))
        (let* ((canonicalized-dspecs
                 (cleavir-code-utilities:canonicalize-declaration-specifiers
                  (reduce #'append (mapcar #'cdr declarations))
                  (cleavir-env:declarations environment)))
               (rest-alloc (cmp:compute-rest-alloc rest canonicalized-dspecs)))
          (multiple-value-bind (idspecs rdspecs)
              (cleavir-generate-ast::itemize-declaration-specifiers
               (cleavir-generate-ast::itemize-lambda-list parsed-lambda-list)
               canonicalized-dspecs)
            (multiple-value-bind (ast lexical-lambda-list)
                (cleavir-generate-ast::process-lambda-list
                 parsed-lambda-list idspecs
                 (cleavir-generate-ast::make-body rdspecs forms nil nil)
                 environment system)
              (cc-ast:make-bind-va-list-ast
                lexical-lambda-list
                (cleavir-generate-ast::convert va-list-form environment system)
                ast
                rest-alloc))))))))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
    ((symbol (eql 'core::bind-va-list)) cst environment (system clasp-cleavir:clasp))
  (cst:db origin (op lambda-list-cst va-list-cst . body-cst) cst
    (declare (ignore op))
    (let ((parsed-lambda-list
            (cst:parse-ordinary-lambda-list system lambda-list-cst :error-p nil)))
      (when (null parsed-lambda-list)
        (error 'cleavir-cst-to-ast::malformed-lambda-list
               :expr (cst:raw lambda-list-cst)
               :origin (cst:source lambda-list-cst)))
      (multiple-value-bind (declaration-csts documentation forms-cst)
          (cst:separate-function-body body-cst)
        (declare (ignore documentation))
        (let* ((declaration-specifiers
                 (loop for declaration-cst in declaration-csts
                       append (cdr (cst:listify declaration-cst))))
               (canonicalized-dspecs
                 (cst:canonicalize-declaration-specifiers
                  system
                  (cleavir-env:declarations environment)
                  declaration-specifiers)))
          (multiple-value-bind (idspecs rdspecs)
              (cleavir-cst-to-ast::itemize-declaration-specifiers-by-parameter-group
               (cleavir-cst-to-ast::itemize-lambda-list parsed-lambda-list)
               canonicalized-dspecs)
            (multiple-value-bind (lexical-lambda-list entries)
                (cleavir-cst-to-ast::lambda-list-from-parameter-groups
                 (cst:children parsed-lambda-list))
              (let ((ast (cleavir-cst-to-ast::process-parameter-groups
                          (cst:children parsed-lambda-list)
                          idspecs entries
                          (cleavir-cst-to-ast::make-body
                           rdspecs
                           (cleavir-cst-to-ast::cst-for-body forms-cst nil origin))
                          environment system)))
                (cc-ast:make-bind-va-list-ast
                 lexical-lambda-list
                 (cleavir-cst-to-ast::convert va-list-cst environment system)
                 ast
                 nil ; FIXME: handle rest-alloc (parse &rest from lambda list)
                 :origin origin)))))))))

#-cst
(defmethod cleavir-generate-ast:check-special-form-syntax
    ((head (eql 'core::bind-va-list)) form)
  (cleavir-code-utilities:check-form-proper-list form)
  (cleavir-code-utilities:check-argcount form 2 nil)
  (assert (cleavir-code-utilities:proper-list-p (second form))))

#-cst
(defmethod cleavir-generate-ast:convert-global-function (info global-env (system clasp-cleavir:clasp))
  (declare (ignore global-env))
  (let ((name (cleavir-env:name info)))
    (cond 
      ((and (consp name) (eq (car name) 'cl:setf))
       (clasp-cleavir-ast:make-setf-fdefinition-ast
        (cleavir-ast:make-load-time-value-ast `',(cadr name) t)))
      ((consp name)
       (error "Illegal name for function - must be (setf xxx)"))
      (t
       (cleavir-ast:make-fdefinition-ast
        (cleavir-ast:make-load-time-value-ast `',name t))))))

#+cst
(defmethod cleavir-cst-to-ast:convert-global-function-reference (cst info global-env (system clasp-cleavir:clasp))
  (declare (ignore global-env))
  (let ((name (cleavir-env:name info))
        (source (cst:source cst)))
    (cond
      ((and (consp name) (eq (car name) 'cl:setf))
       (clasp-cleavir-ast:make-setf-fdefinition-ast
        (cleavir-ast:make-load-time-value-ast `',(cadr name) t :origin source)
        :origin source))
      ((consp name)
       (error "Illegal name for function - must be (setf xxx)"))
      (t
       (cleavir-ast:make-fdefinition-ast
        (cleavir-ast:make-load-time-value-ast `',name t :origin (cst:source cst))
        :origin source)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Converting CORE:INSTANCE-REF/SET
;;;
;;; FIXME: Maybe just use the primops instead.

#-cst
(defmethod cleavir-generate-ast:convert-special
    ((symbol (eql 'core:instance-ref)) form environment (system clasp-cleavir:clasp))
  (cleavir-generate-ast:convert-special 'cleavir-primop:slot-read form environment system))

;;; the slot-read method will do this anyway.
#-cst
(defmethod cleavir-generate-ast:check-special-form-syntax
    ((head (eql 'core:instance-ref)) form))

#+cst
(defmethod cleavir-cst-to-ast:convert-special
    ((symbol (eql 'core:instance-ref)) cst environment (system clasp-cleavir:clasp))
  (cleavir-cst-to-ast:convert-special 'cleavir-primop:slot-read cst environment system))

;;; For -set it's mildly more complicated, as slot-write returns no values.
(def-convert-macro core:instance-set (instance index value)
  (let ((ig (gensym)) (ing (gensym)) (vg (gensym)))
    `(let ((,ig ,instance) (,ing ,index) (,vg ,value))
       (cleavir-primop:slot-write ,ig ,ing ,vg)
       ,vg)))

#-cst
(defmethod cleavir-generate-ast:check-special-form-syntax
    ((head (eql 'core:instance-set)) form)
  (cleavir-code-utilities:check-form-proper-list form)
  (cleavir-code-utilities:check-argcount form 3 3))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Bind special variables.
;;;

#+cst
(defmethod cleavir-cst-to-ast:convert-special-binding
    (variable-cst value-ast next-thunk env (system clasp-cleavir:clasp))
  (make-instance 'cc-ast:bind-ast
    :name-ast (cleavir-cst-to-ast:convert-constant variable-cst env system)
    :value-ast value-ast
    :body-ast (funcall next-thunk)
    :origin (cst:source variable-cst)))
