
\ минимальная реализация работы с USB для программатора USBTiny
\ iva 10.11.2010 --
\ iva 17.12.2014 --

\ ----------void    usb_control>             ( int req, int val, int index )
\ int   usb_in                  ( int req, int val, int index, byte_t* buf, int buflen, int umax )
\ int   usb_out                 ( int req, int val, int index, byte_t* buf, int buflen, int umax )

\ int   usbtiny_avr_op          ( *pgm, AVRPART* p, int op, byte_t res[4] )
\ ----------int     usbtiny_open            ( *pgm, char* name )
\ ----------void    usbtiny_close           ( *pgm )
\ void  usbtiny_set_chunk_size  ( int period )
\ int   usbtiny_set_sck_period  ( *pgm, double v )
\ ----------int     usbtiny_initialize      ( *pgm, AVRPART* p )
\ void  usbtiny_powerdown       ( *pgm )

\ int   usbtiny_cmd             ( *pgm, byte_t cmd[4], byte_t res[4] )

\ int   usbtiny_chip_erase      ( *pgm, AVRPART* p )
\ int   usbtiny_paged_load      ( *pgm, AVRPART* p, AVRMEM* m, int page_size, int n_bytes )
\ int   usbtiny_paged_write     ( *pgm, AVRPART* p, AVRMEM* m, int page_size, int n_bytes )
\ int   usbtiny_read_byte       ( *pgm, AVRPART* p, AVRMEM* m, ulong_t addr, byte_t* value )
\ int   usbtiny_write_byte      ( *pgm, AVRPART* p, AVRMEM* m, ulong_t addr, byte_t value )
\ 


MARKER ALLDROP \ для удаления нижеследующего

S" ~iva/AVR/ISProtocol.f" INCLUDED

64 TO size-rbuf        \ размер буфера
size-rbuf ALLOCATE THROW TO rBuf   \ буфер чтения


\ Flags to indicate how to set RESET on power up
0 CONSTANT RESET_LOW 
1 CONSTANT RESET_HIGH 

\ The SCK speed can be set by avrdude, to allow programming of slow-clocked parts
1   CONSTANT SCK_MIN        \ usec delay (target clock >= 4 MHz)
250 CONSTANT SCK_MAX        \ usec (target clock >= 16 KHz)
\ 10  CONSTANT SCK_DEFAULT    \ usec (target clock >= 0.4 MHz)

HEX 
\ определители UsbTiny
1781 CONSTANT UsbTinyVid  
0C9F CONSTANT UsbTinyPid 

DECIMAL
\ Коды запросов определённых для USBtiny
    \ общие запросы
    00 CONSTANT USBTINY_ECHO    \ echo test
    01 CONSTANT USBTINY_READ    \ read byte (wIndex:address)
    02 CONSTANT USBTINY_WRITE   \ write byte (wIndex:address, wValue:value)
    03 CONSTANT USBTINY_CLR     \ clear bit (wIndex:address, wValue:bitno)
    04 CONSTANT USBTINY_SET     \ set bit (wIndex:address, wValue:bitno)

    \ запросы программирования
    05 CONSTANT USBTINY_powerUP         \ apply power (wValue:SCK-period, wIndex:RESET)
    06 CONSTANT USBTINY_powerDOWN       \ remove power from chip
    07 CONSTANT USBTINY_SPI             \ issue SPI command (wValue:c1c0, wIndex:c3c2)
    08 CONSTANT USBTINY_POLL_BYTES      \ set poll bytes for write (wValue:p1p2)
    09 CONSTANT USBTINY_FLASH_READ      \ read flash (wIndex:address)
    10 CONSTANT USBTINY_FLASH_WRITE     \ write flash (wIndex:address, wValue:timeout)
    11 CONSTANT USBTINY_EEPROM_READ     \ read eeprom (wIndex:address)
    12 CONSTANT USBTINY_EEPROM_WRITE    \ write eeprom (wIndex:address, wValue:timeout)

    ' USBTINY_FLASH_READ     IS FLASH_READ
    ' USBTINY_FLASH_WRITE    IS FLASH_WRITE 
    ' USBTINY_EEPROM_READ    IS EEPROM_READ
    ' USBTINY_EEPROM_WRITE   IS EEPROM_WRITE


\ The default USB Timeout
40 TO USB_TIMEOUT    \ msec

