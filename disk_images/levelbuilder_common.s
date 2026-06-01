; Levelbuilder test code common to both level storage formats
;
; Copyright (c) 2016,2026 Rob McMullen <feedback@playermissile.com>
; Copyright (c) 2016,2026 Kay Savetz <antic@ataripodcast.com>

; Modifications to Jumpman code to boot into level, skipping all then
; menu code.
;
; TODO:
; * handle system reset to restart
; * disable cartridge on XL

        .macpack atari

atract = $4d
vbreak = $206
sdlstl = $230
gprior = $26f
trig0 = $d010
prior = $d01b
consol = $d01f
audc1 = $d201
audc2 = $d203
audc3 = $d205
audc4 = $d207
audctl = $d208
kbcode = $d209
ch = $2fc
skstat = $d20f
porta = $d300
dlistl = $d402
dlisth = $d403
nmien = $d40e
setvbv = $e45c

        .segment "JMHACK2"
        .org $8000

        jmp xexinit

magic:
        .byte "JMII"
version:
        .byte 2
numlives:
        .byte 6
speed:
        .byte 3
crashtesting:
        .byte 0


; graphics data here so display lists and screen data guaranteed not to cross
; a 4k boundary.

harvestdl:
        .byte $70,$70,$70 ; 3x 8 BLANK
        .byte $47,<harvestscreen,>harvestscreen ; LMS MODE 7
        .byte $70,6,6,6,6,$70
        .byte 7,6,6,6,6,6,6,6,6,6,6,6,7
        .byte $41,<harvestdl,>harvestdl

harvestscreen:
        scrcode "PEANUT HARVEST ERROR"
        scrcode "284E OFFSET X: "
scroffsetx:
        scrcode "FF   "
        scrcode "284F OFFSET Y: "
scroffsety:
        scrcode "FF   "
        scrcode "306A JUMPMAN X: "
scrjumpmanx:
        scrcode "FF  "
        scrcode "306F JUMPMAN Y: "
scrjumpmany:
        scrcode "FF  "
        scrcode "HARVEST TABLE: "
scrpeanutaddr:
        scrcode "XXXX "
        scrcode "DID NOT FIND: "
scrchecksum:
        scrcode               "FF    "
scrpeanuts:
        scrcode "                    "
        scrcode "                    "
        scrcode "                    "
        scrcode "                    "
        scrcode "                    "
        scrcode "                    "
        scrcode "                    "
        scrcode "                    "
        scrcode "                    "
        scrcode "                    "
        scrcode "   press trigger    "


replaydl:
        .byte $70,$70,$70 ; 3x 8 BLANK
        .byte $47,<replayscreen,>replayscreen ; LMS MODE 7
        .byte $70,$70,$70,$70
        .byte 7
        .byte $70,$70
        .byte 7,7
        .byte $70,$70,$70
        .byte 7,7
        .byte $70
;        .byte 6,6,6,6
        .byte $41,<replaydl,>replaydl

replayscreen:
        ;          "01234567890123456789"
        scrcode    "   replay options   "
        scrcode    "   SPEED (1-8): "
replayspeed:
        scrcode                    "4   "
        scrcode    "   ADDITIONAL       "
        scrcode    "   LIVES (9,0): "
replaylives:
        scrcode                    "9   "
        scrcode    "   press trigger    "
        scrcode    "      or start      "
        invscrcode "kbcode: "
replaykbcode:
        invscrcode         "ff          "
        invscrcode "consol: "
replayconsol:
        invscrcode         "ff          "
        invscrcode " stick: "
replaystick:
        invscrcode         "ff          "
        invscrcode "  trig: "
replaytrig0:
        invscrcode         "ff          "





xexinit: ; entry point for XEX boot

startlevel:
        lda #$00
        sta $51c9
        jsr $3780       ; clear working data, reset audio

        lda #0          ; player Y positions aren't cleared in 3780, so do it by hand
        sta $306e       ; I must be missing an initialization routine somewhere
        sta $306f
        sta $3070
        sta $3071
        sta $3072

        jsr $3820       ; set up character set
        jsr $2640       ; show blank screen
        lda #$10
        sta $51c7
        lda #$27
        sta $51c8
        jsr $3100       ; reset VBI counters

        ; replace everything before $0a12 to prevent display list and asking teh user to press a key
        jsr $0fd5       ; init gameplay VBI routines?
        lda #0          ; force one player
        jmp $0a12       ; skip over the display list portion of $0a00


r4400: ; replacement for 4400 to load level from memory rather than disk
        lda #<replay
        sta $4104
        lda #>replay
        sta $4105
        lda #1          ; disable
        sta $4106       ;  START
        lda #2          ; disable
        sta $4107       ;  SELECT
        lda #0          ; enable
        sta $4108       ;  OPTION

; TESTING! Cause BRK instruction on SELECT press
        lda crashtesting
        beq @cont

; move harvest grid to invalid position for peanut above and to left of Jumpman on Easy Does It
;        lda #$18
;        sta $8846

        lda #$f0
        sta $4102
        lda #$88
        sta $4103
        lda #0
        sta $4107       ; enable SELECT to cause crash

