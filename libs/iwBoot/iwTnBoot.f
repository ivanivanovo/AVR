\ работа с i-wire BootLoader

finger constant StartIwBoot \ маркер начала библиотеки загрузчика

S" emIwDrive.f" INCLUDED \ подключение и настройка драйвера i-wire 
[NOT?] sizeSgPac [IF] S" iwcmd.f" INCLUDED [THEN] \ константы пакетов
S" eeprom.f"   INCLUDED \ работа с EEPROM

BitsIn ii ( aka cmd.#)
    4 #BitIs memF \ флаг назначение памяти 1-flash, 0-e2
    5 #BitIs memW \ флаг записи 
    6 #BitIs memD \ флаг разностных данных 
    7 #BitIs fRST \ флаг перезагрузки 

code prgWad> (  -- ) \ пыж прогамматора
    ldi r,2 ldiW Y,iwFifOut rcall WtakeBuf
    if_nt
        \ константа
        ldiW R,prgWad  st y+,rH st y+,r
        ldiW Y,iwFifOut rcall WendBufP  \ передвинуть индекс записи 
        _/ fiwTx \ отправить пакет
    then
    ret c; \ prgWad> val?
finger    prgWad>  - . .( <==== пыж прогамматора) CR


finger CONSTANT LocateNRWW \ маркер начала NRWW

BitsIn r0 ( aka SPMCSR)
<bits SPMEN bits> 7 AND #BitIs rSPMEN

code do_SPM ( r=action Z=addr r0:r1=data -- r=action Z=addr r0:r1=x) 
    \ прерывания должны быть уже запрещены!!!
    \ выполнить инструкцию SPM
        mov SPMCSR,r  SPM
        begin mov r0,SPMCSR wait_nb rSPMEN 
    ret c; \ do_SPM val?

code prgFlash ( Z=adr Y->data rH=#' ii=cmd.# --rH=0 Z=adr+ Y=+) \ команда и данные для flash
    \ положить данные из пакета в буфер записи страницы
    cli
    lsr rH \ запись идет парами байт
    if  for
            ld r0,Y+  ld r1,Y+
            if_b memD \ если пришли разностные данные 
                lpm r,Z+ eor r0,r \ обратить их
                lpm r,Z  eor r1,r
                sbiw Z,1
            then
            ldi r,{b SPMEN }  rcall do_SPM \ записать во временный буфер
            adiw Z,2
        next rH
        sbiw Z,2 \ вернуть адрес в страницу
    then 
    if_b memW 
        ldi r,{b PGERS SPMEN } rcall do_SPM \ очистить страницу
        ldi r,{b PGWRT SPMEN } rcall do_SPM \ записать страницу
    then
    sei
    goto prgWad> c; \ prgFlash val?
    
code prgE2 ( Z=adr Y->data rH=[0..12] ii=cmd.# --) \ команда и данные для EEPROM
    skip_b memW ret
    begin tst rH  while
        ld r0,y+ rcall e2SPM 
        adiw z,1  dec rH
    repeat    
    goto prgWad> c;

code BootPac ( -- ) \ обработка пакетов программатора
    rcall GetPac
    if_nt
        ld r,y \ получить размер пакета
        ldd rH,y+1 \ получить семафор
        cpi rH,prgCMD01
        if=
            ldd rH,y+2 andi rH,0xF \ #
            sub r,rH \ r=j-#
            cpi r,3 \ проверить размер пакета
            if= ldd ii,y+2 \ cmd.#
                cpi rH,3
                if>= \ есть данные
                    adiw Y,3
                    \ получить адрес
                    ld zL,y+  ld zH,y+  
                    ld r0,y+  [FOUND?] RAMPZ [IF]  mov RAMPZ,r0 [THEN]
                    subi rH,3 \ остальное - данные
                    if_b memF 
                        rcall prgFlash 
                    else 
                        rcall prgE2 
                    then
                then
                skip_nb fRST goto 0 \ мягкий сброс
            then
        then
        goto skipPac
    then
    ret c;

\ ============ инициализация! ============================
BitsIn r ( aka MCUSR)
    3 #BitIs rWDRF
code BootLoader 
    \ инициализация регистровых констант
    rcall iwIni \ инициализировать i-wire
    mov r,MCUSR
    if_b rWDRF 
        \ прибить собаку
        out MCUSR,(0) 
        ldi r,{b WDE WDCE } mov WDTCSR,r mov WDTCSR,(0) 
    then 

\ ldiW Y,iwFifOut 
\     \ константа
\     ldi r,2 std y+3,r
\     ldi r,0xEA std y+4,r
\     ldi r,0x9B std y+5,r
\     ldi r,0x3 std y+2,r
\     _/ fiwTx \ отправить пакет [EA9B]

    rcall prgWad> \ показать готовность к приему команд
    sei
    \ цикл ожидания команд
    begin
        skip_nb fiwRx rcall BootPac  
        skip_nb fiwTx rcall iwTransmitter
    again
    c;  \ BootLoader val?
0  VECTOR> BootLoader

finger CONSTANT EndIwBoot
SEG @ @ CONSTANT VEC>BOOTLOADER \ получить образ первых 4-х байтов

SzCntrl \ проверка НЕперелета конца памяти

finger LocateNRWW - . .( <==== размер NRWW) cr