: -->SPI ( b1 b2 b3 b4 -- x ) \ передать SPI-команду через USB
    \ bReq b2b1 b4b3
    8 LSHIFT OR -ROT \ b4b3 b1 b2 
    8 LSHIFT OR SWAP \  b2b1 b4b3
    USBTINY_SPI -ROT \ bReq b2b1 b4b3
    usb_control>
    ;

: tryProg ( sck -- f ) \ попытка ввести чип в режим программирования
    RESET_LOW powerup 
    20 PAUSE
    \ Programming Enable  -- 0xAC 0x53 0x00 0x00
    #Programming_Enable  -->SPI DROP 
    rbuf 2+ C@ 0x53 = 
     ;

\ ========= настроить систему программирования на использование данного программатора ===========

:NONAME  ( -- ) \ включить режим программирования
    SCK_MIN
    BEGIN
        DUP
        tryProg 0=  
    WHILE
        DUP SCK_MAX < 
        IF 2* SCK_MAX  MIN  DUP RESET_HIGH powerup  20 PAUSE
        ELSE  PowerDown THROW 
        THEN
    REPEAT
    ." SCK=" . 
    20 PAUSE
    ; 
IS ProgEn \ <================================================================

    
: BUSY? ( -- f) \ 0 -готово, 1 -занят
    \ Poll RDY/BSY ---- 0xF0 0x00 0x00 byte out
    #RDY/BSY -->SPI
    4 = IF rbuf 3 + C@ 1 AND
        ELSE S" Не удалось проверить занятось." :[ 
        THEN 
    ;
:NONAME ( # -- byte )
    \ Read Signature Byte ---- 0x30 0x00 0000000aa    byte out
    \ USBTINY_SPI 0x30 ROT usb_control 
    #Read_Signature_Byte -->SPI
    4 = IF rbuf 3 + C@
        ELSE S" Не удалось прочитать байт сигнатуры." :[ THEN 
    ;
IS  SignatureByte@ \ <======================================================   

:NONAME ( # -- u)
    \ Read Calibration Byte ---- 0x38 0x00 0x0№ byte out
    #Read_Calibration_Byte -->SPI
    4 = IF rbuf 3 + C@
        ELSE S" Не удалось прочитать калибровочный байт." :[ THEN 
    ;
IS CalibrationByte@  \ <====================================================

:NONAME (  -- u)
    \ Read Lock bits ---- 0x58 0x00 0x00 byte out
    #Read_Lock_bits -->SPI
    4 = IF rbuf 3 + C@
        ELSE S" Не удалось прочитать блокировочные биты." :[ THEN 
    ;
IS LockBits@ \ <============================================================

:NONAME ( u 0 -- )
    DROP
    ." LOCK MODE:" DUP INVERT 0xFF AND .
    \ Write Lock bits  0xAC 0xE0 0x00 byte in
    #Write_Lock_bits -->SPI
    4 <> IF  S" Не удалось записать блокировочные биты." :[ THEN 
    BEGIN BUSY? WHILE ."  BUSY!. "   REPEAT
    CR
    ;
IS LockBits! \ <============================================================

:NONAME ( # -- u) \ прочитать байт №
    DUP 0 = 
    IF DROP #Read_Fuse_bits
    ELSE DUP 1 =
         IF DROP #Read_Fuse_High_bits
         ELSE DUP 2 = 
            IF DROP #Read_Extended_Fuse_bits
            ELSE . S" <-Неверный номер #Fuse@." :[
            THEN
         THEN
    THEN
     -->SPI
    4 = IF rbuf 3 + C@  
        ELSE S" Не удалось прочитать фузы." :[ 
        THEN 
    ;
IS #Fuse@ \ <=============================================================

:NONAME ( u # -- ) \ записать байт №
\ .hex .hex ." <=Fuse не пишутся!!!" cr exit
    \ Write Fuse bits ---- 0xAC 0xA0 0x00  byte in
    \ Write Fuse High bits ----0xAC 0xA8 0x00 byte in
    \ Write Extended Fuse Bits ---- 0xAC 0xA4 0x00 byte in
    2DUP #Fuse@ <>
    IF \ не равны
        DUP 0 = 
        IF SWAP #Write_Fuse_bits          ELSE 
        DUP 1 =
        IF SWAP #Write_Fuse_High_bits     ELSE 
        DUP 2 = 
        IF SWAP #Write_Extended_Fuse_bits ELSE 
        . S" <-Неверный номер #Fuse!" :[
        THEN THEN THEN
        -->SPI
        4 <> IF S" Не удалось записать фузы." :[ 
             ELSE ." FUSE_" 1 .R  ." : изменен." cr
             THEN 
    ELSE 2DROP \  ." НЕ пишу фузы" cr
    THEN
    BEGIN BUSY? WHILE ."  BUSY!. "   REPEAT
    ;
IS #Fuse! \ <=============================================================

:NONAME ( )
    \ Chip Erase (Program Memory/EEPROM) ---- 0xAC 0x80 0x00 0x00
    #Chip_Erase -->SPI
    4 <> IF  S" Не удалось очистить чип." :[ THEN 
    C" TwdErase" FIND \ таймаут определен?
    IF EXECUTE  ELSE DROP 20 THEN 
    PAUSE ." Чип очищен." CR
    ;
IS EraseChip \ <============================================================

\ PageFlash!      IS PageM!
:NONAME ( adrB -- ) \ записать страницу Programm Memory
    \ Write Program Memory Page ---- 0x4C adrMSB adrLSB 0x00
    2/ \ адрес байта в адрес слова
    #Write_Program_Memory_Page -->SPI
    4 <> IF S" Не удалось записать страницу в Programm Memory." :[ 
         THEN 
    ;
IS PageFlash! \ <===========================================================

:NONAME ( adr -- ) \ записать страницу EEPROM
    \ Write EEPROM Memory Page (page access) ---- 0xC2 0x00 00aaaa00 0x00
    #Write_EEPROM_Memory_Page -->SPI
    4 <> IF S" Не удалось записать страницу в EEPROM." :[ 
         THEN 
      ;
IS PageEPROM! \ <===========================================================

:NONAME ( byte adr -- ) \ записать байт в Programm Memory
    DUP 1 AND 
    IF   \ Load Program Memory Page, High byte     0x48 adrMSB   adrLSB       byte 
        #Load_Program_Memory_Page,High_byte
    ELSE \ Load Program Memory Page, Low byte      0x40 adrMSB   adrLSB       byte 
        #Load_Program_Memory_Page,Low_byte
    THEN
    -->SPI
    4 <> IF S" Не удалось записать байт в Programm Memory." :[ 
         THEN 
    ;
IS ByteFlash! \ <===========================================================

:NONAME ( byte adr -- ) \ записать байт в EEPROM
    \ Write EEPROM Memory ---- 0xC0 adrMSB adrLSB byte in
    #Write_EEPROM_Memory -->SPI  
    4 <> IF S" Не удалось записать байт в EEPROM." :[ 
         THEN 
    ;
IS ByteEPROM! \ <===========================================================


: Buf!! ( adr buf sbuf  -- n) \ записать буфер
    \ adr - по какому адресу писать, buf - откуда и скока (sbuf) взять
    >R 2>R  
    hand EPwrite M_WRITE TwP  
        4 <( 2R> R@ USB_TIMEOUT )) libusb_control_transfer tickErr
    R> TUCK < ABORT" Ошибка записи."
    ;

: Buf! ( adr buf sbuf  -- n) \ записать буфер
    \ adr - по какому адресу писать, buf - откуда и скока (sbuf) взять
    size-rbuf MIN \ не более размера буфера передачи
    Buf!!
    ;

:NONAME ( a u adrW -- n) \ записать страницу
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
IS Page! \ <=================================================================

:NONAME ( adr u adrW -- ) \ записать побайтно
    \ adr-окуда u-скока adrW-куда
    -ROT OVER + SWAP
    DO  \ adrW
        I C@ OVER  
        ByteM! 1+ \ записать байт, инкремент адреса
        TwP PAUSE   \ дать время на запись байта
    LOOP DROP
    ; IS Byte!

:NONAME  ( ) \ освободить
     USBTINY_powerDOWN 0 0 usb_control> DROP 
     ; 
IS powerdown \ <=============================================================

:NONAME  ( sck reset -- )
     USBTINY_powerUP  -ROT  usb_control> DROP 
     ;
IS powerup \ <============================================================= 

:NONAME ( adr -- n) \ читает память с adr, возвращает число принятых байт
    M_READ 0 ROT usb_control> 
    ; 
IS Memo@ \ <=============================================================



\ :NONAME
\     cr ." Прошу пана: " 
\     HEX
\     \ ubuf COUNT dump SPACE UBuf c@ . cr
\     QUIT
\     ; IS BeforeProg


\ осуществить программирование
UsbTinyVid UsbTinyPid findUSBprog

EndedLoop <>
[IF]
  ALLDROP \ и забыть все это
[THEN] 


