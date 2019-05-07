executable = 3d
all: matrix.o draw.o edgy.o prgrid.o bresenham.o manipulations.o parser.o parametric.o polygon.o polyhedra.o math.o stack.o
	gcc -o $(executable) draw.o matrix.o edgy.o prgrid.o bresenham.o manipulations.o parser.o parametric.o polygon.o polyhedra.o math.o stack.o -lm -lgcc
	./$(executable)
draw.o: draw.S
	gcc -c -g draw.S
matrix.o: matrix.S
	gcc -c -g matrix.S
edgy.o: edgy.S
	gcc -c -g edgy.S
bresenham.o: bresenham.S
	gcc -c -g bresenham.S
prgrid.o: prgrid.S
	gcc -c -g prgrid.S
manipulations.o:manipulations.S
	gcc -c -g manipulations.S
parser.o:parser.S
	gcc -c -g parser.S
parametric.o: parametric.S
	gcc -c -g parametric.S
polygon.o: polygon.S
	gcc -c -g polygon.S
polyhedra.o: polyhedra.S
	gcc -c -g polyhedra.S
math.o: math.S
	gcc -c -g math.S
stack.o: stack.S
	gcc -c -g stack.S
clean:
	rm *.o
	rm $(executable)
