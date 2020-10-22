(in-package :asdf-user)

(defsystem "clasp-cleavir"
  :description "The Clasp/Cleavir compiler front end"
  :version "0.0.1"
  :author "Christian Schafmeister <chris.schaf@verizon.net>"
  :licence "LGPL-3.0"
  :depends-on (:concrete-syntax-tree
               :eclector-concrete-syntax-tree
               :eclector
               :cleavir-bir
               :cleavir-ast-to-bir
               :cleavir-bir-transformations
               :cleavir-cst-to-ast
               :cleavir-ir
               :cleavir-compilation-policy
               :cleavir-conditions
               :cleavir-attributes
               :cleavir-ast-to-hir
               :cleavir-ast-transformations
               :cleavir-escape
               :cleavir-hir-transformations
               :cleavir-partial-inlining
               :cleavir-remove-useless-instructions
               :cleavir-hir-to-mir
               :cleavir-basic-blocks)
  :serial t
  :components ((:file "packages")
               (:file "cleavir-fixups-and-hacks")
               (:file "system")
               (:file "policy")
               (:file "reader")
               (:file "ast")
               (:file "convert-form")
               (:file "convert-special")
               (:file "eliminate-ltvs")
               (:file "hir")
               (:file "introduce-invoke")
               (:file "ast-interpreter")
               (:file "toplevel")
               (:file "setup")
               (:file "ast-to-hir")
               (:file "mir")
               (:file "hir-to-mir")
               (:file "ir")
               (:file "gml-drawing")
               (:file "landing-pad")
               ;;		 (:file "arguments")
               (:file "closure-optimize")
               (:file "translate")
               (:file "translate-instruction")
               ;; BIR
               (:file "translation-environment")
               (:file "bir")
               (:file "bmir")
               (:file "bir-to-bmir")
               (:file "landing-pad-bir")
               (:file "eliminate-ltvs-bir")
               (:file "translate-bir")
               ;; end BIR
               ;;                (:file "satiation")
               (:file "fixup-eclector-readtables")
               (:file "activate-clasp-readtables-for-eclector")
               (:file "define-unicode-tables")
               (:file "inline-prep")
               ;;                 (:file "auto-compile")
               ;;                 (:file "inline")
               ))
