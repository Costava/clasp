(in-package :clasp-cleavir-hir)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction DEBUG-MESSAGE-INSTRUCTION
;;;
;;; This instruction is an DEBUG-MESSAGE-INSTRUCTION that prints a message at runtime.

(defclass debug-message-instruction (cleavir-ir:one-successor-mixin
                                     cleavir-ir:side-effect-mixin cleavir-ir:instruction)
  ((%debug-message :initarg :debug-message :accessor debug-message)))

(defmethod cleavir-ir-graphviz:label ((instr debug-message-instruction))
  (with-output-to-string (s)
    (format s "debug-message(~a)" (debug-message instr))))

(defmethod cleavir-ir:clone-initargs append ((instruction debug-message-instruction))
  (list :debug-message (debug-message instruction)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction DEBUG-BREAK-INSTRUCTION
;;;
;;; This instruction is an DEBUG-BREAK-INSTRUCTION that invokes the debugger

(defclass debug-break-instruction (cleavir-ir:one-successor-mixin
                                   cleavir-ir:side-effect-mixin cleavir-ir:instruction)
  ())

(defmethod cleavir-ir-graphviz:label ((instr debug-break-instruction))
  (with-output-to-string (s)
    (format s "debug-break")))

(defmethod cleavir-ir:clone-initargs append ((instruction debug-break-instruction))
  ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction multiple-value-foreign-CALL-INSTRUCTION
;;;
;;; Calls a foreign function (designated by its name, a string) and receives its result as values.

(defclass multiple-value-foreign-call-instruction (cleavir-ir:one-successor-mixin
                                                   cleavir-ir:side-effect-mixin cleavir-ir:instruction)
  ((%function-name :initarg :function-name :accessor function-name)))

(defmethod cleavir-ir-graphviz:label ((instr multiple-value-foreign-call-instruction))
  (with-output-to-string (s)
    (format s "multiple-value-foreign-call(~a)" (function-name instr))))

(defmethod cleavir-ir:clone-initargs append ((instruction multiple-value-foreign-call-instruction))
  (list :function-name (function-name instruction)))

(defmethod make-multiple-value-foreign-call-instruction
    (function-name inputs outputs &optional (successor nil successor-p))
  (make-instance 'multiple-value-foreign-call-instruction
                 :function-name function-name
                 :inputs inputs
                 :outputs outputs
                 :successors (if successor-p (list successor) '())))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction FOREIGN-call-INSTRUCTION
;;;
;;; This instruction is an FOREIGN-call-INSTRUCTION that prints a message

(defclass foreign-call-instruction (cleavir-ir:one-successor-mixin
                                    cleavir-ir:side-effect-mixin cleavir-ir:instruction)
  ((%foreign-types :initarg :foreign-types :accessor foreign-types)
   (%function-name :initarg :function-name :accessor function-name)))

(defmethod cleavir-ir-graphviz:label ((instr foreign-call-instruction))
  (with-output-to-string (s)
    (format s "foreign-call(~a)" (function-name instr))))

(defmethod cleavir-ir:clone-initargs append ((instruction foreign-call-instruction))
  (list :foreign-types (foreign-types instruction)
        :function-name (function-name instruction)))

(defmethod make-foreign-call-instruction
    (foreign-types function-name inputs outputs &optional (successor nil successor-p))
  (make-instance 'foreign-call-instruction
                 :function-name function-name
                 :foreign-types foreign-types
                 :inputs inputs
                 :outputs outputs
                 :successors (if successor-p (list successor) '())))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction foreign-call-pointer-INSTRUCTION
;;;
;;; This instruction is an foreign-call-pointer-INSTRUCTION that prints a message

(defclass foreign-call-pointer-instruction (cleavir-ir:one-successor-mixin
                                            cleavir-ir:side-effect-mixin cleavir-ir:instruction)
  ((%foreign-types :initarg :foreign-types :accessor foreign-types)))

(defmethod cleavir-ir-graphviz:label ((instr foreign-call-pointer-instruction))
  (with-output-to-string (s)
    (format s "foreign-call-pointer")))

(defmethod cleavir-ir:clone-initargs append ((instruction foreign-call-pointer-instruction))
  (list :foreign-types (foreign-types instruction)))

(defmethod make-foreign-call-pointer-instruction
    (foreign-types inputs outputs &optional (successor nil successor-p))
  (make-instance 'foreign-call-pointer-instruction
                 :foreign-types foreign-types
                 :inputs inputs
                 :outputs outputs
                 :successors (if successor-p (list successor) '())))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction DEFCALLBACK-INSTRUCTION
;;;

(defclass defcallback-instruction (cleavir-ir:one-successor-mixin
                                   cleavir-ir:side-effect-mixin cleavir-ir:instruction)
  ((%args :initarg :args :reader defcallback-args)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction HEADER-STAMP-CASE-INSTRUCTION
;;;

(defclass header-stamp-case-instruction (cleavir-ir:multiple-successors-mixin
                                         cleavir-ir:instruction)
  ())
(defun make-header-stamp-case-instruction (stamp successors)
  (make-instance 'header-stamp-case-instruction
                 :inputs (list stamp)
                 :outputs nil
                 :successors successors))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction VECTOR-LENGTH-INSTRUCTION
;;;
;;; This instruction gets the length of a vector, as CL:LENGTH.

(defclass vector-length-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction)
  ())

(defmethod cleavir-ir-graphviz:label ((instr vector-length-instruction))
  "vlength")

(defun make-vector-length-instruction (input output &optional (successor nil successor-p))
  (make-instance 'vector-length-instruction
                 :inputs (list input)
                 :outputs (list output)
                 :successors (if successor-p (list successor) nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction DISPLACEMENT-INSTRUCTION
;;;
;;; Get the actual _Data of an mdarray.

(defclass displacement-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction)
  ())

(defmethod cleavir-ir-graphviz:label ((instr displacement-instruction))
  "displacement")

(defun make-displacement-instruction (input output &optional (successor nil successor-p))
  (make-instance 'displacement-instruction
                 :inputs (list input)
                 :outputs (list output)
                 :successors (if successor-p (list successor) nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction DISPLACED-INDEX-OFFSET-INSTRUCTION
;;;
;;; Get the actual _DisplacedIndexOffset of an mdarray.

(defclass displaced-index-offset-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction)
  ())

(defmethod cleavir-ir-graphviz:label ((instr displaced-index-offset-instruction))
  "d-offset")

(defun make-displaced-index-offset-instruction (input output &optional (successor nil successor-p))
  (make-instance 'displaced-index-offset-instruction
                 :inputs (list input)
                 :outputs (list output)
                 :successors (if successor-p (list successor) nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction ARRAY-TOTAL-SIZE-INSTRUCTION
;;;
;;; Get the _ArrayTotalSize of an mdarray.

(defclass array-total-size-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction)
  ())

(defmethod cleavir-ir-graphviz:label ((instr array-total-size-instruction))
  "ATS")

(defun make-array-total-size-instruction (input output &optional (successor nil successor-p))
  (make-instance 'array-total-size-instruction
                 :inputs (list input)
                 :outputs (list output)
                 :successors (if successor-p (list successor) nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction ARRAY-RANK-INSTRUCTION
;;;
;;; Get the rank of an mdarray.

(defclass array-rank-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction)
  ())

(defmethod cleavir-ir-graphviz:label ((instr array-rank-instruction))
  "rank")

(defun make-array-rank-instruction (input output &optional (successor nil successor-p))
  (make-instance 'array-rank-instruction
                 :inputs (list input)
                 :outputs (list output)
                 :successors (if successor-p (list successor) nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction ARRAY-DIMENSION-INSTRUCTION
;;;
;;; Get a dimension of an mdarray.

(defclass array-dimension-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction)
  ())

(defmethod cleavir-ir-graphviz:label ((instr array-dimension-instruction))
  "AD")

(defun make-array-dimension-instruction (mdarray axis output &optional (successor nil successor-p))
  (make-instance 'array-dimension-instruction
                 :inputs (list mdarray axis)
                 :outputs (list output)
                 :successors (if successor-p (list successor) nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction HEADER-STAMP-INSTRUCTION
;;;

(defclass header-stamp-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction) ())
(defmethod cleavir-ir-graphviz:label ((instr header-stamp-instruction)) "header-stamp")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction RACK-STAMP-INSTRUCTION
;;;

(defclass rack-stamp-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction) ())
(defmethod cleavir-ir-graphviz:label ((instr rack-stamp-instruction)) "rack-stamp")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction WRAPPED-STAMP-INSTRUCTION
;;;

(defclass wrapped-stamp-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction) ())
(defmethod cleavir-ir-graphviz:label ((instr wrapped-stamp-instruction)) "wrapped-stamp")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction DERIVABLE-STAMP-INSTRUCTION
;;;

(defclass derivable-stamp-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction) ())
(defmethod cleavir-ir-graphviz:label ((instr derivable-stamp-instruction)) "derivable-stamp")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction INSTANCE-RACK-INSTRUCTION
;;;

(defclass instance-rack-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction) ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction INSTANCE-RACK-SET-INSTRUCTION
;;;

(defclass instance-rack-set-instruction
    (cleavir-ir:one-successor-mixin cleavir-ir:side-effect-mixin cleavir-ir:instruction)
  ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction RACK-READ-INSTRUCTION
;;;

(defclass rack-read-instruction
    (cleavir-ir:one-successor-mixin cleavir-ir:instruction)
  ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction RACK-WRITE-INSTRUCTION
;;;

(defclass rack-write-instruction
    (cleavir-ir:one-successor-mixin cleavir-ir:side-effect-mixin cleavir-ir:instruction)
  ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction VASLIST-POP-INSTRUCTION
;;;

(defclass vaslist-pop-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction)
  ())

(defmethod cleavir-ir-graphviz:label ((instr vaslist-pop-instruction)) "vaslist-pop")

(defun make-vaslist-pop-instruction (vaslist output &optional (successor nil successorp))
  (make-instance 'vaslist-pop-instruction
                 :inputs (list vaslist)
                 :outputs (list output)
                 :successors (if successorp (list successor) nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction VASLIST-LENGTH-INSTRUCTION
;;;

(defclass vaslist-length-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction)
  ())

(defmethod cleavir-ir-graphviz:label ((instr vaslist-length-instruction)) "vaslist-length")

(defun make-vaslist-length-instruction (vaslist output &optional (successor nil successorp))
  (make-instance 'vaslist-length-instruction
                 :inputs (list vaslist)
                 :outputs (list output)
                 :successors (if successorp (list successor) nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction BIND-VA-LIST-INSTRUCTION
;;;
;;; Sort of like destructuring-bind, but with a va-list
;;; instead of a list (thus why it's a special operator),
;;; and only allowing ordinary lambda lists.

(defclass bind-va-list-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction)
  ((%lambda-list :initarg :lambda-list :accessor cleavir-ir:lambda-list)
   (%rest-alloc :initarg :rest-alloc :reader rest-alloc)))

(defmethod cleavir-ir-graphviz:label ((instr bind-va-list-instruction))
  (format nil "bind-va-list ~a"
          (mapcar #'cleavir-ir-graphviz::format-item (cleavir-ir:lambda-list instr))))

(defmethod cleavir-ir:clone-initargs append ((instruction bind-va-list-instruction))
  (list :lambda-list (cleavir-ir:lambda-list instruction)
        :rest-alloc (rest-alloc instruction)))

;;; Following two copied from enter-instruction. i mean most of this is.
;;; Maintain consistency of lambda list with outputs.
(defmethod cleavir-ir:substitute-output :after (new old (instruction bind-va-list-instruction))
  (setf (cleavir-ir:lambda-list instruction)
        (subst new old (cleavir-ir:lambda-list instruction) :test #'eq)))

(defmethod (setf cleavir-ir:outputs) :before (new-outputs (instruction bind-va-list-instruction))
  (let ((old-lambda-outputs (rest (cleavir-ir:outputs instruction)))
        (new-lambda-outputs (rest new-outputs)))
    ;; FIXME: Not sure what to do if the new and old outputs are different lengths.
    ;; For now we're silent.
    (setf (cleavir-ir:lambda-list instruction)
          (sublis (mapcar #'cons old-lambda-outputs new-lambda-outputs)
                  (cleavir-ir:lambda-list instruction)
                  :test #'eq))))

(defun make-bind-va-list-instruction (lambda-list va-list rest-alloc &optional (successor nil successor-p))
  (make-instance 'bind-va-list-instruction
                 :lambda-list lambda-list
                 :rest-alloc rest-alloc
                 :inputs (list va-list)
                 ;; copied from cleavir-ir:make-enter-instruction
                 :outputs (loop for item in lambda-list
                                append (cond ((member item lambda-list-keywords) nil)
                                             ((consp item)
                                              (if (= (length item) 3)
                                                  (rest item)
                                                  item))
                                             (t (list item))))
                 :successors (if successor-p (list successor) nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction CAS-CAR-INSTRUCTION

(defclass cas-car-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction) ())

(defmethod cleavir-ir-graphviz:label ((instr cas-car-instruction)) "cas-car")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction CAS-CDR-INSTRUCTION

(defclass cas-cdr-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction) ())

(defmethod cleavir-ir-graphviz:label ((instr cas-cdr-instruction)) "cas-cdr")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction SLOT-CAS-INSTRUCTION

(defclass slot-cas-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction) ())

(defmethod cleavir-ir-graphviz:label ((instr slot-cas-instruction)) "slot-cas")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction ACAS-INSTRUCTION
;;;
;;; Compare-and-swap an array.

(defclass acas-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction)
  ((%element-type :initarg :element-type :reader cleavir-ir:element-type)
   (%simple-p :initarg :simple-p :reader cleavir-ir:simple-p)
   (%boxed-p :initarg :boxed-p :reader cleavir-ir:boxed-p)))

(defmethod cleavir-ir-graphviz:label ((instr acas-instruction)) "acas")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Compute &rest argument allocation based on declarations.
;;;

(defmethod rest-alloc ((self cleavir-ir:enter-instruction))
  (let ((rest (member '&rest (cleavir-ir:lambda-list self))))
    (if rest
        (let* ((restloc (second rest))
               (decls (cdr (assoc restloc (cleavir-ir:bound-declarations self)))))
          (cond ((find 'ignore decls :key #'car) 'ignore)
                ((find 'dynamic-extent decls :key #'car) 'dynamic-extent)
                (t nil)))
        nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction PRECALC-VALUE-INSTRUCTION.
;;;
;;; This instruction is used to lookup a precalculated value
;;; in a precalculated symbol or value vector
;;; Represented as a vector containing an entry for each
;;; precalculated value.  
;;;

(defclass precalc-value-instruction (cleavir-ir:one-successor-mixin cleavir-ir:instruction)
  ((%index :initarg :index :accessor precalc-value-instruction-index)
   (%original-object :initarg :original-object :accessor precalc-value-instruction-original-object)))

(defun make-precalc-value-instruction (index output &key successor original-object
                                                      (origin (if (boundp 'cleavir-ir:*origin*)
                                                                  cleavir-ir:*origin*
                                                                  nil)
                                                              originp))
  (make-instance 'precalc-value-instruction
    :outputs (list output)
    :successors (if (null successor) nil (list successor))
    :origin origin
    :index index
    :original-object original-object))

(defun escaped-string (str)
  (with-output-to-string (s) (loop for c across str do (when (member c '(#\\ #\")) (princ #\\ s)) (princ c s))))

(defmethod cleavir-ir-graphviz:label ((instr precalc-value-instruction))
  (with-output-to-string (s)
    (format s "precalc-value-ref ; ")
    (let ((original-object (escaped-string
			 (format nil "~s" (precalc-value-instruction-original-object instr)))))
      (if (> (length original-object) 30)
	  (format s "~a..." (subseq original-object 0 30))
	  (princ original-object s)))))

(defmethod cleavir-ir:clone-initargs append ((instruction precalc-value-instruction))
  (list :original-object (precalc-value-instruction-original-object instruction)
        :index (precalc-value-instruction-index instruction)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instruction SETF-FDEFINITION-INSTRUCTION.

(defclass setf-fdefinition-instruction (cleavir-ir:fdefinition-instruction)
  ())

(defun make-setf-fdefinition-instruction
    (input output &optional (successor nil successor-p))
  (make-instance 'setf-fdefinition-instruction
    :inputs (list input)
    :outputs (list output)
    :successors (if successor-p (list successor) '())))


(defmethod cleavir-ir-graphviz:label ((instruction setf-fdefinition-instruction)) "setf-fdefinition")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; throw-instruction
;;;

(defclass throw-instruction (cleavir-ir:no-successors-mixin
                             cleavir-ir:side-effect-mixin cleavir-ir:instruction)
  ((%throw-tag :initform nil :initarg :throw-tag :accessor throw-tag)))


(defun make-throw-instruction (throw-tag)
  (make-instance 'throw-instruction
    :inputs (list throw-tag)))

(defmethod cleavir-ir-graphviz:label ((instr throw-instruction))
  (with-output-to-string (stream)
    (format stream "throw")))

(defmethod cleavir-ir:clone-initargs append ((instruction throw-instruction))
  (list :throw-tag (throw-tag instruction)))

(defmethod cl:print-object ((instr throw-instruction) stream)
  (format stream "#<throw>"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Instructions BIND-INSTRUCTION.
;;; Represents special variable binding.
;;; The inputs of bind- are the name and new value;
;;; the outputs are the old value and the new dynamic environment.
;;; It doesn't read or write the global symbol value.
;;;

(defclass bind-instruction (cleavir-ir:one-successor-mixin
                            cleavir-ir:side-effect-mixin cleavir-ir:instruction)
  ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;: Instruction UNWIND-PROTECT-INSTRUCTION
;;;
;;; The one input is the cleanup thunk. It is not actually "used" by the instruction
;;; per se, but should be there because the thunk is needed in the landing pad code
;;; (landing-pad.lisp) which is not otherwise represented in HIR.
;;; The one output is the new dynamic environment.
;;;

(defclass unwind-protect-instruction (cleavir-ir:one-successor-mixin
                                      cleavir-ir:side-effect-mixin cleavir-ir:instruction)
  ())
