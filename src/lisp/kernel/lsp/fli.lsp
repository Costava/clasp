;;; ===========================================================================
;;;                  F L I    I M P L E M E N T A T I O N
;;; ===========================================================================
;;; -- IMPLEMEMTATION NOTES ---
;;;
;;; The complete FLI is comprised of the following files:
;;; .../src/core/fli.cc            - corresponding .cc file
;;; .../include/clasp/core/fli.h   - corresponding .h file
;;; .../src/lisp/kernel/fli.lsp    - this file
;;;
;;; --- END OF IMPLEMEMTATION NOTES ---

;;;----------------------------------------------------------------------------
;;; ISSUES / KNOWN PROBLEMS
;;;
;;;  None so far :-D
;;;
;;;----------------------------------------------------------------------------

(in-package "CLASP-FFI")

;;;----------------------------------------------------------------------------
;;;----------------------------------------------------------------------------
;;; Debugging MACROS

(defmacro fli-debug (fmt &rest args) nil)
#+(or) (defmacro fli-debug (fmt &rest args) `(format *debug-io* ,fmt ,@args))
  

;;; ===========================================================================
;;; FLI LISP SIDE IMPLEMENTATION

;;;----------------------------------------------------------------------------
;;;----------------------------------------------------------------------------
;;; MACROS

