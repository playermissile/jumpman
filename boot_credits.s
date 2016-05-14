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
       .ORG $0a00

; bootstrap code called from the end of the boot sector loader, set at the
; vector 09d6 in the boot code.
bootstrap:
        LDY #$00
loop:   LDA $0a00,y
dest:   STA $0600,y
        INY
        BNE loop
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

extradl:
        .byte $70,$70 ; 3x 8 BLANK
        .byte $42,<extrascreen,>extrascreen
        .byte $41,$ee,$08

extrascreen:
        scrcode "Practice Level v1 by Rob McMullen, 2016 "
