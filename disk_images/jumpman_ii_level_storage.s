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