@cont:  jsr copy_level_to_memory ; defined in level 1 or level 2 format code

        lda numlives
        sta $30f0
        ldy speed
        lda $4d57,y     ; table of speed values
        sta $30ff
        lda $4d5f,y     ; table of printable characters
        sta $30fe
        rts


r500a:  jsr $331c
        ;jsr $56af ; delay loop necessary?
        ldx #$50
        ldy #$cb
        lda #$07
        jsr $e45c    ; SETVBV

        ;jsr $56af  ; delay loop necessary?

        lda #$c0
        sta $d40e    ; NMIEN
        lda #0
        sta $e0
        jsr copyscr
;        lda #$40
;        sta $d40e    ; NMIEN

        ;jsr $56af

        lda #$4d ; fixes the flashy problems by removing the DLI on the first line
        sta $3c03
        lda #$5b ; fix this pointer showing the DLIs have been pushed all the way to the bottom
        sta $f0
        jmp $502b ; need to exit through here, otherwise bombs can't be picked up

; looks like there is an extra DLI bit that can be set on the main playfield
; display list. Routine 4ca0 sets this extra bit, but it's not used in normal
; play



copyscr: lda #$10
        ldy #$70
        ldx #$0f
        jmp copypg      ; use rts from copypg


; replacement for harvest table end. Patched into $4b46
r4b46:
        beq @harvest    ; expecting $ff; if not, then crash
        jmp $4b49       ; continue with harvest table processing
@harvest:
        lda $bc         ; checksum value
        jsr hex2text
        sta scrchecksum
        stx scrchecksum + 1
        lda $2846
        jsr hex2text
        sta scroffsetx
        stx scroffsetx + 1
        lda $2847
        jsr hex2text
        sta scroffsety
        stx scroffsety + 1
        lda $306a
        jsr hex2text
        sta scrjumpmanx
        stx scrjumpmanx + 1
        lda $306f
        jsr hex2text
        sta scrjumpmany
        stx scrjumpmany + 1

        lda $bb
        jsr hex2text
        sta scrpeanutaddr
        stx scrpeanutaddr + 1
        lda $ba
        jsr hex2text
        sta scrpeanutaddr + 2
        stx scrpeanutaddr + 3
        lda #<scrpeanuts
        sta $82
        lda #>scrpeanuts
        sta $83
        ldy #0
        sty $84
        sty $85
ploop:
        ldy $85
        lda ($ba),y
        cmp #$ff
        beq @endploop
        sty $85
        jsr hex2text
        ldy $84
        sta ($82),y
        iny
        txa
        sta ($82),y
        iny
        iny
        iny
        sty $84
        clc
        lda $85
        adc #7
        sta $85
        bcc ploop       ; don't go into endless loop if missing FF

@endploop:
        ldx #>harvestdl
        ldy #<harvestdl
        jsr showdl
        jsr waitkeyrelease
@3:     lda trig0           ; wait until trigger is pressed
        bne @3
        ldx #$ff
        txs
        jmp replay


; Retry screen: after completing level or level failed, return to this screen to
; allow a replay. Speed and number of lives can be changed
replay:
        lda #$1b       ; reset VBI routines
        sta $3087
        sta $3089
        sta $308b
        sta $308e
        lda #$31
        sta $308a
        sta $308c
        sta $3088
        sta $308f
        ldx #$08       ; move all players & missiles off screen
        lda #$00
@1:     sta $cfff,x
        dex
        bne @1

        lda $30ff
        clc
        adc #17
        sta replayspeed

        lda numlives
        clc
        adc #16
        sta replaylives

        ldx #>replaydl
        ldy #<replaydl
        jsr showdl

        jsr waitkeyrelease

@input:
        ldy kbcode
        lda skstat
        and #4
        beq @storekey
        ldy #$ff
@storekey:
        sty ch
        tya
        jsr hex2text
        sta replaykbcode
        stx replaykbcode + 1

        lda porta
        jsr hex2text
        sta replaystick
        stx replaystick + 1

        lda consol
        sta @smcconsol + 1
        jsr hex2text
        sta replayconsol
        stx replayconsol + 1
@smcconsol:
        lda #00
        cmp #6              ; start
        beq @run
        lda trig0
        jsr hex2text
        sta replaytrig0
        stx replaytrig0 + 1
        lda trig0
        beq @run
        lda ch
        cmp #$30            ; 9
        bne @key1
        lda #9
        sta numlives
        lda #16 + 9
        sta replaylives
        bne @input
@key1:  cmp #$32            ; 0
        bne @key2
        lda #0
        sta numlives
        lda #16
        sta replaylives
@key2:
        ldy #$08
@key3:  lda $4d4f-1,y     ; table of keycode values matching numbers 1-8
        cmp ch
        beq @key4
        dey
        bne @key3
        beq @input
@key4:  lda $4d56,y     ; table of speed values
        sta speed
        clc
        adc #17
        sta replayspeed

        jmp @input
@run:
        jmp startlevel

.include "jumpman_ii_utils.s"
