(defsystem "clurl"
  :version "0.1.0"
  :author "Pushkar Raj"
  :license "MIT"
  :depends-on ("ningle"
               "clack"
               "cl-dbi"
	       "cl-dotenv")
  :components ((:module "src"
                :components
                ((:file "main"))))
  :description "URL shortner written in common lisp."
  :build-operation "program-op"
  :build-pathname "clurl"
  :entry-point "clurl::main")
