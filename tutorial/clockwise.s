        .segment "JUMPMAN"
        .org $2900

; os memory map
random = $d20a

; jumpman memory map
p2state = $3058
p2datal = $305d
p2datah = $3062
p2height = $3067
p2x = $306c
p2y = $3071
p2num = $3076

m0state = $30a2
m0x = $30a6
m0y = $30aa
jmalive = $30bd
jmstatus = $30be
getq2 = $41e0
bangsnd = $4974

; my vars
centerx = $80
centery = $70
gunstepinit = 6
mindelay = 3 * gunstepinit
gundata = $2e00

vbi1:
        lda jmalive     ; don't rotate gun when jm is dead
        cmp #$02
        bne cont1
        lda gunstep     ; if timer already reset, skip to exit
        cmp #$ff
        beq exit1
        lda #$ff        ; init timer
        sta gunstep
        lda #0          ; move all missiles off screen
        sta active
        sta active+1
        sta active+2
        sta active+3
        sta m0x
        sta m0x+1
        sta m0x+2
        sta m0x+3
exit1:  jmp $311b
cont1:  lda gundir      ; check for first time init
        cmp #$ff
        bne cont2

        jsr timerini    ; do first time init
        lda #16
        sta p2height    ; set gun sprite height
        lda #1
        sta p2state     ; activate gun sprite
        lda #<gundata   ; set pointer to gun data
        sta p2datal
        lda #>gundata
        sta p2datah
        lda #centerx    ; set gun x/y coords using offset
        sec             ; data for each animation frame
        sbc gunxoff
        sta p2x
        lda #centery
        sec
        sbc gunyoff
        sta p2y

cont2:  dec timer       ; shot timer
        dec gunstep     ; only rotate gun every N frames
        bpl startloop
        lda #gunstepinit ; reset gun counter
        sta gunstep
        inc gundir      ; increment gun animation frame
        lda gundir
        cmp numlist
        bcc @1
        lda #0
        sta gundir
@1:     tay             ; y is direction of rotation, used as index into lists
        clc
        adc #1          ; set frame number of gun; note image list starts from #1
        sta p2num       
        lda #centerx    ; set gun x/y coords using offset
        sec             ; data for each animation frame. As above
        sbc gunxoff,y
        sta p2x
        lda #centery
        sec
        sbc gunyoff,y
        sta p2y

startloop:
        ldx #$ff

loop:   inx             ; x is shot number
        cpx numshot     ; check number of shots
        beq exit1
        lda active,x    ; is already active?
        bne moveshot    ; yes, jump to the routine to move the bullet
        lda timer       ; no, only allow a new shot when the timer reaches $ff
        bpl loop

        jsr timerini    ; new shot allowed! reset timer

        lda #$01        ; activate missile
        sta active,x
        sta m0state,x

        ; set up direction of shot by using current direction of gun to find dx
        ; and dy values. also set initial position of shot
        ldy gundir      ; reload y register because it's clobbered by the sound routine
        lda dxlolist,y
        sta dxlo,x
        sta posxlo,x
        lda dxhilist,y
        sta dxhi,x
        clc
        adc #centerx
        sta posxhi,x
        lda dylolist,y
        sta dylo,x
        sta posylo,x
        lda dyhilist,y
        sta dyhi,x
        clc
        adc #centery
        sta posyhi,x

        ; sound the gun
        stx scratch     ; save the X register because it's clobbered
        lda #<bangsnd   ; by the sound routine
        sta $3040
        lda #>bangsnd
        sta $3041
        lda #$04
        jsr $32b0
        ldx scratch

        ; use 16 bit addition to move shots to get smooth movement for
        ; all angles. Only the high byte is used for the screen coordinate
moveshot:
        clc
        lda posxlo,x
        adc dxlo,x
        sta posxlo,x
        lda posxhi,x
        adc dxhi,x
        sta posxhi,x
        sta m0x,x
        cmp #$10        ; check if off left or right edge of screen
        bcc recycle
        cmp #$e0
        bcs recycle

        clc
        lda posylo,x
        adc dylo,x
        sta posylo,x
        lda posyhi,x
        adc dyhi,x
        sta posyhi,x
        sta m0y,x
        cmp #$ce        ; check if off bottom (or top via wraparound)
        bcs recycle

        jmp loop        ; end of main bullet loop

recycle: 
        lda #$00        ; mark bullet as inactive
        sta active,x
        sta m0x,x
        jmp loop

timerini:
        lda random      ; delay between bullets is random value + a minimum value
        and #$0f
        adc #mindelay
        sta timer
        rts

scratch: .byte 0
numshot: .byte 4
timer:   .byte 0
active:  .byte 0, 0, 0, 0
gundir:  .byte $ff
gunstep: .byte gunstepinit
posxlo:  .byte 0, 0, 0, 0
posxhi:  .byte 0, 0, 0, 0
posylo:  .byte 0, 0, 0, 0
posyhi:  .byte 0, 0, 0, 0
dxlo:    .byte 0, 0, 0, 0
dxhi:    .byte 0, 0, 0, 0
dylo:    .byte 0, 0, 0, 0
dyhi:    .byte 0, 0, 0, 0

.include "clockwise.gundata.inc"
