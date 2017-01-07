[FOUND?] TheProg [IF] \eof [THEN]

DECIMAL

\ 64 CONSTANT size-rbuf        \ размер буфера
\ CREATE rbuf size-rbuf ALLOT   \ буфер чтения

0  VALUE size-rbuf        \ размер буфера
0  VALUE rBuf       \ адрес буфера чтения

0  VALUE EndMemory  \ последний адрес памяти
0  VALUE SizePage   \ размер страницы в байтах
10 VALUE TwP        \ таймаут для записи страницы
0  VALUE AsWord?    \ индикатор доступа по словам(по парам байт)


DEFER powerup ( )   \ занять чип
DEFER powerdown ( ) \ освободить
DEFER ProgEn ( -- ) \ включить режим программирования

DEFER FLASH_WRITE    \ IS M_WRITE
DEFER FLASH_READ     \ IS M_READ
DEFER PageFlash!     \ записать страницу Programm Memory
DEFER ByteFlash! ( byte adr -- ) \ записать байт в Programm Memory

DEFER EEPROM_WRITE   \ IS M_WRITE
DEFER EEPROM_READ    \ IS M_READ
DEFER PageEPROM! ( adr -- ) \ записать страницу EEPROM
DEFER ByteEPROM! ( byte adr -- ) \ записать байт в EEPROM

DEFER Page! ( a u adrW -- n) \ записать страницу



DEFER Memo@ ( adr -- n) \ читает память с adr, возвращает число принятых байт
DEFER closeUsbDev ( -- ) \ закрыть устройство

