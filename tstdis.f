S" ~iva/AVR/asmAVR.f" INCLUDED \ ассемблер, дизассемблер и другое

\ 0x 920A CONSTANT device \ Процессор ATmega48PA 
 0x 9109 CONSTANT device \ Процессор ATtn26
S" ~iva/AVR/selectAVR.f" INCLUDED \ набор команд для данного микроконтроллера
DECIMAL
RAM[ 1 take bt ]RAM
code AAA
\    in r,rH
    in r,bt
    out bt,r
    tst r
    add r,rh
\    in r,PORTB
\    ret 
    c;
hex
aaa val?    
