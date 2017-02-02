\ структура меток
\ автор: ~iva дата: 2010 ревизия: 1
\ ======== ИНФО ================================================================
\ В микроконтроллерах различают 3 вида памяти (по методу доступа): 
\ ROM - память программ, 
\ RAM - память для записи и чтения, в AVR сюда попадают регистры, порты, 
\       собственная память и внешняя память (если есть), 
\ EPROM - энергонезависимая память для записи и чтения.
\ В дополнение к этим трем сегментам, считаю целесообразным выделение отдельного
\ сегмента для доступа к битам портов и регистров - BIT.
\
\ Все сегменты имеют начальный адрес, размер и указатель свободного элемента.
\ Любой адрес в любом сегменте может иметь собственное имя, метку, label. Так 
\ как имена можно (и нужно) давать уникальными, то все метки можно собрать в 
\ одном словаре. По имени метки можно получить её значение (адрес в некотором 
\ сегменте), однако по значению нельзя однозначно определить имя метки (нужно 
\ для дизассемблировании), так как адреса в разных сегметах могут совпадать.
\ Что бы избежать наложения имен при обратном поиске по метке каждый сегмент 
\ имеет свою цепочку.
\ Метки собираются в словаре ASMLABELS как VALUE, т.е. при исполнении оставляют  
\ на стеке значение данное на момент определения, а также увеличивается счётчик
\ использования слова-метки (это пригодится для вычленения "мертвого" кода).  
\ Метку так же можно определить и по значению, для этого производится проход по 
\ цепи labels текущего контекста до первого совпадения или до её конца (link=0).
\
\ 28.13.2010
\ Для удобства программирования чипа решил вести ещё сегменты Fuses и Locs
\
\ структура меток
\ ==============================================================================
\ label: метка     
\ ============================================================== слова доступа==
\ adr               поле связи (link)   CELL обязательно            @
\ value             значение метки      CELL обязательно            label-value
\ type              тип метки           CELL обязательно            label-type
\ count             счетчик вызовов     CELL обязательно            label-count
\ u"метка"          имя метки           C-STRING обязательно        label-name
\ ======== КОНСТАНТЫ И ПЕРЕМЕННЫЕ ==============================================

\  23.01.2014 регистры помечаются 1 в старшем бите cell
-1 1 RSHIFT CONSTANT fRegMask \ маска для гашения флага-признака регистра
fRegMask INVERT CONSTANT fReg \ флаг-признак регистра
: +fReg ( n -- fn) \ приклеить к числу признак регистра
    fReg OR ;
: -fReg ( fn -- n ) \ отклеить признак регистра
    fRegMask AND ;     
\  23.01.2014


S" ~iva/AVR/buffers.f" INCLUDED \ создание и работа с сегментами и другое

: labels ( --adr)     \ адрес начала контекстной цепочки меток
    seg-labels  ;
VOCABULARY ASMLABELS   \ словарь меток
VOCABULARY BITS        \ отдельный словарь для именованных битов 
VOCABULARY FUSES       \ отдельный словарь для именованных фузов 
VOCABULARY LOCKS       \ отдельный словарь для именованных локов 
\ ======== СЛУЖЕБНЫЕ СЛОВА ДЛЯ ОПРЕДЕЛЕНИЯ ГЛАВНЫХ СЛОВ ========================
: KB ( n -- n*1024) \ ка-байт
    1024 * ;
0 1 KB createSeg: ROM-SEG
0 1 KB createSeg: RAM-SEG
0 1 KB createSeg: EPROM-SEG
\ 0 0   createSeg: BIT-SEG \ нулевого размера, только для меток
CREATE BIT-SEG RAM-SEG HERE 6 CELLS DUP ALLOT MOVE S" BIT-SEG" str!
0 8 createSeg: FUSE-SEG \ 8 байт, с запасом
0 2 createSeg: LOCK-SEG \ 2 байта, с запасом

