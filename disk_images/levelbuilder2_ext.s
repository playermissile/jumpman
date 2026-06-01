; Levelbuilder image for level storage version 2
;
; Copyright (c) 2016,2026 Rob McMullen <feedback@playermissile.com>
; Copyright (c) 2016,2026 Kay Savetz <antic@ataripodcast.com>

.include "levelbuilder_common.s"

.include "jumpman_ii_level_storage.s"

copy_level_to_memory:
        lda #$90        ; copy possibly compressed data from page $90 to page $10
        ldy #$10
        ldx #$10        ; $10 pages
        jsr copypg

        ldx #$7f        ; copy header to 2800
@1:     lda $8f80,x
        sta $2800,x
        dex
        bpl @1

        jsr unpack_level_v2

        rts
