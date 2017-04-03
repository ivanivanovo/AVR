\ загрузчик 
[NOT?] ESC> [IF] S" console_codes.f" INCLUDED [THEN]
[NOT?] 2VARIABLE [IF] S" lib/include/double.f" INCLUDED [THEN]

0 VALUE OnBoot  \ начало загружаемой области
0 VALUE OffBoot \ конец загружаемой области
8 CONSTANT WDatMax \ максимальный размер пакета данных, четное, [2..10]

\ ==================== либы ==========================================================

\ =============== система программирования ===================================

\ структура для сборки пакета программирования
0
1 -- prgS       \ семафор программирования
1 -- cmd        \ флаги команды
1 -- ZLpoint    \ адрес записи младший байт
1 -- ZHpoint    \ адрес записи старший байт
1 -- ZEpoint    \ адрес записи дополнительный старший байт
WDatMax -- Wdat \ WDatMax байт данных
CONSTANT StructPrg

DEFER Boot> ( adr u --) \ отправка пакета


: Boot>. ( adr u --) \ показка пакетов
    OVER  C@ ." prg: " HEX[ 2 .0R ]HEX ." | " \ prg
    OVER  1+ C@ \ cmd
    DUP [ {b fRst } ] LITERAL AND IF ." r" ELSE ." ." THEN
    DUP [ {b fWrt } ] LITERAL AND IF ." w" ELSE ." ." THEN
        [ {b fMsk } ] LITERAL AND IF ." s" ELSE ." ." THEN
    ." | "
    2 /STRING
    0 -ROT
    OVER + SWAP 
    DO I C@ HEX[ 2 .0R ]HEX SPACE
       DUP 2 = IF ." |" SPACE THEN
       1+
    LOOP DROP
    CR
    ;

2VARIABLE fprgWad \ adr u полученного пыжа, u используется как флаг
: 2off ( adr --) \ обнулить двойную переменную
    0 0 ROT 2!
    ;
: 2on ( adr --) \ установить двойную переменную
    -1 -1 ROT 2!
    ;
fprgWad 2off

: WaitPrgWad ( --) \ ждать пыжика от программируемого чипа
    fprgWad @ IF exit THEN \ не ждать
    getMs \ засечь время
    begin \ контроль времени ожидания
        getMs OVER 300 + <
    while
        fprgWad 2@ \ проверить получение
        sizePrgWad = IF DUP THEN
        until
        1+ W@ 
        SigLoader <> ABORT" Требуется замена загрузчика!"
        fprgWad 2off  \ погасить его
        ." ." \ показать получение
    else ABORT" Нет ответа!"
        then DROP
    ;

: Boot[ ( --) \ пометить начало загружаемой области
    finger TO OnBoot
    ;
: ]Boot ( --) \ пометить конец загружаемой области    
    finger TO OffBoot
    ;

: +fcmd ( fMask --) \ установить флаги в команде
    S@ DROP cmd DUP C@ \ fMask adr cmd
    ROT OR SWAP C!
    ;

: adrZ! ( adr -- ) \ установить адрес
    |3 ROT EMIT>S SWAP EMIT>S EMIT>S
    ;
0 VALUE defoltCMD
: [Boot]? ( adr --f) \ проверка попадания adr внутрь загружаемой области
    OnBoot OffBoot 1- BETH
    ;
: filling? ( adr src n -- f) \ продолжать заполнение?
    WDatMax < \ adr src f' \ 
    IF ( adr src) OVER [Boot]? =
        IF ( adr) PAGESIZEb MOD ELSE DROP FALSE THEN
    ELSE 2DROP FALSE THEN
    ;
