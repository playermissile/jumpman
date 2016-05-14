
.PHONY : test copy default clean

default : jumpman_ext.obj bootloader.obj practice.atr levelbuilder_ext.obj levelbuilder.atr

jumpman_ext.obj : jumpman_ext.o jumpman_ext.lnk
	ld65 -o jumpman_ext.obj -C jumpman_ext.lnk jumpman_ext.o

jumpman_ext.lst jumpman_ext.o : jumpman_ext.s
	ca65 -l jumpman_ext.lst jumpman_ext.s -o jumpman_ext.o

boot_credits.obj : boot_credits.o boot_credits.lnk
	ld65 -o boot_credits.obj -C boot_credits.lnk boot_credits.o

boot_credits.lst boot_credits.o : boot_credits.s
	ca65 -l boot_credits.lst boot_credits.s -o boot_credits.o

levelbuilder_ext.obj : levelbuilder_ext.o levelbuilder_ext.lnk
	ld65 -o levelbuilder_ext.obj -C levelbuilder_ext.lnk levelbuilder_ext.o

levelbuilder_ext.lst levelbuilder_ext.o : levelbuilder_ext.s
	ca65 -l levelbuilder_ext.lst levelbuilder_ext.s -o levelbuilder_ext.o

bootloader.obj : bootloader.o bootloader.lnk
	ld65 -o bootloader.obj -C bootloader.lnk bootloader.o

bootloader.lst bootloader.o : bootloader.s
	ca65 -l bootloader.lst bootloader.s -o bootloader.o

levelbuilder.atr: bootloader.obj levelbuilder_ext.obj levelbuilder2.xex
	python xex2atr.py -o levelbuilder.atr -b bootloader.obj levelbuilder2.xex
	python insert-bin.py -o levelbuilder.atr levelbuilder.atr levelbuilder_ext.obj 22438

practice.atr: jumpman_ext.obj Jumpman\ \(1983\)\(Epyx\)\(US\)\[\!\].atr jumpman_ext.patch jumpman_ext.lst boot_credits.obj boot_credits.patch boot_credits.lst
	python insert-bin.py -o practice.atr Jumpman\ \(1983\)\(Epyx\)\(US\)\[\!\].atr jumpman_ext.obj 88720
	python patch-bin.py -o practice.atr practice.atr jumpman_ext.patch jumpman_ext.lst
	python insert-bin.py -o practice.atr practice.atr boot_credits.obj 656
	python patch-bin.py -o practice.atr practice.atr boot_credits.patch boot_credits.lst

clean :
	$(RM) *.o *~ *.map *.lst jumpman_ext.xex
