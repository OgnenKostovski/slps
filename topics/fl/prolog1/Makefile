include ../include.mk

build:

test: 
	@echo Testing implementation `pwd`
	swipl -q -f TestIO.pro -t "main('${factorial}','${temp}')"
	diff ${factorial} ${temp}
	rm -f temp.txt
	swipl -q -f TestEvaluator.pro -t "main('${factorial}','${apply}',"`cat ../shared/fac5b.txt`")"
	swipl -q -f TestOptimizer.pro -t "main('${unoptimized}','${optimized}')"
	@echo Done.

clean:
	rm -rf *~
	rm -f temp.txt
