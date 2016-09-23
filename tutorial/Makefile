
.PHONY : test copy default clean

PATCH = python ../scripts/patch-bin.py
INSERT = python ../scripts/insert-bin.py
XEX2ATR = python ../scripts/xex2atr.py

ATRS = clockwise.atr

default : $(ATRS)

clockwise.gundata.obj clockwise.gundata.inc: clockwise-gen.py
	python clockwise-gen.py

clockwise.obj : clockwise.o clockwise.lnk
	ld65 -o clockwise.obj -C clockwise.lnk clockwise.o

clockwise.lst clockwise.o : clockwise.s clockwise.gundata.inc
	ca65 -l clockwise.lst clockwise.s -o clockwise.o

clockwise.atr: clockwise.obj clockwise.atr.in clockwise.gundata.obj
	$(INSERT) -o clockwise.atr clockwise.atr.in clockwise.obj 662
	$(INSERT) -o clockwise.atr clockwise.atr clockwise.gundata.obj 1942

clean :
	$(RM) *.o *.obj *~ *.map *.lst $(ATRS) clockwise.gundata.obj clockwise.gundata.inc
