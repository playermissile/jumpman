; Jumpman II utilities
;
; Copyright (c) 2016,2026 Rob McMullen <feedback@playermissile.com>
; Copyright (c) 2016,2026 Kay Savetz <antic@ataripodcast.com>

.ifndef setvbv
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
.endif

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
        pha     ; save temporarily
        and #$0f
        cmp #$a
        bcc @1
        adc #6  ; oooh! Save a byte! Operation we want is +7, but carry is guaranteed to be set
@1:     adc #16
        tax
        pla
        lsr a
        lsr a
        lsr a
        lsr a
        cmp #$a
        bcc @2
        adc #6
@2:     adc #16
        rts


; show display list and turn off anything behind the scenes, like audio, DLIs or VBIs.
; High byte in X, low byte in Y for display list
showdl:
        sty sdlstl
        sty dlistl
        stx dlisth
        stx sdlstl + 1
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
        rts


waitkeyrelease:
@2:     lda consol          ; wait until any CONSOL button is released
        cmp #7
        bne @2
@3:     lda trig0           ; wait until trigger is released
        beq @3
        rts
