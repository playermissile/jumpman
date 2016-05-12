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
        JMP stage2
        ; now we need 10 extra bytes to keep rest of the code in the same spot
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop


; All this code resides at $6300 - $67ff on disk and is copied to $8000
; by the boot2 code above. After this point, we need the origin to appear
; as if everything was assembled at $8000. boot2 uses $23 bytes of code
; so the new origin is $8023. If the size of boot2 changes, adjust this
; origin and the offset in the ca65 link file!

        .segment "JMHACK2"
        .org $8023      ; $23 bytes in boot2 code

; reserve space for vector table so I don't have to keep changing addresses
; in the Jumpman atr
jumptable:
        jmp loadlvl
        jmp nextlvl

start:  .byte $20,$10,$15,$13,$08,$a0,$93,$94,$81,$92,$94,$a0,$14,$0f,$20,$10,$0c,$01,$19,$a0 ; $14 data bytes moved copy of "press start to play"

        ;jmp xexinit
        nop
        nop
        jmp r4400
        nop
        nop
        nop
        jmp r5300


; replace the game options display list 
opt_dl: .byte $70,$70,$70 ; 3x 8 BLANK game options display list
        .byte $47,$00,$70 ; LMS 7000 MODE 7
        .byte $07         ; MODE 7, "game options" title area at $7014
        .byte $c7,$00,$70 ; LMS + DLI, point to blank area
        .byte $c7,$28,$70 ; LMS + DLI, point to first line of menu
        .byte $87,$87,$87,$87
        .byte $07       ; MODE 7
        .byte $70,$70   ; **NEW!!** extra blank space because of new option
        .byte $47,$b4,$70 ; LMS, point to where start/select line should be
        .byte $41
        .word opt_dl ; JVB back to start of display list

patches: ; list of patch addresses, 3 bytes per entry low, high, replacement

        ; modify the game options code to point to our (larger) game options display list
        .word $242a
        .byte <opt_dl
        .word $242f
        .byte >opt_dl

        ; debugging! only one extra life
        .word $4d01
        .byte 1

        .word $5300
        .byte $4c
        .word $5301
        .byte <r5300
        .word $5302
        .byte >r5300

        .word $ffff

patch:  ldx #0
        ldy #0
@2:     lda patches,x
        sta $82
        inx
        lda patches,x
        sta $83
        inx
        and $82
        cmp #$ff
        bne @1
        rts
@1:     lda patches,x
        inx
        sta ($82),y
        jmp @2


stage2: ; entry point after normal ATR boot
        ;jsr fixupdl
        jsr patch
        jmp $2900       ; jump back to original post-boot start addr

fixupdl: ; modify the game options code to point to our (larger) game options display list
        lda #<opt_dl
        sta $242a
        lda #>opt_dl
        sta $242f
        rts


; choose sector start for practice level
loadlvl: ; hook into code at 24dd
        ldy $2603
        cpy #6
        beq practice_init
        lda $2507,y
        sta $30ee
        lda $250d,y
        sta $30ef
        rts

practice_level:
        .byte 0

practice_init: ; new code to load in practice level sector
        lda #0
        sta practice_level
practice:
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
        lda #$40
        sta nmien

        ; replace code at 24ec to avoid chosing the number of players. Force this to be one player by doing everything that $0a00 does except waiting for the user to press a key
        pla
        pla
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
        rts
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


; hook into successful level completion check. If game option 6, don't play any more levels, jump right back to the practice screen
nextlvl: ; hook into code at $5200
        lda $2603
        cmp #6
        beq @cont
        rts             ; continue with old level check routine
@cont:  pla             ; pop return address off stack
        pla
        ; FIXME: need to figure out what to call to reset colors and players
        jmp practice

; hook into final score to intercept end of game check
r5300:
        jsr $3780
        lda $2603
        cmp #6
        beq @cont
        jmp $5303       ; continue with old level check routine
@cont:  jmp practice


r4400: ; replacement for 4400 to skip loading if $#ff passed in high sector
        lda $30ef
        cmp #$ff
        beq @1
        jsr $443c
        jmp $4403
@1:     lda #$88        ; copy working level to $2800
        ldy #$28
        ldx #$8
        jsr copypg
        rts


; copy pages. Source page in A, dest page in Y, num pages in X
copypg: sta @1 + 2
        sty @2 + 2
        ldy #$00
@1:     lda $ff00,y
@2:     sta $ff00,y
        iny
        bne @1
        inc @1 + 2
        inc @2 + 2
        dex
        bne @1
        rts
