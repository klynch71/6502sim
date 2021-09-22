; This program is similar to that run by default in the visual6502.org simulation
; which can be found at: http://www.visual6502.org/JSSim/expert.html
; The only difference is that we do not automatically initialize our registers like
; visual6502.org does, so our initial instructions are:
;              - clear decimal mode flag
;              - initialize the stack
;              - set the X & Y registers to zero
;              - set the accumulator to zero
;              - initialize or memory storage location, zpg_addr to zero.
; Our mem_loc will be $1f instead of $0f because we added the extra instructions at
; the beginning so we need to move our memory write location  out more.

zpg_addr = $1f              ; zero page address of storage used in the subroutne

            cld             ; clear decimal mode flag
            ldx #$fd        ; load x with stack location
            txs             ; transfer x to stack register
            lda #0          ; load accumulator with 0
            ldx #0          ; load x register with 0
            ldy #0          ; load y register with 0
            stx zpg_addr    ; put x register (0) into mem_loc
            
            ; same as 6502.org from here to end except we write to a different memory address
            lda #0          ; load accumulator with 0
gosub:      jsr subroutine
            jmp gosub

subroutine: inx             ; increment x
            dey             ; decrement y
            inc zpg_addr    ; increment value in zpg_addr
            sec             ; set carry bit
            adc #02         ; add two + carry to accumulator
            rts             ; return from subroutne