: PackFill ( adr --adr' n ) \ пакет заполнения
    DUP [Boot]? >R \ adr   R:(src)
    0
    BEGIN  \ adr n
        R@ IF OVER SegA C@ ELSE [ {b fMsk } ] LITERAL +fcmd 0 THEN \ adr n b
        EMIT>S
        1+ SWAP 1+ SWAP \ adr+1 n+1
        OVER PAGESIZEb MOD 0= IF [ {b fWrt } ] LITERAL +fcmd THEN \ записать заполненную страницу
        \ условие
        2DUP R@ SWAP filling?
    WHILE \ пока mod(adr), src-неизменился
    REPEAT 
    R> DROP 
    \ adr' n 
    ;

: HeadPack>S ( --) \ шапка пакета программирования
    NEW>S
    prgCMD01 EMIT>S
    defoltCMD EMIT>S
    ;
: Pages! (  --) \ записать все страницы
    \ выровнять загружаемую область по страницам
    OnBoot PAGESIZEb / PAGESIZEb * \ adrPstart
    OffBoot PAGESIZEb /mod SWAP IF 1+ THEN PAGESIZEb * \ adrPstart adrPend
    OVER - \ adr0 u
    \ adr0 выровнен на начало первой страницы
    \ u кратно PAGESIZEb
    BEGIN DUP WHILE \ пока есть данные
        HeadPack>S \ шапка пакета
        OVER adrZ!
        \ тело пакета
        \ adr u
        SWAP PackFill \ u adr' n
        ROT SWAP - \ adr' u'  
        fprgWad 2off \ что-б ждал пыжика
        S@ Boot> S>DROP \ отправка пакета
    REPEAT
    2DROP 
    ;

: PingBoot ( -- ) \ проверочный пакет программатора
    0 TO defoltCMD \ простая запись
    HeadPack>S 0 adrZ!
    fprgWad 2off \ что-б ждал пыжика
    S@ Boot>   \ отправка пакета
    S>DROP 
    ;
: [Vect] ( --) \ загрузка области векторов
    OnBoot OffBoot
            0 TO OnBoot ROM_FREE TO OffBoot
            ['] Pages! CATCH -ROT
    TO OffBoot TO OnBoot 
    THROW
    ;
: [VBoot] ( --) \ загрузка векторов загрузчика
    SEG  
        BOOT-SEG TO SEG [Vect]
    TO SEG
    ;
: [Boot] ( -- ) \ загрузка помеченной области 
    Pages! 
    ;

: GoBoot ( adr --) \ выход из загрузчика по adr
    defoltCMD >R
        [ {b fRst } ] LITERAL TO defoltCMD
        HeadPack>S 
        2/ adrZ!
        fprgWad 2on \ что-б не ждал пыжика
        S@ Boot> S>DROP \ отправка пакета
    R> TO defoltCMD
    ;    

: Boot! ( --) \ полная загрузка
    \ проверить активности загрузчик в чипе
    PingBoot 
    CR
    \ проверить пересечение с критической областью
    crtBootA OnBoot OffBoot BETH
    crtBootB OnBoot OffBoot BETH
    OR ABORT" В загружаемой области находится критический код загрузчика!"
    \ загрузка
    OffBoot OnBoot - 
    S" [35m" ESC>
    ." ************************************" CR
    ." *             Booting!             *" CR
    ." * Размер для загрузки: " 5 .R ."  байт. *" CR
    ." ************************************" CR
    0 TO defoltCMD \ простая запись
    [VBoot] CR \ вектора загрузчика
    [Boot]  CR \ загрузка помеченной области 
    [Vect]  CR \ вектора основной программы
    ." *************** END ****************" CR
    defoltText
\ не всегда корректно идти на 0
\    0 GoBoot \ переход на основную программу
    ;

: 4>S ( u--)
    |4 
    >R  >R  >R 
                   EMIT>S
            R> EMIT>S
        R> EMIT>S
    R> EMIT>S
    ;
: VSBoot! ( VerSign adr --) \ выход из загрузчика по adr
    NEW>S 
        prgCMD01 EMIT>S 
        [ {b fRst } ] LITERAL EMIT>S
        2/ adrZ! \ адрес программы для записи сигнатуры
        4>S \ данные=сигнатура
        fprgWad 2on \ что-б не ждал пыжика
        S@ Boot> \ отправка пакета
    S>DROP 
    ;    
: _Boot! ( u -- )
    4>S
    fprgWad 2on \ что-б не ждал пыжика
    S@ Boot> S>DROP \ отправка пакета
    Boot!
    ;
: SignBoot! ( VerSign -- ) \ загрузка групповая
    NEW>S prgVsig EMIT>S 
    _Boot!
    ;
: UIDBoot! ( UID -- ) \ загрузка индивидуальная
    NEW>S prgUID EMIT>S 
    _Boot!
    ;
