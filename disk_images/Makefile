
.PHONY : test copy default clean

JUMPMAN_SRC = Jumpman\ \(1983\)\(Epyx\)\(US\)\[\!\].atr
PATCH = python ../scripts/patch-bin.py
INSERT = python ../scripts/insert-bin.py
XEX2ATR = python ../scripts/xex2atr.py
ADDXEX = python ../scripts/addxex.py

default : jumpman_ext.obj bootloader.obj practice.atr levelbuilder-v1-easydoesit.xex levelbuilder-v2-easydoesit.xex levelbuilder-unified.atr

jumpman_ext.obj : jumpman_ext.o jumpman_ext.lnk
	ld65 -o jumpman_ext.obj -C jumpman_ext.lnk jumpman_ext.o

jumpman_ext.lst jumpman_ext.o : jumpman_ext.s jumpman_ii_title.s
	ca65 -l jumpman_ext.lst jumpman_ext.s -o jumpman_ext.o

boot_credits.obj : boot_credits.o boot_credits.lnk
	ld65 -o boot_credits.obj -C boot_credits.lnk boot_credits.o

boot_credits.lst boot_credits.o : boot_credits.s
	ca65 -l boot_credits.lst boot_credits.s -o boot_credits.o

levelbuilder-unified.obj : levelbuilder-unified.o levelbuilder-unified.lnk
	ld65 -o levelbuilder-unified.obj -C levelbuilder-unified.lnk levelbuilder-unified.o

levelbuilder-unified.lst levelbuilder-unified.o : levelbuilder-unified.s jumpman_ii_utils.s
	ca65 -l levelbuilder-unified.lst levelbuilder-unified.s -o levelbuilder-unified.o

levelbuilder-unified.xex: $(JUMPMAN_SRC) levelbuilder-unified.obj levelbuilder-unified.patch
	$(RM) levelbuilder-unified.xex
	$(ADDXEX) -o levelbuilder-unified.xex -a 0x2800 ZEROS 0x800 # add space for Block A or original level
	$(ADDXEX) -o levelbuilder-unified.xex -a 0x0a00 $(JUMPMAN_SRC) --atr 548 559 # add 0xa00-0xfff
	$(ADDXEX) -o levelbuilder-unified.xex -a 0x2000 $(JUMPMAN_SRC) --atr 560 575  # add 0x2000-27ff
	$(ADDXEX) -o levelbuilder-unified.xex -a 0x3000 $(JUMPMAN_SRC) --atr 592 693  # add 0x3000-62ff
	$(ADDXEX) -o levelbuilder-unified.xex -a 0x6800 $(JUMPMAN_SRC) --atr 704 719 # add 0x6800-6fffd
	$(ADDXEX) -o levelbuilder-unified.xex -a 0x02e0 BYTES 0x00 0x80 # add RUNINI
	$(ADDXEX) -o levelbuilder-unified.xex -a 0x8000 levelbuilder-unified.obj # add xex initialization
	$(PATCH) -o levelbuilder-unified.xex levelbuilder-unified.xex levelbuilder-unified.patch levelbuilder-unified.lst

easydoesit.v1.bin:
	$(ADDXEX) -o easydoesit.v1.bin -r $(JUMPMAN_SRC) --atr 17 32 # extract Easy Does It

levelbuilder-v1-easydoesit.xex: levelbuilder-unified.xex easydoesit.v1.bin
	$(PATCH) -o levelbuilder-v1-easydoesit.xex levelbuilder-unified.xex -a 0x2800 easydoesit.v1.bin

levelbuilder-v2-easydoesit.xex: levelbuilder-unified.xex easydoesit.v2.bin
	$(PATCH) -o levelbuilder-v2-easydoesit.xex levelbuilder-unified.xex -a 0x2800 easydoesit.v2.bin
	$(ADDXEX) -o levelbuilder-v2-easydoesit.xex -a 0xa800 GAMELOOP # add standard gameloop

bootloader.obj : bootloader.o bootloader.lnk
	ld65 -o bootloader.obj -C bootloader.lnk bootloader.o

bootloader.lst bootloader.o : bootloader.s
	ca65 -l bootloader.lst bootloader.s -o bootloader.o

levelbuilder-unified.atr: bootloader.obj levelbuilder-v1-easydoesit.xex
	$(XEX2ATR) -o levelbuilder-unified.atr -b bootloader.obj levelbuilder-v1-easydoesit.xex

practice.atr: jumpman_ext.obj $(JUMPMAN_SRC) jumpman_ext.patch jumpman_ext.lst boot_credits.obj boot_credits.patch boot_credits.lst jumpman_ii_title.patch
	$(INSERT) -o practice.atr.~1 $(JUMPMAN_SRC) jumpman_ext.obj 88720
	$(PATCH) -o practice.atr.~2 practice.atr.~1 jumpman_ext.patch jumpman_ext.lst
	$(INSERT) -o practice.atr.~3 practice.atr.~2 boot_credits.obj 656
	$(PATCH) -o practice.atr.~4 practice.atr.~3 boot_credits.patch boot_credits.lst
	$(PATCH) -o practice.atr practice.atr.~4 jumpman_ii_title.patch jumpman_ext.lst
	$(RM) practice.atr.~?

clean :
	$(RM) *.o *.obj *~ *~[0-9] *.map *.lst
	$(RM) easydoesit.v1.bin
	$(RM) practice.atr
	$(RM) levelbuilder-unified.atr
	$(RM) levelbuilder-unified.xex levelbuilder-v1-easydoesit.xex levelbuilder-v2-easydoesit.xex
