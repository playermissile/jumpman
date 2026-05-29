; Enhancements to Jumpman!
;
; Copyright (c) 2016,2026 Rob McMullen <feedback@playermissile.com>
; Copyright (c) 2016,2026 Kay Savetz <antic@ataripodcast.com>


jumpman_ii_title:
        jsr $5400       ; plot the Jumpman logo that's been set up before this call
        lda #$c2       ; get Jumpman graphic drawn in marquee
        sta $e0        ; screen at 77bb
        lda #$77
        sta $e1
        lda #$02       ; 2 bytes wide
        sta $e6
        lda #<ii_image       ; source pixmap
        sta $e3
        lda #>ii_image
        sta $e4
        lda #$0c       ; 12 lines high
        sta $e9
        lda #$01       ; x offset of 1
        sta $e2
        jmp $5ba0       ; go to the original target displays the copyright and uses its return

ii_image:
        .byte %00011111, %11111100
        .byte %00111111, %11111000
        .byte %00001100, %00110000
        .byte %00001100, %00110000
        .byte %00001100, %00110000
        .byte %00001100, %00110000
        .byte %00001100, %00110000
        .byte %00001100, %00110000
        .byte %00001100, %00110000
        .byte %00001100, %00110000
        .byte %00011111, %11111100
        .byte %00111111, %11111000
