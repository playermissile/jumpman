; Level storage version 2 support
;
; Copyright (c) 2016,2026 Rob McMullen <feedback@playermissile.com>
; Copyright (c) 2016,2026 Kay Savetz <antic@ataripodcast.com>

;
; score handling in v2
;

; the score in v1 is pulled from 2800 and 2801 here
;0fc0       lda L2800
;0fc3       sta L4636
;0fc6       lda L2801
;0fc9       sta L4637

; but 2800 and 2801 are stored again later on in the load process at 4500
;4500       lda L2800
;4503       sta L4636
;4506       lda L2801
;4509       sta L4637
;
; so 0fc3 should then be:
;0fc3:  bmi $0fcc
;0fc5:  jmp $455c
;0fc8:  nop
;0fc9: <unchanged sta $4637>
;0fcc: <unchanged jmp $4ca0>
;
; and 4500 should change this to:
;4500:  lda $2801
;4503:  jsr hex2text
;4506:  sta $4635
;4509:  stx $4637
;
; this is all handled in patch files because no additional space was needed

unpack_level_v2:
        lda #$00        ; src in $(e0): $1000
        sta $e0
        lda #$10
        sta $e1
        lda #$80        ; dest in $(e2): $2880
        sta $e2
        lda #$28
        sta $e3
        lda $2860       ; count for Block A in $(e4)
        sta $e4
        lda $2861
        sta $e5

        lda $2866
        beq @1
        cmp #1
        bne fail
        jsr unpack_lz4
        clc
        bcc handle_block_b
@1:     jsr copy_uncompressed

handle_block_b:
        ; e0 will be pointing to first byte of Block B raw data
        lda $2864        ; dest in $(e2): typically $a800
        sta $e2
        lda $2865
        sta $e3
        lda $2862       ; count for Block B in $(e4)
        sta $e4
        lda $2863
        sta $e5

        lda $2867
        beq @1
        cmp #1
        bne fail
        jsr unpack_lz4
        rts
@1:     jsr copy_uncompressed
        rts

fail:
        jmp $455c       ; unsupported compression algorithm

copy_uncompressed:
        ldy #0
        ldx $e5         ; number of pages
        beq @partial
@page:  lda ($e0),y
        sta ($e2),y
        iny
        bne @page
        inc $e1
        inc $e3
        dex
        bne @page

@partial:
        cpy $e4
        beq @cleanup
        lda ($e0),y
        sta ($e2),y
        iny
        bne @partial
@cleanup:
        clc
        lda $e0
        adc $e4
        sta $e0
        bcc @exit
        inc $e1
@exit:  rts



;LZ4 data decompressor for Apple II
;Peter Ferrie (peter.ferrie@gmail.com)
;
;from http://pferrie.host22.com/misc/appleii.htm
;Converted to ATasm by Rob McMullen
;
; raw compressed data in $e0
; destination address in $e2
; count in $e4, which is then reused as a temp variable
src = $e0
dst = $e2
count = $e4
end = $e6
delta = $e8

unpack_lz4:
        ldy	#0
        clc
        lda src
        adc count
        sta end
        lda src+1
        adc count+1
        sta end+1

parsetoken:
    jsr	getsrc
    pha
    lsr
    lsr
    lsr
    lsr
    beq	copymatches
    jsr	buildcount
    tax
    jsr	docopy
    lda	src
    cmp	end
    lda	src+1
    sbc	end+1
    bcs	done

copymatches:
    jsr	getsrc
    sta	delta
    jsr	getsrc
    sta	delta+1
    pla
    and	#$0f
    jsr	buildcount
    clc
    adc	#4
    tax
    bcc	@1
    inc	count+1
@1:	lda	src+1
    pha
    lda	src
    pha
    sec
    lda	dst
    sbc	delta
    sta	src
    lda	dst+1
    sbc	delta+1
    sta	src+1
    jsr	docopy
    pla
    sta	src
    pla
    sta	src+1
    jmp	parsetoken

done:
    pla
    rts

docopy:
    jsr	getput
    dex
    bne	docopy
    dec	count+1
    bne	docopy
    rts

buildcount:
    ldx	#1
    stx	count+1
    cmp	#$0f
    bne	@3
@1:	sta	count
    jsr	getsrc
    tax
    clc
    adc	count
    bcc	@2
    inc	count+1
@2:	inx
    beq	@1
@3:	rts

getput:
    jsr	getsrc

putdst:
    sta (dst), y
    inc	dst
    beq @1
    rts
@1:	inc	dst+1
    rts

getsrc:
    lda (src), y
    inc	src
    beq	@1
    rts
@1:	inc	src+1
    rts
