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

; Jumpman definitions
joy_vert = $3020
joy_horz = $3024
joy_btn = $302c
screen = $7000
line1 = screen + 160
line2 = screen + 180


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
        sta $80
        lda #>extrascreen
        sta $81

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

mydisk2: inc extradl_ptr
        bne @1
        inc extradl_ptr + 1
@1:     lda extradl_ptr
        sta $80
        lda extradl_ptr + 1
        sta $81
        ldy #8
@2:     lda version, y
        sta ($80), y
        dey
        bpl @2

mydisk: inc $80
        bne @1
        inc $81
@1:     ldy #32
@2:     lda ($80), y
        sta version + 8, y
        dey
        bpl @2
        jmp $e453


extradl:
;        .byte $70,$70,$70,$70,$70 ; 6x 8 BLANK boot screen display list
;        .byte $48,$00,$10 ; LMS 1000 MODE 8
;        .byte $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08 ; 15x MODE 8
;        .byte $70,$70 ; 2x 8 BLANK
;        .byte 2    ; MODE 2
        .byte $70
        .byte $42
extradl_ptr:
;        .byte <extrascreen,>extrascreen
        .byte <version, >version
;        .byte $41,<extradl, >extradl
        .byte $41, $ee, $08

version:
        scrcode "v1.0                                    "

extrascreen:
        scrcode "             2016 coding by Rob McMullen"
        scrcode ". Reverse engineering notes by Rob McMullen & Kevin Savetz available at http://playermissile.com/jumpman"