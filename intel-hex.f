\ слова для работы с файлами в формате intel-HEX
\ автор: ~iva 2009 

\ ======== ИНФО ================================================================
( Каждая запись представляет собой ASCII-строку файла. 
    Одна строка – одна запись.
    Общий формат записей
    -----------------------------------------------------
    «:»     1байт   2байта  1байт   RECLEN_байт     1байт 
    -----------------------------------------------------    
     v      v       v       v       v               v
     ^маркер записи
            ^количество байт в поле данных 
             RECLEN
                    ^смещение
                            ^тип записи
                             00 - данные
                             01 - конец файла
                             02 - адрес сегмента
                             03 - сегментный адрес старта
                             04 - линейный адрес
                             05 - линейный адрес старта
                                    ^данные
                                                    ^контрольная сумма.
                                                     сумма всех байт записи, 
                                                     исключая «:», по модулю 256
                                                     должна быть равной нулю
Пример:
    :100000001BC6189518951895189518951895D9C563
    :10 0010 00 18951895189518951895189518951895 78
    :00000001FF
)
                                                     
\ ======== ЗАДАЧИ ==============================================================
\ 1-ая задача: 
\ нужно открыть файл, прочитать его с контролем, разместить данные в буфере 
\ : LOAD-AS-HEX ( c-adr u -- ) c-adr u - это строка с именем файла
\ : HEX-LOAD ( "имя-файла" -- )  

\ 2-ая задача:
\ сохранить данные из текущего сегмента в файл в hex-формате
\ : SAVE-AS-HEX ( c-adr u -- ) c-adr u - это строка с именем файла
\ : HEX-SAVE ( "имя-файла" -- ) 

\ ======== ПОДКЛЮЧАЕМЫЕ ФАЙЛЫ и слова нужные не только здесь ===================
VOCABULARY INTEL-HEX
SAVE-VOCS
ALSO INTEL-HEX DEFINITIONS

\ ======== КОНСТАНТЫ И ПЕРЕМЕННЫЕ ==============================================
0       VALUE fid       \ идентификатор файла
256     VALUE len       \ максимальная длина строки
CREATE bstr len ALLOT   \ буфер для приема строки

\ ======== СЛУЖЕБНЫЕ СЛОВА ДЛЯ ОПРЕДЕЛЕНИЯ ГЛАВНЫХ СЛОВ ========================
: число ( c-adr i -- c-adr+i u2) 
    \ возвращает число записанное i символами в строке c-adr
    0 -ROT 0 -ROT >NUMBER   THROW \ ABORT" Ошибка преобразования числа."
    -ROT D>S 
    ;
    
: HEX>число ( c-adr n -- c-adr+n u) 
    \ читает n символов из c-adr, возвращает число им соответствующее и
    \ увеличивает адрес
    HEX[ 
        ['] число CATCH \ чтобы вернуться и востановить систему счисления
            IF ]HEX .S CR TRUE ABORT" Ошибка преобразования числа." THEN 
    ]HEX  ;
: BYTE>STR ( b -- c-adr u) \ преобразует байт в 2-х символьную строку, 
    \ согласно текущей системы счисления
    0 <# # # #>
    ;             
: BYTE>S ( b -- ) \ помещает байт в символьном виде в S-строку, 
    BYTE>STR +>S
    ;             
: проверить_запись ( c-adr u --  |ABORT )
    \ проверяет признак записи, контрольную сумму и преобразовывает символьное
    \ представление байт в числовое. 
    \ пишет результат преобразования в строку по исходному адресу c-adr
    OVER C@ [CHAR] : <> ABORT" Ошибка формата записи."  \ проверка ":"
    \ c-adr u
    OVER 1+ 0 ROT \ c-adr  c-adr  CS=0 u 
    2/  0 DO                \ c-adr1   c-adr2   CS
            SWAP            \ c-adr1   CS       c-adr2
            2 HEX>число >R  \ c-adr1   CS       c-adr2+2    R:byte
            ROT R@ OVER C!  \ CS       c-adr2+2 c-adr1      R:byte
            1+              \ CS       c-adr2+2 c-adr1+1    R:byte
            ROT >R SWAP     \ c-adr1+1 c-adr2+2             R:byte  CS
            R> R> +         \ c-adr1+1 c-adr2+2 CS
         LOOP
    255 AND ABORT" Ошибка контрольной суммы строки."
    2DROP 
    ;
