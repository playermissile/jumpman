; Enhancements to Jumpman!
;
; Copyright (c) 2016, Rob McMullen <feedback@playermissile.com>
; Copyright (c) 2016, Kevin Savetz <antic@ataripodcast.com>

; Loader that resides in sectors 694 - 703. That space is unused
; on disk but is still loaded during the boot process. It ends up
; in memory at $6300 - $67ff, so we have 5 pages to work with.

        .macpack atari

; OS definitions
atract = $4d
vbreak = $206
sdlstl = $230
gprior = $26f
prior = $d01b
audc1 = $d201
audc2 = $d203
audc3 = $d205
audc4 = $d207
audctl = $d208
dlistl = $d402
dlisth = $d403
nmien = $d40e
setvbv = $e45c

; Jumpman definitions
joy_vert = $3020
joy_horz = $3024
joy_btn = $302c
screen = $7000
line1 = screen + 160
line2 = screen + 180


       .segment "JMHACK1"
       .ORG $6300

; bootstrap code called from the end of the boot sector loader, set at the
; vector 09d6 in the boot code.
boot2:  LDX #$05
        LDY #$00
loop:   LDA $6300,y
dest:   STA $8000,y
        INY
        BNE loop
        INC dest + 2
        INC loop + 2
        DEX
        BNE loop
        JMP $2900       ; back to original start point after boot
boot2end:

; All this code resides at $6300 - $67ff on disk and is copied to $8000
; by the boot2 code above. After this point, we need the origin to appear
; as if everything was assembled at $8000. boot2 will also get copied so
; adjust the origin to after that number of bytes. The .lnk file alse needs
; to get adjusted with the correct number of bytes, but I don't know how
; to do that other than by hand. So if boot2 changes, update that file.

        .segment "JMHACK2"
        .org $8000 + boot2end - boot2   ; calculate offset into $8000

; choose sector start for practice level
loadlvl: ; hook into code at 24dd
        ldy $2603
        cpy #6
        beq practice_init
        lda $2507,y
        sta $30ee
        lda $250d,y
        sta $30ef
        jmp $24ec

practice_level:
        .byte 0

practice_init: ; new code to load in practice level sector
        lda #0
        sta practice_level
practice:
        jsr $3100       ; reset vertical blank counters
        jsr $2513       ; reset colors
        jsr $3780       ; initialize working data at $3000
        jsr $3800       ; clear $7000 playfield screen
        lda #<practicedl
        sta sdlstl
        lda #>practicedl
        sta sdlstl + 1
        lda #<levelnum_dli
        sta $30e2
        lda #>levelnum_dli
        sta $30e3

        lda #0
        sta atract
        ; note! Select is automatically coded to go back to game options screen!
        jsr show_instructions

tone:
        lda #$13
        sta $3040
        lda #$26
        sta $3041
        lda #$10
        jsr $32b0
@1:     lda $3030
        ora $3032
        cmp #$00
        bne @1          ; wait for tone to get done playing

        lda #$30
        jsr $56b6       ; partial delay; $30x$ff, not full $ffx$ff

updown:
        ldy joy_horz
        cpy #0
        beq leftright
        ldx practice_level
        bne @up
        ldx #1
        bne @store
@up:    cpy #0
        bmi @down
        inx
        cpx #33
        bcc @store
        ldx #1
        bne @store
@down:  dex
        bne @store
        ldx #32
@store: stx practice_level
        jsr show_instructions

        jmp tone

leftright:
        ldy joy_vert
        cpy #0
        beq button
        lda practice_level
        bne @right
        lda #1
        bne @store
@right: cpy #0
        bmi @left
        cmp #32
        bne @1
        lda #1
        bne @store
@1:     clc
        adc #8
        cmp #33
        bcc @store
        sec
        sbc #31
        bne @store
@left:  cmp #1
        bne @2
        lda #32
        bne @store
@2:     sec
        sbc #8
        beq @wrap
        bpl @store
@wrap:  clc
        adc #31
@store: sta practice_level
        jsr show_instructions

        jmp tone

button:
        lda joy_btn
        cmp #1
        beq updown

        lda practice_level ; ranges from 1 to 32
        sta $82
        lda #0
        sta $83

        asl $82         ; multiply by 16
        rol $83
        asl $82
        rol $83
        asl $82
        rol $83
        asl $82
        rol $83
        inc $82         ; add 1 to get sectors 17, 33, ... 512
        bne @1
        inc $83
