\ 1100 CONSTANT BootSize
1100 CONSTANT BootSize

\ ==================== Guard =========================================================
: FLASHsize ( -- u ) \ размер памяти в байтах
    FLASHEND 1+ 2* ;
: MovCodeEnd 
    FLASHsize BootSize - \ перенос кода в конец памяти программ
    PAGESIZE 2* 1- INVERT AND \ на страничную границу
    \ добираемся до целевого адреса "своим ходом", попутно очищая пропущенную память
    finger - 0 DO 0xFF C>SEG LOOP \ забитие кодом "NOP"
    ;
: SzCntrl ( --) \ контроль размера
    finger 2/ FLASHEND 1+ >  ABORT" Размер кода выходит за пределы flash." 
    ; 
\ ==================== либы ==========================================================
FUSE{ SELFPRGEN }=0 \ разрешить самопрограммирование
\ finger
\     MovCodeEnd
    S" iwTnBoot.f" INCLUDED
\ org


code SetProgMode ( --) \ переход в режим программирования
    \ перезаписать нулевую страницу ..
    \ переместив стартовый вектор на BOOTLOADER
    cli \ запретить прерывания
    ldi r,{b SPMEN } 
    clrW Z
    ldiW Y,VEC>BOOTLOADER (LW) movW r0,Y  rcall do_SPM  
    adiw Z,2
    ldiW Y,VEC>BOOTLOADER (HW) movW r0,Y  rcall do_SPM 
    ldi rH,PAGESIZE 2 -
    for \ скопировать в буфер остальное
        adiw Z,2
        lpm r0,Z+ lpm r1,Z  sbiw z,1 
        rcall do_SPM   
    next rH
    ldi ii,{b memW memF } rcall prgFlash
    c; \ SetProgMode hex[ val? ]hex
code HardRST \ аппаратный сброс
    \ оживить собаку
    ldi r,{b WDE } mov WDTCSR,r
    \ зациклиться до гавка
    begin again 
    c; \ HardRST val?
finger SetProgMode - . .( <==== размер загрузчика theBoot) CR

\ =============== система программирования ===================================
LOCK[ labels @ label-value @ 8 / 1+ ]LOCK  CONSTANT #LOCKs \ количество байт LOCK
FUSE[ labels @ label-value @ 8 / 1+ ]FUSE  CONSTANT #FUSEs \ количество байт FUSE

PAGESIZE 2* CONSTANT PAGESIZEb \ размер страницы в байтах
PAGESIZEb 1- INVERT CONSTANT PgSzMask \ страничная маска 

\ структура для сборки пакета программирования
0
1 -- prgS       \ семафор программирования
1 -- CMD.#      \ флаги и количество данных
1 -- ZLpoint    \ адрес записи младший байт
1 -- ZHpoint    \ адрес записи старший байт
1 -- ZEpoint    \ адрес записи дополнительный старший байт
2 CELLS -- Wdat \ 8 байт данных
CONSTANT StructPrg

CREATE (prgPack) StructPrg ALLOT

#def #EraseChip EraseChip 
#def #Flash!    Flash!
#def #PowerDown PowerDown
#def #PrgEn ' ProgEn EXECUTE CATCH

: BootLoader! \ прошить только бутлоадер
    chip: 
    SEG @ @ \ получить текущий стартовый вектор
    VEC>BOOTLOADER SEG @ ! \ установить стартовый вектор на загрузчика
    postpone #EraseChip 
    \ запись области векторов
    SEG @    TO FlashSRCaddr
    ROM_FREE TO FlashNumWrite
    0        TO FlashStartAddr
    postpone #Flash!
    SEG @ ! \ востановить текущий стартовый вектор

    \ запись загрузчика
    StartIwBoot SEG @ +     TO FlashSRCaddr
    EndIwBoot StartIwBoot - TO FlashNumWrite
    StartIwBoot             TO FlashStartAddr
    postpone #Flash!
    FlashNumWrite . ." <==== размер загрузчика" cr
    postpone #PowerDown
    ;

