\ работа с EEPROM
\ 
finger CONSTANT StartEeprom

code e2SPM ( c  ADDR -- x  ADDR ) \ запись в EPROM
     \      r0  Z      r0  Z 
     begin wait_nb eepe   \ ждать готовности
[FOUND?] eearH  [IF] out eearH,Zh  [THEN] \ установка адреса   
[FOUND?] eearL  [IF] out eearL,zL  [ELSE] out eear,zL [THEN] \ установка адреса   
     out eedr,r0   \ установка  байта
     mov r0, SREG cli \ запретить прерывания
        set_b  eempe   set_b  eepe \ запись
     mov SREG,r0  \ вернуть как было
     ret c; \ e2SPM val?

code e2LPM ( ADDR -- ADDR  c)  \ загрузка из EPROM
     \       Z       Z    r0 
     begin wait_nb eepe   \ ждать готовности
[FOUND?] eearH  [IF] out eearH,Zh  [THEN] \ установка адреса   
[FOUND?] eearL  [IF] out eearL,zL  [ELSE] out eear,zL [THEN] \ установка адреса   
     set_b eere
     in  r0,eedr
     ret c; \ e2LPM val?

code RAM2EE ( X=AddrRam Z=AddrE2 r=n --) \ 
\ скопировать n байт из RAM в EEPROM
\ портит r0
    for ld r0,x+
        rcall e2SPM adiw Z,1
    next r 
    ret c;

code EE2RAM ( Z=AddrE2 X=AddrRam r=n --)
\ скопировать n байт из EEPROM в RAM 
\ портит r0
    for 
        rcall e2LPM st x+,r0   adiw Z,1
    next r
    ret c;

finger StartEeprom - . .( <==== размер eeprom) CR

