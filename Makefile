clurl: src/main.lisp clurl.asd build.lisp
	sbcl --eval \
	"(asdf:load-asd (uiop:merge-pathnames* (uiop:getcwd) #p\"clurl.asd\"))" \
	--load build.lisp

clean:
	rm -rf clurl
