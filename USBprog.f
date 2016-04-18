
C" ASCIIZ>>" FIND  NIP 0= [IF] S" ~iva/AVR/toolbox.f" INCLUDED [THEN]
DECIMAL

S" ~iva/AVR/USBtiny.f" INCLUDED
DECIMAL
: echo ( -- )  \ проверочное эхо, вернёт в буфере свои параметры 
    \ rbuf[C0 00  01 00   02 00  00 08]
    USBTINY_ECHO   1       2  ( sizebuf)  usb_control ;
: powerdown ( ) \ освободить
     USBTINY_powerDOWN 0 0 usb_control DROP 
     ;
: powerup ( sck reset -- )
     USBTINY_powerUP  -ROT  usb_control DROP 
     ;   
: :( ( --) \ завершить работу с программатором
    CR ." :(" CR powerdown closeUsbTiny QUIT 
    ;
: :[ ( adr u -- ) \ завершить работу с программатором и сказать почему
    TYPE :( 
    ;        
: USB>SPI ( b1 b2 b3 b4 -- x ) \ передать SPI-команду через USB
    \ bReq b2b1 b4b3
    8 LSHIFT OR -ROT \ b4b3 b1 b2 
    8 LSHIFT OR SWAP \  b2b1 b4b3
    USBTINY_SPI -ROT \ bReq b2b1 b4b3
    usb_control
    ;

: tryProg ( sck -- f ) \ попытка ввести чип в режим программирования
    RESET_LOW powerup 
    20 PAUSE
    \ Programming Enable  -- 0xAC 0x53 0x00 0x00
    0xAC 0x53 0 0  USB>SPI DROP 
    rbuf 2+ C@ 0x53 = 
     ;
: ProgEn ( -- ) \ включить режим программирования
    SCK_MIN
    BEGIN
        ." SCK=" DUP . CR
        DUP
        tryProg 0=  
    WHILE
        DUP SCK_MAX < 
        IF 2* SCK_MAX  MIN  DUP RESET_HIGH powerup  20 PAUSE
        ELSE DROP TRUE THROW \ S" Не удалость включить режим программирования." :[ 
        THEN
    REPEAT
    DROP
    20 PAUSE
    ;

DEFER M_READ    \ чтение из памяти
DEFER M_WRITE   \ запись в память
DEFER PageM!    \ запись в станичную память    
DEFER ByteM!    \ запись байта в память

0  VALUE EndMemory  \ последний адрес памяти
0  VALUE SizePage   \ размер страницы в байтах
10 VALUE TwP        \ таймаут для записи страницы
0  VALUE AsWord?    \ индикатор доступа по словам(по парам байт)

: memo-read ( adr -- n) \ читает память с adr, возвращает число принятых байт
    M_READ 0 ROT usb_control 
    ;
    
: BUSY? ( -- f) \ 0 -готово, 1 -занят
    \ Poll RDY/BSY ---- 0xF0 0x00 0x00 byte out
    0xF0 0 0 0 USB>SPI
    4 = IF rbuf 3 + C@ 1 AND
        ELSE S" Не удалось проверить занятось." :[ 
        THEN 
    ;
: SignatureByte ( # -- byte )
    \ Read Signature Byte ---- 0x30 0x00 0000000aa    byte out
    \ USBTINY_SPI 0x30 ROT usb_control 
    0x30 0x00 ROT 0 USB>SPI
    4 = IF rbuf 3 + C@
        ELSE S" Не удалось прочитать байт сигнатуры." :[ THEN 
    ;
: Signature@ ( -- u)
    0 SignatureByte DUP 0x1E =
    IF DROP 1 SignatureByte 8 LSHIFT 2 SignatureByte OR
    ELSE .HEX S" Чип не от ATMEL." :[ THEN
    ;
: CalibrationByte@ ( # -- u)
    \ Read Calibration Byte ---- 0x38 0x00 0x0№ byte out
    0x38 0x00 ROT 0 USB>SPI
    4 = IF rbuf 3 + C@
        ELSE S" Не удалось прочитать калибровочный байт." :[ THEN 
    ;
: LockBits@ (  -- u)
    \ Read Lock bits ---- 0x58 0x00 0x00 byte out
    0x58 0 0 0 USB>SPI
    4 = IF rbuf 3 + C@
        ELSE S" Не удалось прочитать блокировочные биты." :[ THEN 
    ;
: LockBits! ( u 0 -- )
    DROP
    ." LOCK MODE:" DUP INVERT  .
    \ Write Lock bits  0xAC 0xE0 0x00 byte in
    0xAC 0xE0 ROT BYTE-SPLIT SWAP USB>SPI
    4 <> IF  S" Не удалось записать блокировочные биты." :[ THEN 
    BEGIN BUSY? WHILE ."  BUSY!. "   REPEAT
    CR
    ;
: #Fuse@ ( # -- u) \ прочитать байт №
    DUP 0 = 
    IF DROP 0x50 0  
    ELSE DUP 1 =
         IF DROP 0x58 8
         ELSE DUP 2 = 
            IF DROP 0x50 8
            ELSE . S" <-Неверный номер #Fuse@." :[
            THEN
         THEN
    THEN
    0 0 USB>SPI
    4 = IF rbuf 3 + C@  
        ELSE S" Не удалось прочитать фузы." :[ 
        THEN 
    ;
: #Fuse! ( u # -- ) \ записать байт №
\ .hex .hex ." <=Fuse не пишутся!!!" cr exit
    \ Write Fuse bits ---- 0xAC 0xA0 0x00  byte in
    \ Write Fuse High bits ----0xAC 0xA8 0x00 byte in
    \ Write Extended Fuse Bits ---- 0xAC 0xA4 0x00 byte in
    2DUP #Fuse@ <>
    IF \ не равны
       ." FUSE:  Изменены." cr
        DUP 0 = 
        IF DROP 0xA0  
        ELSE DUP 1 =
             IF DROP 0xA8
             ELSE DUP 2 = 
                IF DROP 0xA4
                ELSE . S" <-Неверный номер #Fuse!" :[
                THEN
             THEN
        THEN
        0xAC SWAP ROT 0 SWAP USB>SPI
        4 <> IF S" Не удалось записать фузы." :[ 
            THEN 
    ELSE 2DROP \  ." НЕ пишу фузы" cr
    THEN
    BEGIN BUSY? WHILE ."  BUSY!. "   REPEAT
    ;
: EraseChip ( )
    \ Chip Erase (Program Memory/EEPROM) ---- 0xAC 0x80 0x00 0x00
    0xAC 0x80 0 0 USB>SPI
    4 <> IF  S" Не удалось очистить чип." :[ THEN 
    C" TwdErase" FIND \ таймаут определен?
    IF EXECUTE  ELSE DROP 20 THEN 
    PAUSE ." Чип очищен." CR
    ;
: DUMPchip ( adr u -- ) \ распечатать дамп из памяти чипа
    HEX[ 0 -ROT \ счетчик строк, убрать
        OVER DUP memo-read 1- OVER + SWAP \ заполнить буфер данными из чипа 
        2SWAP OVER + SWAP
        DO ( stline к н ) \ 
            \ в начале строки напечатать адрес
            \ именно из-за этого адреса нельзя воспользоваться стандартным dump
            ROT DUP 0= IF I 4 .0R 2 SPACES THEN -ROT
            2DUP I -ROT BETH 0= \ нужные данные есть в буфере?
            IF DROP 1+ DUP memo-read 1- OVER + SWAP THEN \ нет - перезаполнить
            I OVER - rbuf + C@ 2 .0R SPACE \ напечатать байт
            \ проверить счетчик символов в строке
            ROT 1+ DUP 16 = 
            IF DROP 
                2 SPACES 
                \ текстовое изображение строки
                I OVER - 15 - rbuf + 16  
                OVER + SWAP 
                DO I C@  
                    \ печатать только отображаемые символы
                    DUP BL < IF  DROP [CHAR] . THEN 
                   EMIT 
                LOOP 
               0 CR  \ завершить текущую строку, счет=0, перейти на следующую
            THEN -ROT \ убрать счётчик
        LOOP DROP 2DROP
    ]HEX
    ;

: PageFlash! ( adrB -- ) \ записать страницу Programm Memory
    \ Write Program Memory Page ---- 0x4C adrMSB adrLSB 0x00
    2/ \ адрес байта в адрес слова
    byte-split SWAP 0x4C -ROT 0 USB>SPI
    4 <> IF S" Не удалось записать страницу в Programm Memory." :[ 
         THEN 
    ;
: PageEPROM! ( adr -- ) \ записать страницу EEPROM
    \ Write EEPROM Memory Page (page access) ---- 0xC2 0x00 00aaaa00 0x00
    byte-split SWAP 0xC2 -ROT 0 USB>SPI
    4 <> IF S" Не удалось записать страницу в EEPROM." :[ 
         THEN 
      ;
: ByteFlash! ( byte adr -- ) \ записать байт в Programm Memory
    DUP 1 AND 3 LSHIFT 0x40 OR -ROT
    \ Load Program Memory Page, Low byte      0x40 adrMSB   adrLSB       byte 
    \ Load Program Memory Page, High byte     0x48 adrMSB   adrLSB       byte 
    1 RSHIFT byte-split SWAP ROT USB>SPI
    4 <> IF S" Не удалось записать байт в Programm Memory." :[ 
         THEN 
    ;
: ByteEPROM! ( byte adr -- ) \ записать байт в EEPROM
    \ Write EEPROM Memory ---- 0xC0 adrMSB adrLSB byte in
    0xC0 -ROT byte-split SWAP ROT  (  .s cr)    USB>SPI  
    4 <> IF S" Не удалось записать байт в EEPROM." :[ 
         THEN 
    ;
: Buf! ( adr buf sbuf  -- n) \ записать буфер
    \ adr - по какому адресу писать, buf - откуда и скока (sbuf) взять
    size-rbuf MIN \ не более размера буфера передачи
    >R 2>R 
    M_WRITE TwP 2R> R> WMEM-USB
    ;

: Page! ( a u adrW -- n) \ записать страницу
    DUP >R -ROT
    SizePage MIN      \ не более станицы  
    R@ SizePage MOD - \ или ещё меньше, если адрес не совпадает с началом страницы
    BEGIN ( adrW' a' u')
        DUP 0 >
    WHILE
        3DUP Buf! \ отправить в чип ( adrW a u n)
        >R
        ROT R@ + ROT R@ + ROT R> - \ adrW'=adrW+n a'=a+n u'=u-n
    REPEAT 2DROP  \ adrW'
    R@ PageM!  
    R> - \ вычисление количества записаных байт
    BEGIN BUSY? WHILE ."  BUSY!. "   REPEAT
    ;
: Memo! ( buf sizebuf adrW -- ) \ записать содержимое буфера в память
    SizePage \ есть ли станицы?
    IF \ пишем по страницам
        BEGIN ( a u adrW )
            OVER 0 >
        WHILE ( a u adrW ) 
            3DUP Page! \ a u adrW n
            >R
            ROT R@ + ROT R@ - ROT R> +  \ сменить a'=a+n u'=u-n adrW'=adrW+n
        REPEAT DROP 2DROP 
    ELSE \ пишем по байтам
        \ adr u adrW
        -ROT OVER + SWAP
        DO  \ adrW
            I C@ OVER  
            ByteM! 1+ \ записать байт, инкремент адреса
            TwP PAUSE   \ дать время на запись байта
        LOOP DROP
    THEN
    ;
: Verify ( adr u adrf -- f ) \ 0 - неравны 
\ сравнить участок памяти с записанным в чипе
    BEGIN
        OVER 
    WHILE
        2DUP memo-read DUP 1 < IF DROP 2DROP 2DROP FALSE EXIT THEN 
        MIN
        >R >R OVER R> SWAP rBuf  R@ TUCK  \ adr u adrf adr n rbuf n  R: n
        COMPARE IF R> 2DROP 2DROP FALSE EXIT THEN 
        ROT R@ + ROT R@ - ROT R> + 
    REPEAT 2DROP DROP
    TRUE
    ;
: WriteChip ( adr u adr1  -- ) \ записать u байт с адреса adr в adr1 Memory
    C" device" FIND
    IF EXECUTE Signature@  <> \ проверить сигнатуру
        IF S" Сигнатура подключенного чипа не совпадает с целевой."     :[ THEN
    ELSE DROP S" Сигнатура целевого чипа не задана, не могу проверить." :[ 
    THEN
    \ adr u adr1 
    3DUP Verify 0= 
    IF  \ EraseChip 
        3DUP Memo! \ записать
        Verify \ проверить
        0= ABORT" Верификация не удалась."
        ." Запись и верификация прошли успешно." CR
       \ IF ." Запись и верификация прошли успешно." CR ELSE S" Сбой записи." :[ THEN 
    ELSE  2DROP DROP ." Верификация прошла успешно." CR 
    THEN
    ;


: Flash_ ( ) \ настройка на работу с програмной памятью
    TRUE TO AsWord? \ запись только по словами
    C" FLASHEND"  FIND
    IF EXECUTE 2* 1+ ELSE DROP 0 THEN TO EndMemory
    C" PAGESIZE" FIND \ страничная память определена?
    IF EXECUTE 2* ELSE DROP 0 THEN TO SizePage
    C" TwdFlash" FIND \ таймаут определен?
    IF EXECUTE  ELSE DROP 10 THEN TO TwP
    ['] ByteFlash!          IS ByteM!
    ['] PageFlash!          IS PageM!
    ['] USBTINY_FLASH_WRITE IS M_WRITE
    ['] USBTINY_FLASH_READ  IS M_READ
    ;
: EPROM_ ( ) \ настройка на работу с энергонезависимой памятью
    FALSE TO AsWord? \ запись возможна отдельными байтами
    C" E2END"  FIND
    IF EXECUTE  ELSE DROP 0 THEN TO EndMemory
    C" EEPAGESIZE" FIND \ страничная память определена?
    IF EXECUTE  ELSE DROP 0 THEN TO SizePage
    C" TwdEPROM" FIND \ таймаут определен?
    IF EXECUTE  ELSE DROP 10 THEN TO TwP
    ['] ByteEPROM!          IS ByteM!
    ['] PageEPROM!          IS PageM!
    ['] USBTINY_EEPROM_WRITE IS M_WRITE
    ['] USBTINY_EEPROM_READ  IS M_READ
    ;

\eof
\ идея реализации макроса

#def if=   over = if
#def exif  EXIT THEN

: AA ( u -- )
    dup 0 < over 3 > or if . ." - а нужно от нуля до трёх." exif
    3 if= . ." -три."   exif 
    2 if= . ." -два."   exif 
    1 if= . ." -один."  exif 
    0 if=  drop ." -ничего." exif 
    ;