@1:     lda $82
        sta $30ee
        lda $83
        sta $30ef

        lda #$e4        ; point to no-op DLI before starting level
        sta $30e2
        lda #$30
        sta $30e3
;        lda #$40
;        sta nmien

;        lda #0
;        sta $4d01       ; DEBUGGING! Only one life

        ; replace code at 24ec to avoid chosing the number of players. Force this to be one player by doing everything that $0a00 does except waiting for the user to press a key
practice2:
        lda #$00
        sta $51c9
        sta $4106
        jsr $3780
        jsr $2640
        lda #$10
        sta $51c7
        lda #$27
        sta $51c8
        jsr $3100       ; reset vertical blank counters

        ; replace everything before $0a12 to prevent display list and asking teh user to press a key
        jsr $0fd5       ; init gameplay VBI routines?
        lda #0          ; force one player
        jmp $0a12       ; skip over the display list portion of $0a00

show_instructions: ; start with a fresh copy of the level numbers each time
        ldy #160
@1:     lda levelnums - 1, y
        sta $7000 - 1,y
        dey
        bne @1

        lda practice_level ; check to see if this the first time
        beq basic_instructions

        tax             ; highlight chosen level number
        lda scr_level_loc, x
        tax
        ldy #5
@3:     lda $7000, x
        ora #%10000000
        sta $7000, x
        inx
        dey
        bne @3

        ldy #20
@2:     lda trigger_instructions - 1,y
        sta line1 - 1,y
        lda #0
        sta line2 - 1,y
        dey
        bne @2

        lda #<levelnames
        sta $82
        lda #>levelnames
        sta $83
        ldx practice_level

        ldy #0
        lda ($82),y     ; load first indent byte
@checkindent:
        dex
        beq @printname

@skipname: ; not the level number, so skip everything until next indent byte
        inc $82
        bne @4
        inc $83
@4:     lda ($82), y
        bmi @skipname
        bpl @checkindent

@printname:
        tax             ; indent byte used as offset to line2
@printloop:
        iny
        lda ($82), y
        bpl @exit
        sta line2, x
        inx
        bne @printloop
@exit:  rts

basic_instructions:
        ldy #40
@1:     lda joy_instructions - 1,y
        sta line1 - 1,y
        dey
        bne @1
        rts

levelnum_dli:
        pha
        lda $30b8
        sta $d40a
        sta $d018
        pla
        rti
        nop

practicedl:
        .byte $70,$70,$70 ; 3x 8 BLANK
        .byte $c7,<practicescreen,>practicescreen
        .byte $70
        .byte $47,$00,$70
        .byte 7,7,7,7,7,7,7,$70
        .byte 7,7
        .byte $41,<practicedl,>practicedl

practicescreen:
        invscrcode "! PRACTICE A LEVEL '"
levelnums:
        scrcode "  1    9   17   25A "
        scrcode "  2   10   18   25B "
        scrcode "  3   11   19   25C "
        scrcode "  4   12   20   26  "
        scrcode "  5   13   21   27  "
        scrcode "  6   14   22   28  "
        scrcode "  7   15   23   29  "
        scrcode "  8   16   24   30  "
joy_instructions:
        invscrcode "choose with "
        scrcode "joystick"
pushselect:
        invscrcode "push "
        scrcode "select"
        invscrcode " for menu"
trigger_instructions:
        invscrcode "push "
        scrcode "trigger"
        invscrcode " to play"

scr_level_loc:
        .byte $ff
        .byte 0,20,40,60,80,100,120,140
        .byte 5,25,45,65,85,105,125,145
        .byte 10,30,50,70,90,110,130,150
        .byte 15,35,55,75,95,115,135,155


; hook into successful level completion check. If game option 6, don't play any more levels, jump right back to the practice screen. Real code jumps to 6d22 when there are no more levels to play, so need to duplicate what's going on there. 6d22 -> 4780 -> 3cf4 -> 6800 -> 68fd -> 0bb8
nextlvl: ; hook into code at $5200
        lda $2603
        cmp #6
        beq cleanup
        jmp $5203       ; continue with old level check routine

; hook into final score to intercept end of game check. Original code goes to 5600 to display end of game score, 68fd to display high score table, the 0bb8 to do something, then to 23eb to get back to game options screen.
r5300:
        jsr $3780
        lda $2603
        cmp #6
        beq cleanup
        jmp $5303       ; continue with old level check routine

