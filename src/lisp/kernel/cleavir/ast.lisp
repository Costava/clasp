(in-package :clasp-cleavir-ast)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class SETF-FDEFINITION-AST.
;;;
;;; This AST is generated from a reference to a global SETF function.

(defclass setf-fdefinition-ast (cleavir-ast:fdefinition-ast)
  ())

(defun make-setf-fdefinition-ast (name-ast &key origin)
  (make-instance 'setf-fdefinition-ast :name-ast name-ast :origin origin))

(cleavir-io:define-save-info setf-fdefinition-ast)

(defmethod cleavir-ast:map-children progn (function (ast setf-fdefinition-ast))
  (funcall function (cleavir-ast:name-ast ast)))
(defmethod cleavir-ast:children append ((ast setf-fdefinition-ast))
  (list (cleavir-ast:name-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class THROW-AST
;;;
;;; This AST is used to represent a THROW

(defclass throw-ast (cleavir-ast:ast)
  ((%tag-ast :initarg :tag-ast :reader tag-ast)
   (%result-ast :initarg :result-ast :reader result-ast)))

(defun make-throw-ast (tag-ast result-ast &optional origin)
  (make-instance 'throw-ast
    :tag-ast tag-ast
    :result-ast result-ast
    :origin origin))

(cleavir-io:define-save-info throw-ast
  (:tag-ast tag-ast)
  (:result-ast result-ast))

(defmethod cleavir-ast:map-children progn (function (ast throw-ast))
  (funcall function (tag-ast ast))
  (funcall function (result-ast ast)))
(defmethod cleavir-ast:children append ((ast throw-ast))
  (list (tag-ast ast) (result-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class DEBUG-MESSAGE-AST
;;;
;;; This AST is used to represent a debugging message inserted into the generated code.

(defclass debug-message-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%debug-message :initarg :debug-message  :accessor debug-message)))

(cleavir-io:define-save-info debug-message-ast
    (:debug-message debug-message))

(defmethod cleavir-ast-graphviz::label ((ast debug-message-ast))
  (with-output-to-string (s)
    (format s "debug-message (~a)" (debug-message ast))))

(defmethod cleavir-ast:map-children progn (function (ast debug-message-ast))
  (declare (ignore function)))
(defmethod cleavir-ast:children append ((ast debug-message-ast)) nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class DEBUG-BREAK-AST
;;;
;;; This AST is used to represent a debugging break inserted into the generated code.

(defclass debug-break-ast (cleavir-ast:no-value-ast-mixin cleavir-ast:ast)
  ())

(cleavir-io:define-save-info debug-break-ast
    ())

(defmethod cleavir-ast-graphviz::label ((ast debug-break-ast))
  (with-output-to-string (s)
    (format s "debug-break")))

(defmethod cleavir-ast:map-children progn (function (ast debug-break-ast))
  (declare (ignore function)))
(defmethod cleavir-ast:children append ((ast debug-break-ast)) nil)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class BASE-FOREIGN-CALL-AST
;;;
;;; This AST is used to represent a call to an intrinsic function inserted into the generated code.

(defclass base-foreign-call-ast (cleavir-ast:ast)
  ((%foreign-types :initarg :foreign-types :accessor foreign-types :initform nil)
   (%argument-asts :initarg :argument-asts :reader argument-asts)))

(cleavir-io:define-save-info base-foreign-call-ast
    (:foreign-types foreign-types)
    (:argument-asts argument-asts))

(defmethod cleavir-ast-graphviz::label ((ast base-foreign-call-ast))
  (with-output-to-string (s)
    (format s "base-foreign-call ~a" (foreign-types ast))))

(defmethod cleavir-ast:map-children progn (function (ast base-foreign-call-ast))
  (mapc function (argument-asts ast)))
(defmethod cleavir-ast:children append ((ast base-foreign-call-ast))
  (argument-asts ast))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class MULTIPLE-VALUE-FOREIGN-CALL-AST
;;;
;;; This AST is used to represent a call to an intrinsic function inserted into the generated code.

(defclass multiple-value-foreign-call-ast (base-foreign-call-ast)
  ((%function-name :initarg :function-name  :accessor function-name)))

(cleavir-io:define-save-info multiple-value-foreign-call-ast
    (:function-name function-name))

(defmethod cleavir-ast-graphviz::label ((ast multiple-value-foreign-call-ast))
  (with-output-to-string (s)
    (format s "multiple-value-foreign-call (~a)" (function-name ast))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class FOREIGN-call-AST
;;;
;;; This AST is used to represent a call to a named foreign function
;;;   inserted into the generated code.

(defclass foreign-call-ast (cleavir-ast:one-value-ast-mixin base-foreign-call-ast)
  ((%function-name :initarg :function-name :accessor function-name)))

(cleavir-io:define-save-info foreign-call-ast
    (:function-name function-name))

(defmethod cleavir-ast-graphviz::label ((ast foreign-call-ast))
  (with-output-to-string (s)
    (format s "foreign-call (~a)" (function-name ast))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class foreign-call-pointer-AST
;;;
;;; This AST is used to represent a call to an pointer to a function inserted into the generated code.

(defclass foreign-call-pointer-ast (cleavir-ast:one-value-ast-mixin base-foreign-call-ast)
  ())

(defmethod cleavir-ast-graphviz::label ((ast foreign-call-pointer-ast))
  (with-output-to-string (s)
    (format s "foreign-call-pointer")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class DEFCALLBACK-AST
;;;
;;; This AST is used to represent a callback definition.

(defclass defcallback-ast (cleavir-ast:no-value-ast-mixin cleavir-ast:ast)
  (;; None of these are evaluated and there's a ton of them
   ;; so why bother splitting them up
   (%args :initarg :args :reader defcallback-args)
   (%callee :initarg :callee :reader cleavir-ast:callee-ast)))

(defmethod cleavir-ast:map-children progn (function (ast defcallback-ast))
  (funcall function (cleavir-ast:callee-ast ast)))
(defmethod cleavir-ast:children append ((ast defcallback-ast))
  (list (cleavir-ast:callee-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class HEADER-STAMP-CASE-AST
;;;

(defclass header-stamp-case-ast (cleavir-ast:ast)
  ((%stamp-ast :initarg :stamp-ast :reader stamp-ast)
   (%derivable-ast :initarg :derivable-ast :reader derivable-ast)
   (%rack-ast :initarg :rack-ast :reader rack-ast)
   (%wrapped-ast :initarg :wrapped-ast :reader wrapped-ast)
   (%header-ast :initarg :header-ast :reader header-ast)))

(defmethod cleavir-ast:map-children progn (function (ast header-stamp-case-ast))
  (funcall function (stamp-ast ast))
  (funcall function (derivable-ast ast))
  (funcall function (rack-ast ast))
  (funcall function (wrapped-ast ast))
  (funcall function (header-ast ast)))
(defmethod cleavir-ast:children append ((ast header-stamp-case-ast))
  (list (stamp-ast ast) (derivable-ast ast) (rack-ast ast)
        (wrapped-ast ast) (header-ast ast)))

(defun make-header-stamp-case-ast (stamp derivable rack wrapped header &optional origin)
  (make-instance 'header-stamp-case-ast
                 :stamp-ast stamp :derivable-ast derivable :rack-ast rack
                 :wrapped-ast wrapped :header-ast header
                 :origin origin))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class VECTOR-LENGTH-AST
;;;
;;; Represents an operation to get the length of a vector.
;;; If the vector has a fill pointer it returns that,
;;; as the length and fill pointer have the same offset.

(defclass vector-length-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%vector :initarg :vector :accessor cleavir-ast:arg-ast)))

(cleavir-io:define-save-info vector-length-ast
    (:vector cleavir-ast:arg-ast))

(defmethod cleavir-ast-graphviz::label ((ast vector-length-ast))
  "vlength")

(defmethod cleavir-ast:map-children progn (function (ast vector-length-ast))
  (funcall function (cleavir-ast:arg-ast ast)))
(defmethod cleavir-ast:children append ((ast vector-length-ast))
  (list (cleavir-ast:arg-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class DISPLACEMENT-AST
;;;
;;; Gets the actual underlying array of any mdarray.

(defclass displacement-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%mdarray :initarg :mdarray :accessor cleavir-ast:arg-ast)))

(cleavir-io:define-save-info displacement-ast
    (:mdarray cleavir-ast:arg-ast))

(defmethod cleavir-ast-graphviz::label ((ast displacement-ast))
  "displacement")

(defmethod cleavir-ast:map-children progn (function (ast displacement-ast))
  (funcall function (cleavir-ast:arg-ast ast)))
(defmethod cleavir-ast:children append ((ast displacement-ast))
  (list (cleavir-ast:arg-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class DISPLACED-INDEX-OFFSET-AST
;;;
;;; Gets the actual underlying DIO of any mdarray.

(defclass displaced-index-offset-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%mdarray :initarg :mdarray :accessor cleavir-ast:arg-ast)))

(cleavir-io:define-save-info displaced-index-offset-ast
    (:mdarray cleavir-ast:arg-ast))

(defmethod cleavir-ast-graphviz::label ((ast displaced-index-offset-ast))
  "d-offset")

(defmethod cleavir-ast:map-children progn (function (ast displaced-index-offset-ast))
  (funcall function (cleavir-ast:arg-ast ast)))
(defmethod cleavir-ast:children append ((ast displaced-index-offset-ast))
  (list (cleavir-ast:arg-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class ARRAY-TOTAL-SIZE-AST
;;;
;;; Gets the total size of any mdarray.

(defclass array-total-size-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%mdarray :initarg :mdarray :accessor cleavir-ast:arg-ast)))

(cleavir-io:define-save-info array-total-size-ast
    (:mdarray cleavir-ast:arg-ast))

(defmethod cleavir-ast-graphviz::label ((ast array-total-size-ast))
  "ATS")

(defmethod cleavir-ast:map-children progn (function (ast array-total-size-ast))
  (funcall function (cleavir-ast:arg-ast ast)))
(defmethod cleavir-ast:children append ((ast array-total-size-ast))
  (list (cleavir-ast:arg-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class ARRAY-RANK-AST
;;;
;;; Gets the rank of any mdarray.

(defclass array-rank-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%mdarray :initarg :mdarray :accessor cleavir-ast:arg-ast)))

(cleavir-io:define-save-info array-rank-ast
    (:mdarray cleavir-ast:arg-ast))

(defmethod cleavir-ast-graphviz::label ((ast array-rank-ast))
  "rank")

(defmethod cleavir-ast:map-children progn (function (ast array-rank-ast))
  (funcall function (cleavir-ast:arg-ast ast)))
(defmethod cleavir-ast:children append ((ast array-rank-ast))
  (list (cleavir-ast:arg-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class ARRAY-DIMENSION-AST
;;;
;;; Gets the dimensions of any mdarray.

(defclass array-dimension-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%mdarray :initarg :mdarray :accessor cleavir-ast:arg1-ast)
   (%axis :initarg :axis :accessor cleavir-ast:arg2-ast)))

(cleavir-io:define-save-info array-dimension-ast
    (:mdarray cleavir-ast:arg1-ast)
  (:axis cleavir-ast:arg2-ast))

(defmethod cleavir-ast-graphviz::label ((ast array-dimension-ast))
  "AD")

(defmethod cleavir-ast:map-children progn (function (ast array-dimension-ast))
  (funcall function (cleavir-ast:arg1-ast ast))
  (funcall function (cleavir-ast:arg2-ast ast)))
(defmethod cleavir-ast:children append ((ast array-dimension-ast))
  (list (cleavir-ast:arg1-ast ast)
        (cleavir-ast:arg2-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class HEADER-STAMP-AST

(defclass header-stamp-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%arg :initarg :arg :accessor cleavir-ast:arg-ast)))
(cleavir-io:define-save-info header-stamp-ast (:arg cleavir-ast:arg-ast))
(defmethod cleavir-ast-graphviz::label ((ast header-stamp-ast)) "header-stamp")
(defmethod cleavir-ast:map-children progn (function (ast header-stamp-ast))
  (funcall function (cleavir-ast:arg-ast ast)))
(defmethod cleavir-ast:children append ((ast header-stamp-ast))
  (list (cleavir-ast:arg-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class RACK-STAMP-AST

(defclass rack-stamp-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%arg :initarg :arg :accessor cleavir-ast:arg-ast)))
(cleavir-io:define-save-info rack-stamp-ast (:arg cleavir-ast:arg-ast))
(defmethod cleavir-ast-graphviz::label ((ast rack-stamp-ast)) "rack-stamp")
(defmethod cleavir-ast:map-children progn (function (ast rack-stamp-ast))
  (funcall function (cleavir-ast:arg-ast ast)))
(defmethod cleavir-ast:children append ((ast rack-stamp-ast))
  (list (cleavir-ast:arg-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class WRAPPED-STAMP-AST

(defclass wrapped-stamp-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%arg :initarg :arg :accessor cleavir-ast:arg-ast)))
(cleavir-io:define-save-info wrapped-stamp-ast (:arg cleavir-ast:arg-ast))
(defmethod cleavir-ast-graphviz::label ((ast wrapped-stamp-ast)) "wrapped-stamp")
(defmethod cleavir-ast:map-children progn (function (ast wrapped-stamp-ast))
  (funcall function (cleavir-ast:arg-ast ast)))
(defmethod cleavir-ast:children append ((ast wrapped-stamp-ast))
  (list (cleavir-ast:arg-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class DERIVABLE-STAMP-AST

(defclass derivable-stamp-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%arg :initarg :arg :accessor cleavir-ast:arg-ast)))
(cleavir-io:define-save-info derivable-stamp-ast (:arg cleavir-ast:arg-ast))
(defmethod cleavir-ast-graphviz::label ((ast derivable-stamp-ast)) "derivable-stamp")
(defmethod cleavir-ast:map-children progn (function (ast derivable-stamp-ast))
  (funcall function (cleavir-ast:arg-ast ast)))
(defmethod cleavir-ast:children append ((ast derivable-stamp-ast))
  (list (cleavir-ast:arg-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class INSTANCE-RACK-AST
;;;

(defclass instance-rack-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%object :initarg :object-ast :accessor cleavir-ast:object-ast)))

(cleavir-io:define-save-info instance-rack-ast
    (:object-ast cleavir-ast:object-ast))

(defmethod cleavir-ast-graphviz::label ((ast instance-rack-ast))
  "instance-rack")

(defmethod cleavir-ast:map-children progn (function (ast instance-rack-ast))
  (funcall function (cleavir-ast:object-ast ast)))
(defmethod cleavir-ast:children append ((ast instance-rack-ast))
  (list (cleavir-ast:object-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class INSTANCE-RACK-SET-AST
;;;

(defclass instance-rack-set-ast (cleavir-ast:no-value-ast-mixin cleavir-ast:ast)
  ((%object :initarg :object-ast :accessor cleavir-ast:object-ast)
   (%value :initarg :value-ast :accessor cleavir-ast:value-ast)))

(cleavir-io:define-save-info instance-rack-set-ast
    (:object-ast cleavir-ast:object-ast)
  (:value-ast cleavir-ast:value-ast))

(defmethod cleavir-ast-graphviz::label ((ast instance-rack-set-ast))
  "instance-rack-set")

(defmethod cleavir-ast:map-children progn (function (ast instance-rack-set-ast))
  (funcall function (cleavir-ast:object-ast ast))
  (funcall function (cleavir-ast:value-ast ast)))
(defmethod cleavir-ast:children append ((ast instance-rack-set-ast))
  (list (cleavir-ast:object-ast ast) (cleavir-ast:value-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class RACK-READ-AST
;;;

(defclass rack-read-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%object :initarg :object-ast :accessor cleavir-ast:object-ast)
   (%slot-number :initarg :slot-number-ast
                 :accessor cleavir-ast:slot-number-ast)))

(cleavir-io:define-save-info rack-read-ast
    (:object-ast cleavir-ast:object-ast)
  (:slot-number-ast cleavir-ast:slot-number-ast))

(defmethod cleavir-ast-graphviz::label ((ast rack-read-ast))
  "rack-read")

(defmethod cleavir-ast:map-children progn (function (ast rack-read-ast))
  (funcall function (cleavir-ast:object-ast ast))
  (funcall function (cleavir-ast:slot-number-ast ast)))
(defmethod cleavir-ast:children append ((ast rack-read-ast))
  (list (cleavir-ast:object-ast ast) (cleavir-ast:slot-number-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class RACK-WRITE-AST
;;;

(defclass rack-write-ast (cleavir-ast:no-value-ast-mixin cleavir-ast:ast)
  ((%object :initarg :object-ast :accessor cleavir-ast:object-ast)
   (%slot-number :initarg :slot-number-ast
                 :accessor cleavir-ast:slot-number-ast)
   (%value :initarg :value-ast :accessor cleavir-ast:value-ast)))

(cleavir-io:define-save-info rack-write-ast
    (:object-ast cleavir-ast:object-ast)
  (:slot-number-ast cleavir-ast:slot-number-ast)
  (:value-ast cleavir-ast:value-ast))

(defmethod cleavir-ast-graphviz::label ((ast rack-write-ast))
  "rack-write")

(defmethod cleavir-ast:map-children progn (function (ast rack-write-ast))
  (funcall function (cleavir-ast:object-ast ast))
  (funcall function (cleavir-ast:slot-number-ast ast))
  (funcall function (cleavir-ast:value-ast ast)))
(defmethod cleavir-ast:children append ((ast rack-write-ast))
  (list (cleavir-ast:object-ast ast) (cleavir-ast:slot-number-ast ast)
        (cleavir-ast:value-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class VASLIST-POP-AST
;;;
;;; Pops an element off a valist.
;;; Doesn't necessarily check that there is an element.

(defclass vaslist-pop-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%arg-ast :initarg :vaslist :reader cleavir-ast:arg-ast)))

(cleavir-io:define-save-info vaslist-pop-ast
    (:vaslist cleavir-ast:arg-ast))

(defmethod cleavir-ast-graphviz::label ((ast vaslist-pop-ast))
  "vaslist-pop")

(defmethod cleavir-ast:map-children progn (function (ast vaslist-pop-ast))
  (funcall function (cleavir-ast:arg-ast ast)))
(defmethod cleavir-ast:children append ((ast vaslist-pop-ast))
  (list (cleavir-ast:arg-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class VASLIST-LENGTH-AST
;;;
;;; Gets the remaining number of arguments of a vaslist.

(defclass vaslist-length-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:ast)
  ((%arg-ast :initarg :vaslist :reader cleavir-ast:arg-ast)))

(cleavir-io:define-save-info vaslist-length-ast
    (:vaslist cleavir-ast:arg-ast))

(defmethod cleavir-ast-graphviz::label ((ast vaslist-length-ast))
  "vaslist-length")

(defmethod cleavir-ast:map-children progn (function (ast vaslist-length-ast))
  (funcall function (cleavir-ast:arg-ast ast)))
(defmethod cleavir-ast:children append ((ast vaslist-length-ast))
  (list (cleavir-ast:arg-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class CAS-AST-MIXIN
;;;
;;; Abstract. Class for compare-and-swap ASTs.

(defclass cas-ast-mixin (cleavir-ast:one-value-ast-mixin)
  (;; The "old" value being compared to the loaded one.
   (%cmp-ast :initarg :cmp-ast :reader cmp-ast)
   ;; The "new" value that's maybe being stored.
   (%value-ast :initarg :value-ast :reader cleavir-ast:value-ast)))

(cleavir-io:define-save-info cas-ast-mixin
    (:cmp-ast cmp-ast) (:value-ast cleavir-ast:value-ast))

(defmethod cleavir-ast:map-children progn
    (function (ast cas-ast-mixin))
  (funcall function (cmp-ast ast))
  (funcall function (cleavir-ast:value-ast ast)))
(defmethod cleavir-ast:children append ((ast cas-ast-mixin))
  (list (cmp-ast ast) (cleavir-ast:value-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class CAS-CAR-AST
;;;
;;; Compare-and-swap a cons's car.

(defclass cas-car-ast (cas-ast-mixin cleavir-ast:cons-access-ast)
  ())

(defmethod cleavir-ast-graphviz::label ((ast cas-car-ast))
  "cas-car")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class CAS-CDR-AST
;;;
;;; Compare-and-swap a cons's cdr.

(defclass cas-cdr-ast (cas-ast-mixin cleavir-ast:cons-access-ast)
  ())

(defmethod cleavir-ast-graphviz::label ((ast cas-cdr-ast))
  "cas-cdr")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class SLOT-CAS-AST
;;;
;;; Compare-and-swap an instance slot.

(defclass slot-cas-ast (cas-ast-mixin cleavir-ast:slot-access-ast)
  ())

(defmethod cleavir-ast-graphviz::label ((ast slot-cas-ast))
  "slot-cas")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class ACAS-AST
;;;
;;; Compare-and-swap an array element.

(defclass acas-ast (cas-ast-mixin cleavir-ast:array-access-ast) ())

(defmethod cleavir-ast-graphviz::label ((ast acas-ast)) "acas")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class PRECALC-VECTOR-FUNCTION-AST
;;;
;;; This AST is a subclass of FUNCTION-AST. It is used when an AST
;;; is transformed by hoisting all the LOAD-TIME-VALUE-ASTs in the tree
;;; by turning them into PRECALC-VALUE-AST that are also required
;;; arguments of the PRECALC-VECTOR-FUNCTION-AST.
;;;
;;; This AST class supplies a slot that contains a list of the forms
;;; that were contained in the LOAD-TIME-VALUE-ASTs. In order to
;;; evaluate the original AST, the transformed AST must be called with
;;; two vectors that are filled by evaluating those forms and putting
;;; their results (symbols and values) into the presym-vector and preval-vector
;;; calc-value-vector and passing that as arguments.
;;


(defclass precalc-vector-function-ast (cleavir-ast:top-level-function-ast)
  ((%precalc-asts :initarg :precalc-asts :reader precalc-asts)))

(defun make-precalc-vector-function-ast (body-ast precalc-asts forms policy
                                         &key origin)
  (make-instance 'precalc-vector-function-ast
                 :body-ast body-ast
                 :lambda-list nil
                 :precalc-asts precalc-asts
                 :forms forms
                 :policy policy
                 :origin origin))

(cleavir-io:define-save-info precalc-vector-function-ast
    (:precalc-asts precalc-asts))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class BIND-AST
;;;
;;; Represents a special variable binding.
;;;

(defclass bind-ast (cleavir-ast:ast)
  ((%name :initarg :name-ast :reader cleavir-ast:name-ast)
   (%value :initarg :value-ast :reader cleavir-ast:value-ast)
   (%body :initarg :body-ast :reader cleavir-ast:body-ast)))

(cleavir-io:define-save-info bind-ast
    (:name-ast cleavir-ast:name-ast)
  (:value-ast cleavir-ast:value-ast)
  (:body-ast cleavir-ast:body-ast))

(defmethod cleavir-ast-graphviz::label ((ast bind-ast)) "bind")

(defmethod cleavir-ast:map-children progn (function (ast bind-ast))
  (funcall function (cleavir-ast:name-ast ast))
  (funcall function (cleavir-ast:value-ast ast))
  (funcall function (cleavir-ast:body-ast ast)))
(defmethod cleavir-ast:children append ((ast bind-ast))
  (list (cleavir-ast:name-ast ast)
        (cleavir-ast:value-ast ast)
        (cleavir-ast:body-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class UNWIND-PROTECT-AST
;;;
;;; Represents CL:UNWIND-PROTECT.
;;;
;;; NOTE: The cleanup forms are stored as a thunk. This could be changed
;;; so that the actual code is run, avoiding the overhead of allocating a
;;; closure, and calling and so on. For now I'm assuming it's unimportant.
;;;

(defclass unwind-protect-ast (cleavir-ast:ast)
  ((%body :initarg :body-ast :reader cleavir-ast:body-ast)
   ;; This will be a FUNCTION-AST.
   (%cleanup :initarg :cleanup-ast :reader cleanup-ast)))

(cleavir-io:define-save-info unwind-protect-ast
    (:body-ast cleavir-ast:body-ast)
  (:cleanup-ast cleanup-ast))

(defmethod cleavir-ast-graphviz::label ((ast unwind-protect-ast))
  "unwind-protect")

(defmethod cleavir-ast:map-children progn (function (ast unwind-protect-ast))
  (funcall function (cleavir-ast:body-ast ast))
  (funcall function (cleanup-ast ast)))
(defmethod cleavir-ast:children append ((ast unwind-protect-ast))
  (list (cleavir-ast:body-ast ast)
        (cleanup-ast ast)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class PRECALC-VALUE-REFERENCE-AST
;;;
;;; This class represents a reference to a value that is precalculated
;;; at load-time (COMPILE-FILE) or compile-time (COMPILE) and placed into
;;; a LoadTimeValue object that is passed to the function.
;;;

(defclass precalc-value-reference-ast (cleavir-ast:one-value-ast-mixin cleavir-ast:side-effect-free-ast-mixin cleavir-ast:ast)
  ((%ref-index :initarg :index :accessor precalc-value-reference-ast-index)
   (%original-object :initarg :original-object :accessor precalc-value-reference-ast-original-object)))


(cleavir-io:define-save-info precalc-value-reference-ast
  (:index precalc-value-reference-ast-index)
  (:original-object precalc-value-reference-ast-original-object))

(defmethod cleavir-ast:map-children progn (function (ast precalc-value-reference-ast))
  (declare (ignore function)))
(defmethod cleavir-ast:children append ((ast precalc-value-reference-ast))
  nil)

(defun escaped-string (str)
  (with-output-to-string (s) (loop for c across str do (when (member c '(#\\ #\")) (princ #\\ s)) (princ c s))))

(defmethod cleavir-ast-graphviz::label ((ast precalc-value-reference-ast))
  (with-output-to-string (s)
    (format s "precalc-val-ref ; ")
    (let ((original-object (escaped-string
                            (format nil "~s" (precalc-value-reference-ast-original-object ast)))))
      (if (> (length original-object) 10)
	  (format s "~a..." (subseq original-object 0 10))
	  (princ original-object s)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class BIND-VA-LIST-AST
;;;
;;; Bind variables according to an ordinary lambda list based on a va_list.
;;; A lot like a function-ast, but not actually one because it just binds.

(defclass bind-va-list-ast (cleavir-ast:ast)
  ((%lambda-list :initarg :lambda-list :reader cleavir-ast:lambda-list)
   (%va-list-ast :initarg :va-list :reader va-list-ast)
   (%body-ast :initarg :body-ast :reader cleavir-ast:body-ast)
   ;; Either NIL, indicating normal allocation,
   ;; or DYNAMIC-EXTENT, indicating dynamic extent (stack) allocation,
   ;; or IGNORE, indicating no allocation.
   (%rest-alloc :initarg :rest-alloc :reader rest-alloc)))

(defun make-bind-va-list-ast (lambda-list va-list-ast body-ast rest-alloc
                              &key origin (policy cleavir-ast:*policy*))
  (make-instance 'bind-va-list-ast
    :origin origin :policy policy :rest-alloc rest-alloc
    :va-list va-list-ast :body-ast body-ast :lambda-list lambda-list))

(cleavir-io:define-save-info bind-va-list-ast
    (:lambda-list cleavir-ast:lambda-list)
  (:va-list va-list-ast)
  (:body-ast cleavir-ast:body-ast)
  (:rest-alloc rest-alloc))

(defmethod cleavir-ast:map-children progn (function (ast bind-va-list-ast))
  (funcall function (va-list-ast ast))
  (funcall function (cleavir-ast:body-ast ast)))
(defmethod cleavir-ast:children append ((ast bind-va-list-ast))
  (list (cleavir-ast:body-ast ast)))

(defmethod cleavir-ast:map-variables progn (function (ast bind-va-list-ast))
  (loop for item in (cleavir-ast:lambda-list ast)
        if (typep item 'cleavir-ast:lexical-variable)
          do (funcall function item)
        else if (listp item)
               do (ecase (length item)
                    ((2) ; optional: (var var-p)
                     (funcall function (first item))
                     (funcall function (second item)))
                    ((3) ; key: (key var var-p)
                     (funcall function (second item))
                     (funcall function (third item))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Load-time-value hoisting, Clasp-style.

(defun process-ltv (env form read-only-p)
  "If the form is an immediate constant, returns it. If the form has previously been processed here,
returns the previous results. Otherwise, generates code for the form that places the result into a
precalculated-vector and returns the index."
  (cond
    ((constantp form env)
     (let* ((value (ext:constant-form-value form env))
            (immediate (core:create-tagged-immediate-value-or-nil value)))
       (if immediate
           (values immediate t)
           (multiple-value-bind (index indexp)
               (literal:reference-literal value t)
             ;; FIXME: Might not to reorganize things deeper.
             (unless indexp
               (error "BUG: create-tagged-immediate-value-or-nil is inconsistent with literal machinery."))
             (values index nil)))))
    ;; Currently read-only-p is ignored from here on.
    ;; But it might be possible to coalesce EQ forms or something.
    ;; COMPLE-FILE will generate a function for the form in the Module
    ;; and arrange for it's evaluation at load time
    ;; and to make its result available as a value
    ((eq cleavir-generate-ast:*compiler* 'cl:compile-file)
     (values (literal:with-load-time-value
                 (clasp-cleavir::compile-form form env))
             nil))
    ;; COMPILE on the other hand evaluates the form and puts its
    ;; value in the run-time environment.
    (t
     (let ((value (cleavir-env:eval form env env)))
       (multiple-value-bind (index-or-immediate index-p)
           (literal:codegen-rtv-cclasp value)
         (values index-or-immediate (not index-p)))))))

(defun hoist-load-time-value (ast env)
  (let ((ltvs nil)
        (forms nil))
    (cleavir-ast:map-ast-depth-first-preorder
     (lambda (ast)
       (when (typep ast 'cleavir-ast:load-time-value-ast)
         (push ast ltvs)))
     ast)
    (dolist (ltv ltvs)
      (let ((form (cleavir-ast:form ltv)))
        (multiple-value-bind (index-or-immediate immediatep literal-name)
            (process-ltv env form (cleavir-ast:read-only-p ltv))
          (if immediatep
              (change-class ltv 'cleavir-ast:immediate-ast
                            :value index-or-immediate)
              (change-class ltv 'precalc-value-reference-ast
                            :index index-or-immediate
                            :origin (clasp-cleavir::ensure-origin (cleavir-ast:origin ltv) 9999912)
                            :original-object form)))
        (push form forms)))
    (clasp-cleavir-ast:make-precalc-vector-function-ast
     ast ltvs forms (cleavir-ast:policy ast)
     :origin (cleavir-ast:origin ast))))
