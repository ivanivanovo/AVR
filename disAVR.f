\ дизассемблер AVR
\ автор: ~iva 2010
\ ревизия: декабрь 2011 = вывод -> надо всё переписать... бяка, хоть работает

\ ======== ИНФО ================================================================
\ Все инструкции для данного микроконтроллера упаковываются в связанную цепочку
\ структур opcodes. Эти структуры используются для ассемблирования и дизассе-
\ мблирования. Доступ к любой структуре возможен двумя спообами: 
\ а) по имени команды (при подключенном словаре DASSM)
\ b) через переменную opcodes, которая указывает на начало цепи opcodes
\ ======== ЗАДАЧИ ==============================================================
\ Нужно дизассемблировать область памяти заданную адресом и длинной, в надежде
\ что там находится бинарный код микроконтроллера семейства AVR-8. 
\ Полученный листинг (текст с мнемониками) записывается в указанный файл.
\ ======== ПОДКЛЮЧАЕМЫЕ ФАЙЛЫ и слова нужные не только здесь ===================
S" ~iva/AVR/AVRset.f"    INCLUDED    \ настройка на AVR и другое

\ ======== КОНСТАНТЫ И ПЕРЕМЕННЫЕ ==============================================
\ ======== СЛУЖЕБНЫЕ СЛОВА ДЛЯ ОПРЕДЕЛЕНИЯ ГЛАВНЫХ СЛОВ ========================
\ ========== слова для дизасемблирования =======================================
\ ==============================================================================

0 VALUE CurLabelName    \ c-adr имени метки
0 VALUE CurLabelValue   \ смещение метки в сегменте
0 VALUE CurLabelType    \ тип метки
8 VALUE LenDump         \ стандартная длина строки дампа
0 VALUE WordLabelValue  \ показывать смещение в словах 

: ClearCurLabel ( --) \ очистка текущих значений
    0 TO CurLabelName    \ c-adr имени метки
    0 TO CurLabelValue   \ смещение метки в сегменте
    0 TO CurLabelType    \ тип метки
    ;
: SetCurLabel ( label --)
    DUP label-value @ TO CurLabelValue
    DUP label-name    TO CurLabelName  \ имя
        label-type  @ TO CurLabelType  \ тип
    ;