: Reclen ( -- RECLEN)
    bstr C@ ;
: Offset ( -- OFFSET)
    bstr 1+ C@ 8 LSHIFT 
    bstr 2 + C@ 
    + ;
: Tipe   ( -- TIPE)
    bstr 3 + C@ ;
: a-Dat ( -- a-adr)
    bstr 4 + ;
: не_последняя? ( -- TRUE | FALSE)
    \ читает заголовок записи, flag TRUE если это не последняя запись
    \ если это данные, то возвращает число байт данных, 
    \ иначе только 0 и true
    Tipe 0 = IF Reclen TRUE EXIT THEN  \ T=0 'данные'
    Tipe 1 = IF FALSE EXIT  THEN \ T=1 'последняя запись'
    Tipe 5 > ABORT" Неизвестный тип записи"  \ T>5 ругаемся
    0 TRUE  \ T=2...5 игнорируем
    ;
    
: в_сегмент ( n -- )
    IF  \ размещение данных в буфере
        Offset ORG \ по адресу смещения
        a-Dat Reclen   \ c-adr reclen
        OVER + SWAP DO I C@ C>Seg  LOOP
    THEN ;
    
: закрыть_файл ( -- )
    fid CLOSE-FILE  THROW ;       
    
\ =========== ГЛАВНЫЕ СЛОВА ====================================================
PREVIOUS DEFINITIONS ALSO INTEL-HEX
: Hex2Bin ( c-adr u -- c-adr u/2) \ преобразование HEX-строки в бинарную
    2/ 2DUP OVER SWAP
    OVER + SWAP
    ?DO \ c-adr'
        2 HEX>число \ c-adr' n
        I C!
    LOOP DROP 
    ;

: LOAD-AS-HEX ( c-adr u -- )   
    \ загрузить файл с именем в c-adr u в текущий сегмент
    R/O OPEN-FILE THROW TO fid  
    BEGIN
        bstr DUP len 2 - fid READ-LINE THROW DROP \ считать_запись  
        проверить_запись 
        не_последняя? 
    WHILE \ данные
        в_сегмент
    REPEAT
    закрыть_файл 
    ;
: HEX-LOAD ( "имя-файла" -- )
    BL WORD  COUNT LOAD-AS-HEX 
    ;  
 : SAVE-AS-HEX ( c-adr u -- )
    \ сохранить текщий сегмент в файл с именем в строке c-adr u
    \ файл создается или перезаписывается без вопросов
    W/O CREATE-FILE ABORT" Ошибка создания файла." TO fid
    HEX[
    0 finger!
    BEGIN   \ цикл по строкам
        S" :" >S \ старт записи
        wender finger - 16 MIN DUP >R BYTE>S  \ RECLEN
        finger 256 /MOD DUP >R BYTE>S DUP >R BYTE>S \ OFFSET 
        S" 00" +>S   \ TIPE
        R> R> + R@ +    \ CS
        \ цикл по байтам
        R> 0 \ RECLEN 0
        DO    \ CS
            >R Seg>C DUP >R  \ byte R:CS byte 
            BYTE>S     \      R:CS byte
            R> R> +          \ CS'
        LOOP
        255 AND 256 SWAP - BYTE>S
        S@ fid WRITE-LINE THROW S>DROP 
        wender finger = \ пока wender > finger 
    UNTIL  
    ]HEX
    S" :00000001FF" fid WRITE-LINE THROW  \ последняя запись
    fid CLOSE-FILE THROW
    ;    
: HEX-SAVE ( "имя-файла" -- )
    BL WORD COUNT SAVE-AS-HEX ;
RESTORE-VOCS
\ ========= ТЕСТЫ И ПРИМЕРЫ ====================================================
\ S" prog.hex" LOAD-AS-HEX
\ HEX-SAVE PROG.HEX
\ RAM
\ HEX-LOAD tst.hex
\ HEX-SAVE TST.HEX
\ ROM 
\ HEX-SAVE PROG2.HEX

\ BYE

