.DEVICE ATtiny2313A
.include "tn2313Adef.inc"
.equ NextTimer=96

            RJMP  main
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  
            RETI  

Time:       IN    R24,TIFR
            SBRS  R24,0
            RET   
            LDS   R24,NextTimer
            INC   R24
            MOV   R25,R24
            CPI   R24,2
            BRNE  m0
            CLR   R25
m0:         STS   NextTimer,R25
            BRNE  m1
            LDI   R25,1
            OUT   TIFR,R25
m1:         LDI   R29,0
            LDI   R28,97
m2:         DEC   R24
            BREQ  m3
            ADIW  R28,4
            RJMP  m2
m3:         LD    R24,Y
            LDD   R25,Y+1
            SBIW  R24,1
            BRCS  m4
            ST    Y,R24
            STD   Y+1,R25
            BRNE  m4
            LDD   R30,Y+2
            LDD   R31,Y+3
            IJMP  
m4:         RET   

FreeSlot:   CLT   
            LDI   R29,0
            LDI   R28,97
m5:         LD    R24,Y
            LDD   R25,Y+1
            OR    R24,R25
            BREQ  m7
            ADIW  R28,4
            LDI   R25,0
            LDI   R24,105
            CP    R28,R24
            CPC   R29,R25
            BRCC  m6
            RJMP  m5
m6:         SET   
m7:         RET   

FindSlot:   CLT   
            LDI   R29,0
            LDI   R28,97
m8:         LDD   R24,Y+2
            LDD   R25,Y+3
            CP    R30,R24
            CPC   R31,R25
            BREQ  m10
            ADIW  R28,4
            LDI   R25,0
            LDI   R24,105
            CP    R28,R24
            CPC   R29,R25
            BRCC  m9
            RJMP  m8
m9:         RJMP  FreeSlot
m10:        RET   

Delay_:     POP   R31
            POP   R30
            RCALL FindSlot
            BRTS  m11
            STD   Y+2,R30
            STD   Y+3,R31
            ST    Y,R26
            STD   Y+1,R27
m11:        RET   

Mig:        SBI   PORTB,1
            LDI   R27,0
            LDI   R26,1
            RCALL Delay_
            CBI   PORTB,1
            RET   

Migni:      RCALL Mig
            LDI   R27,0
            LDI   R26,50
            RCALL Delay_
            RJMP  Migni

main:       CLR   R3
            SBI   ACSR,7
            SBI   DDRB,1
            LDI   R24,19
            OUT   OCR0A,R24
            LDI   R24,2
            OUT   TCCR0A,R24
            OUT   TCNT0,R3
            LDI   R24,5
            OUT   TCCR0B,R24
            RCALL Migni
m12:        RCALL Time
            RJMP  m12
