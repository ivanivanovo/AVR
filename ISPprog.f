
S" ~iva/AVR/ISProtocol.f" INCLUDED


: cmd>buf ( cmd1 cmd2 cmd3 cmd4 -- )
    >R >R >R c>buf R> c>buf R> c>buf R> c>buf
    ;

: signOn ( )
  clrbuf  
  CMD_SIGN_ON c>buf
  UBuf>
  Tred @  3 >
  IF UBuf 3 + Tred @ 3 - TYPE CR THEN
  ;


:NONAME ( ) \ ввод режима программирования
    clrbuf
    CMD_ENTER_PROGMODE_ISP c>buf
    200 DUP TO USB_TIMEOUT c>buf \ тамаут команды (ms)
    100 c>buf \ задержка на стабилизацию pin (ms)
     25 c>buf \ задержка на выполнение команды (ms)
     32 c>buf \ количество циклов синхронизации
      0 c>buf \ задержка между байтами (ms)
   0x53 c>buf \ проверочный байт, 0x53-AVR 0x69-AT89xx
      3 c>buf \ номер проверочного байта в ответе, 0-без проверки, 3-AVR, 4-AT89
      #Programming_Enable cmd>buf
      UBuf>
      ProgInterfaceS TYPE CR
    ; IS ProgEn \ <======================================================

:NONAME ( ) \ выход из режима программирования
    clrbuf
    CMD_LEAVE_PROGMODE_ISP  c>buf
    1 1 c>buf c>buf
    UBuf>
    ; IS PowerDown \ <======================================================

:NONAME ( ) \ очистка чипа
    clrbuf
    CMD_CHIP_ERASE_ISP c>buf
    C" TwdErase" FIND \ таймаут определен?
    IF EXECUTE  ELSE DROP 20 THEN c>buf 
    1 c>buf \ проверочный метод
    #Chip_Erase cmd>buf
    UBuf>
    ." Чип очищен." CR
    ; IS EraseChip \ <======================================================

