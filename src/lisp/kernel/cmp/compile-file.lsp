(in-package #:cmp)

#+(or)
(eval-when (:execute)
  (setq core:*echo-repl-read* t))

;;;; Top level interface: COMPILE-FILE, etc.

;;; Use the *cleavir-compile-file-hook* to determine which compiler to use
;;; if nil == bclasp. Code for the bclasp compiler is in codegen-toplevel.lsp;
;;; look for t1expr.

(defvar *compile-verbose* t)
(defvar *compile-print* t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Describing top level forms (for compile-print)

(defun describe-form (form)
  ;; We could be smarter about this. For example, for (progn ...) nothing very interesting
  ;; will print, even though subforms are just as toplevel.
  ;; But it's just aesthetic, so cheaping out a little is okay.
  (fresh-line)
  (write-string ";   ")
  (write form :length 2 :level 2 :lines 1 :pretty nil)
  (terpri)
  (values))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Compilation units

(defvar *compiler-real-time*)
(defvar *compiler-run-time*)
(defvar *compiler-timer-protection* nil)

(defun do-compiler-timer (closure &rest args &key message report-link-time verbose override)
  (cond (override
	 (let* ((*compiler-timer-protection* nil))
	   (apply #'do-compiler-timer closure args)))
	((null *compiler-timer-protection*)
	 (let* ((*compiler-timer-protection* t)
                (llvm-sys:*accumulated-llvm-finalization-time* 0)
                (llvm-sys:*number-of-llvm-finalizations* 0)
                (*compiler-real-time* (get-internal-real-time))
                (*compiler-run-time* (get-internal-run-time))
                (llvm-sys:*accumulated-clang-link-time* 0)
                (llvm-sys:*number-of-clang-links* 0))
           (multiple-value-prog1
               (do-compiler-timer closure)
             (let ((llvm-finalization-time llvm-sys:*accumulated-llvm-finalization-time*)
                   (compiler-real-time (/ (- (get-internal-real-time) *compiler-real-time*) (float internal-time-units-per-second)))
                   (compiler-run-time (/ (- (get-internal-run-time) *compiler-run-time*) (float internal-time-units-per-second)))
                   (link-time llvm-sys:*accumulated-clang-link-time*))
               (when verbose
                 #+(or)
                 (let* ((link-string (if report-link-time
                                        (core:bformat nil " link(%.1f)" link-time)
                                        ""))
                        (total-llvm-time (+ llvm-finalization-time (if report-link-time
                                                                       link-time
                                                                       0.0)))
                        (percent-llvm-time (if (zerop compiler-real-time)
                                               0.0
                                               (* 100.0 (/ total-llvm-time compiler-real-time))))
                        (percent-time-string
                          (if report-link-time
                              (core:bformat nil "(llvm+link)/real(%1.f%%)" percent-llvm-time)
                              (core:bformat nil "llvm/real(%1.f%%)" percent-llvm-time))))
                   (core:bformat t "   %s seconds real(%.1f) run(%.1f) llvm(%.1f)%s %s%N"
                                 message
                                 compiler-real-time
                                 compiler-run-time
                                 llvm-finalization-time
                                 link-string
                                 percent-time-string)
                   (finish-output)))))))
        (t (funcall closure))))

(defmacro with-compiler-timer ((&key message report-link-time verbose override) &rest body)
  `(do-compiler-timer (lambda () (progn ,@body)) :message ,message :report-link-time ,report-link-time :verbose ,verbose))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Compile-file pathnames

;;; I wonder, why that doesn't take core:*clasp-build-mode* into account
(defun cfp-output-extension (output-type)
  (let ((result (cond
                  ((eq output-type :bitcode) (if *use-human-readable-bitcode* "ll" "bc"))
                  ((and (eq *default-object-type* :faso) (eq output-type :object)) "faso")
                  ((eq output-type :object) "o")
                  ((eq output-type :fasl) "fasl")
                  ((eq output-type :faso) "faso")
                  ((eq output-type :fasoll) "fasoll")
                  ((eq output-type :fasobc) "fasobc")
                  ((eq output-type :faspll) "faspll")
                  ((eq output-type :faspbc) "faspbc")
                  ((eq output-type :fasp) "fasp")
                  ((eq output-type :executable) #-windows "" #+windows "exe")
                  (t (error "unsupported output-type ~a" output-type)))))
    (let ((build-extension (core:build-extension output-type)))
      (unless (string= build-extension result)
        (error "For output-type ~s there is a mismatch between cfp-extension (~s) and build-extension (~s) - if this never happens then get rid of cfp-extension" output-type result build-extension)))
    result))

(defun cfp-output-file-default (input-file output-type &key target-backend)
  (let* ((defaults (merge-pathnames input-file *default-pathname-defaults*)))
    (when target-backend
      (setq defaults (make-pathname :host target-backend :defaults defaults)))
    (make-pathname :type (cfp-output-extension output-type)
                   :defaults defaults)))


;;; Copied from sbcl sb!xc:compile-file-pathname
;;;   If INPUT-FILE is a logical pathname and OUTPUT-FILE is unsupplied,
;;;   the result is a logical pathname. If INPUT-FILE is a logical
;;;   pathname, it is translated into a physical pathname as if by
;;;   calling TRANSLATE-LOGICAL-PATHNAME.
;;; So I haven't really tried to make this precisely ANSI-compatible
;;; at the level of e.g. whether it returns logical pathname or a
;;; physical pathname. Patches to make it more correct are welcome.
(defun compile-file-pathname (input-file &key (output-file nil output-file-p)
                                           (output-type (default-library-type) output-type-p)
					   type
					   target-backend
                              &allow-other-keys)
  (setf output-type (maybe-fixup-output-type output-type output-type-p))
  (when type (error "Clasp compile-file-pathname uses :output-type rather than :type"))
  (let* ((pn (if output-file-p
		 (merge-pathnames output-file (translate-logical-pathname (cfp-output-file-default input-file output-type :target-backend target-backend)))
		 (cfp-output-file-default input-file output-type :target-backend target-backend)))
         (ext (cfp-output-extension output-type)))
    (if (or output-type-p (not output-file-p))
        (make-pathname :type ext :defaults pn)
        pn)))

(defun cf-module-name (type pathname)
  "Create a module name from the TYPE (either :user or :kernel)
and the pathname of the source file - this will also be used as the module initialization function name"
  (string-downcase (bformat nil "___%s_%s" (string type) (pathname-name pathname))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Compile-file proper

(defvar *triple* nil)

(defun generate-obj-asm-stream (module output-stream file-type reloc-model &key (target-faso-file *default-object-type*))
  (with-track-llvm-time
      (progn
        (unless *triple*
          (let* ((triple-string (llvm-sys:get-target-triple module))
                 (normalized-triple-string (llvm-sys:triple-normalize triple-string))
                 (triple (llvm-sys:make-triple normalized-triple-string)))
            (setf *triple* triple)))
        (let* ((triple *triple*)
               (target-options (llvm-sys:make-target-options)))
          (multiple-value-bind (target msg)
              (llvm-sys:target-registry-lookup-target "" triple)
            (unless target (error msg))
            (let* ((target-machine (llvm-sys:create-target-machine target
                                                                   (llvm-sys:get-triple triple)
                                                                   ""
                                                                   ""
                                                                   target-options
                                                                   reloc-model
                                                                   (code-model :jit nil :target-faso-file target-faso-file)
                                                                   'llvm-sys:code-gen-opt-default
                                                                   NIL ; JIT?
                                                                   ))
                   (pm (llvm-sys:make-pass-manager))
                   (target-pass-config (llvm-sys:create-pass-config target-machine pm))
                   (_ (llvm-sys:set-enable-tail-merge target-pass-config nil))
                   (tli (llvm-sys:make-target-library-info-wrapper-pass triple #||LLVM3.7||#))
                   (data-layout (llvm-sys:create-data-layout target-machine)))
              (llvm-sys:set-data-layout module data-layout)
              (llvm-sys:pass-manager-add pm tli)
              (llvm-sys:add-passes-to-emit-file-and-run-pass-manager target-machine pm output-stream nil #|<-dwo-stream|# file-type module)))))))


(defun compile-file-generate-obj-asm (module output-pathname &key file-type (reloc-model 'llvm-sys:reloc-model-undefined))
  (with-atomic-file-rename (temp-output-pathname output-pathname)
    (with-open-file (output-stream temp-output-pathname :direction :output)
      (generate-obj-asm-stream module output-stream file-type reloc-model :target-faso-file nil))))

(defvar *debug-compile-file* nil)
(defvar *debug-compile-file-counter* 0)

(defvar *compile-file-output-pathname* nil)

(defun compile-file-source-pos-info (stream)
  (core:input-stream-source-pos-info
   stream *compile-file-file-scope*
   *compile-file-source-debug-lineno* *compile-file-source-debug-offset*))

(defun bclasp-loop-read-and-compile-file-forms (source-sin environment)
  (let ((eof-value (gensym)))
    (loop
      ;; Required to update the source pos info. FIXME!?
      (peek-char t source-sin nil)
      ;; FIXME: if :environment is provided we should probably use a different read somehow
      (let ((core:*current-source-pos-info* (compile-file-source-pos-info source-sin))
            (form (read source-sin nil eof-value)))
        (if (eq form eof-value)
            (return nil)
            (progn
              (when *compile-print* (describe-form form))
              (when *debug-compile-file* (bformat t "compile-file: cf%d -> %s%N" (incf *debug-compile-file-counter*) form))
              (core:with-memory-ramp (:pattern 'gctools:ramp)
                (t1expr form))))))))

(defun loop-read-and-compile-file-forms (source-sin environment compile-file-hook)
  ;; If the Cleavir compiler hook is set up then use that
  ;; to generate code
  (if compile-file-hook
      (funcall compile-file-hook source-sin environment)
      (bclasp-loop-read-and-compile-file-forms source-sin environment)))

(defun compile-file-to-module (given-input-pathname
                               &key
                                 compile-file-hook
                                 type
                                 output-type
                                 environment
                                 image-startup-position
                                 (optimize t)
                                 (optimize-level *optimization-level*)
                                 external-format)
  "* Arguments
- given-input-pathname :: A pathname.
- output-path :: A pathname.
- compile-file-hook :: A function that will do the compile-file
- type :: :kernel or :user (I'm not sure this is useful anymore)
- environment :: Arbitrary, passed only to hook
Compile a lisp source file into an LLVM module."
  ;; TODO: Save read-table and package with unwind-protect
  (let* ((*package* *package*)
         (input-pathname (or (probe-file given-input-pathname)
			     (error 'core:simple-file-error
				    :pathname given-input-pathname
				    :format-control "compile-file-to-module could not find the file ~s to open it"
				    :format-arguments (list given-input-pathname))))
         (source-sin (open input-pathname :direction :input :external-format (or external-format :default)))
         (module (llvm-create-module (namestring input-pathname)))
	 (module-name (cf-module-name type given-input-pathname)))
    (or module (error "module is NIL"))
    (with-open-stream (sin source-sin)
      (when *compile-verbose*
	(bformat t "; Compiling file: %s%N" (namestring input-pathname)))
      (let (run-all-name)
        (with-module (:module module
                      :optimize (when optimize #'optimize-module-for-compile-file)
                      :optimize-level optimize-level)
          ;; (1) Generate the code
          (with-debug-info-generator (:module *the-module*
                                      :pathname *compile-file-source-debug-pathname*)
            (or module (error "module is NIL"))
            (with-make-new-run-all (run-all-function (namestring input-pathname))
              (with-literal-table (:id 0)
                  (loop-read-and-compile-file-forms source-sin environment compile-file-hook))
              (setf run-all-name (llvm-sys:get-name run-all-function))))
          (cmp-log "About to verify the module%N")
          (cmp-log-dump-module *the-module*)
          (irc-verify-module-safe *the-module*)
          (quick-module-dump *the-module* "preoptimize")
          ;; (2) Add the CTOR next
          (make-boot-function-global-variable module run-all-name
                                              :position image-startup-position
                                              :register-library t))
        ;; Now at the end of with-module another round of optimization is done
        ;; but the RUN-ALL is now referenced by the CTOR and so it won't be optimized away
        ;; ---- MOVE OPTIMIZATION in with-module to HERE ----
        )
      (quick-module-dump module "postoptimize")
      module)))

(defun generate-info (input-file output-info-pathname)
  "Write information about the compile-file to the .info file"
  (with-open-file (fout output-info-pathname :direction :output :if-exists :supersede)
    (format fout "Compile-file-info ~a~%" input-file)
    (maphash (lambda (inlinee-name count-ht)
               (let ((is-inline (gethash :inline count-ht)))
                 (maphash (lambda (inlined-name count)
                            (unless (eq :inline inlined-name)
                              (let ((real-count (if is-inline
                                                    (/ count 3)
                                                    count)))
                                (format fout "inlined-into \"~a\" \"~a\" ~a~%"
                                        (cmp:jit-function-name inlinee-name)
                                        (cmp:jit-function-name inlined-name)
                                        real-count))))
                          count-ht)))
             *track-inlined-functions*)))

(defun default-object-type ()
  *default-object-type*)

(defun default-library-type (&optional (output-type *default-object-type*))
  (case output-type
    (:faso :fasp)
    (:object :fasl)
    (:fasoll :faspll)
    (:fasobc :faspbc)
    (:faspll :faspll)
    (:faspbc :faspbc)
    (otherwise (error "Handle output-type for ~a" output-type))))

(defun maybe-fixup-output-type (output-type output-type-p)
  (when output-type-p
    (cond
      ((eq output-type :object)
       (setf output-type (default-object-type)))
      ((eq output-type :fasl)
       (setf output-type (default-library-type)))))
  output-type)


(defun compile-file-serial (input-file
                            &key
                              (output-file nil output-file-p)
                              (verbose *compile-verbose*)
                              (print *compile-print*)
                              (optimize t)
                              (optimize-level *optimization-level*)
                              (external-format :default)
                              (source-debug-pathname nil cfsdpp)
                              (source-debug-lineno 0)
                              (source-debug-offset 0)
                              ;; output-type can be (or :fasl :bitcode :object)
                              ;; logic needs to be consistent with compile-file-serial and cfp-output-extension
                              (output-type (default-library-type) output-type-p)
                              ;; type can be either :kernel or :user
                              (type :user)
                              ;; A unique prefix for symbols of compile-file'd files that
                              ;; will be linked together
                              (unique-symbol-prefix "")
                              ;; Control the order of startup functions
                              (image-startup-position (core:next-startup-position)) 
                              ;; Generate an info file for the compilation T or NIL
                              (output-info (member :DEBUG-COMPILE-FILE-OUTPUT-INFO *features*))
                              ;; ignored by bclasp
                              ;; but passed to hook functions
                              environment)
  "See CLHS compile-file."
  #+debug-monitor(sys:monitor-message "compile-file ~a" input-file)
  (setf output-type (maybe-fixup-output-type output-type output-type-p))
  (let* ((*compile-file-parallel* nil))
    (if (not output-file-p) (setq output-file (cfp-output-file-default input-file output-type)))
    (with-compiler-env ()
      (let* ((output-path
               (if output-type-p
                    (compile-file-pathname input-file :output-file output-file :output-type output-type)
                    (compile-file-pathname input-file :output-file output-file)))
             (*track-inlined-functions* (make-hash-table :test #'equal))
             (output-info-pathname (when output-info (make-pathname :type "info" :defaults output-path)))
             (*compilation-module-index* 0) ; FIXME: necessary?
             ;; KLUDGE: We could just bind these in the lambda list,
             ;; except the interpreter can't handle that and will die messily.
             (*compile-verbose* verbose)
             (*compile-print* print)
             (*compile-file-pathname* (pathname (merge-pathnames input-file)))
             (*compile-file-truename* (translate-logical-pathname *compile-file-pathname*))
             (*compile-file-source-debug-pathname*
               (if cfsdpp source-debug-pathname *compile-file-truename*))
             (*compile-file-file-scope*
               (core:file-scope *compile-file-source-debug-pathname*))
             (*compile-file-source-debug-lineno* source-debug-lineno)
             (*compile-file-source-debug-offset* source-debug-offset)
             (*compile-file-output-pathname* output-path)
             (*compile-file-unique-symbol-prefix* unique-symbol-prefix))
        (when print (format t "compile-file-serial ~a image-startup-position: ~a~%" output-path image-startup-position))
        (with-compiler-timer (:message "Compile-file" :report-link-time t :verbose *compile-verbose*)
          (with-compilation-results ()
            (let ((module (compile-file-to-module input-file
                                                  :type type
                                                  :output-type output-type
                                                  :compile-file-hook *cleavir-compile-file-hook*
                                                  :environment environment
                                                  :image-startup-position image-startup-position
                                                  :optimize optimize
                                                  :optimize-level optimize-level
                                                  :external-format external-format)))
              (compile-file-output-module module output-file output-type output-path input-file type
                                          :position image-startup-position)
              (when output-info-pathname (generate-info input-file output-info-pathname))
              (gctools:thread-local-cleanup)
              (truename output-path))))))))

(defun reloc-model ()
  (cond
    ((or (member :target-os-linux *features*) (member :target-os-freebsd *features*))
     'llvm-sys:reloc-model-pic-)
    (t 'llvm-sys:reloc-model-undefined)))

(defun output-bitcode (module file &key output-type)
  (with-track-llvm-time
      (write-bitcode module file :output-type output-type)))

(defun output-kernel-fasl (output-file input-file output-type)
  (let ((fasl-output-file (make-pathname :type "fasl" :defaults output-file)))
    (when *compile-verbose*
      (bformat t "Writing %s kernel fasl file to: %s%N" output-type fasl-output-file)
      (finish-output))
    (llvm-link fasl-output-file :input-files (list input-file) :input-type :bitcode)))

(defun compile-file-output-module-to-faso (module output-file input-file
                                           &key position (output-bitcode t))
  "Generate a faso file from the module"
  (when output-bitcode
    (let ((temp-bitcode-file (compile-file-pathname input-file
                                                    :output-file output-file :output-type :bitcode)))
      (ensure-directories-exist temp-bitcode-file)
      (when *compile-verbose*
        (bformat t "Writing temporary bitcode file to: %s%N" temp-bitcode-file))
      (output-bitcode module (core:coerce-to-filename temp-bitcode-file)
                      :output-type :object)))
  (when *compile-verbose*
    (bformat t "Writing faso file to: %s%N" output-file)
    (finish-output))
  (let ((stream (generate-obj-asm-stream module :simple-vector-byte8
                                         'llvm-sys:code-gen-file-type-object-file
                                         (reloc-model))))
    (core:write-faso output-file (list stream) :start-object-id position)))

(defun compile-file-output-module (module output-file output-type output-path input-file type
                                   &key position (output-bitcode t))
  (when (null output-path)
    (error "The output-path is nil for input filename ~a~%" input-file))
  (ensure-directories-exist output-path)
  (cond
    ((eq output-type :object)
     (when *compile-verbose*
       (bformat t "Writing object to: %s%N" (core:coerce-to-filename output-path)))
     ;; save the bitcode so we can look at it.
     (let ((temp-bitcode-file
             (compile-file-pathname input-file :output-file output-file :output-type :bitcode)))
       (ensure-directories-exist temp-bitcode-file)
       (when *compile-verbose*
         (bformat t "Writing temporary bitcode file to: %s%N" temp-bitcode-file))
       (output-bitcode module temp-bitcode-file
                       :output-type (default-library-type output-type))
       (prog1
           (compile-file-generate-obj-asm module output-path
                                          :file-type 'llvm-sys:code-gen-file-type-object-file
                                          :reloc-model (reloc-model))
         (when (eq type :kernel)
           (output-kernel-fasl output-file temp-bitcode-file :object)))))
    ((eq output-type :faso)
     (compile-file-output-module-to-faso module output-file input-file
                                         :position position :output-bitcode output-bitcode))
    ((eq output-type :bitcode)
     (when *compile-verbose*
       (bformat t "Writing bitcode to: %s%N" (core:coerce-to-filename output-path)))
     (prog1 (output-bitcode module (core:coerce-to-filename output-path)
                            :output-type (default-library-type output-type))
       (when (eq type :kernel)
         (output-kernel-fasl output-file output-path :bitcode))))
    ((eq output-type :fasp)
     (let ((temp-bitcode-file (compile-file-pathname input-file
                                                     :output-file output-file :output-type :bitcode)))
       (ensure-directories-exist temp-bitcode-file)
       (when *compile-verbose*
         (bformat t "Writing temporary bitcode file to: %s%N" temp-bitcode-file))
       (output-bitcode module (core:coerce-to-filename temp-bitcode-file)
                       :output-type :object)
       (when *compile-verbose*
         (bformat t "Writing faso file to: %s%N" output-file)
         (finish-output))
       (let ((stream (generate-obj-asm-stream module :simple-vector-byte8
                                              'llvm-sys:code-gen-file-type-object-file
                                              (reloc-model))))
         (core:write-faso output-file (list stream) :start-object-id position))))
    ((member output-type '(:fasoll :faspll))
     (let ((filename (compile-file-pathname input-file :output-file output-file :output-type output-type)))
       (ensure-directories-exist filename)
       (when *compile-verbose*
         (format t "Writing ~a file to: ~a~%" output-type filename))
       (with-atomic-file-rename (temp-pathname filename)
         (with-open-file (fout temp-pathname :direction :output :if-exists :supersede)
           (llvm-sys:dump-module module fout)))))
    ((member output-type '(:fasobc :faspbc))
     (let ((filename (compile-file-pathname input-file :output-file output-file :output-type output-type)))
       (ensure-directories-exist filename)
       (when *compile-verbose*
         (format t "Writing ~a file to: ~a~%" output-type filename))
       (with-atomic-file-rename (temp-pathname filename)
         (llvm-sys:write-bitcode-to-file module (namestring temp-pathname)))))
    ((eq output-type :fasl)
     (let ((temp-bitcode-file (compile-file-pathname input-file
                                                     :output-file output-file :output-type :bitcode)))
       (ensure-directories-exist temp-bitcode-file)
       (when *compile-verbose*
         (bformat t "Writing temporary bitcode file to: %s%N" temp-bitcode-file))
       (output-bitcode module (core:coerce-to-filename temp-bitcode-file)
                       :output-type :object)
       (when *compile-verbose*
         (bformat t "Writing fasl file to: %s%N" output-file)
         (finish-output))
       (llvm-link output-file :input-files (list temp-bitcode-file) :input-type :bitcode)))
    (t ;; Unknown
     (error "Add support to file of type: ~a" output-type)))
  (with-track-llvm-time
      (llvm-sys:module-delete module)))

(export 'compile-file)

(eval-when (:load-toplevel :execute)
  (setf (fdefinition 'compile-file) #'compile-file-serial))

#+(or bclasp cclasp)
(progn
  (defun bclasp-compile-file (input-file &rest args)
    (let ((cmp:*cleavir-compile-hook* nil)
          (cmp:*cleavir-compile-file-hook* nil)
          (core:*use-cleavir-compiler* nil)
          (cmp:*compile-file-parallel* nil)
          (core:*eval-with-env-hook* #'core:interpret-eval-with-env))
      (apply 'compile-file-serial input-file args)))
  (export 'bclasp-compile-file))