: SkipMarks ( label--label') \ пропустить внутренние метки
    DUP 0= IF EXIT THEN
    BEGIN DUP label-type @ MarkType = WHILE @ REPEAT
    ;
: DownLabel ( val -- label-1 |0 ) \ найти метку ниже текущей позиции, 0 если нету
    >R
        labels BEGIN DUP @ SkipMarks DUP IF label-value @ R@ > THEN  WHILE @ REPEAT
        labels OVER = IF DROP 0 THEN
    R> DROP 
    ;
: UpLabel ( val -- label+1 |0 ) \ найти метку выше или равную текущей позиции, 0 если нету
    DownLabel DUP IF @ THEN
    ;
VARIABLE PozStr \ текущая позиция в строке
TRUE  VALUE AddrOpcode? \ нужен-ли адрес и опкод? пока да
5  CONSTANT SizeAreaVAL
4  CONSTANT SizeAreaOpcode
12 CONSTANT SizeAreaLabel
0  VALUE PozVal
SizeAreaVAL 3 +  VALUE PozOp
PozOp SizeAreaOpcode 2* 2+ + VALUE PozLabel
PozLabel SizeAreaLabel + VALUE PozMnemo

: .Label: (  -- ) \ напечатать имя метки в поле шириной n
    CurLabelName
    IF  CurLabelName COUNT TYPE ." :" 
        CurLabelName COUNT SYMBOLS 1+ PozStr +!  
        0 TO CurLabelName \ печатать только один раз
    THEN
    ;
: NewString ( ) \ начать новую строку
    CR 0 PozStr !
    ;

(
00412   F7E9                  BRNE  m59
00414   EF8F                  LDI   R24,255
00416   9380 00A4             STS   iwAddr,R24
0041A   E1ED                  LDI   zL,29
0041C   8200      m60:        ST    Z,R0
)
: GoPoz ( p -- ) \ перейти на позицию
    PozStr @ - DUP SPACES 
    DUP 0 > IF PozStr +! ELSE DROP THEN
    ;
: TypeLabel ( ) \ напечатать метку
    PozLabel GoPoz     
    .Label:
    ;
: TypeVal ( val -- ) \ напечатать смещение
    AddrOpcode? 
    IF  PozVal GoPoz   
        WordLabelValue IF 2/ THEN \ смещение в байтах или в словах
        SizeAreaVAL HEX[ .0R ]HEX SPACE 
        SizeAreaVAL 1+ PozStr +! 
    ELSE DROP THEN
    ;
: TypeOpcode ( opcode -- )
    AddrOpcode?
    IF  PozOp GoPoz  
        SizeAreaOpcode HEX[ .0R ]HEX SPACE 
        SizeAreaOpcode 1+ PozStr +!
    ELSE DROP THEN
    ;
: TypeStrDump ( val # -- )
    ?DUP
    IF
        OVER  TypeVal 
        \ метка
        TypeLabel PozMnemo GoPoz ." .db "
        ( val #) SWAP SEG @ + SWAP ( adr # )
        TUCK 0 
        DO \ цикл по байта
            C@+ DUP <# 0 #S #> TYPE ." ," \ печатать байты
            PAD I + !           \ запоминать символы
        LOOP  DROP          
       ( # )
        \ строка
        LenDump OVER  - 3 *  2+ SPACES
        ."  ; " PAD SWAP TYPE_ASCII 
        NewString \ CR    
    ELSE DROP
    THEN
    ;
: AsTable ( val u -- )
    ?DUP
    IF  LenDump /MOD \ количество полных строк (длиной LenDump) и хвост (<LenDump)
        ROT SWAP 0
        ?DO LenDump 2DUP TypeStrDump +  LOOP \ цикл по полным строкам
        SWAP TypeStrDump   \ допечатать хвост, если есть        
    ELSE DROP
    THEN  
    ;
: OperandToken ( adr-inst № -- xt)
    2DUP op.mask @ TO MASKA 
         op.exec @ 
    ;

: refind-opcode ( opcode adr-link -- adr-link' ) 
\ найти структуру по opcode начиная с текущего
    BEGIN @ 
          2DUP mask @ AND OVER clishe @ = \ поиск по клише
    UNTIL
    NIP
    ;       

: find-opcode ( opcode -- adr-link) \ найти структуру по opcode от начала 
    opcodes refind-opcode
    ;
: DeCombo ( adr -- adr" {S="mnemo op1,op2} )
\ выдать строку соответствующую содержимому opcode по adr
\ дизассемблировать код в opcode, выдать строку на строковом стеке
\ adr" адрес после взятой добавки
        W@+ TO opcode 
        opcodes ( adr' adr-link0 )  
        BEGIN \ для одного опкода может существовать несколько мнемоник (clr r0 == eor r0,r0)
            @ opcode  SWAP ( adr' opcode adr-link1 )
            refind-opcode    \ найти его статью ( adr' adr-link )
            OVER \  ( adr' adr-link adr')
            NEW>S   
            OVER   mnemo COUNT 6 n+>S \ напечатать мнемонику команды 
            запятая OFF    \ перед первым операндом запятую не ставить
            \ проверить ширину масок операндов
            OVER DUP 1 op.mask @ SWAP 2 op.mask @ OR
            0xFFFF > 
                \ взять добавку самостоятельно
                IF W@+ 
                   DUP TypeOpcode \ допечатать опкод, если нужен
                   opcode 16 LSHIFT  OR TO opcode 
                THEN
            \ выполнить операнды с проверкой
            OVER   1 OperandToken ( adr'  xtop )  CATCH  >R                     
            запятая ON     \ после первого операнда запятую уже можно ставить
            OVER   2 OperandToken   CATCH    R> OR                         
            ( adr' adr-link' adr" flag )
        WHILE DROP S>DROP \ cr ." оборот" cr
        REPEAT NIP NIP
    ; 
: AsCode ( val u --)
    DIS/ASM >R \ запомнить режим
    DIS! \ режим дизассемблирования
    OVER + SWAP
    ?DO (  )
        I DUP label-find ?DUP IF SetCurLabel THEN 
        DUP TypeVal \ напечатать адрес-смещение, если нужен
        SEG @ + \ текщий адрес ( adr0 ) 
        DUP @ TypeOpcode \ напечатать опкод, если нужен
        ( adr0 )
        DUP DeCombo 
        ( adr0 adr") 
        TypeLabel
        ( adr0 adr")
        \ напечатать команду и операнды
        PozMnemo GoPoz S@ TYPE S>DROP
        NewString \ CR \ закрыть строку
        ( adr0 adr+ )
        SWAP - \ вычисление сдвига по адресу 
    +LOOP ( )
    R> TO DIS/ASM \ востановить режим
    ;
: (dis) ( val u -- ) \ дизассемблировать область памяти  
    CurLabelType CodeType = 
    CurLabelType MarkType = OR
    IF AsCode ELSE AsTable THEN
    ;
\ ======== ГЛАВНЫЕ СЛОВА =======================================================
: Val_ ( val -- val'|0) \ дизасемблировать от смещения val, до следующей метки
    \ оформить текущее определение
    DUP label-find ?DUP IF SetCurLabel  ELSE ClearCurLabel THEN
    \ найти следующую метку определения
    DUP \ (val val )
    BEGIN 2+ \ val'
        DUP wender <
    WHILE    
        DUP label-find ?DUP
        IF label-type @ MarkType = ELSE TRUE THEN
    WHILE  REPEAT THEN
    \ вычислить размер текущего определения
    ( val val')  TUCK  OVER - ( val' val n )
    \ дизасемблировать текущее определение
    (dis) 
    ; 

: val? ( val -- ) \ показать определение
        Val_ DROP
        CR \ после участка кода идёт пустая строка, как визуальный разделитель
    ;
: vectors? ( -- ) \ распечатать поле векторов прерываний
    0 val?
    ;

: [LIST] ( val1 valLast -- ) \ дизассемблировать от val1 до valLast
        SWAP
        BEGIN Val_ 2DUP > \ пока не добрались до valLast
        WHILE CR REPEAT 2DROP

    ;
: LISTING ( --) \ дизассемблировать всё
    0 wender [LIST]
    ;
\eof
: see ( val -- ) \ показать ассемблер
    FALSE TO AddrOpcode?
    PozLabel PozMnemo
        0 TO PozLabel SizeAreaLabel TO PozMnemo
        ROT val?
    TO PozMnemo TO PozLabel
    TRUE TO AddrOpcode?
    ;
: seeAll ( -- ) \ показать ассемблер программы
    FALSE TO AddrOpcode?
    PozLabel PozMnemo
        0 TO PozLabel SizeAreaLabel TO PozMnemo
        LISTING
    TO PozMnemo TO PozLabel
    TRUE TO AddrOpcode?
    ;
\ ======== ТЕСТЫ И ПРИМЕРЫ =====================================================


