; This program uses a subroutine to clear 16 bytes of memory starting at BLOCK
; The subroutine algorithm is from Michael Pointer and you can learn more here:
; http://6502.org/source/general/clearmem.htm
;

TOPNT = $CC              ;zero page address that holds start of memory to clear
BLOCK = $3000            ;start of memory to clear

.ORG $0000                ;start program at $0000
START:
         LDX #$1f        ;initialize stack pointer register
         TXS
         LDA #0          ;load address to clear into TOPNT and TOPNT+1
         STA TOPNT
         LDA #$20
         STA TOPNT+1
         LDY #$0F        ;clear 16 bytes
         JSR CLRMEM
         JMP START       ;just keep going

CLRMEM:  LDA #$00        ;Set up zero value
CLRM1:   DEY             ;Decrement counter
         STA (TOPNT),Y   ;Clear memory location
         BNE CLRM1       ;Not zero, continue checking
         RTS             ;RETURN
