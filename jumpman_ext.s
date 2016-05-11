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


       .segment "JMHACK1"
       .ORG $6300

; bootstrap code called from the end of the boot sector loader, set at the
; vector 09d6 in the boot code.
boot2:  LDA #$80     ;copy 5 pages from $6300 to $8000
        STA dest + 2
        LDA #$63
        sta loop + 2
        LDX #$05
        LDY #$00
loop:   LDA $ff00,y
dest:   STA $ff00,y
        INY
        BNE loop
        INC dest + 2
        INC loop + 2
        DEX
        BNE loop
        JMP stage2


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
        jmp r503c


; replace the game options display list 
opt_dl: .byte $70,$70,$70 ; 3x 8 BLANK game options display list
        .byte $47,$00,$70 ; LMS 7000 MODE 7
        .byte $07    ; MODE 7
        .byte $87,$87,$87,$87,$87,$87 ; 6x DLI MODE 7
        .byte $07       ; MODE 7
        .byte $70,$70   ; **NEW!!** extra blank space because of new option
        .byte $07       ; MODE 7
        .byte $41
        .word opt_dl ; JVB back to start of display list

patches: ; list of patch addresses, 3 bytes per entry low, high, replacement

        ; modify the game options code to point to our (larger) game options display list
        .word $242a
        .byte <opt_dl
        .word $242f
        .byte >opt_dl

        ; replace level scrolling routine
        .word $503c
        .byte $4c
        .word $503d
        .byte <r503c
        .word $503e
        .byte >r503c

        ; replace level scrolling routine
        .word $500a
        .byte $4c
        .word $500b
        .byte <r500a
        .word $500c
        .byte >r500a

        ; short-circuit call to level scrolling routine
;        .word $5591
;        .byte <r5590
;        .word $5592
;        .byte >r5590

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
        beq practice
        lda $2507,y
        sta $30ee
        lda $250d,y
        sta $30ef
        rts

practice_level:
        .byte 0

practice: ; new code to load in practice level sector
        lda #<practicedl
        sta sdlstl
        lda #>practicedl
        sta sdlstl + 1
        lda #0
        sta atract
        ; note! Select is automatically coded to go back to game options screen!
        lda #0
        sta practice_level
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

        lda practice_level
        sta $82
        lda #0
        sta $83

        asl $82       ; multiply by 16
        rol $83
        asl $82
        rol $83
        asl $82
        rol $83
        asl $82
        rol $83
        clc
        lda #$11
        adc $82
        sta $30ee
        lda #$00
        adc $83
        sta $30ef

;        lda #$61
;        sta $30ee
;        lda #$0
;        sta $30ef

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

show_instructions: ; check to see if this the first time
        lda practice_level
        beq basic_instructions
        ldy #20
@1:     lda trigger_instructions - 1,y
        sta line1 - 1,y
        lda #0
        sta line2 - 1,y
        dey
        bne @1
        lda practice_level
        jsr hex2text
        sta line2
        stx line2 + 1
        rts
basic_instructions:
        ldy #40
@1:     lda joy_instructions - 1,y
        sta line1 - 1,y
        dey
        bne @1
        rts


practicedl:
        .byte $70,$70,$70 ; 3x 8 BLANK
        .byte $47,<practicescreen,>practicescreen
        .byte $70,7,7,7,7,7,7,7,7,$70
;       .byte $70,6,6,6,6,6,6,6,6,$70
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
line1:
        scrcode "                    "
line2:
        scrcode "                    "
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

        .byte $c0,$c0,$c0,$c0,$e5,$e1,$f3,$f9,$c0,$e4,$ef,$e5,$f3,$c0,$e9,$f4,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$f2,$ef,$e2,$ef,$f4,$f3,$c0,$e9,$c0,$c0,$c0,$c0,$c0,$c0 ; $28 data bytes


; hook into level completion check. If game option 6, don't play any more levels, jump right back to the game options screen
nextlvl: ; hook into code at $5200
        lda $2603
        cmp #6
        beq @cont
        rts             ; continue with old level check routine
@cont:  pla             ; pop return address off stack
        pla
        lda #1          ; fake out being beginner level
        sta $2603
        lda #$ff
        sta $30f0
        jmp $23eb       ; jump to game options entry point


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

fastload: .byte $0

r503c: ; replacement for slow scroll to copy screen
        lda fastload
        cmp #$ff
        beq @1
        lda $50d6
        jmp $503f
@1:     lda #0
        sta $e0
        jsr copyscr
        jmp $5049

r500a:  jsr $331c
        lda fastload
        cmp #$ff
        beq @1
        jmp $500d
@1:     jsr $56af
        ldx #$50
        ldy #$cb
        lda #$07
        jsr $e45c    ; SETVBV

        jsr $56af

        lda #$c0
        sta $d40e    ; NMIEN
        lda #0
        sta $e0
        jsr copyscr
;        lda #$40
;        sta $d40e    ; NMIEN

        jsr $56af

        lda #$4d ; fixes the flashy problems by removing the DLI on the first line
        sta $3c03
        lda #$5b ; fix this pointer showing the DLIs have been pushed all the way to the bottom
        sta $f0
        jmp $502b ; need to exit through here, otherwise bombs can't be picked up

; looks like there is an extra DLI bit that can be set on the main playfield
; display list. Routine 4ca0 sets this extra bit, but it's not used in normal
; play



; currently, this results in an empty playfield! Still flashy!
r5590:  jsr $3800
        jsr $331c
        jsr copyscr
        rts

copyscr: lda #$10
        ldy #$70
        ldx #$0f
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

; convert hex value in A to two characters, high nibble returned
; in A, low nibble in X
hex2text:
        tay     ; save temporarily
        and #$0f
        cmp #$a
        bcc @1
        adc #6  ; oooh! Save a byte! Operation we want is +7, but carry is guaranteed to be set
@1:     adc #16
        tax
        tya
        lsr a
        lsr a
        lsr a
        lsr a
        cmp #$a
        bcc @2
        adc #6
@2:     adc #16
        rts