DEFER SignatureByte@ ( # -- byte ) 
DEFER CalibrationByte@ ( # -- byte)
DEFER LockBits@ (  -- u)
DEFER LockBits! ( u 0 -- )
DEFER #Fuse@ ( # -- u) \ прочитать байт №
DEFER #Fuse! ( u # -- ) \ записать байт №
DEFER EraseChip ( )


DEFER M_READ    \ чтение из памяти
DEFER M_WRITE   \ запись в память
DEFER PageM!    \ запись в станичную память    
DEFER ByteM!    \ запись байта в память


: :( ( --) \ завершить работу с программатором
    CR ." :(" CR powerdown closeUsbDev QUIT 
    ;
    
: :[ ( adr u -- ) \ завершить работу с программатором и сказать почему
    TYPE :( 
    ;        
    
: Signature@ ( -- u)
    0 SignatureByte@ DUP 0x1E =
    IF DROP 1 SignatureByte@ 8 LSHIFT 2 SignatureByte@ OR
    ELSE .HEX S" Чип не от ATMEL." :[ THEN
    ;

: DUMPchip ( adr u -- ) \ распечатать дамп из памяти чипа
    ?DUP IF
        HEX[ 0 -ROT \ счетчик строк, убрать
            OVER DUP Memo@ 1- OVER + SWAP \ заполнить буфер данными из чипа 
            2SWAP OVER + SWAP
            DO ( stline к н ) \ 
                I 0x100 MOD  0= IF CR THEN \ горизонтальный блоковый интервал
                \ в начале строки напечатать адрес
                \ именно из-за этого адреса нельзя воспользоваться стандартным dump
                ROT DUP 0= IF I 4 .0R 2 SPACES THEN -ROT
                2DUP I -ROT BETH 0= \ нужные данные есть в буфере?
                IF DROP 1+ DUP Memo@ 1- OVER + SWAP THEN \ нет - перезаполнить
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
                        \ DUP BL < IF  DROP [CHAR] . THEN 
                        DUP BL [CHAR] ~ BETH 0= IF  DROP [CHAR] . THEN 
                        EMIT 
                    LOOP 
                   0 CR  \ завершить текущую строку, счет=0, перейти на следующую
                ELSE DUP 8 = IF 2 SPACES THEN  \ вертикальный интервал 
                THEN -ROT \ убрать счётчик
            LOOP DROP 2DROP
        ]HEX
    ELSE DROP ." Пусто." CR
    THEN
    ;

DEFER Byte! ( adr u adrW -- ) \ побайтная запись в память

: Memo! ( buf sizebuf adrW -- ) \ записать содержимое буфера в память
        \ buf-окуда sizebuf-скока adrW-куда     
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
        \ adr u adrW \ adr-окуда u-скока adrW-куда
        Byte!
    THEN
    ;
: Verify ( adr u adrf -- f ) \ 0 - неравны 
\ сравнить участок памяти с записанным в чипе
    BEGIN
        OVER 
    WHILE
        2DUP Memo@ DUP 1 < IF DROP 2DROP 2DROP FALSE EXIT THEN 
        MIN
        >R >R OVER R> SWAP rBuf  R@ TUCK  \ adr u adrf adr n rbuf n  R: n
        COMPARE IF R> 2DROP 2DROP FALSE EXIT THEN 
        ROT R@ + ROT R@ - ROT R> + 
    REPEAT 2DROP DROP
    TRUE
    ;
: WriteChip ( adr u adr1  -- ) \ записать u байт с адреса adr в adr1 Memory
    \ adr u adr1 
    3DUP Verify 0= 
    IF  3DUP Memo! \ записать
        TwP PAUSE
        Verify \ проверить
        0= IF ." Верификация не удалась." CR 1 THROW THEN
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
    ['] ByteFlash!      IS ByteM!
    ['] PageFlash!      IS PageM!
    ['] FLASH_WRITE     IS M_WRITE
    ['] FLASH_READ      IS M_READ
    ;
: EPROM_ ( ) \ настройка на работу с энергонезависимой памятью
    FALSE TO AsWord? \ запись возможна отдельными байтами
    C" E2END"  FIND
    IF EXECUTE  ELSE DROP 0 THEN TO EndMemory
    C" EEPAGESIZE" FIND \ страничная память определена?
    IF EXECUTE  ELSE DROP 0 THEN TO SizePage
    C" TwdEEPROM" FIND \ таймаут определен?
    IF EXECUTE  ELSE DROP 10 THEN TO TwP
    ['] ByteEPROM!      IS ByteM!
    ['] PageEPROM!      IS PageM!
    ['] EEPROM_WRITE    IS M_WRITE
    ['] EEPROM_READ     IS M_READ
    ;



: N-byte ( -- n ) \ узнать число байт для записи
    0 labels 
    BEGIN @ ?DUP WHILE DUP label-value @ ROT MAX SWAP REPEAT 1+ \ -- число_бит=максимальный_номер+1  
    8 /MOD SWAP IF 1+ THEN \ число байт   
    ;
: Fuses! ( ) \ записать фузы в чип
    FUSE[ 
        N-byte
        0 ?DO seg @ I + C@ I  #Fuse! LOOP 
    ]FUSE
    ;
: Locks! ( ) \ записать локи в чип
    LOCK[
        N-byte
        0 ?DO seg @ I + C@ I  LockBits! LOOP 
    ]LOCK    
    ;

: CheckPreProg ( adr u adr1  -- ) \ 
    \ для начала проверим размер памяти
    2DUP + EndMemory 1+ > IF ." Дамп слишком велик для данного чипа." :[ THEN
    AsWord? 
    IF \ проверка чётности, если запись идёт по словам
        2DUP 1 AND IF ." Адрес записи должен быть чётным." :[ THEN
        1 AND IF ." Количество записываемых байт должено быть чётным." :[ THEN
    THEN
    ;

: Flash! ( -- ) \ записать кодофайл в ROM
    ROM[ 
        Flash_
        FlashNumWrite 0= IF FlashFullWrite THEN \ заполнение по умолчанию
        HEX[
        ." FLASH [" FlashStartAddr 4 .0R ." .." FlashStartAddr FlashNumWrite + 4 .0R ." ] "
        ]HEX
        FlashSRCAddr FlashNumWrite FlashStartAddr
        CheckPreProg WriteChip
    ]ROM
    ;

: EPROM! ( ) \ записать кодофайл в EEPROM
    EPROM[ EPROM_
        E2SRCAddr 0= IF E2FullWrite THEN \ заполнение по умолчанию
        E2NumWrite 
        IF  \ есть данные
            HEX[
            ." EPROM [" E2StartAddr 4 .0R ." .." E2StartAddr E2NumWrite + 4 .0R ." ] "
            ]HEX
            E2SRCAddr E2NumWrite E2StartAddr
            CheckPreProg  WriteChip 
        THEN
    ]EPROM
    ;


: #Calibr@ ( # -- byte ) \ чтение калибровочного байта "на лету"
    ProgEn  CalibrationByte@ powerdown  ;
: #Calibr@. ( # -- byte ) \ чтение калибровочного байта "на лету" с печатью
    #Calibr@ dup CR ." Калибровочный байт RC-генератора =0x" .hex  ;    

: ResetChip ( ) \ сброс чипа
    ProgEn 20 PAUSE PowerDown
    ;

#def :> ( --)   CR powerdown closeUsbDev CR TRUE THROW \ завершить работу с программатором


: TheProg ( --)
    ['] Flash! CATCH 
    DUP 1 = 
    IF  DROP \ верификация не прошла
        EraseChip  
        Flash!
    ELSE THROW \ выход по ошибке
    THEN
    EPROM! Fuses! Locks! \ запись всего и с руганью на ошибки
    ;

: Chip!! ( )
    ['] ProgEn CATCH 
    IF ." Неподключено." CR 
    ELSE
        device Signature@  <> IF ." Не тот чип." :> THEN \ проверить сигнатуру
        CR
        PreProg 
            TheProg
        PostProg
    THEN PowerDown    
    ;


