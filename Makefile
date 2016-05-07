
.PHONY : test copy default clean

default : jumpman_ext.obj bootloader.obj levelbuilder.atr

jumpman_ext.obj : jumpman_ext.o jumpman_ext.lnk
	ld65 -o jumpman_ext.obj -C jumpman_ext.lnk jumpman_ext.o

jumpman_ext.lst jumpman_ext.o : jumpman_ext.s
	ca65 -l jumpman_ext.lst jumpman_ext.s -o jumpman_ext.o

bootloader.obj : bootloader.o bootloader.lnk
	ld65 -o bootloader.obj -C bootloader.lnk bootloader.o

bootloader.lst bootloader.o : bootloader.s
	ca65 -l bootloader.lst bootloader.s -o bootloader.o

levelbuilder.atr: bootloader.obj jumpman_ext.obj levelbuilder2.xex
	python xex2atr.py -o levelbuilder.atr -b bootloader.obj levelbuilder2.xex
	python insert-bin.py -o levelbuilder.atr levelbuilder.atr jumpman_ext.obj 22438

clean :
	$(RM) *.o *~ *.map *.lst jumpman_ext.xex
