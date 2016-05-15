; Boot loader disclaimer/credits for Jumpman
;
; Copyright (c) 2016, Rob McMullen <feedback@playermissile.com>
; Copyright (c) 2016, Kevin Savetz <antic@ataripodcast.com>

; Loader that resides in sectors 6 & 7. That space is unused
; on disk but not loaded in automatically, so code in the first sector
; must be modified to load this. It is loaded at $0a00 which is
; overwritten by subsequent loads in the boot code, so it must be moved
; to lower memory.

        .macpack atari

; OS definitions
atract = $4d
vbreak = $206
sdlstl = $230
gprior = $26f
prior = $d01b
colpf2 = $d018
colbk = $d01a
audc1 = $d201
audc2 = $d203
audc3 = $d205
audc4 = $d207
audctl = $d208
dlistl = $d402
dlisth = $d403
wsync = $d40a
nmien = $d40e
setvbv = $e45c

screen = $1000
line = screen + $c8
marquee_ptr = $80
delay = $82
count = $83

       .segment "JMHACK1"
       .ORG $0a00

; bootstrap code called from the end of the boot sector loader, set at the
; vector 09d6 in the boot code.
bootstrap:
        LDY #$00
loop:   LDA $0a00,y
dest:   STA $0600,y
        INY
        BNE loop

        lda #<extrascreen
        sta marquee_ptr
        lda #>extrascreen
        sta marquee_ptr + 1
        jsr credits
        lda #20
        sta delay
        lda #(scrolling2 - scrolling1)
        sta count
        JMP $0800
bootstrapend:

; All this code resides at $6300 - $67ff on disk and is copied to $0600
; by the boot2 code above. After this point, we need the origin to appear
; as if everything was assembled at $0600. boot2 will also get copied so
; adjust the origin to after that number of bytes. The .lnk file alse needs
; to get adjusted with the correct number of bytes, but I don't know how
; to do that other than by hand. So if boot2 changes, update that file.

        .segment "JMHACK2"
        .org $0600 + bootstrapend - bootstrap   ; calculate offset into $0600

mydisk: 
        lda delay
        beq @scroll
        dec delay
        bne @1

@scroll:
        lda count
        beq @siov
        dec count
        inc marquee_ptr
        bne @1
        inc marquee_ptr + 1
@1:     jsr credits
@siov:  jmp $e453

credits:
@1:     ldy #31
@2:     lda ($80), y
        sta line + 8, y
        dey
        bpl @2
        ldy #7
@3:     lda version, y
        sta line, y
        dey
        bpl @3
        rts

extradl:
        .byte $70
        .byte 2
        .byte $41, $ee, $08

version:
        scrcode "v1.0    "

extrascreen:
        scrcode          "     2016 coding by Rob McMullen"
scrolling1:
        scrcode ". Reverse engineering notes by Rob McMullen & Kevin Savetz available at http://playermissile.com/jumpman"
scrolling2:
