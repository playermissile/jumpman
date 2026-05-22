
.PHONY : test copy default clean

JUMPMAN_SRC = Jumpman\ \(1983\)\(Epyx\)\(US\)\[\!\].atr
PATCH = python ../scripts/patch-bin.py
INSERT = python ../scripts/insert-bin.py
XEX2ATR = python ../scripts/xex2atr.py
ADDXEX = python ../scripts/addxex.py

default : jumpman_ext.obj bootloader.obj practice.atr levelbuilder_ext.obj levelbuilder.xex levelbuilder.atr

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

levelbuilder.xex: $(JUMPMAN_SRC) levelbuilder_ext.obj levelbuilder_ext.patch
	-rm levelbuilder.xex
	$(ADDXEX) -o levelbuilder.xex -a 0x8800 $(JUMPMAN_SRC) --atr 17 32 # add Easy Does It
	$(ADDXEX) -o levelbuilder.xex -a 0x0a00 $(JUMPMAN_SRC) --atr 548 559 # add 0xa00-0xfff
	$(ADDXEX) -o levelbuilder.xex -a 0x2000 $(JUMPMAN_SRC) --atr 560 575  # add 0x2000-27ff
	$(ADDXEX) -o levelbuilder.xex -a 0x3000 $(JUMPMAN_SRC) --atr 592 693  # add 0x3000-62ff
	$(ADDXEX) -o levelbuilder.xex -a 0x6800 $(JUMPMAN_SRC) --atr 704 719 # add 0x6800-6fffd
	$(ADDXEX) -o levelbuilder.xex -a 0x8000 levelbuilder_ext.obj # add xex initialization
	$(ADDXEX) -o levelbuilder.xex -a 0x02e0 BYTES 0x00 0x80 # add RUNINI
	$(PATCH) -o levelbuilder.xex levelbuilder.xex levelbuilder_ext.patch levelbuilder_ext.lst

bootloader.obj : bootloader.o bootloader.lnk
	ld65 -o bootloader.obj -C bootloader.lnk bootloader.o

bootloader.lst bootloader.o : bootloader.s
	ca65 -l bootloader.lst bootloader.s -o bootloader.o

levelbuilder.atr: bootloader.obj levelbuilder_ext.obj levelbuilder.xex
	$(XEX2ATR) -o levelbuilder.atr -b bootloader.obj levelbuilder.xex

practice.atr: jumpman_ext.obj $(JUMPMAN_SRC) jumpman_ext.patch jumpman_ext.lst boot_credits.obj boot_credits.patch boot_credits.lst title_screen.patch
	$(INSERT) -o practice.atr.~1 $(JUMPMAN_SRC) jumpman_ext.obj 88720
	$(PATCH) -o practice.atr.~2 practice.atr.~1 jumpman_ext.patch jumpman_ext.lst
	$(INSERT) -o practice.atr.~3 practice.atr.~2 boot_credits.obj 656
	$(PATCH) -o practice.atr.~4 practice.atr.~3 boot_credits.patch boot_credits.lst
	$(PATCH) -o practice.atr practice.atr.~4 title_screen.patch jumpman_ext.lst
	$(RM) practice.atr.~?

clean :
	$(RM) *.o *.obj *~ *.map *.lst jumpman_ext.xex practice.atr levelbuilder.atr
