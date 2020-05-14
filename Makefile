all: lex yacc main.cu source.cu function.cu
	nvcc --expt-extended-lambda main.cu source.cu function.cu

lex: yacc lex.l
	lex -o lex.cu lex.l

yacc: header.h template.h table.h yacc.y
	yacc -d -o yacc.cu yacc.y

submit: clean
	mkdir -p CS16B032_CS16B047
	cp ./* CS16B032_CS16B047/
	tar -czf  CS16B032_CS16B047.tgz CS16B032_CS16B047/*
	rm -rf CS16B032_CS16B047

clean:
	rm -rf *tgz
	rm -rf CS16B032_CS16B047/*

git-login:
	git clone https://$(Username):$(Password)@github.com/trrishabh/GPU-DBMS.git

git-commit:
	git branch
	git checkout master
	git add .
	git config --global user.email "adarshsinghiitm@gmail.com"
	git config --global user.name "adarsh1783"
	git commit -m 'final update'

git-push:
	git push origin master