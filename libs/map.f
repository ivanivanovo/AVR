\ ============================ создание файла карты памяти ====================
: FormatDef ( adr u x -- adr' u') \ сделать строку #define ...
    HEX[
        -ROT S" #define " >S +>S S"    0x" +>S
        4 ,0R  +>S  0xD emit>S S@ S>DROP
    ]HEX
    ;
0 VALUE hfid
: typeF ( adr u -- ) \ печатать в файл
    hfid WRITE-LINE THROW
    ;

: RAM_map ( adr u --) \ создать заголовочный файл  с адресами переменных
    \ adr u - строка с базовым именем
    >S  [CHAR] _ EMIT>S
        SDUP S" RAM_map.h" +>S 
            0 emit>S S@ W/O CREATE-FILE THROW TO hfid  S>DROP
        SDUP 
        S" Ram" +>S 
            S@ AddrRam FormatDef TypeF  S>DROP
        \ относительный адреса переменных
        RAM[
            labels
            BEGIN @ DUP WHILE
                DUP label-type @ DataType =
                IF SDUP 
                    DUP label-name COUNT +>S
                    DUP label-value @ AddrRam -
                    \ или Абсолютные
                    DUP 0 < IF AddrRam + S" _A" +>S THEN
                    S@ ROT FormatDef TypeF  
                   S>DROP
                THEN
            REPEAT DROP
        ]RAM
    S>DROP
    hfid CLOSE-FILE THROW
    0 TO hfid
    ;


