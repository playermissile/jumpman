; Custom bootloader for Jumpman testing
;
; Modified from my 3 sector boot sector DOS menu
;
; Copyright (c) 1984, 2016 Rob McMullen <feedback@playermissile.com>
; Licensed under the GPLv3; see playermissile.com for more info

        .macpack atari

        .segment "BOOTLOADER"
        .org $0700

xsave = $19
addr = $43
endaddr = $45
buffer = $100 ; first half of the stack is unlikely to be used. Only works for single density, though!
sdlstl = $230
initad = $02e2
runad = $02e0
dlistl = $d402
dlisth = $d403

; copying the kboot format
        .byte $00,$03,$00,$07,<init,>init ; boot header
        jmp init ; jump to init
count:
        .word $ffff ; number of bytes to load
        .byte $00 ; unused; kboot uses it if > 65536 bytes
        .byte $00 ; zero

init:
        ldy #$00
        sty $0309    ; DBYTHI
        sty $0304    ; DBUFLO
        sty $0244    ; COLDST
        sty initad
        sty initad + 1
        iny
        sty $09      ; BOOT?
        sty $0301    ; DUNIT
        dec $0306    ; DTIMLO
        lda #$31
        sta $0300    ; DDEVIC
        lda #$52
        sta $0302    ; DCOMND
        lda #$80
        sta $0308    ; DBYTLO
        lda #>buffer
        sta $0305    ; DBUFHI

        lda #<dlist
        sta sdlstl
        sta dlistl
        lda #>dlist
        sta sdlstl + 1
        sta dlisth

        lda #0
        tax
        sta $030b       ; start at sector 4
        lda #4
        sta $030a
        jsr load     
        dex     ; force reread of first byte

segment:
        jsr getbyte
        sta addr
        jsr getbyte
        sta addr + 1
        and addr
        cmp #$ff
        beq segment
        jsr getbyte
        sta endaddr
        jsr getbyte
        sta endaddr + 1

readloop:
        jsr getbyte
        sta (addr),y
        inc addr
        bne @1
        inc addr + 1
@1:     lda endaddr
        cmp addr
        lda endaddr + 1
        sbc addr + 1
        bcs readloop
        lda initad
        ora initad + 1
        beq segment
        stx xsave
        jsr seginit
        ldx xsave
        ldy #$00
        sty initad
        sty initad + 1
        beq segment

seginit:
        jmp (initad)

getbyte:
        ; check if finished
        lda count
        bne @1
        lda count + 1
        bne @2
        jmp (runad)  ; execute the program! Something better have been stuffed in 2e0!
       
@2:     dec count + 1
@1:     dec count

        cpx #$80
        bcc readbyte

load:
        lda #$40
        sta $0303    ; DSTATS
        jsr $e459    ; SIOV
        bpl loadok
        dec $0701       ; reuse the 3 for retry count!
        bne load
        brk     ; do something on the error

loadok:
        inc $030a    ; increment sector number
        bne @1
        inc $030b
@1:     lda $030a
        sta $d019    ; COLPF3
        ldy #$00
        ldx #$00
readbyte:
        lda buffer,x
        inx
        rts


dlist:
        .byte $70,$70,$70,$70,$70 ; 3x 8 BLANK
        .byte $46,<screen,>screen ; LMS MODE 6
        .byte $70 ; 32 BLANK
        .byte $07,$70,$70,$70,$06,$70,$06,$70,$06
        .byte $41,<dlist,>dlist

screen:
        scrcode "     LOADING...     "
;        scrcode "JUMPMAN LEVEL TESTER"
        .byte $ea,$f5,$ed,$f0,$ed,$e1,$ee,$00,$ec,$e5,$f6,$e5,$ec,$00,$f4,$e5,$f3,$f4,$e5,$f2 ; $14 data bytes

        scrcode "        FROM        "
        scrcode " playermissile"
        .byte $4e
        scrcode "com  "
        scrcode "  ataripodcast"
        .byte $4e
        scrcode "com  "
