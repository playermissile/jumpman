; Enhancements to Jumpman!
;
; Copyright (c) 2016, Rob McMullen <feedback@playermissile.com>
; Copyright (c) 2016, Kevin Savetz <antic@ataripodcast.com>

; Loader that resides in sectors 694 - 703. That space is unused
; on disk but is still loaded during the boot process. It ends up
; in memory at $6300 - $67ff, so we have 5 pages to work with.

        .macpack atari

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

        jmp xexinit
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

xexinit: ; entry point for XEX boot
        jsr patch
        jsr $3780       ; clear memory
        jsr $3820       ; set up character set
        lda #$ff        ; flag to load test level instead of accessing disk
        sta $30ef
        sta fastload
        lda #<youbigdummy
        sta vbreak
        lda #>youbigdummy
        sta vbreak + 1
        jmp practice2

        ;jmp $55c0       ; jump to entry point right after loading sectors

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

practice: ; new code to load in practice level sector
        lda #$61
        sta $30ee
        lda #$0
        sta $30ef

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

; Harvest table crash page. Intercept the BRK operator that occurs
; when there's a harvest table miss and display the relevant info.
; We are in an interrupt handler here, so need to end with RTI
youbigdummy:
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
        beq showdl
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


showdl:
        lda #<dummydl
        sta sdlstl
        sta dlistl
        lda #>dummydl
        sta dlisth
        sta sdlstl + 1
        lda #$40
        sta nmien
        lda #0
        sta audctl
        sta audc1
        sta audc2
        sta audc3
        sta audc4
        lda #$14
        sta gprior
        sta prior
        ldx #$e4
        ldy #$62
        lda #$07
        jsr setvbv

        pla             ; mess with stack to return to our wait loop
        sta $80         ; there are two vars on the stack, then the return
        pla             ; address.
        pla
        lda #>wait
        pha
        lda #<wait
        pha
        lda $80
        pha
        rti
        nop
        nop
        nop
wait:   nop
        nop
        nop
@1:     jmp @1

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



dummydl:
        .byte $70,$70,$70,$70,$70 ; 3x 8 BLANK
        .byte $47,<dummyscreen,>dummyscreen ; LMS MODE 6
        .byte $70,$06,$06,$06,$06,$06,$70
        .byte 7,6,6,6,6,6,6,6
        .byte $41,<dummydl,>dummydl

dummyscreen:
        scrcode "PEANUT HARVEST ERROR"
        scrcode "00BC CHECKSUM: "
scrchecksum:
        scrcode "FF   "
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
scrpeanuts:
        scrcode "                    "
        scrcode "                    "
        scrcode "                    "
        scrcode "                    "
        scrcode "                    "
        scrcode "                    "
        scrcode "                    "


; copy of code from 2476: game options screen
gopt:
        lda #$04
        sta $4108       ; option is allowed
        lda $2603       ; game option number
        clc
        adc #$01
        cmp #$07        ;Number of items in the game options list
        bne @1
        lda #$01
@1:     sta $2603
        sta $32fe
        ldx #$14     ;copies "push start to play" after option is first pressed
@2:     lda start,x  ;new location, was 25c1
        sec
        sbc #$20
        sta $70b3,x  ;destination on screen for "push start to play"
        dex
        bne @2
        lda #$13
        sta $3040
        lda #$26
        sta $3041
        lda #$10
        jsr $32b0       ; what does this subroutine do? 
@wait1: lda $3030
        ora $3032
        cmp #$00
        bne @wait1
        lda #$c9
        sta $4100
        lda #$24
        sta $4101
        lda #$00
        sta $4106
        sta $4108
        jmp $2473
        lda #$01
        sta $4106
        lda #$04
        sta $4108
        lda #$00
        sta $4107
        lda #$40
        sta $d40e
        jsr $8023    ;new call to $8023: load start sector for chosen game option
