extract:
	${tooldir}/html2bgf collect.kw src.htm raw.bgf
	${tooldir}/exbgf2xbgf ../../../convergence/exbgf/java/exbgf/recover-read3.exbgf recover.xbgf
	${tooldir}/exbgf2xbgf ../../../convergence/exbgf/java/exbgf/correct-read3.exbgf correct.xbgf
	${tooldir}/xbgf recover.xbgf raw.bgf ext.bgf
	${tooldir}/xbgf correct.xbgf ext.bgf grammar.bgf

get:
	curl -k http://java.sun.com/docs/books/jls/third_edition/html/typesValues.html  > src.htm
	curl -k http://java.sun.com/docs/books/jls/third_edition/html/names.html       >> src.htm
	curl -k http://java.sun.com/docs/books/jls/third_edition/html/packages.html    >> src.htm
	curl -k http://java.sun.com/docs/books/jls/third_edition/html/classes.html     >> src.htm
	curl -k http://java.sun.com/docs/books/jls/third_edition/html/interfaces.html  >> src.htm
	curl -k http://java.sun.com/docs/books/jls/third_edition/html/arrays.html      >> src.htm
	curl -k http://java.sun.com/docs/books/jls/third_edition/html/statements.html  >> src.htm
	curl -k http://java.sun.com/docs/books/jls/third_edition/html/expressions.html >> src.htm

include ../../Makefile.grammar
