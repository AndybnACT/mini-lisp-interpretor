mLisp: project.tab.o project.lex.yy.o
	gcc -o mLisp project.tab.o project.lex.yy.o -ll
clean:
	rm *.o

%.tab.c: %.y
	bison -d -o $@ $^
%.tab.o: %.tab.c
	gcc -c -g $^

%.lex.yy.c: %.l
	flex -o $@ $^
%.lex.yy.o: %.lex.yy.c
	gcc -c -g $^
