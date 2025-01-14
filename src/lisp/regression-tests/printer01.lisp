(in-package #:clasp-tests)

(test print-1
      (string=
       "-1"
       (LET ((*PRINT-BASE* 16))
         (WITH-OUTPUT-TO-STRING (*STANDARD-OUTPUT*) (write -1)))))

(test print-1a
      (string=
       "-2000000000000000"
       (LET ((*PRINT-BASE* 16))
         (WITH-OUTPUT-TO-STRING (*STANDARD-OUTPUT*)
           (write most-negative-fixnum)))))

(test print-2
      (null
       (multiple-value-list
        (pprint 23))))

(test print-3
      (equal '(nil)
             (MULTIPLE-VALUE-LIST
              (PRINT-UNREADABLE-OBJECT (nil t)))))

(test print-4
      (= 10
         (let ((*package* (find-package "COMMON-LISP-USER"))
               (*print-array* t)
               (*print-base* 10)
               (*print-case* :upcase)
               (*print-circle* nil)
               (*print-escape* t)
               (*print-gensym* t)
               (*print-length* nil)
               (*print-level* nil)
               (*print-lines* nil)
               (*print-miser-width* nil)
               (*print-pretty* nil)
               (*print-radix* nil)
               (*print-readably* t)
               (*print-right-margin* nil)
               (*read-base* 10)
               (*read-default-float-format* 'single-float)
               (*read-eval* t)
               (*read-suppress* nil)
               )
           (let ((*print-pretty* t)
                 (*print-readably* nil)
                 (obj (vector nil nil)))
             (length (write-to-string obj))))))

(test print-5
      (string= "#()"
               (WRITE-TO-STRING
                (MAKE-ARRAY '(4)
                            :INITIAL-CONTENTS
                            '(0 1 2 3)
                            :ELEMENT-TYPE
                            '(UNSIGNED-BYTE 2)
                            :FILL-POINTER
                            0)
                :READABLY NIL :ARRAY T :PRETTY NIL)))

(test print-5a
      (string= "#(1 2 3)"
               (let ((*print-pretty* nil)
                     (*print-array* t)
                     (*print-readably* nil))
                 (write-to-string
                  (make-array 3 :initial-contents '(1 2 3) :fill-pointer t)))))

;;; fails to write readably
;;; http://www.lispworks.com/documentation/HyperSpec/Body/t_rnd_st.htm#random-state
;;; It can be printed out and successfully read back in by the same implementation, 
;;; Implementations are required to provide a read syntax for objects of type random-state,
;;; but the specific nature of that syntax is implementation-dependent.
;;; this would work
;;; (CORE:RANDOM-STATE-set *random-state* (CORE:RANDOM-STATE-GET *random-state*))
;;; So we perhaps need a reader-macro for random-state

(test print-read-1
      (read-from-string (WRITE-TO-STRING (MAKE-RANDOM-STATE *RANDOM-STATE*) :READABLY T)))

(test print-all-array-types
      (let ((arrays
             (list
        ;;; MDArray_O?
              (MAKE-ARRAY (list 2 2) :INITIAL-CONTENTS '((0 1)(1 0)) :ELEMENT-TYPE t)
        ;;; SimpleVector_O
              (vector 1 2 3)
        ;;;BitVector_O
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS '(0 1)
                          :adjustable t
                          :ELEMENT-TYPE 'bit)
        ;;; SIMPLE-VECTOR-BYTE8-T
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS '(0 1)
                          :ELEMENT-TYPE '(integer 0 4))
        ;;; SimpleVector_byte16_t_O
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS '(0 1)
                          :ELEMENT-TYPE '(integer 0 300))
        ;;; SimpleVector_byte32_t_O>
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS '(0 1)
                          :ELEMENT-TYPE (list 'integer 0 (1+ (* 256 256))))
        ;;;SimpleVector_byte64_t_O
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS '(0 1)
                          :ELEMENT-TYPE (list 'integer 0 (1+ most-positive-fixnum)))
        ;;; SimpleVector_fixnum_O
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS '(0 1)
                          :ELEMENT-TYPE (list 'integer 0 most-positive-fixnum))
        ;;; SimpleVector_int8_t_O
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS '(0 1)
                          :ELEMENT-TYPE (list 'integer -8 8))
        ;;; SimpleVector_int16_t_O
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS '(0 1)
                          :ELEMENT-TYPE (list 'integer -257 257))
        ;;; SimpleVector_int32_t_O
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS '(0 1)
                          :ELEMENT-TYPE (list 'integer (- (expt 2 17)) (expt 2 17)))
        ;;; SimpleVector_int64_t_O
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS '(0 1)
                          :ELEMENT-TYPE (list 'integer (- (expt 2 31)) (1+ most-positive-fixnum)))
        ;;; SimpleVector_fixnum
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS '(0 1)
                          :ELEMENT-TYPE (list 'integer (- (expt 2 31)) (expt 2 31)))
        ;;; SimpleVectorFloat_O
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS '(0.0 1.0)
                          :ELEMENT-TYPE 'single-float)
        ;;;SimpleVectorDouble_O
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS '(0.0d0 1.0d0)
                          :ELEMENT-TYPE 'double-float)
        ;;; SimpleBaseString_O
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS (list (code-char 65) (code-char 66))
                          :ELEMENT-TYPE 'base-char)
        ;;; Str8Ns_O
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS (list (code-char 65) (code-char 66))
                          :adjustable t
                          :ELEMENT-TYPE 'base-char)
        ;;;  SimpleCharacterString_O
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS
                          (list (code-char 256) (code-char 256))
                          :ELEMENT-TYPE 'character)
        ;;;  StrWNs_O
              (MAKE-ARRAY 2
                          :INITIAL-CONTENTS
                          (list (code-char 256) (code-char 256))
                          :adjustable t
                          :ELEMENT-TYPE 'character)
              )))
        (dolist (array arrays t)
          (print (write-to-string array :READABLY nil :ARRAY nil :PRETTY NIL))
          (print (write-to-string array :READABLY nil :ARRAY t :PRETTY NIL))
          #+(or)(print (write-to-string array :READABLY t :ARRAY nil :PRETTY NIL))
          (print (write-to-string array :READABLY t :ARRAY t :PRETTY NIL))
          (format t "~%"))))


(test-expect-error print-6 (write-byte) :type program-error)
(test-expect-error print-7 (write-byte 233 nil) :type type-error)
(test-expect-error print-8 (write-byte 233 t) :type type-error)
(test-expect-error print-9 (write-byte 233 23) :type type-error)
(test-expect-error print-10
                   (with-output-to-string (*standard-output*)
                     (write-byte 23 *standard-output*)) :type type-error)

(test print-11
      (string= "#0A23"
               (with-standard-io-syntax
                 (LET ((A (MAKE-ARRAY NIL :INITIAL-ELEMENT 23)))
                   (WRITE-TO-STRING A :READABLY NIL :ARRAY T :pretty nil)))))

(test print-12
      (let ((result
             (with-standard-io-syntax
               (LET ((A (MAKE-ARRAY NIL :INITIAL-ELEMENT 23)))
                 (WRITE-TO-STRING A :READABLY NIL :ARRAY nil :pretty nil)))))
        (and (zerop (search "#<" result))
             (search ">" result))))

(test print-13
      (string= "-0.0"
               (let ((type 'SINGLE-FLOAT)
                     (number -0.0))
                 (LET ((*READ-DEFAULT-FLOAT-FORMAT* TYPE))
                   (FORMAT NIL "~f" number)))))

(test print-14
      (string= "-0.0"
               (let ((type 'SINGLE-FLOAT)
                     (number -0.0))
                 (LET ((*READ-DEFAULT-FLOAT-FORMAT* type))
                   (PRIN1-TO-STRING number)))))

(test print-15
      (stringp
       (write-to-string 
        (LET ((S
               (OPEN "foo.txt"
                     :DIRECTION
                     :OUTPUT
                     :IF-EXISTS
                     :SUPERSEDE
                     :ELEMENT-TYPE
                     '(UNSIGNED-BYTE 8))))
          (CLOSE S)
          s)))
      )

(test
 PRINT.RATIOS.RANDOM.root-cause
 (string= "#22r-1212B0C39/13K5KA78B"
          (let ((*PRINT-BASE* 22)
                (*print-radix* t))
            (write-to-string -59990859179/64657108615))))


(test PRINT.BIT-VECTOR.RANDOM.root-cause
      (string=
       "#*011010001010000010001110110110100000000011000100001111100000000000101111010100011100110001010100001"
       (let ((*PRINT-READABLY* t)
             (*PRINT-ARRAY* NIL)
             )
         (write-to-string
          #*011010001010000010001110110110100000000011000100001111100000000000101111010100011100110001010100001
          ))))

(test PRINT.RATIOS.RANDOM.root-cause.2
      (string=
       "#10r-7/16"
       (let ((num -7/16)
             (*PRINT-READABLY* T)
             (*PRINT-ARRAY* NIL) (*PRINT-BASE* 10) (*PRINT-RADIX* T)
             (*PRINT-CASE* :CAPITALIZE) (*PRINT-CIRCLE* NIL)
             (*PRINT-ESCAPE* NIL) (*PRINT-GENSYM* NIL) (*PRINT-LEVEL* 47)
             (*PRINT-LENGTH* 25) (*PRINT-LINES* 48) (*PRINT-MISER-WIDTH* NIL)
             (*PRINT-PRETTY* NIL) (*PRINT-RIGHT-MARGIN* NIL)
             (*READ-DEFAULT-FLOAT-FORMAT* 'DOUBLE-FLOAT)
             )
         (write-to-string num))))

;;; e.g. not "#A#1=(T (3) #1#)" since there is no circle
(test PRINT.VECTOR.RANDOM.1.take.1
      (null
       (search
       "#1="
       (let ((vector (vector 25 26 27))
              (*PRINT-READABLY* T)
              (*PRINT-CIRCLE* t)
              (*PRINT-PRETTY* T)
              )
         (write-to-string vector)))))

;;; "#1=#(25 26 #1#)"
(test PRINT.VECTOR.RANDOM.1.take.2
      (zerop
       (search
        "#1="
        (let ((vector (vector 25 26 27))
              (*PRINT-READABLY* T)
              (*PRINT-CIRCLE* t)
              (*PRINT-PRETTY* T)
              )
          (setf (aref vector 2) vector)
          (write-to-string vector)))))

;;; e.g. not "#A#1=(T (2 2) #1#)"
(test PRINT.array.RANDOM.1.take.1
      (null
       (search
        "#1="
        (let ((array (make-array (list 2 2) :initial-contents '((5 6)(7 8))))
              (*PRINT-READABLY* T)
              (*PRINT-CIRCLE* t)
              (*PRINT-PRETTY* T)
              )
          (write-to-string array)))))

(test PRINT.array.RANDOM.1.take.2
      (zerop
       (search
        "#1="
        (let ((array (make-array (list 2 2) :initial-contents '((5 6)(7 8))))
              (*PRINT-READABLY* T)
              (*PRINT-CIRCLE* t)
              (*PRINT-PRETTY* T)
              )
          (setf (aref array 1 1) array)
          (write-to-string array)))))

(test PRINT.cons.RANDOM.1.take.2
     (zerop
       (search
        "#1="
          (let ((a (list 1 2 3)))
            (setf (cdddr a) a)
            (let ((*print-circle* t))
              (write-to-string a))))))

(test-expect-error
 type-errors-safety>speed
 (locally (declare (optimize (safety 3)(speed 0)))
   (copy-pprint-dispatch 0))
 :type type-error)

(test read-print-consistency-arrays
      (with-standard-io-syntax
        (let ((*PRINT-CIRCLE* T)
              (*PRINT-READABLY* T)
              (*PRINT-PRETTY* T))
          (arrayp 
           (read-from-string
            (with-output-to-string (s)
              (write #2A((3 4 5)) :stream s)))))))

(test write-to-string.1.simplified
      (let ((unicode-string (make-array 4 :element-type 'character
                                        :initial-contents (mapcar #'code-char (list 40340 25579 40824 28331)))))
        (string=
         (with-output-to-string (s)(write unicode-string :stream s))
         (write-to-string unicode-string))))

(test drmeister-fep-problem
      (string=
       (format nil "!~36,3,'0r" 1)
       "!001"))

(test PPRINT-DISPATCH.6-simplified
      (string= "ABC"
               (WITH-STANDARD-IO-SYNTAX
                 (LET ((*PRINT-PPRINT-DISPATCH* (COPY-PPRINT-DISPATCH NIL))
                       (*PRINT-READABLY* NIL)
                       (*PRINT-ESCAPE* NIL)
                       (*PRINT-PRETTY* T))
                   (LET ((F
                          #'(LAMBDA (STREAM OBJ)
                              (DECLARE (IGNORE OBJ))
                              (WRITE "ABC" :STREAM STREAM))))
                     (SET-PPRINT-DISPATCH '(EQL X) F)
                     (WRITE-TO-STRING 'X))))))

(test PPRINT-DISPATCH.6
      (multiple-value-bind (a b c d e)
          (WITH-STANDARD-IO-SYNTAX
            (LET ((*PRINT-PPRINT-DISPATCH* (COPY-PPRINT-DISPATCH NIL))
                  (*PRINT-READABLY* NIL)
                  (*PRINT-ESCAPE* NIL)
                  (*PRINT-PRETTY* T))
              (LET ((F
                     #'(LAMBDA (STREAM OBJ)
                         (DECLARE (IGNORE OBJ))
                         (WRITE "ABC" :STREAM STREAM))))
                (VALUES (WRITE-TO-STRING 'X)
                        (SET-PPRINT-DISPATCH '(EQL X) F)
                        (WRITE-TO-STRING 'X)
                        (SET-PPRINT-DISPATCH '(EQL X) NIL)
                        (WRITE-TO-STRING 'X)))))
        (and
         (string= a "X")
         (null b)
         (string= c "ABC")
         (null d)
         (string= e "X"))))
;;; Test c++ cl:format chokes on ~2% and returns "Could not format ..."
(test lisp-format-works (null (search "Could" (format nil "Bar ~2%"))))

(defun print-symbol-with-prefix (stream symbol &optional colon at)
  "For use with ~/: Write SYMBOL to STREAM as if it is not accessible from
  the current package."
  (declare (ignore colon at))
  (let ((*package* (find-package :keyword)))
    (write symbol :stream stream :escape t)))

(test issue-911
 (let ((count 42)
       (function 'print))
   (format t
           "~@<~@(~D~) call~:P to ~
               ~/clasp-tests::print-symbol-with-prefix/ ~
               ~2:*~[~;was~:;were~] compiled before a compiler-macro ~
               was defined for it. A declaration of NOTINLINE at the ~
               call site~:P will eliminate this warning, as will ~
               defining the compiler-macro before its first potential ~
               use.~@:>"
           count
           function)
   t))

(test format.justify.37
      ;; no padding, output fits
      (string-equal
       (format nil "AA~4T~8,,,'*<~%BBBB~,12:;CCCC~;DDDD~>")
       "AA  CCCCDDDD"))

(test format.justify.38
      ;; no padding, output doesn't fit
      (string-equal
       (format nil "AA~4T~8,,,'*<~%BBBB~,11:;CCCC~;DDDD~>")
       "AA  
BBBBCCCCDDDD"))

(test format.justify.39
      ;; one padding character per segment, output fits
      (string-equal
       (format nil "AA~4T~10,,,'*<~%BBBB~,14:;CCCC~;DDDD~>")
       "AA  CCCC**DDDD"))

(test format.justify.40
      ;; one padding character per segment, output doesn't fit
      (string-equal
       (format nil "AA~4T~10,,,'*<~%BBBB~,13:;CCCC~;DDDD~>")
       "AA  
BBBBCCCC**DDDD"))

(test format.justify.41
      ;; Same with ~@T
      (string-equal
       (format nil "AA~1,2@T~8,,,'*<~%BBBB~,12:;CCCC~;DDDD~>")
       "AA  CCCCDDDD"))

(test format.justify.42
      (string-equal
       (format nil "AA~1,2@T~8,,,'*<~%BBBB~,11:;CCCC~;DDDD~>")
       "AA  
BBBBCCCCDDDD"))

(test format.justify.43
      (string-equal
       (format nil "AA~1,2@T~10,,,'*<~%BBBB~,14:;CCCC~;DDDD~>")
       "AA  CCCC**DDDD"))

(test format.justify.44
      (string-equal
       (format nil "AA~1,2@T~10,,,'*<~%BBBB~,13:;CCCC~;DDDD~>")
       "AA  
BBBBCCCC**DDDD"))

(test print-0-strange-radix
      (string= "0"
               (LET ((*PRINT-READABLY* NIL))
                 (LET ((*PRINT-BASE* 7))
                   (WITH-OUTPUT-TO-STRING (*STANDARD-OUTPUT*)
                     (PRIN1 0))))))

#|
wrong
(THIS ..)(THIS ..)
|#

(test pprint-failure-2a
      ;; should only find  ".." once in the output, not twice
      (= 2 (count #\.
                  (let ((*package* (find-package :cl-user)))
                    (with-output-to-string (stream)
                      (with-standard-io-syntax
                        (write `(this prints wrongly)
                               :pretty t  :circle t :lines 1 :right-margin 15 :readably nil :stream stream)))))))

(test pprint-failure-2
      ;; should only find  ".." once in the output, not twice
      (= 2 (count #\.
                  (with-output-to-string (stream)
                    (with-standard-io-syntax
                      (write `(1234 12345 1234567)
                             :pretty t  :circle t :lines 1 :right-margin 15 :readably nil :stream stream))))))
(test pprint-failure-3a
      (>
       (length
        (let ((*package* (find-package :cl-user)))
          (with-output-to-string (stream)
            (with-standard-io-syntax
              (write #(PROGV PROGV PROGV PROGV PROGV PROGV PROGV PROGV PROGV PROGV PROGV)
                     :ESCAPE T :PRETTY T :CIRCLE T :LINES 0 :RIGHT-MARGIN 28 :readably nil :stream stream)))))
       0))

(test pprint-failure-3b
      (>
       (length
        (with-output-to-string (stream)
          (with-standard-io-syntax
            (write #(12345 12345 12345 12345 12345 12345 12345 12345 12345 12345 12345)
                   :ESCAPE T :PRETTY T :CIRCLE T :LINES 1 :RIGHT-MARGIN 28 :readably nil :stream stream))))
       0))

(test write-string-happy-path
      (string-equal
       "ABABĀĀĀĀ » "
       (with-output-to-string (stream)
               ;;; SimpleBaseString_O
         (write-string
          (MAKE-ARRAY 2
                      :INITIAL-CONTENTS (list (code-char 65) (code-char 66))
                      :ELEMENT-TYPE 'base-char)
          stream)
        ;;; Str8Ns_O
         (write-string
          (MAKE-ARRAY 2
                      :INITIAL-CONTENTS (list (code-char 65) (code-char 66))
                      :adjustable t
                      :ELEMENT-TYPE 'base-char)
          stream)
        ;;;  SimpleCharacterString_O
         (write-string 
          (MAKE-ARRAY 2
                      :INITIAL-CONTENTS
                      (list (code-char 256) (code-char 256))
                      :ELEMENT-TYPE 'character)
          stream)
        ;;;  StrWNs_O
         (write-string
          (MAKE-ARRAY 2
                      :INITIAL-CONTENTS
                      (list (code-char 256) (code-char 256))
                      :adjustable t
                      :ELEMENT-TYPE 'character)
          stream)
         (write-string " » " stream))))

(let ((string "1234567890"))
  (with-output-to-string (stream)
    (test-expect-error write-string-error-1
                       (write-string string stream :start nil) :type type-error)
    (test-expect-error write-string-error-2
                       (write-string string stream :start -1) :type type-error)
    (test-expect-error write-string-error-2a
                       (write-string string stream :start 100) :type type-error)
    (test-expect-error write-string-error-3
                       (write-string string stream :start (make-hash-table)) :type type-error)
    (test-expect-error write-string-error-4
                       (write-string string stream :end -1) :type type-error)
    (test-expect-error write-string-error-4a
                       (write-string string stream :end 100) :type type-error)
    (test-expect-error write-string-error-5
                       (write-string string stream :end (make-hash-table)) :type type-error)
    (test-expect-error write-string-error-6
                       (write-string string stream :start 2 :end 1) :type type-error)))

(test write-string-subseq-SimpleBaseString_O
      (let ((string "12345")
            (from 1)
            (to 4))
        (string= (subseq string from to)
                 (with-output-to-string (stream)
                   (write-string string stream :start from :end to)))))

(test write-string-subseq-SimpleCharacterString_O
      (let ((string "12»45")
            (from 1)
            (to 4))
        (string= (subseq string from to)
                 (with-output-to-string (stream)
                   (write-string string stream :start from :end to)))))

(test write-string-subseq-Str8Ns_O
      (let ((string (MAKE-ARRAY 5
                                :INITIAL-CONTENTS (list #\1 #\2 #\3 #\4 #\5)
                                :adjustable t
                                :ELEMENT-TYPE 'base-char))
            (from 1)
            (to 4))
        (string= (subseq string from to)
                 (with-output-to-string (stream)
                   (write-string string stream :start from :end to)))))

(test write-string-subseq-StrWNs_O
      (let ((string (MAKE-ARRAY 5
                                :INITIAL-CONTENTS (list #\1 #\2 (char "12»45" 2) #\4 #\5)
                                :adjustable t
                                :ELEMENT-TYPE 'base-char))
            (from 1)
            (to 4))
        (string= (subseq string from to)
                 (with-output-to-string (stream)
                   (write-string string stream :start from :end to)))))

(test ansi-test-format-e
      (string=
       (FORMAT NIL "~,2,,2e" 0.05)
       "50.0e-3"))