: ROM   ( ) ROM-SEG TO SEG ; \ определение контекста сегмента ROM
: .CSEG ROM ;
: RAM   ( ) RAM-SEG TO SEG ; \ определение контекста сегмента RAM   
: .DSEG RAM ;
: EPROM ( ) EPROM-SEG TO SEG ; \ определение контекста сегмента EPROM
: .ESEG EPROM ;
: BIT   ( ) BIT-SEG TO SEG ; \ определение контекста сегмента BIT
: FUSE  ( ) FUSE-SEG TO SEG ; \ определение контекста сегмента FUSE
: LOCK  ( ) LOCK-SEG TO SEG ; \ определение контекста сегмента LOCK

: SAVE-SEGMENT ( )    SEG 1 >V ;
: RESTORE-SEGMENT ( ) V> DROP TO SEG ;
: ROM[   SAVE-SEGMENT ROM   ; : ]ROM    RESTORE-SEGMENT ;
: RAM[   SAVE-SEGMENT RAM   ; : ]RAM    RESTORE-SEGMENT ;
: EPROM[ SAVE-SEGMENT EPROM ; : ]EPROM  RESTORE-SEGMENT ;
: BIT[   SAVE-SEGMENT BIT   ; : ]BIT    RESTORE-SEGMENT ;

: <BITS   SAVE-VOCS  ALSO BITS DEFINITIONS ; \ временно подключить словарь битов
: BITS>    RESTORE-VOCS ;
: <LABELS SAVE-VOCS  ALSO ASMLABELS DEFINITIONS ; \ временно подключить словарь меток
: LABELS>  RESTORE-VOCS ;
: <FUSE   SAVE-VOCS  ALSO FUSES DEFINITIONS ; \ временно подключить словарь FUSES
: FUSE>    RESTORE-VOCS ;
: <LOCK   SAVE-VOCS  ALSO LOCKS DEFINITIONS ; \ временно подключить словарь LOCKS
: LOCK>    RESTORE-VOCS ;

: FUSE[  SAVE-SEGMENT FUSE  <FUSE ; : ]FUSE  FUSE> RESTORE-SEGMENT ;
: LOCK[  SAVE-SEGMENT LOCK  <LOCK ; : ]LOCK  LOCK> RESTORE-SEGMENT ;

FUSE[ SEG @ seg-size @ TRUE FILL ]FUSE  \ заполнить сегмент единицами
LOCK[ SEG @ seg-size @ TRUE FILL ]LOCK  \ заполнить сегмент единицами

ROM \ проинициализируем  

: label-value ( adr-link -- adr-value) CELL+ ;
: label-type  ( adr-link -- adr-type)  label-value CELL+ ;
: label-count ( adr-link -- adr-count) label-type  CELL+ ;
: label-name  ( adr-link -- c-adr)     label-count CELL+ ;
: labelA      ( adr-link -- adr) \ получить адрес метки в памяти
    label-value @ SEG @ + ;