(defmacro with-foreign-object ((var type) &body body)
  `(let ((,var (%allocate-foreign-object ,type)))
     (unwind-protect
          (progn ,@body)
       (%free-foreign-object ,var))))

(defmacro with-foreign-objects (bindings &rest body)
  (if bindings
      `(with-foreign-object ,(car bindings)
         (with-foreign-objects ,(cdr bindings)
           ,@body))
      `(progn ,@body)))

;;;----------------------------------------------------------------------------
;;;----------------------------------------------------------------------------

(declaim (inline ensure-core-pointer))
(defun ensure-core-pointer (ptr)
  (cond
    ((not ptr) (error "#'ensure-core-ptr *** Illegal argument value: PTR may not be NIL!"))
    ((eql (type-of ptr) 'CLASP-FFI::FOREIGN-DATA) (%core-pointer-from-foreign-data ptr ))
    ((eql (type-of ptr) 'CORE::POINTER) ptr)
    (t (error "#'ensure-core-pointer *** Illegal type ~S of ptr. Cannot convert to core::pointer." (type-of ptr)))))

;;; === B U I L T - I N   F O R E I G N   T Y P E S ===

;;; Implemented directly in C++.
;;; Also: See vector *foreign-type-spec-table* => Vector with all foreign type
;;; specs, consisting each of:
;;; - Lisp symbol
;;; - Lisp name
;;; - size
;;; - alignment
;;; - C++ name
;;; Adding built-in foreign types requires adding a type spec to this table!

(defun dbg-print-*foreign-type-spec-table* ()
  (fli-debug "*** DEBUG INFO: clasp-ffi::*foreign-type-spec-table* =>~%~%")
  (loop
     for spec across *foreign-type-spec-table*
     for idx from 0 to (1- (length *foreign-type-spec-table*))
     when spec
     do
       (fli-debug "~d: ~S~&" idx spec))
  (fli-debug "~%*** END OF DEBUG INFO ***~%"))

(eval-when (:compile-toplevel :load-toplevel :execute)

  (defgeneric %lisp-type->lisp-name (lisp-type-kw))

  (defmacro generate-type-spec-accessor-functions ()
    `(progn
       ;; type -> type spec
       ,@(loop for spec across *foreign-type-spec-table*
            for idx from 0 to (1- (length *foreign-type-spec-table*))
            when spec
            collect
              `(defmethod %lisp-type->type-spec ((lisp-type-kw (eql ',(%lisp-symbol spec))))
                 (elt *foreign-type-spec-table* ,idx)))
       ))

  (defmethod %lisp-type->type-spec (lisp-type-kw)
    (error "Unknown FLI lisp type ~S - cannot determine type spec." lisp-type-kw))
  ) ;; eval-when

;;; %FOREIGN-TYPE-SIZE
(eval-when (:compile-toplevel :load-toplevel :execute)

  (defgeneric %foreign-type-size (lisp-type-kw))

  (defmacro generate-foreign-type-size-functions ()
    `(progn
       ;; type -> type spec
       ,@(loop for spec across *foreign-type-spec-table*
            for idx from 0 to (1- (length *foreign-type-spec-table*))
            when spec
            collect
              `(defmethod %foreign-type-size ((lisp-type-kw (eql ',(%lisp-symbol spec))))
                 (%size (elt *foreign-type-spec-table* ,idx))))
       ))

  (defmethod %foreign-type-size (lisp-type-kw)
    (error "Unknown FLI lisp type ~S - cannot determine foreign size." lisp-type-kw))
  ) ;; eval-when

;;; %FOREIGN-TYPE-ALIGNMENT
(eval-when (:compile-toplevel :load-toplevel :execute)

  (defgeneric %foreign-type-alignment (lisp-type-kw))

  (defmacro generate-foreign-type-alignment-functions ()
    `(progn
       ;; type -> type spec
       ,@(loop for spec across *foreign-type-spec-table*
            for idx from 0 to (1- (length *foreign-type-spec-table*))
            when spec
            collect
              `(defmethod %foreign-type-alignment ((lisp-type-kw (eql ',(%lisp-symbol spec))))
                 (%alignment (elt *foreign-type-spec-table* ,idx))))
       ))

  (defmethod %foreign-type-alignment (lisp-type-kw)
    (error "Unknown FLI lisp type ~S - cannot determine foreign alignment." lisp-type-kw))
  ) ;; eval-when

;;; === T R A N S L A T O R    S U P O R T ===

(defgeneric %lisp-type->llvm-type-symbol (lisp-type-kw))

(defmacro generate-llvm-type-symbol-accessor-functions ()
  `(progn
     ;; type -> llvm type symbol
     ,@(loop for spec across *foreign-type-spec-table*
          for idx from 0 to (1- (length *foreign-type-spec-table*))
          when spec
	  collect
	    `(defmethod %lisp-type->llvm-type-symbol ((lisp-type-kw (eql ',(%lisp-symbol spec))))
               (%llvm-type-symbol (elt *foreign-type-spec-table* ,idx))))
     ))

(defmethod %lisp-type->llvm-type-symbol (lisp-type-kw)
  (error "Unknown FLI lisp type ~S - cannot determine llvm type symbol." lisp-type-kw))

(eval-when (:compile-toplevel :load-toplevel :execute)

  (defun init-translators ()

    (%set-llvm-type-symbol (%lisp-type->type-spec :short) 'cmp::%i16%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :unsigned-short) 'cmp::%i16%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :ushort) 'cmp::%i16%)

    (%set-llvm-type-symbol (%lisp-type->type-spec :int) 'cmp::%i32%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :unsigned-int) 'cmp::%i32%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :uint) 'cmp::%i16%)

    (%set-llvm-type-symbol (%lisp-type->type-spec :long) 'cmp::%i64%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :unsigned-long) 'cmp::%i64%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :ulong) 'cmp::%i64%)

    (%set-llvm-type-symbol (%lisp-type->type-spec :long-long) 'cmp::%i128%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :llong) 'cmp::%i128%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :unsigned-long-long) 'cmp::%i128%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :ullong) 'cmp::%i128%)

    (%set-llvm-type-symbol (%lisp-type->type-spec :int8) 'cmp::%i8%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :uint8) 'cmp::%i8%)

    (%set-llvm-type-symbol (%lisp-type->type-spec :int16) 'cmp::%i16%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :uint16) 'cmp::%i16%)

    (%set-llvm-type-symbol (%lisp-type->type-spec :int32) 'cmp::%i32%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :uint32) 'cmp::%i32%)

    (%set-llvm-type-symbol (%lisp-type->type-spec :int64) 'cmp::%i64%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :uint64) 'cmp::%i64%)

    #+int128 (%set-llvm-type-symbol (%lisp-type->type-spec :int128) 'cmp::%i128%)
    #+int128 (%set-llvm-type-symbol (%lisp-type->type-spec :uint128) 'cmp::%i128%)

    (%set-llvm-type-symbol (%lisp-type->type-spec :size) 'cmp::%size_t%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :ssize) 'cmp::%size_t%)

    (%set-llvm-type-symbol (%lisp-type->type-spec :single-float) 'cmp::%float%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :float) 'cmp::%float%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :double) 'cmp::%double%)
    #+long-float (%set-llvm-type-symbol (%lisp-type->type-spec :long-float) 'cmp::%long-float%)

    (%set-llvm-type-symbol (%lisp-type->type-spec :pointer) 'cmp::%i64*%)

    (%set-llvm-type-symbol (%lisp-type->type-spec :void) 'cmp::%void%)

    (%set-llvm-type-symbol (%lisp-type->type-spec :char) 'cmp::%i8%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :unsigned-char) 'cmp::%i8%)
    (%set-llvm-type-symbol (%lisp-type->type-spec :uchar) 'cmp::%i8%)

    ;; TODO: CHECK & IMPLEMEMT !
    ;; (%set-llvm-type-symbol (%lisp-type->type-spec :time) 'cmp::+time_t+)
    ;; (%set-llvm-type-symbol (%lisp-type->type-spec :ptrdiff) 'cmp::+ptrdiff_t+)

    )

  (defun safe-translator-type (lisp-type-kw)
    (symbol-value (%lisp-type->llvm-type-symbol lisp-type-kw)))

  (defun safe-translator-to-object-name (lisp-type-kw)
    (%to-object-fn-name (%lisp-type->type-spec lisp-type-kw)))

  (defun safe-translator-from-object-name (lisp-type-kw)
    (%from-object-fn-name (%lisp-type->type-spec lisp-type-kw)))

  ) ;; eval-when

;;; === B U I LT - I N   O P E R A T I O N S ===

;;; === P O I N T E R   O P E R A T I O N S ===

;;; Implemented directly in C++:
;;; - %pointerp
;;; - %null-pointer
;;; - %null-pointer-p
;;; - %make-pointer
;;; - %inc-pointer

;;; === F O R E I G N - A L L O C / - F R E E ===

(declaim (inline %foreign-alloc))
(defun %foreign-alloc (size)
  (%allocate-foreign-data size))

(declaim (inline %foreign-free))
(defun %foreign-free (ptr)
  (%free-foreign-data ptr))

;;; These code lines were debugged with the help of drneister, stassats and
;;; Shinmera on 2016-09-22 as a joint effort on IRC channel #clasp. Thx again!!

;;; === M E M - R E F ===

(defgeneric %mem-ref (ptr type &optional offset))

(defmacro generate-mem-ref-accessor-functions ()
  `(progn
     ,@(loop for spec across *foreign-type-spec-table*
          when spec
	  collect
	    `(defmethod %mem-ref (ptr (type (eql ',(%lisp-symbol spec))) &optional (offset 0))
	       (funcall ',(intern (concatenate 'string "%MEM-REF-" (string (%lisp-symbol spec))) 'clasp-ffi)
                        (%offset-address-as-integer ptr offset))))))

(defmethod %mem-ref (ptr type &optional offset)
  (declare (ignore ptr offset))
  (error "Unknown lisp type ~S for %mem-ref." type))

;;; === M E M - S E T ===

(defgeneric %mem-set (ptr type value &optional offset))

(defmacro generate-mem-set-accessor-functions ()
  `(progn
     ,@(loop for spec across *foreign-type-spec-table*
          when spec
	  collect
	    `(defmethod %mem-set (ptr (type (eql ',(%lisp-symbol spec))) value &optional (offset 0))
	       (funcall ',(intern (concatenate 'string "%MEM-SET-" (string (%lisp-symbol spec))) 'clasp-ffi)
                        (%offset-address-as-integer ptr offset) value)))))

(defmethod %mem-set (ptr type value &optional offset)
  (declare (ignore ptr offset value))
  (error "Unknown lisp type ~S for %mem-set." type))

;;; === F O R E I G N   F U N C T I O N  C A L L I N G ===

;;; This code has been invented on-the-fly by drmeister on 2016-10-13 ...
;;; I still marvel at how drmeister comes up with simple code... Thx!

(eval-when (:compile-toplevel :load-toplevel :execute)

  (defun translator-name (prefix direction type)
    (format nil "~a~a_object_~a"
            prefix direction
            (string-downcase (string (%lisp-name (%lisp-type->type-spec type))))))

  (defun to-translator-name (type)
    (translator-name "" "to" type))

  (defun from-translator-name (type)
    (translator-name "tr_" "from" type))

  (defun no-tr-to-translator-name (type)
    (translator-name "" "to" type))

  (defun no-tr-from-translator-name (type)
    (translator-name "" "from" type))

  (defun split-list (list)
    (do ((list list (rest (rest list)))
         (left '() (list* (first list) left))
         (right '() (if (endp (rest list)) right (list* (second list) right))))
        ((endp list) (list (nreverse left) (nreverse right)))))

  (defun extract-signature (arguments)
    "Converts (:float 16.0 :int 3 :float) -> (values '(:float (:float :int)) (16.0 3))"
    (let* ((types-args (clasp-ffi::split-list arguments))
           (types (car types-args))
           (args (cadr types-args))
           (arg-types (butlast types))
           (last (car (last types))))
      (values (list last arg-types) args)))
      
  (defun split-arguments (arguments)
    (let* ((splits (split-list arguments))
           (types-and-maybe-return-type (car splits))
           (args (cadr splits))
           (explicit-return-type (> (length types-and-maybe-return-type) (length args)))
           (return-type (if explicit-return-type
                            (car (last types-and-maybe-return-type))
                            :void))
           (types (if explicit-return-type
                      (butlast types-and-maybe-return-type 1)
                      types-and-maybe-return-type)))
      #| ;;; debug info output
      (fli-debug "/Users/frgo/swdev/clasp/src/clasp/src/lisp/kernel/lsp/arguments = ~S~&" arguments)
      (fli-debug "splits = ~S~&" splits)
      (fli-debug "types-and-maybe-return-type = ~S~&" types-and-maybe-return-type)
      (fli-debug "args = ~S~&" args)
      (fli-debug "explicit-return-type = ~S~&" explicit-return-type)
      (fli-debug "return-type = ~S~&" return-type)
      (fli-debug "types = ~S~&" types)
      |#
      (values (loop for type in types
                 for arg in args
                 collect `(core:foreign-call
                           ,(from-translator-name type)
                           ,arg))
              return-type)))

  (defun process-arguments (arguments)
    ;; (fli-debug "PROCESS-ARGUMENTS: arguments = ~S~&" arguments)
    (cond

      ((null arguments)
       (values nil :void))

      ((and (listp arguments)
            (not (listp (car arguments)))
            (> (length arguments) 1))
       (split-arguments arguments))

      ((and (listp arguments)
            (not (listp (car arguments)))
            (= (length arguments) 1))
       (values nil (car arguments)))

      ((and (listp arguments)
            (listp (car arguments))
            (= (length arguments) 1))
       (split-arguments (car arguments)))

      (t (error "%foreign-funcall/process-arguments: Malformed arguments for foreign funcall: ~S" arguments))))

  ) ;; EVAL-WHEN

(defmacro %foreign-funcall (name &rest arguments)
  (multiple-value-bind (signature args)
      (extract-signature arguments)
    ;; (fli-debug "%FOREIGN-FUNCALL: ARGS = ~S, RETURN-TYPE = ~S~&"
    ;;         args return-type )
    `(core:foreign-call-pointer ,signature (ensure-core-pointer (core:dlsym :rtld-default ,name)) ,@args)))

(defmacro %foreign-funcall-pointer (ptr &rest arguments)
  (multiple-value-bind (signature args)
      (extract-signature arguments)
    `(core:foreign-call-pointer ,signature (ensure-core-pointer ,ptr) ,@args)))

;;; === F O R E I G N   L I B R A R Y   H A N D L I N G ===

(declaim (inline %load-foreign-library))
(defun %load-foreign-library (name path)
  "Load a foreign library to be found at path. (name is ignored)"
  (declare (ignore name))
  (%dlopen path))

(declaim (inline %close-foreign-library))
(defun %close-foreign-library (ptr)
  "Close a foreign library."
  (%dlclose ptr))

;;; === F O R E I G N   G L O B A L S ===

(declaim (inline %foreign-symbol-pointer))
(defun %foreign-symbol-pointer (name module)
  "Return a pointer (of type ForeignData_sp / FOREIGN_DATA to a foreign symbol."
  (declare (ignore module))
  (%dlsym name))

;;;----------------------------------------------------------------------------
;;;
;;; F L I   I N I T I A L I Z A T I O N

(eval-when (:load-toplevel :execute :compile-toplevel)
  (generate-type-spec-accessor-functions)
  (init-translators)
  (generate-llvm-type-symbol-accessor-functions)
  (generate-mem-ref-accessor-functions)
  (generate-mem-set-accessor-functions)
  (generate-foreign-type-size-functions)
  (generate-foreign-type-alignment-functions)
  (values))

;;;----------------------------------------------------------------------------
;;;----------------------------------------------------------------------------
;;; C A L L B A C K  S U P P O R T

;;; Agsin, drmeister did most of the work. This was adapted to run in the
;;; CLASP-FFI package.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun mangled-callback-name (name)
    (format nil "clasp_ffi_cb_~a" name)))

(defun %expand-callback-definition (name-and-options return-type-kw argument-symbols argument-type-kws body)

  #+(or)(fli-debug "%expand-callback-definition: name-and-options = ~S, return-tyoe-kw = ~S, argument-symbols = ~S, argument-type-kws = ~S, body = ~S~&"
                   name-and-options return-type-kw argument-symbols argument-type-kws body )

  (multiple-value-bind (function-name convention)
      (if (consp name-and-options)
          (destructuring-bind (name &key convention)
              name-and-options
            (values name convention))
          (values name-and-options :cdecl))
    ;; Convert type keywords into llvm types ie: :int -> %i32%
    (let* ((body-form `(lambda ,argument-symbols ,@body))
           (argument-names (mapcar (lambda (s)
                                     (fli-debug "s = ~a~%" s) (string s))
                                   argument-symbols))
           (mangled-function-name (mangled-callback-name function-name))
           (return-type (safe-translator-type return-type-kw ))
           (argument-types (mapcar (lambda (type-kw)
                                     (safe-translator-type type-kw))
                                   argument-type-kws))
           ;; Get the type of the function
           (function-type (llvm-sys:function-type-get return-type argument-types))
           ;; Create a new llvm function in the current llvm Module cmp:*the-module*
           (new-func (llvm-sys:function-create function-type
                                               'llvm-sys:external-linkage
                                               mangled-function-name
                                               cmp::*the-module*))
           (cmp::*current-function* new-func)
           (cmp::*current-function-name* mangled-function-name)
           ;; Create an IRBuilder - a helper for adding instructions to func
           (irbuilder-cur (llvm-sys:make-irbuilder cmp::*llvm-context*)))
      ;;(format t "Created function ~a in ~a~%" (llvm-sys:get-name new-func) cmp:*the-module*)
      ;; Create the entry basic block in the current function
      (let ((bb (cmp::irc-basic-block-create "entry" cmp::*current-function*)))
        (llvm-sys:set-insert-point-basic-block irbuilder-cur bb)
        ;; Start generating instructions
        (cmp::with-irbuilder (irbuilder-cur)
          ;; (1) Call the translators for every argument returning a value in a llvm register
          ;;       Get the c-args from the function argument list
          (let* ((c-args (mapcar #'(lambda (arg argname)
                                     (llvm-sys:set-name arg argname)
                                     arg)
                                 (llvm-sys:get-argument-list new-func) argument-names))
                 ;; Call a translator for each c-arg and accumulate a list of cl-args in registers
                 (cl-args (mapcar (lambda (c-arg arg-type-kw arg-name)
                                    (let* ((to-object-name (no-tr-to-translator-name arg-type-kw))
                                           (trans-arg-name (format nil "translated-~a" arg-name))
                                           ;; Create the function declaration on the fly
                                           (to-object-func (cmp::get-function-or-error cmp::*the-module* to-object-name)))
                                      (llvm-sys:create-call-array-ref
                                       cmp::*irbuilder*
                                       to-object-func
                                       (list c-arg)
                                       trans-arg-name nil)))
                                  c-args argument-type-kws argument-names)))
            ;; (2) Call the closure with the arguments in registers
            (let* ((real-args (if (< (length cl-args) core:+number-of-fixed-arguments+)
                                  (append cl-args (make-list (- core:+number-of-fixed-arguments+ (length cl-args)) :initial-element (cmp::null-t-ptr)))
                                  cl-args))
                   (function-object (if core:*use-cleavir-compiler*
                                        (funcall (find-symbol "COMPILE-LAMBDA-FORM-TO-LLVM-FUNCTION" :clasp-cleavir) body-form)
                                        (cmp::compile-lambda-function body-form)))
                   (invoke-fn (cmp::get-function-or-error cmp::*the-module* "cc_call_callback"))
                   (fptr (cmp:irc-bit-cast function-object cmp:%t*% "fptr-t*"))
                   (cl-result (llvm-sys:create-call-array-ref
                               cmp::*irbuilder*
                               invoke-fn
                               (list* fptr (cmp::null-t-ptr) (cmp:jit-constant-size_t (length cl-args)) real-args) "cl-result")))
              ;; (3) Call the translator for the return value
              (if (eq return-type-kw :void)
                  ;; Return with void
                  (llvm-sys:create-ret-void cmp::*irbuilder*)
                  ;; Return the result
                  (let* ((from-object-name (no-tr-from-translator-name return-type-kw))
                         (from-object-func (cmp::get-function-or-error cmp::*the-module* from-object-name))
                         (c-result (llvm-sys:create-call-array-ref
                                    cmp::*irbuilder*
                                    from-object-func
                                    (list (llvm-sys:create-extract-value cmp::*irbuilder* cl-result (list 0) "val0"))
                                    "cl-result" nil)))
                    (llvm-sys:create-ret cmp::*irbuilder* c-result))))))))
    `',function-name))

(defmacro %defcallback (name-and-options return-type-kw argument-symbols argument-type-kws &rest body)
  (%expand-callback-definition name-and-options return-type-kw argument-symbols argument-type-kws body))

(defmacro %callback (sym)
  `(%get-callback ',sym))

(defun %get-callback (sym-name)
  (if sym-name
      ;;; QUESTION: This was dlsym% - was that a typo?
      (%dlsym (mangled-callback-name sym-name))
      nil))

;;;----------------------------------------------------------------------------
;;;----------------------------------------------------------------------------
;;; E X P O R T S

(eval-when (:load-toplevel :execute :compile-toplevel)
  (export '(with-foreign-object
            with-foreign-objects
            %foreign-alloc
            %foreign-free
            %mem-ref
            %mem-set
            %foreign-funcall
            %foreign-funcall-pointer
            %load-foreign-library
            %close-foreign-library
            %foreign-symbol-pointer
            %foreign-type-size
            %foreign-type-alignment
            %defcallback
            %callback
            %get-callback)))

;;;----------------------------------------------------------------------------
;;;----------------------------------------------------------------------------
;;; T E S T I N G

#+(or)
(defun test-ffi ()

  (format *debug-io* "*** TEST 1: %MEM-SET and %MEM-REF ...~&")
  (format *debug-io* "    Expected results: a = 47111, b = 47112.~&")

  (let* ((*v1* (%allocate-foreign-object :uint32))
         (a nil)
         (b nil)
         (fa (%foreign-data-address *v1*)))

    ;; --- WITH LOW-LEVEL CALLS ---
    (%mem-set-uint32 fa 47111)
    (setq a (%mem-ref-uint32 fa))

    ;; --- WITH HIGH-LEVEL CALLS ---
    (%mem-set fa :uint32 47112)
    (setq b (%mem-ref fa :uint32))

    (format *debug-io* "*** a = ~S, b = ~S.~&" a b))

  (format *debug-io* "*** TEST 2: %FOREIGN-FUNCALL ...~&")
  (format *debug-io* " => (%foreign-funcall \"fli_test_add\" (:int 2 :short 45 :int)) -> ~S~&" (%foreign-funcall "fli_test_add" (:int 2 :short 45 :int)))

  (format *debug-io* "*** TEST 3: %FOREIGN-FUNCALL-POINTER ...~&")
  (let ((fn-addr (%dlsym "fli_test_mul2_uint32")))
    (format *debug-io* " => for function fli_test_mul2_uint32: (%foreign-funcall-pointer ~S (:uint32 45 :uint32)) -> ~S~&" fn-addr (%foreign-funcall-pointer fn-addr (:uint32 45 :uint32))))

  (format *debug-io* "*** TEST 4: %FOREIGN-FUNCALL-POINTER ...~&")
  (let ((fn-addr (%dlsym "fli_test_mul2_long")))
    (format *debug-io* " => for function fli_test_mul2_long: (%foreign-funcall-pointer ~S (:long 45 :long)) -> ~S~&" fn-addr (%foreign-funcall-pointer fn-addr (:long 45 :long))))

  )

#+(or)
(defun dbg-numeric-limits ()
  (%foreign-funcall "info_numeric_limits"))
