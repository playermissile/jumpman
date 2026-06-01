; Levelbuilder image for level storage version 1
;
; Copyright (c) 2016,2026 Rob McMullen <feedback@playermissile.com>
; Copyright (c) 2016,2026 Kay Savetz <antic@ataripodcast.com>

.include "levelbuilder_common.s"

copy_level_to_memory:
        lda #$88        ; copy working level to $2800
        ldy #$28
        ldx #$8
        jsr copypg
        rts
