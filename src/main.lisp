(defpackage clurl
  (:use :cl))
(in-package :clurl)

(ql:quickload '(:ningle :clack :cl-dbi))

(defun make-db-connection ()
  (defvar *connection*
    (dbi:connect :postgres
		 :host (uiop:getenv "CLURL_HOST")
		 :port (parse-integer (uiop:getenv "CLURL_PORT"))
		 :database-name (uiop:getenv "CLURL_DB")
		 :username  (uiop:getenv "CLURL_USERNAME")
		 :password  (uiop:getenv "CLURL_PASSWORD"))))

(defvar *app* (make-instance 'ningle:app))

(defun read-file (infile)
  (with-open-file (instream infile :direction :input
				   :if-does-not-exist nil)
    (when instream
      (let ((string (make-string (file-length instream))))
        (read-sequence string instream)
        string))))

(setf (ningle:route *app* "/" :method :GET)
      (read-file #p"./src/index.html"))

(defun save-url (url)
  "Save `url' into database and return the `code' associated with it."
  (let ((code (gen-random-code-string))
	(query (dbi:prepare *connection*
			 "INSERT INTO urls VALUES(?, ?);")))
    (loop :while (get-url-by-code code)
	  :do (setq code (gen-random-code-string)))
    (dbi:execute query (list code url))
    code))

(setf (ningle:route *app* "/" :method :POST)
      #'(lambda (params)
	  (let* ((url (cdr (assoc "url" params :test #'string=)))
		 (code (save-url url)))
	    `(200 (:content-type "application/json")
	      ,(list "{ \"shortUrl\":\"" code  "\" }")))))

(setf (ningle:route *app* "/:code" :method :GET)
      #'(lambda (params)
	  (let* ((code (cdr (assoc :code params)))
		 (url (get-url-by-code code)))
	    (if url
		`(302 (:location ,url) nil)
		(format nil "No url found!")))))

(defun get-url-by-code (code)
  "Get `url' associated with `code'."
  (let* ((query (dbi:prepare *connection*
		    "SELECT url FROM urls WHERE code = ?"))
	 (query (dbi:execute query (list code))))
    (second (dbi:fetch query))))


(defun gen-random-code-string (&key (length 5))
  "Generates a random alphanumeric string of `:length' characters."
  (let* ((allowed-chars "abcdefghijklmnopqrstuvwxyz0123456789")
	(chars (loop :for i :from 1 :to length
		     :collect (char allowed-chars
				    (random (length allowed-chars))))))
    (format nil "~{~a~}" chars)))

(defun main ()
  (make-db-connection)
  (clack:clackup *app*)
  (loop))
