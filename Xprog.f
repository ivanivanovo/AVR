
S" XPROGprotocol.f" INCLUDED

0x0800000 CONSTANT PDI_Flash_Base   \ смещение флеш памяти в пространстве PDI
0x08C0000 CONSTANT PDI_EPPROM_Base
0x08E0200 CONSTANT PDI_Prod_Signature_Base
0x08E0400 CONSTANT PDI_User_Signature_Base
0x08F0020 CONSTANT PDI_Fuse_Base
0x1000000 CONSTANT PDI_Data_Mem_Base

\ : ErrorS. ( u --) \ обработать ошибки
\     ?DUP 
\     IF
\         DUP XPRG_ERR_FAILED     = IF S" Команда завершилась с ошибкой" THEN
\         DUP XPRG_ERR_COLLISION  = IF S" Коллизия" THEN
\         DUP XPRG_ERR_TIMEOUT    = IF S" Таймаут истек" THEN
\         TYPE CR THROW
\     THEN
\     ;
: XprogErr? ( -- u ) \ проверить статус завершения команды
    UBuf 2+ C@ 
    ;
: XPROG_SETMODE \ установить режим программирования
    clrbuf
    CMD_XPROG_SETMODE c>buf
    ProgInterface PDIprog = IF XPRG_PROTOCOL_PDI ELSE
    ProgInterface TPIprog = IF XPRG_PROTOCOL_TPI ELSE
    TRUE ABORT" Выбранный протокол не поддерживается."
    THEN THEN c>buf
    UBuf>
    UBuf 1+ C@ ABORT" Не удалось установить режим программирования"  
    
    ;

:NONAME ( ) \ ввод режима программирования
    XPROG_SETMODE
    clrbuf
    CMD_XPROG c>buf
    XPRG_CMD_ENTER_PROGMODE c>buf
    UBuf>
    XprogErr? ABORT" Не удалось войти войти в режим программирования"
    ProgInterfaceS TYPE CR
    ; IS ProgEn \ <======================================================

:NONAME ( ) \ выход из режима программирования
    clrbuf
    CMD_XPROG c>buf
    XPRG_CMD_LEAVE_PROGMODE  c>buf
    UBuf>
    ; IS PowerDown \ <======================================================