cleanup: ; copy the select handler code since select can be called at essentially any time to go back to the game options screen
        lda #$0d
        sta $3c33
        sta $3c59
        lda #$40
        sta $d20e    ; IRQEN

@done:  jmp practice

        

levelnames:
        .byte $04,$e5,$e1,$f3,$f9,$c0,$e4,$ef,$e5,$f3,$c0,$e9,$f4
        .byte $06,$f2,$ef,$e2,$ef,$f4,$f3,$c0,$e9
        .byte $05,$e2,$ef,$ed,$e2,$f3,$c0,$e1,$f7,$e1,$f9
        .byte $03,$ea,$f5,$ed,$f0,$e9,$ee,$e7,$c0,$e2,$ec,$ef,$e3,$eb,$f3
        .byte $06,$f6,$e1,$ed,$f0,$e9,$f2,$e5,$c0
        .byte $06,$e9,$ee,$f6,$e1,$f3,$e9,$ef,$ee
        .byte $03,$e7,$f2,$e1,$ee,$e4,$c0,$f0,$f5,$fa,$fa,$ec,$e5,$c0,$e9
        .byte $06,$e2,$f5,$e9,$ec,$e4,$e5,$f2,$c0
        .byte $03,$ec,$ef,$ef,$eb,$c0,$ef,$f5,$f4,$c0,$e2,$e5,$ec,$ef,$f7
        .byte $06,$e8,$ef,$f4,$c0,$e6,$ef,$ef,$f4
        .byte $06,$f2,$f5,$ee,$e1,$f7,$e1,$f9,$c0
        .byte $05,$f2,$ef,$e2,$ef,$f4,$f3,$c0,$e9,$e9,$c0
        .byte $05,$e8,$e1,$e9,$ec,$f3,$f4,$ef,$ee,$e5,$f3
        .byte $03,$e4,$f2,$e1,$e7,$ef,$ee,$c0,$f3,$ec,$e1,$f9,$e5,$f2,$c0
        .byte $02,$e7,$f2,$e1,$ee,$e4,$c0,$f0,$f5,$fa,$fa,$ec,$e5,$c0,$e9,$e9,$c0
        .byte $04,$f2,$e9,$e4,$e5,$c0,$e1,$f2,$ef,$f5,$ee,$e4,$c0
        .byte $05,$f4,$e8,$e5,$c0,$f2,$ef,$ef,$f3,$f4,$c0
        .byte $04,$f2,$ef,$ec,$ec,$c0,$ed,$e5,$c0,$ef,$f6,$e5,$f2
        .byte $02,$ec,$e1,$e4,$e4,$e5,$f2,$c0,$e3,$e8,$e1,$ec,$ec,$e5,$ee,$e7,$e5
        .byte $06,$e6,$e9,$e7,$f5,$f2,$e9,$f4,$c0
        .byte $05,$ea,$f5,$ed,$f0,$cd,$ee,$cd,$f2,$f5,$ee
        .byte $07,$e6,$f2,$e5,$e5,$fa,$e5
        .byte $01,$e6,$ef,$ec,$ec,$ef,$f7,$c0,$f4,$e8,$e5,$c0,$ec,$e5,$e1,$e4,$e5,$f2,$c0
        .byte $05,$f4,$e8,$e5,$c0,$ea,$f5,$ee,$e7,$ec,$e5
        .byte $04,$ed,$f9,$f3,$f4,$e5,$f2,$f9,$c0,$ed,$e1,$fa,$e5
        .byte $04,$ed,$f9,$f3,$f4,$e5,$f2,$f9,$c0,$ed,$e1,$fa,$e5
        .byte $04,$ed,$f9,$f3,$f4,$e5,$f2,$f9,$c0,$ed,$e1,$fa,$e5
        .byte $05,$e7,$f5,$ee,$e6,$e9,$e7,$e8,$f4,$e5,$f2
        .byte $05,$f2,$ef,$e2,$ef,$f4,$f3,$c0,$e9,$e9,$e9
        .byte $01,$ee,$ef,$f7,$c0,$f9,$ef,$f5,$c0,$f3,$e5,$e5,$c0,$e9,$f4,$ce,$ce,$ce,$ce
        .byte $04,$e7,$ef,$e9,$ee,$e7,$c0,$e4,$ef,$f7,$ee,$df,$c0
        .byte $02,$e7,$f2,$e1,$ee,$e4,$c0,$f0,$f5,$fa,$fa,$ec,$e5,$c0,$e9,$e9,$e9
