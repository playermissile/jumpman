; Enhancements to Jumpman!
;
; Copyright (c) 2016,2026 Rob McMullen <feedback@playermissile.com>
; Copyright (c) 2016,2026 Kay Savetz <antic@ataripodcast.com>

; Loader that resides in sectors 694 - 703. That space is unused
; on disk but is still loaded during the boot process. It ends up
; in memory at $6300 - $67ff, so we have 5 pages to work with.

        .macpack atari

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

        .segment "JMHACK2"
        .org $8000

xexinit: ; entry point for XEX boot
        lda #<youbigdummy
        sta vbreak
        lda #>youbigdummy
        sta vbreak + 1

startlevel:
        lda #$00
        sta $51c9
        sta $4106
        jsr $3780       ; clear working data, reset audio
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
        lda #$88        ; copy working level to $2800
        ldy #$28
        ldx #$8
        jsr copypg

        lda numlives
        sta $30f0

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

numlives:
        .byte 0

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
@forever:
        ;jmp @forever
        jmp startlevel