: Boot>. ( adr u --) \ отправка пакета
    OVER + SWAP DO I C@ HEX[ 2 .0R ]HEX SPACE LOOP CR 
    ;
DEFER Boot> ( adr u --) \ отправка пакета

{b memF      }  CONSTANT cmdFload    \ константа загрузки 8 байт данных в буфер
{b memW memF }  CONSTANT cmdFpgWrite \ команда записи страницы X
{b fRST      }  CONSTANT CMDrst      \ команда сброса программатора

: prgSem! ( --) \ положить в пакет семафор программатора
    prgCMD01 (prgPack) prgS C!
    ;
: prgCMD! ( cmd.# --) \ положить в пакет команду программатора
    (prgPack) CMD.# C!
    ;

: pgFloadPAC ( val cmd.# --) \  пакет с данными
    prgSem!  prgCMD! \ команда загрузки 8 байт данных в буфер
    \ данные (val)
    DUP (prgPack) ZLpoint !
    SEG @ + ( addr_val)
    DUP    @ (prgPack) Wdat !
    CELL + @ (prgPack) Wdat CELL + !
    (prgPAck) 13 Boot>  \ отправить пакет
    ;
\ : pgFwritePAC ( val --) \ пакет для записи прогруженной старницы
\     prgSem! cmdFpgWrite prgCMD! \ команда записи страницы 
\     (prgPack) ZLpoint ! \ адрес страницы
\     (prgPAck) 5 Boot>  \ отправить пакет      
\     ;

: prgRstPAC ( --) \ пакет сброса программатора
    prgSem! CMDrst prgCMD! \ команда сброса программатора
    (prgPack) 2 Boot> \ отправить пакет
    ;

VARIABLE fprgWad \ флаг получения пыжа программатора
fprgWad OFF

: PageAlign- ( val -- val'-) \ выровнять адрес на начало текущей страницы
    PgSzMask AND
    ;
: PageAlign+ ( val -- val'+) \ выровнять адрес на начало следующей страницы
    PageAlign- PAGESIZEb +
    ;
: PageBoot! ( # -- ) \ загрузить страницу # (0+)
    PAGESIZEb * \ v объектный адрес кода
    PAGESIZEb 8 / 0
    ?DO \ v' грузить страницу пакетами
        DUP I 8 * + \ v' v"
        I 7 = IF cmdFpgWrite ELSE cmdFload THEN 11 + \ последний с флагом записи страницы
        pgFloadPAC \  пакет с данными
    LOOP
    \ начальный адрес записанной страницы 
    0= IF 
        \ сброс чипа
        fprgWad ON \ что-б не ждал пыжика
        prgRstPAC \ команда сброса программатора
        CR ." --RESET--"  
    THEN
    ;

: Boot! ( start_val u --) \ загрузить прошивку через iwBootloader
    fprgWad OFF \ что-б ждал пыжика
    OVER PAGESIZEb / -ROT \ номер стартовой страницы
    + DUP PageAlign+  StartIwBoot > ABORT" Наезд на код загрузчика!!!"
    PAGESIZEb / \ номер последней страницы
    ." bootFlash:[" OVER PAGESIZEb * HEX[ 4 .0R ." .." DUP 1+ PAGESIZEb * 1- 4 .0R ." ]" ]HEX CR
    \ startPg  endPg
    DO \ запись идет от последней страницы к начальной 
        I  PageBoot!
    -1 +LOOP
    CR ." Запись завершена." 
    ;

: WaitPrgWad ( --) \ ждать пыжика от программируемого чипа
    getMs \ засечь время
    begin \ контроль времени ожидания
        getMs OVER 200 + <
    while
        fprgWad @ \ проверить получение
        until
        fprgWad OFF  \ погасить его
        ." ." \ показать получение
    else TRUE ABORT" Нет ответа!"
        then DROP
    ;


