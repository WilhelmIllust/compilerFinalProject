#makefile for windows 10
#require :
#	make
#		http://gnuwin32.sourceforge.net/packages/make.htm
#	flex
#		http://gnuwin32.sourceforge.net/packages/flex.htm
#	bison
#		http://gnuwin32.sourceforge.net/packages/bison.htm
#	win_flex_bison
#		https://sourceforge.net/projects/winflexbison/

LIBS = -L"C:\GnuWin32\lib"
INCLUDES = -isystem "C:\GnuWin32\win_bison"
CC = g++
GL_FILE = -g -Wall
GL_LIB = -lopengl32 -lglu32 -lfreeglut -L"C:\Program Files\Common Files\MinGW\freeglut\lib"
GL_INCLUDE = -isystem "C:\Program Files\Common Files\MinGW\freeglut\include"
RM = del /f /s /q
BISON = win_bison
FLEX = win_flex

main:test1.tab.o lex.yy.o glshow.o
	$(CC) $(GL_FILE) -o test.exe glshow.o test1.tab.o test1.yy.o $(GL_LIB) $(LIBS) $(INCLUDES) $(GL_INCLUDE)
test1.tab.h:test1.y
		$(BISON) -d test1.y
test1.tab.cpp:test1.y
		$(BISON) -d test1.y
		rename test1.tab.c test1.tab.cpp
test1.yy.cpp:test1.l test1.tab.cpp test1.tab.h
		$(FLEX) test1.l
		rename lex.yy.c test1.yy.cpp
test1.tab.o:test1.tab.cpp
		$(CC) -c test1.tab.cpp $(LIBS) $(INCLUDES)
lex.yy.o:test1.yy.cpp
		$(CC) -c test1.yy.cpp $(LIBS) $(INCLUDES)
glshow.o:glshow.cpp
		$(CC) -c $(GL_FILE) glshow.cpp -o glshow.o $(GL_LIB) $(LIBS) $(INCLUDES) $(GL_INCLUDE)

clean:
		$(RM) *.o test.exe test1.tab.h test1.tab.cpp test1.yy.cpp datalink.h.gch