: PDIoffset ( adr mem -- adr') \ преревести адрес в пространство PDI
    DUP  XPRG_MEM_TYPE_APPL        = IF PDI_Flash_Base ELSE
    DUP  XPRG_MEM_TYPE_BOOT        = IF PDI_Flash_Base BOOT.START + ELSE
    DUP  XPRG_MEM_TYPE_EEPROM      = IF PDI_EPPROM_Base ELSE
    DUP  XPRG_MEM_TYPE_FUSE        = IF PDI_Fuse_Base ELSE
    DUP  XPRG_MEM_TYPE_LOCKBITS    = IF PDI_Fuse_Base FUSE.SIZE + 1+ ELSE
    DUP  XPRG_MEM_TYPE_USERSIG     = IF PDI_User_Signature_Base ELSE
    DUP  XPRG_MEM_TYPE_PRODSIG     = IF PDI_Prod_Signature_Base ELSE
    DUP  XPRG_MEM_TYPE_DATAMEM     = IF PDI_Data_Mem_Base ELSE
        TRUE ABORT" Неизвестный тип памяти"
    THEN THEN THEN THEN THEN THEN THEN THEN 
    NIP +
    ;
: ErasedMem? ( erase -- typeMem ) \ определить тип стираемой памяти
   DUP  XPRG_ERASE_CHIP          = IF XPRG_MEM_TYPE_APPL    ELSE   
   DUP  XPRG_ERASE_APP           = IF XPRG_MEM_TYPE_APPL    ELSE  
   DUP  XPRG_ERASE_BOOT          = IF XPRG_MEM_TYPE_BOOT    ELSE  
   DUP  XPRG_ERASE_EEPROM        = IF XPRG_MEM_TYPE_EEPROM  ELSE
   DUP  XPRG_ERASE_APP_PAGE      = IF XPRG_MEM_TYPE_APPL    ELSE
   DUP  XPRG_ERASE_BOOT_PAGE     = IF XPRG_MEM_TYPE_BOOT    ELSE
   DUP  XPRG_ERASE_EEPROM_PAGE   = IF XPRG_MEM_TYPE_EEPROM  ELSE
   DUP  XPRG_ERASE_USERSIG       = IF XPRG_MEM_TYPE_USERSIG ELSE
        TRUE ABORT" Непонятный тип памяти"
   THEN THEN THEN THEN THEN THEN THEN THEN     
   NIP
   ;
: ReadMem ( adr u mem -- adr' u )
    \ adr - откуда читать, u - сколько, mem - тип памяти
    \ adr' - адрес куда положено прочитанное
    clrbuf  CMD_XPROG c>buf   XPRG_CMD_READ_MEM c>buf
    DUP >R c>buf \ тип памяти
    SWAP R> PDIoffset
    |4 c>buf c>buf c>buf c>buf \ адрес в чипе
    DUP |2 c>buf c>buf \ размер
    UBuf> XprogErr? ABORT" Не удалось прочитать из памяти."
    UBuf 3 + SWAP
    ;
: EraseMem ( adr erase -- ) \ стирание заданной памяти
    clrbuf   CMD_XPROG c>buf  XPRG_CMD_ERASE c>buf
    DUP c>buf \ тип стираемой памяти 
    ErasedMem? PDIoffset |4 c>buf c>buf c>buf c>buf \ адрес в чипе
    UBuf> XprogErr? ABORT" Стирка не задалась."
    ;
0 CONSTANT ModeLoadPage
2 CONSTANT ModeWritePage
ModeLoadPage VALUE PageMode  \ запись станицы при 2 или 3
: WriteMem ( adr u adrW mem -- ) \ записать в mem по adr u байт
    clrbuf  CMD_XPROG c>buf  XPRG_CMD_WRITE_MEM c>buf
    DUP >R c>buf \ тип памяти
    PageMode c>buf \ битовое поля работы со страницей
    R> PDIoffset |4 c>buf c>buf c>buf c>buf \ адрес PDI
    ( adr u )
    DUP |2 c>buf c>buf \ размер
    TUCK UBuf Tred @ + SWAP CMOVE Tred +!
\ shwbuf cr
    UBuf> XprogErr? ABORT" Запись чой-то не задалась."
    ;

:NONAME ( ) \ стирание чипа
    0 XPRG_ERASE_CHIP EraseMem
    C" TwdErase" FIND \ таймаут определен?
    IF EXECUTE  ELSE DROP 20 THEN 
    PAUSE ." Чип очищен." CR
    ; IS EraseChip
\ ========== CRC =====================================
: memCRC ( mem -- CRC) \ подсчет CRC памяти
    clrbuf  CMD_XPROG c>buf  XPRG_CMD_CRC c>buf
    c>buf
    UBuf> XprogErr? ABORT" Ошибка чтения CRC"    
    UBuf 3 + @
    ;

\ ========== FLASH ===================================
\ ['] ByteFlash!      IS ByteM!
\ ['] PageFlash!      IS PageM!
\ ['] FLASH_WRITE     IS M_WRITE
:NONAME ( )
    XPRG_MEM_TYPE_APPL
    ; IS FLASH_WRITE
\ ['] FLASH_READ      IS M_READ
:NONAME ( adr -- adr' n) \ читать EPROM с адреса adr
    size-rBuf XPRG_MEM_TYPE_APPL ReadMem
    ; IS FLASH_READ

VARIABLE TmpByte \ адрес записываемого байта

\ WriteMem ( adr u adrW mem -- )

\ ========== EPROM ===================================
\ ['] ByteEPROM!      IS ByteM!
\ ['] PageEPROM!      IS PageM!
\ ['] EEPROM_WRITE    IS M_WRITE
:NONAME ( )
    XPRG_MEM_TYPE_EEPROM
    ; IS EEPROM_WRITE
\ ['] EEPROM_READ     IS M_READ
:NONAME ( adr -- adr' n) \ читать EPROM с адреса adr
    size-rBuf XPRG_MEM_TYPE_EEPROM ReadMem
    ; IS EEPROM_READ

:NONAME ( adr -- n) \ читает память с adr, возвращает число принятых байт
    M_READ SWAP TO rBuf
    szUbuf MIN
    ; IS Memo@

: Buf! ( a u adrW -- n) \ прогрузить и записать буфер
    OVER size-rbuf > \ не более размера буфера передачи
    IF   \ остаток для записи больше размера передачи
        NIP size-rbuf SWAP 
        ModeLoadPage
    ELSE \ остаток помещается в передачу
        ModeWritePage
    THEN  TO PageMode
    OVER >R M_WRITE WriteMem R>
    ;

 :NONAME ( a u adrW -- n) \ прогрузить и записать страницу     
    SWAP SizePage MIN DUP >R SWAP \ не более станицы 
    BEGIN \ кусочная запись в размер буфера
        3DUP Buf! \ a u adrW n
        >R 
        R@ + ROT R@ + ROT R> - ROT
        OVER 0=
    UNTIL 
    2DROP DROP R> \ n   
    ; IS Page!

\ ========== FUSE  ===================================
\ DEFER #Fuse@ ( # -- u) \ прочитать байт №
:NONAME ( # -- u) \ прочитать байт №
    1 XPRG_MEM_TYPE_FUSE ReadMem
    DROP C@
    ; IS #Fuse@ \ <=============================================================

:NONAME ( u # -- ) \ записать 1 байт #
\ .s ." <#Fuse@ "  cr
    2DUP #Fuse@ <>
    IF \ не равны
        DUP ." FUSE_" 1 .R ." : "
        >R  TmpByte ! TmpByte   1 R@ 
        XPRG_MEM_TYPE_FUSE  WriteMem
        TwdFuse PAUSE \ время на запись
        TmpByte C@ R> #Fuse@ <>
        IF S"  Запись не подтверждена." :[
        ELSE ." изменен"
        THEN CR
    ELSE 2DROP
    THEN
    ; IS #Fuse! \ <=============================================================
\ ========== LOCK  ===================================
\ DEFER LockBits@ (  -- u)
:NONAME (  -- u)
    0 1 XPRG_MEM_TYPE_LOCKBITS ReadMem
    DROP C@
    ; IS LockBits@ \ <============================================================

:NONAME ( u 0 -- ) \ записать 1 байт 0
    >R  TmpByte ! TmpByte   1 R> 
    XPRG_MEM_TYPE_LOCKBITS WriteMem
    10 PAUSE
    LockBits@ 
    ." LOCK MODE:" INVERT  0xFF AND .
    CR
    ; IS LockBits! \ <============================================================

:NONAME ( # -- byte) \ прочитать калибровочный байт #
    1 XPRG_MEM_TYPE_PRODSIG ReadMem
    DROP C@
    ; IS CalibrationByte@

MCU.DEVID0 CONSTANT DeviceSignature
:NONAME ( # -- byte) \ прочитать калибровочный байт #
    DeviceSignature  + 1 XPRG_MEM_TYPE_DATAMEM ReadMem
    DROP C@
    ; IS SignatureByte@ 
