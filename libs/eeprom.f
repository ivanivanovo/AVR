\ работа с EEPROM
\ 
finger CONSTANT StartEeprom

code e2SPM ( c  ADDR -- x  ADDR ) \ запись в EPROM
     \      r0  Z      r0  Z 
     begin wait_nb eepe   \ ждать готовности
[FOUND?] eearH [IF] out eearH,Zh  [THEN] out eearL,zL  \ установка адреса   
     out eedr,r0   \ установка  байта
     mov r0, SREG cli \ запретить прерывания
        set_b  eempe   set_b  eepe \ запись
     mov SREG,r0  \ восстановить как было
     ret c; \ e2SPM val?

code e2LPM ( ADDR -- ADDR  c)  \ загрузка из EPROM
     \       Z       Z    r0 
     begin wait_nb eepe   \ ждать готовности
[FOUND?] eearH  [IF] out eearH,Zh  [THEN] out eearL,zL  \ установка адреса   
     set_b eere
     in  r0,eedr
     ret c;

finger StartEeprom - . .( <==== размер eeprom) CR