:NONAME ( # -- byte )
    clrbuf
    CMD_READ_SIGNATURE_ISP c>buf
    4 c>buf
    #Read_Signature_Byte cmd>buf
    UBuf>
    UBuf 2 + c@
    ; IS  SignatureByte@ \ <======================================================

: LoadAddress ( addr --) \ указать начальный адрес для чтения или записи
\ ." LOAD_ADDRESS:  0x" DUP .HEX cr
    AsWord? IF 2/ THEN \ перевести адрес байта в адрес слова
    clrbuf
    CMD_LOAD_ADDRESS c>buf
    |4 c>buf c>buf c>buf c>buf
    UBuf>
    ;

FALSE VALUE WritePage? \ флаг готовности к записи страницы

: ModeByte ( -- ) \ составить байт режима программирования
    SizePage
    IF \ страничный доступ
        0x41 \ контроль по опросу RDY/BSY
        0x80 WritePage? AND OR 
    ELSE \ запись по словам или байтам
        2 \  контроль по времени
    THEN
    c>buf
    ;

: Buf! ( buf sbuf   -- n) \ записать буфер
\ cr .S ." <== Buf!!" cr
    \ buf - откуда и скока (sbuf) взять
    >R ( n)
    clrbuf
    M_WRITE \ команда записи куда-то
    R@ |2 c>buf c>buf \ размер данных
    ModeByte
    TwP c>buf
    SizePage IF PageM! ELSE ByteM! THEN
    UBuf Tred @ + R@ CMOVE R@ Tred +! \ положить данные в буфер передачи
\ shwBuf cr
    UBuf>
    R>
    ;



\ ========== FLASH ===================================
\ ['] ByteFlash!      IS ByteM!
\ ['] PageFlash!      IS PageM!
\ ['] FLASH_WRITE     IS M_WRITE
\ ['] FLASH_READ      IS M_READ

:NONAME ( )
    cmd0_Load_Program_Memory_Page   c>buf
    cmd0_Write_Program_Memory_Page  c>buf
    cmd0_Read_Program_Memory        c>buf
    0 0 c>buf c>buf
    ; DUP IS ByteFlash! IS PageFlash!

:NONAME ( -- ) 
    CMD_PROGRAM_FLASH_ISP c>buf
    ; IS FLASH_WRITE

:NONAME ( -- n) \ читает память с текущего адреса, возвращает число принятых байт
\ ." FLASH_READ" cr
    clrbuf
    CMD_READ_FLASH_ISP c>buf
    size-rBuf DUP |2 c>buf c>buf
    cmd0_Read_Program_Memory c>buf \ Read Program Memory, Low byte
    UBuf>  ( -- size-rBuf)
    ; IS FLASH_READ

\ ========== EPROM ===================================
\ ['] ByteEPROM!      IS ByteM!
\ ['] PageEPROM!      IS PageM!
\ ['] EEPROM_WRITE    IS M_WRITE
\ ['] EEPROM_READ     IS M_READ

\ DEFER EEPROM_WRITE   \ IS M_WRITE
:NONAME ( -- )
\ .S ." EEPROM_WRITE" CR
    CMD_PROGRAM_EEPROM_ISP c>buf
    ; IS EEPROM_WRITE

\ DEFER EEPROM_READ    \ IS M_READ
:NONAME ( -- n) \ читает память с текущего адреса, возвращает число принятых байт
\ ." EEPROM_READ" cr
    clrbuf
    CMD_READ_EEPROM_ISP c>buf
    size-rBuf DUP |2 c>buf c>buf
    cmd0_Read_EEPROM_Memory c>buf
    UBuf>  ( -- size-rBuf)
    ; IS EEPROM_READ
:NONAME ( )
\ .S ." PageEPROM!" CR
    cmd0_Load_EEPROM_Memory_Page    c>buf
    cmd0_Write_EEPROM_Memory_Page   c>buf
    cmd0_Read_EEPROM_Memory         c>buf
    0 0 c>buf c>buf
    ; IS PageEPROM!
:NONAME ( )
\ .S ." ByteEPROM!" CR
    cmd0_Write_EEPROM_Memory        c>buf
    0    c>buf
    0    c>buf
    0 0 c>buf c>buf
    ; IS ByteEPROM!

: chunk ( u - u') \ кусок для записи
    DUP size-rbuf > \ не более размера буфера передачи
    IF \ остаток для записи больше размера передачи
        DROP size-rbuf FALSE \ Не последний пакет
    ELSE \ остаток помещается в передачу
        TRUE \ последний пакет для записи
    THEN TO WritePage?
    ;

:NONAME ( a u adrW -- ) \ прогрузить и записать u байт
\ .S ." <Byte!" CR
   LoadAddress
    ( a u)
    BEGIN ( a' u')
        DUP 0 >
    WHILE
        2DUP chunk \  сколько будем писать за раз
        Buf! \ загрузить в буфер чипа ( a u n)
        >R SWAP R@ + SWAP R> - \  a'=a+n u'=u-n
    REPEAT 2DROP  \ 
\ .S ." >Byte!" CR
    ; IS Byte!    
:NONAME ( a u adrW -- n) \ прогрузить и записать страницу
\ .S ." Page!"
    SWAP SizePage MIN  SWAP \ не более станицы 
    OVER >R Byte! R>
    ; IS Page! \ <=================================================================

:NONAME ( adr -- n) \ читает память с adr, возвращает число принятых байт
\ ." Memo@" cr
    LoadAddress
    M_READ  
    szUBuf MIN 
    UBuf 2 + TO rBuf
    ; IS Memo@ \ <=============================================================


\ ========== FUSE  ===================================
[WITHOUT?] TwdFuse  5 CONSTANT TwdFuse [THEN]

\ DEFER #Fuse@ ( # -- u) \ прочитать байт №
:NONAME ( # -- u) \ прочитать байт №
    clrbuf
    CMD_READ_FUSE_ISP c>buf
    4 c>buf
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
    cmd>buf UBuf> 
    Tred @ 4 = 
    IF UBuf 2 + C@  
    ELSE S" Не удалось прочитать фузы." :[ 
    THEN 
    ; IS #Fuse@ \ <=============================================================

\ DEFER #Fuse! ( u # -- ) \ записать байт №
:NONAME ( u # -- ) \ записать байт №
    2DUP #Fuse@ <>
    IF \ не равны
        DUP  ." FUSE_" 1 .R ." : "
        clrbuf CMD_PROGRAM_FUSE_ISP c>buf
        DUP 0 = 
        IF OVER #Write_Fuse_bits          ELSE 
        DUP 1 =
        IF OVER #Write_Fuse_High_bits     ELSE 
        DUP 2 = 
        IF OVER #Write_Extended_Fuse_bits ELSE 
        DROP S" <-Неверный номер #Fuse!" :[
        THEN THEN THEN
        cmd>buf UBuf> 
        TwdFuse PAUSE \ время на запись
        \ u #
        #Fuse@  <>
        IF S"  Запись не удалась."  :[ 
        ELSE  ." изменен"
        THEN  CR
    ELSE 2DROP 
    THEN
    ; IS #Fuse! \ <=============================================================


\ ========== LOCK  ===================================
\ DEFER LockBits@ (  -- u)
:NONAME (  -- u)
    clrbuf
    CMD_READ_LOCK_ISP c>buf
    4 c>buf
    #Read_Lock_bits cmd>buf
    UBuf>
    Tred @ 4 = 
    IF UBuf 2 + C@
    ELSE S" Не удалось прочитать блокировочные биты." :[ THEN 
    ; IS LockBits@ \ <============================================================

\ DEFER LockBits! ( u 0 -- )
:NONAME ( u 0 -- )
    DROP 
    clrbuf
    CMD_PROGRAM_LOCK_ISP c>buf
    #Write_Lock_bits cmd>buf
    UBuf>
    10 PAUSE
    LockBits@ 
    ." LOCK MODE:" INVERT  0xFF AND .
    CR
    ; IS LockBits! \ <============================================================

:NONAME ( # -- byte) \ прочитать калибровочный байт #
    clrbuf
    CMD_READ_OSCCAL_ISP c>buf
    4 c>buf
    #Read_Calibration_Byte cmd>buf
    UBuf>
    UBuf 2 + C@
    ; IS CalibrationByte@