: label-FirstFind  ( n -- adr-link | 0 ) 
\ найти первое совпадение, последним определенное
\ найти метку, которая была определена самой последней
    labels 
    BEGIN @ DUP WHILE ( n adr')
        2DUP label-value @ = IF NIP EXIT THEN \ проход по списку до совпадения 
    REPEAT NIP ; 

VARIABLE last-label
: label-LastFind  ( n -- adr-link | 0 )
\ найти последнее совпадение, первым определенное
\ найти метку, которая была определена самой первой
    0 last-label !
    labels 
    BEGIN @ DUP WHILE ( n adr')
        2DUP label-value @ = IF DUP last-label ! THEN 
    REPEAT 2DROP \ проход по списку до конца 
    last-label @  ;

 : label-find label-LastFind ;
\ : label-find label-FirstFind ;

: str>label ( adr u --adr-link|0) \ поиск метки по имени в текущем сегменте
    >S                            \ 0 - если не найдено 
    labels 
    BEGIN @ DUP WHILE
        DUP label-name COUNT S@ COMPARE 0 = IF  S>DROP   EXIT THEN
    REPEAT
    DROP
    \ повторим попытку, но уже ВСЕ СТРОКИ ПЕРЕВЕДЁМ В ВЕРХНИЙ РЕГИСТР
    S@ UPPERCASE-W \ искомое в верхний регистр
    labels 
    BEGIN @ DUP WHILE
        DUP label-name 
        DUP COUNT 1+ NIP PAD SWAP CMOVE   \ текущее скопируем в PAD
        PAD COUNT 2DUP UPPERCASE-W        \ так же в верхний регистр
        \ сравнение строк в верхнем регистре    
        S@ COMPARE 0 = IF  S>DROP   EXIT THEN 
    REPEAT
    S>DROP 
    ;
: name>label ( "name" -- adr-link|0) \ поиск метки по имени в текущем сегменте
    BL WORD COUNT str>label ;        \ 0 - если не найдено 
    
: label>name ( n -- adr u | 0 0 )
    label-find DUP IF label-name COUNT ELSE  0 THEN ;   

: Label_ ( type n --) \ создать структуру метки без имени
    labels @ HERE labels ! 
    ,   \ поле связи
    ,   \ значение метки n
    , \ тип метки
    0 , \ счетчик вызовов
    ;
: Nick ( type n "name" --) \ создать структуру метки "name"
    Label_ BL WORD COUNT str!  \ имя метки
    ;

: !label: ( type n "name" --) \ создать слово и структуру метки "name"
    >IN @ CREATE >IN ! Nick
          DOES> DUP label-count 1+! \ увеличить счётчик вызовов
                    label-value @   \ выдать значение 
    ;
: !label(S): ( type n adr u  --) \ создать слово и структуру метки с именем из строки adr u
    S" !label: " >S +>S
    S@ EVALUATE S>DROP
    ;

: label: ( type "name" --) finger !label: ;
0 CONSTANT CodeType
1 CONSTANT DataType
2 CONSTANT RegType
3 CONSTANT PortType
4 CONSTANT BitType
5 CONSTANT MarkType \ внутренняя метка

: data: ( "name" --) DataType label: ;
: TypeName ( type -- adr u)
        DUP CodeType = IF DROP S" Code " ELSE  
        DUP DataType = IF DROP S" Data " ELSE  
        DUP RegType  = IF DROP S" Reg  " ELSE  
        DUP PortType = IF DROP S" Port " ELSE  
        DUP BitType  = IF DROP S" Bit  " ELSE
            MarkType = IF      S" mark "
                THEN THEN THEN THEN THEN THEN  
    ;
: label-show ( label -- n t| adr u f) \ показать содержимое объекта метки
    DUP label-type @ 
    DUP  CodeType = 
    OVER DataType = OR
    OVER MarkType = OR
        IF NIP TypeName FALSE EXIT THEN
    DUP  RegType  =
    OVER PortType = OR
        IF TypeName TYPE label-value  @ -fReg SEG @  + C@ TRUE   EXIT THEN
    DUP  BitType  =
        IF TypeName TYPE label-value @ -fReg 8 /MOD SEG @   + C@ 1 ROT LSHIFT AND 0<> 1 AND ( IF 1 ELSE 0 THEN) TRUE EXIT THEN
    DROP S" ???  " FALSE
    ;
: take ( n <name>--) \ зарезервировать n байт под именем name
    DataType label: finger>
    ;
: array take ;
: Allot_b ( <name>--) \ зарезервировать байт под именем name
     1 array ;
: Allot_w ( <name>--) \ зарезервировать слово под именем name
     2 array ;

: labels-map ( --) \ показывает метки в текущем сегменте
 CR 
 ."  ===========" seg-name COUNT DUP -ROT TYPE 19 SWAP - 0 DO ." =" LOOP CR   
 ."  adr--|---name--|type- |val |st" CR
 ."  ------------------------------" CR
    labels 
    BEGIN @ DUP WHILE
        DUP label-type @ MarkType <> 
        IF  DUP label-value @ -fReg 5 .R  2 SPACES
            DUP label-name COUNT 2DUP SYMBOLS >R TYPE 10 R> - SPACES 
            DUP label-show ." =" IF 3 .R 2 SPACES ELSE DUP -ROT TYPE 10 SWAP - SPACES THEN 
            DUP label-count @ 3 .R  CR
        THEN
    REPEAT DROP
    ;
: labels-maps ( -- ) \ вывод меток во всех сегментах
          ROM[ labels-map ]ROM
          RAM[ labels-map ]RAM
        EPROM[ labels-map ]EPROM
          BIT[ labels-map ]BIT
         FUSE[ labels-map ]FUSE
         LOCK[ labels-map ]LOCK
    ;

    
