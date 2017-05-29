DECIMAL
CR
\ ======== система команд микропроцессора ======================================
[FOUND?] WARNING [IF] WARNING OFF [THEN]
FALSE VALUE LowFirstRW \ младший байт читается И записывается первым
\ этот флаг TRUE для xMega
0 CONSTANT ISPprog
1 CONSTANT PDIprog
2 CONSTANT TPIprog
ISPprog VALUE ProgInterface \ интерфейс программирования

: ProgInterfaceS ( -- addr u) \ выдать строку с именем интерфейса программирования
    ProgInterface ISPprog = IF  S" ISP" ELSE
    ProgInterface PDIprog = IF  S" PDI" ELSE
    ProgInterface TPIprog = IF  S" TPI" ELSE
    TRUE ABORT" Неизвестный интерфейс программирования."
    THEN THEN THEN
    ;

[FOUND?] device 
S" ~iva/AVR/chips/" >S \ где искать файлы описания микроконтроллеров, ниже добавим нужный файл
<LABELS
    [IF] \ выбор описания микроконтроллера по его сигнатуре 
         \ подключаемый файл содержит стандартные имена регистров, портов и битов, 
         \ а так же набор команд специфичный для выбранного микроконтроллера. 
        device 0x 9006 = [IF]   .( Процессор ATtiny15 )  S" tn15.ff"    +>S [THEN]
        device 0x 9307 = [IF]   .( Процессор ATmega8 )   S" m8.ff"      +>S [THEN]
        device 0x 9109 = [IF]   .( Процессор ATtiny26 )  S" tn26.ff"    +>S [THEN]
        device 0x 910C = [IF]   .( Процессор ATtiny261 ) S" tn261.ff"   +>S [THEN]
\        device 0x 910A = [IF]   .( Процессор ATtiny2313) S" tn2313.ff"  +>S [THEN]
        device 0x 910A = [IF]   .( Процессор ATtiny2313A) S" tn2313A.ff"  +>S [THEN]
        device 0x 920D = [IF]   .( Процессор ATtiny4313) S" tn4313.ff"  +>S [THEN]
        device 0x 9205 = [IF]   .( Процессор ATmega48)   S" m48.ff"     +>S [THEN]
        device 0x 920A = [IF]   .( Процессор ATmega48P)  S" m48pa.ff"   +>S [THEN]
        device 0x 930F = [IF]   .( Процессор ATmega88P)  S" m88pa.ff"   +>S [THEN]
        device 0x 940B = [IF]   .( Процессор ATmega168PA)  S" m168pa.ff"   +>S [THEN]
        device 0x 9406 = [IF]   .( Процессор ATmega168A)  S" m168a.ff"  +>S [THEN]
        device 0x 9514 = [IF]   .( Процессор ATmega328)  S" m328.ff"    +>S [THEN]
        device 0x 9108 = [IF]   .( Процессор ATtiny25)   S" tn25.ff"    +>S [THEN]
        device 0x 910B = [IF]   .( Процессор ATtiny24)   S" tn24.ff"    +>S [THEN]
        device 0x 9206 = [IF]   .( Процессор ATtiny45)   S" tn45.ff"    +>S [THEN]
        device 0x 9207 = [IF]   .( Процессор ATtiny44)   S" tn44.ff"    +>S [THEN]
        device 0x 9215 = [IF]   .( Процессор ATtiny441)  S" tn441.ff"    +>S [THEN]
        device 0x 930B = [IF]   .( Процессор ATtiny85)   S" tn85.ff"    +>S [THEN]
        device 0x 930C = [IF]   .( Процессор ATtiny84)   S" tn84.ff"    +>S [THEN]
        device 0x 9315 = [IF]   .( Процессор ATtiny841)  S" tn841.ff"    +>S [THEN]
        device 0x 9007 = [IF]   .( Процессор ATtiny13 )  S" tn13.ff"    +>S [THEN]
        device 0x 9843 = [IF]   .( Процессор ATxMega256A3BU )  S" x256A3BU.ff"    +>S  PDIprog TO ProgInterface [THEN]
        device 0x 9541 = [IF]   .( Процессор ATxMega32A4U )  S" x32A4U.ff"    +>S  PDIprog TO ProgInterface [THEN]
        device 0x 9441 = [IF]   .( Процессор ATxMega16A4U )  S" x16A4U.ff"    +>S  PDIprog TO ProgInterface [THEN]
    [ELSE] .( Процессор AVR не определён.) CR 
            S" ../AVR_instructions.set" +>S 
    [THEN] 

0 EMIT>S S@  INCLUDED S>DROP \ добавляем ноль в конец, загрузим файл
LABELS> CR

[FOUND?] WARNING [IF] WARNING ON [THEN]
<DASSM
    :NONAME ( -- ) \ очистка векторов прерываний
        0 ORG \ finger!
        BEGIN   
        \ места векторов прерывания в ROM заполняются командой RETI
        \ потом их можно будет заменить переходом на реальный адрес
            RETI  0 coder
            finger ROM_FREE =
        UNTIL 
        ; EXECUTE 
DASSM>

 S" ~iva/AVR/bitsAVR.f" INCLUDED  \ подключить битовые слова
 S" ~iva/AVR/fuses.f"   INCLUDED  \ для работы с фузами и локами
 S" ~iva/AVR/sborAVR.f" INCLUDED  \ подключить сборные слова
\ S" ~iva/AVR/USBprog.f" INCLUDED  \ подключить программатор (старая ветка)
 S" ~iva/AVR/programmers.f" INCLUDED  \ подключить программаторы

\ установить указатель на начало SRAM, если оно есть
RAMEND 0 > [IF] RAM[ SRAM_START ORG ]RAM [THEN] 
VOCABULARY PROJECT \ словарь проекта
ALSO PROJECT DEFINITIONS

