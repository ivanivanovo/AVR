\ инструментальные слова для удобства
DECIMAL

\ ------------------------------------------------------------------------------
: [FOUND?] ( "слово" -- f) \ узнать есть-ли такое слово, true - слово определено
    BL WORD FIND NIP  ;
: [NOT?] ( "слово" -- f) \ узнать есть-ли такое слово, true - слово НЕ определено
    [FOUND?] 0= ;
: [WITH?] [FOUND?] ['] [IF] EXECUTE ;
: [WITHOUT?] [NOT?] ['] [IF] EXECUTE ;

[WITHOUT?] CELL- : CELL- CELL - ; [THEN]
[WITHOUT?] 2+    : 2+ 2 + ; [THEN]
[WITHOUT?] /STRING    
    : /STRING ( adr u n -- adr' u')
        ROT OVER + -ROT - ; 
[THEN]
[WITHOUT?] OFF 
: OFF ( adr -- ) \ выключить переменную
    FALSE SWAP ! ; 
: ON  ( adr -- ) \ включить переменную   
    TRUE  SWAP ! ; 
[THEN]
[WITHOUT?] WARNING VARIABLE WARNING [THEN]
[WITHOUT?] 2VARIABLE : 2VARIABLE CREATE  2 CELLS ALLOT ; [THEN]
\ ------------------------------------------------------------------------------
\ Последовательность вида ( Un Un-1...U1 n ) в математике называется n-мерным 
\ вектором. Для оперирования с такими объектами ввел векторный стек, иначе -стек 
\ векторов. ( Un Un-1...U1 n--) помещается на именованый векторный стек как 
\ единый объект. Для работы с векторами определенной размерности, можно опре-
\ делить частные слова. 
\ Вектор изымается с V-стека также единым куском (-- Un Un-1...U1 n).
\ U VSTACK NameStack
\ a b c d 4 NameStack >STACK 
\ NameStack STACK>  ( --a b c d 4)

: VSTACK ( u "name" --) \ создать векторный стек "name" и зарезервировать
                        \ для него u ЯЧЕЕК 
    CREATE HERE 2 CELLS + , CELLS HERE OVER + CELL+ , 0 , 
    ALLOT ;               \                          \   \дно
                           \ указатель (адрес)        \ограничитель(макс. адрес)
\ Запись "a b c d 4 NameStack >STACK" размещает в памяти так:
\ ПАМЯТЬ: указатель ограничитель 0 ....  a b c d 4.....|
\ NameStack ---^ v     v                         ^     ^
\                |     |-------------------------+-----|
\                |-------------------------------|

: >STACK ( x*i x*u u name -- x*i ) \ переместить u элементов в стек "name"
    OVER 0= IF 2DROP EXIT THEN
    DUP >R @ CELL+ \ начальный адрес 
    OVER CELLS  OVER + \ конечный адрес
        DUP  R@ CELL+ @ > ABORT" Переполнение v-стека."
    DUP >R         2DUP > ABORT" Только положительное число."
    DO I ! CELL NEGATE +LOOP 
    R> R> !
    ;
: STACK@ ( name -- x*n n) \ вернуть из стека name последнюю запись
    @ DUP @ ?DUP 0= ABORT" Исчерпание v-стека." 
    1+ CELLS SWAP CELL+ DUP ROT -
    DO I @  CELL +LOOP 
    ;
: STACK> ( name -- x*n n) \ снять со стека name последнюю запись
    DUP >R 
    STACK@  
    DUP 1+ CELLS R@ @ SWAP - R> !
    ;
: STACK>DROP ( name -- ) \  убрать со стека name последнюю запись
    DUP @ DUP @ ?DUP 0= IF 2DROP EXIT THEN
    1+ CELLS - SWAP !
    ;   
\ ------------------------------------------------------------------------------
256 VSTACK V \ общий v-стек
: >V ( i*n n --) \ положить в v-стек n элементов
    V >STACK ;
: V> ( -- i*n n) \ снять с v-стека последнюю запись    
    V STACK> ;
: V@ ( -- i*n n) \ вернуть с v-стека последнюю запись
    V STACK@ ;
: V>DROP ( --) \ убрать с v-стека последнюю запись
    V STACK>DROP ;
\ частные слова для работы с двумерными векторами ( adr u строки например)
: 2>V ( a b --) 2 >V ; : 2Vcheck ( n --) 2 = 0= ABORT" Ошибка на V-стеке." ;
: 2V> ( -- a b) V> 2Vcheck ; : 2V@ ( -- a b) V@ 2Vcheck ; 
: 1>V ( a --) 1 >V ; : 1Vcheck ( n --) 1 = 0= ABORT" Ошибка на V-стеке." ;
: 1V> ( -- a ) V> 1Vcheck ; : 1V@ ( -- a ) V@ 1Vcheck ; 

\ ------------------------------------------------------------------------------
\ Строчный стек. Позволяет сохранять и востанавливать строки, а так же 
\ "склеивать" их.
1024 CELL / VSTACK S
\ Запись S" abcd" >S размещает в памяти так:
\ ПАМЯТЬ: указатель ограничитель 0 ....  abcd 4 ..........|
\     S -------^ v     v                      ^           ^
\                |     |----------------------+------ ----|
\                |----------------------------|
\ Следующая запись S" klm" >S размещает в памяти так:
\ ПАМЯТЬ: указатель ограничитель 0 ....  abcd 4 klm 3 ....|
\     S -------^ v     v                            ^     ^
\                |     |----------------------------+-----|
\                |----------------------------------|

: overS? ( adr -- ) S CELL+ @ > ABORT" Переполнение s-стека." ;
: emptyS? ( adr --) S 3 CELLS + < ABORT" Исчерпание s-стека." ;
: >S ( adr u --) \ скопировать строку в s-стек 
    S @ CELL+ TUCK OVER + \ a a1 u a1+u
    DUP >R overS? DUP >R
    CMOVE 
    R> R@ ! R> S ! ; 
: +>S ( adr u --) \ добавить строку к строке в s-стеке
    S @ TUCK OVER + \ a a1 u a1+u 
    DUP >R overS? OVER @ OVER + >R
    CMOVE
    R> R@ ! R> S ! ;
WARNING @ WARNING OFF
: S@ ( --- adr u) \ выдать реквизиты строки в s-стеке
    S @ DUP @ SWAP OVER - DUP emptyS? SWAP ;
WARNING !

: S+S ( -- ) \ склеить строку в s-стеке с предыдущей строкой 
     S@ OVER CELL- DUP emptyS? S ! ( adr u )
     +>S ;
: S>DROP ( -- ) \ снять строку с s-стека
    S@ DROP CELL- S ! ; 
\ некоторые мои слова имеют скверную привычку дозаписывать строки по месту их нахождения
\ что сбивает S-стек с толку.
\ поэтому таким словам нужно скармливать копию строки
: S> ( -- adr u) \ снять строку со стека и скопировать в PAD
    S@ >R PAD R@ CMOVE PAD R>
    S>DROP
    ;
: NEW>S ( --) S @  CELL+ 0 OVER ! S ! ; \ забить новую строку
: EMIT>S ( c -- ) \ добавить символ к строке в s-стеке
    S @  DUP @ 1+ OVER 1+ DUP >R ! C! R> S !
    ;
: SDUP ( S: str -- S: str str  ) \ дублировать строку на S-стеке
    S@ >S ;
: #>S ( # -- S:"###" ) \ положить число в символьном виде на s-стек
     S>D <# #S #> >S
     ;    
: 0>S ( -- ) \ закрыть строку нулем
    0 EMIT>S
    ;
\ ------------------------------------------------------------------------------
 32 VSTACK VOCS \ стек словарей
: SAVE-VOCS ( -- )  \ сохранить текущее состояние словарей
    GET-CURRENT GET-ORDER 1+ ( wid-c wid-n ... wid1 n+1 )
    \ >V ; 
     VOCS >STACK ; 
: RESTORE-VOCS ( --) \ востановить предыдущее состояние словарей
   \ V> 
    VOCS STACK> 
    1- SET-ORDER SET-CURRENT ;

\ ------------------------------------------------------------------------------
[WITHOUT?] BINARY : BINARY  2 BASE ! ; [THEN]

\ ------------------------------------------------------------------------------
\ 10 VSTACK BASES \ стек для хранения систем счисления
\ : BASE: CREATE , DOES> @ BASE @ 1 BASES >STACK  BASE ! ;
\ : :BASE CREATE   DOES> DROP BASES STACK> DROP BASE ! ;
: BASE: CREATE , DOES> @ BASE @ 1 >V  BASE ! ; \ определяющее слово
: :BASE CREATE   DOES> DROP V> DROP BASE ! ;   \ определяющее слово
16 BASE: HEX[ \ временно работаем в шестнадцатеричной системе  
        :BASE ]HEX \ востановить предыдущую систему
10 BASE: DEC[ \ временно работаем в десятичной системе  
        :BASE ]DEC \ востановить предыдущую систему
 8 BASE: OCT[ \ временно работаем в восеричной системе  
        :BASE ]OCT \ востановить предыдущую систему
 2 BASE: BIN[ \ временно работаем в двоичной системе  
        :BASE ]BIN \ востановить предыдущую систему
: .BIN  ( n -> ) BIN[ .  ]BIN ; \ вывести число в двоичной форме
: .UBIN ( n -> ) BIN[ U. ]BIN ; \ вывести беззнаковое число в двоичной форме
: .OCT  ( n -> ) OCT[  . ]OCT ; \ вывести число в восьмеричной форме
: .UOCT ( n -> ) OCT[ U. ]OCT ; \ вывести беззнаковое число в восьмеричной форме
: .DEC  ( n -> ) DEC[  . ]DEC ; \ вывести в десятичной форме
: .UDEC ( n -> ) DEC[ U. ]DEC ; \ вывести беззнаковое число в десятичной форме
: .HEX  ( n -> ) HEX[  . ]HEX ; \ вывести число в шестнадцатиричной форме
: .UHEX ( n -> ) HEX[ U. ]HEX ; \ вывести беззнаковое число в шестнадца-ой форме

: asNum ( "str" -- n ) \ преобразовать строку в число
    0 S>D BL WORD COUNT >NUMBER 2DROP D>S ;
: HEX> ( "str" -- n) \ взять число как шестнадцатеричное
    HEX[ asNum ]HEX ; IMMEDIATE 
: 0x [COMPILE] HEX> ; IMMEDIATE 
: 0h [COMPILE] HEX> ; IMMEDIATE  
: BIN> ( "str" -- n) \ взять число как двоичное
    BIN[ asNum ]BIN ; IMMEDIATE 
: OCT> ( "str" -- n) \ взять число как восмеричное
    OCT[ asNum ]OCT ; IMMEDIATE 
: DEC> ( "str" -- n) \ взять число как десятичное
    DEC[ asNum ]DEC ; IMMEDIATE 

\ ------------------------------------------------------------------------------
[WITHOUT?] W! 
HEX[
: W! ( cc addr -- ) \ записать два байта как число
    OVER 0FF AND OVER C! 
    SWAP 0FF00 AND 8 RSHIFT SWAP 1+ C!  
    ;
]HEX
[THEN]    

[WITHOUT?] W@ 
HEX[
: W@ ( addr -- cc) \ взять два байта как число
    @ 0FFFF AND 
    ;
]HEX
[THEN]    
: W@+ ( adr -- adr+2 w) \ w@ с постинкрементом указателя 
    DUP 2+ SWAP W@ 
    ;
: C@+ ( adr -- adr+1 c) \ чтение символа с постинкрементом адреса
    DUP 1+ SWAP C@ 
    ;
: ,R ( n1 n2 -- adr u)
    OVER 0< DUP >R IF  SWAP NEGATE SWAP THEN
    SWAP <# 0 #S #>
    ROT OVER - R@ IF 1- THEN \ adr u n2-u
    DUP 0 > IF 0 DO SPACE LOOP 
            ELSE DROP THEN 
    R> IF ." -" THEN
     ;
[WITHOUT?] .R 
: .R ( n1 n2 --) \ форматный ввывод числа n1, вправо в поле с n2 позициями)
    ,R TYPE ;
[THEN]
\ [WITHOUT?] VECT 
\ Простейшая реализация векторизаци кода
\ : VECT ( "name"--) CREATE 0 , DOES> @ EXECUTE ;
\ : VECT> ( xt --)    BL WORD FIND IF >BODY ! THEN ;    
\ [ELSE] : VECT> ( xt --) [COMPILE] TO ;    
\ [THEN]    

[WITHOUT?] DEFER  \ реализация из стандарта 200х
: DEFER ( "name" -- )
    CREATE ['] ABORT ,
    DOES>   @  EXECUTE ;
: DEFER! ( xt2 xt1 -- )
     >BODY ! ;
: DEFER@ ( xt1 -- xt2 )
     >BODY @ ;
: IS ( xt " <spaces> name" -- )
    STATE @ 
    IF POSTPONE ['] POSTPONE DEFER!
    ELSE  ' DEFER!
    THEN ; IMMEDIATE
[THEN]

: ,0R ( n1 n2 -- adr u)
    \ преобразует число n1 в строку, с ведущими нулями в поле размером n2
    SWAP 0 ROT 
    <# 0 DO # LOOP #> ;
: .0R ( n1 n2 --) 
    \ печатать число n1 с ведущими нулями в поле размером n2
    ,0R TYPE
    ;  

: #bits ( n --i) \ подсчитать число значащих бит в числе
    2* 0  
    BEGIN \ n i
        SWAP 1 RSHIFT ?DUP WHILE SWAP 1+ 
    REPEAT
    ;
 
: EMIT_ASCII ( n -- ) \ напечатать n как символ ASCII
    DUP BL < IF DROP ." ."
             ELSE DUP 127 < 
                IF EMIT ELSE DROP ." ?" THEN
             THEN
    ;
: TYPE_ASCII ( adr u --) \ распечатать байты как ASCII символы
    OVER + SWAP
    DO  I C@ EMIT_ASCII LOOP
    ;

HEX[
: WORD-SPLIT ( n -- lo hi) \ разбить на слова (2байта)
    DUP 0FFFF AND SWAP 0FFFF0000 AND  10 RSHIFT ;
: (LW) WORD-SPLIT DROP ;    \ выделить младшее слово
: (HW) WORD-SPLIT NIP ;     \ выделить старшее слово

: BYTE-SPLIT ( n -- lo hi)  \ разбить на байты
    DUP 0FF AND SWAP 0FF00 AND  8 RSHIFT ;
: (LB) BYTE-SPLIT DROP ;    \ выделить младший байт
: (HB) BYTE-SPLIT NIP ;     \ выделить старший байт

: UTF? ( w -- f) \ истина если двухбайтное число похоже на UTF
    0C0C0 AND 080C0 = ;
: SYMBOLS ( adr u - u1) \ число символов в строке
    \ подсчёт именно СИМВОЛОВ, а не байт
    DUP -ROT
    OVER + SWAP
    ?DO I C@  7F > \ если не ASCII
        IF I W@ UTF? \ если UTF
           -1 AND + \ уменьшить счётчик символов 
        THEN 
    LOOP
    ; 
]HEX
: UTF8-CASEv ( -- adr u ) \ русские символы нижнего регистра
    S" йцукенгшщзхъфывапролджэячсмитьбюё" ;
: UTF8-CASE^ ( -- adr u ) \ РУССКИЕ СИМВОЛЫ ВЕРХНЕГО РЕГИСТРА
    S" ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮЁ" ;

S" ~iva/AVR/KOI8-R.f" INCLUDED
\ S" ~iva/AVR/WIN1251.f" INCLUDED
\ S" ~iva/AVR/CP866.f" INCLUDED

WARNING @ WARNING OFF
: CHAR-UPPERCASE ( c -- c1 ) 
\ подмена однобайтного символа версией верхнего регистра
  \ для правильной работы с символами не ASCII
  \ требуется подключить файл нужной кодировки
  DUP [CHAR] a [CHAR] z 1+ WITHIN IF 32 - EXIT THEN
  STR-CASEv 0
  ?DO 
    2DUP I + C@ = 
        IF 2DROP STR-CASE^ DROP I + C@ UNLOOP EXIT  THEN
  LOOP  DROP
;

: UPPERCASE ( addr1 u1 -- ) \ работает с однобайтными символами
  OVER + SWAP ?DO
    I C@ CHAR-UPPERCASE I C!
  LOOP ;

WARNING !

: CASE^ ( adr u --) \ перевести строку в верхний регистр
    UPPERCASE \ НЕ работает с русскими в UTF8
    ;
: WCHAR-UPPERCASE ( wc -- wc1 ) 
\ подмена двухбайтного символа версией верхнего регистра
    UTF8-CASEv 0
    DO 2DUP I + W@ =
        IF 2DROP UTF8-CASE^ DROP I + W@ UNLOOP EXIT  THEN
    LOOP DROP   
    ;

: UPPERCASE-W ( addr1 u1 -- ) \ работает с однобайтными и 2х-байтными символами
    OVER + SWAP
    ?DO I W@ UTF? \ если UTF 
        IF   I W@ WCHAR-UPPERCASE I W!
        ELSE I C@  CHAR-UPPERCASE I C!
        THEN
    LOOP    
;   
\ S" ЖерБёнок-Funt" 2dup UPPERCASE-W type cr

: BETH ( n a b -- f) \ true если a<=n<=b или b<=n<=a
    2DUP MIN -ROT MAX
    >R OVER > SWAP R> > OR 0= ; 

[WITHOUT?] ASCIIZ>  
: ASCIIZ> ( c-adr -- adr u) \ преобразовать представление строки с нулём на 
                          \ конце, в нормальное
        DUP BEGIN DUP C@ WHILE 1+ REPEAT OVER - ;
[THEN]
: ASCIIZ>> ( c-adr u -- adr1) \ c-adr начальный адрес строки с кучей нулей на конце,
    \  adr1 -первый выровненный адрес с ненулевым содержанием
    + ALIGNED \ выровненный адрес после строки с нулём
    BEGIN DUP @ 0= WHILE CELL+ REPEAT 
    ;
: FindWord ( adr u -- 0 | xt 1| xt -1) \ ищет слово в всех словарях из списка поиска
    2>R \ сохранить имя
    GET-ORDER \ получить список словарей
    BEGIN DUP \ пробег по словарям
        WHILE \ пока есть словари
        1- SWAP 2R@ ROT SEARCH-WORDLIST ?DUP 
    UNTIL \ пока не найдёт
    \ найдено
    2>R \ сохранить результат
    0 ?DO DROP LOOP \ удалить остаток списка
    2R> \ восстановить результат 
        THEN \ словари кончились, поиск не удался
    2R> 2DROP \ удалить имя
    ;
VARIABLE CurVoc
: FindVoc ( adr u -- 0 | wid) \ ищет слово в всех словарях, возвращает id словаря
    2>R \ сохранить имя
    
    GET-ORDER  \ получить список словарей
    BEGIN DUP \ пробег по словарям
        WHILE \ пока есть словари
        1- SWAP 2R@ ROT \ подготовиться к поиску
            DUP CurVoc ! \ запомнить id где ищем
            SEARCH-WORDLIST \ ищем
            DUP IF TRUE ELSE  0 CurVoc ! THEN \ не нашли - забываем
    UNTIL \ пока не найдёт
    \ найдено
    2DROP \ удалить результат
    0 ?DO DROP LOOP \ удалить остаток списка
        THEN \ словари кончились, поиск не удался
    2R> 2DROP \ удалить имя
    CurVoc @
    ;
[WITH?] VOC-NAME.
: FindVoc. ( adr u -- ) \ найти слово и напечатать имя словаря, где найдено
    FindVoc ?DUP IF VOC-NAME. ELSE ." Не найдено." THEN
    ;
[THEN]
: 3DUP ( a b c -- a b c a b c )
    >R 2DUP R@ -ROT R> ;
: COUNTER: ( n "name" -- ) \ создать счетчик с именем name и начальным значением n
\ при каждом вызове этого слова выдается новое значение на 1 больше предыдущего
    CREATE , DOES> DUP @ SWAP 1+!  ;

WARNING @ WARNING OFF
: str! ( adr u --) \ поместить строку, как строку со счётчиком по HERE
    -TRAILING \ обрезать хвостовые пробелы
    HERE >R  
    DUP 1+ ALLOT \ a u  
    DUP R@ C! \ a u
    R> 1+ SWAP  CMOVE 
    ;
WARNING !


: #def ( <name строка.... > -- ) \ запомнить строку под именем name
    \ при исполненни name - выполнить строку  
    CREATE  \ выделяем name, создаём статью
        10 PARSE str!   \ выделяем и сохраняем остаток строки 
        IMMEDIATE       \ новое слово будет немедленным
    DOES> COUNT  EVALUATE  ; \ прочитать строку и выполнить

: see#def ( <name_def> -- ) \ показать определение #def
    ' >BODY COUNT TYPE ;
\ Примеры:
\ #def +C5.  C5 + . \ макрос с еще неопределенным макросом (C5) внутри
\ #def C5 2 3 +     \ определение простого макроса C5
\ #def основа 10    \ значение зависит от системы счисления на момент выполнения

\ #def naa : aa ." AA" cr ; \ определение слова в макросе


: MACROS ( adr u <name> --) \ запомнить строку под именем name
    \ при исполненни name - выполнить строку
    CREATE HERE OVER DUP 1+ ALLOT ALIGN \ резервируем место под строку со счётчиком
        OVER C!         \ запомним u
        1+ SWAP CMOVE   \ сохраним строку
        IMMEDIATE       \ новое слово будет немедленным
    DOES> COUNT EVALUATE ; \ прочитать строку и выполнить

\ S" 4 3 + . " MACROS M7. \ без параметров
\ M7.  cr
\ S" + . CR " MACROS сложить   \ с параметрами 
\ 4 6 сложить


: (DUMP) ( adr u -- ) \ распечатать дамп в заданых границах 
    \ с выровненными адресами
    ?DUP IF
        HEX[
            OVER + SWAP \ отображаемые адреса
            2DUP 
            -16 AND
            DO
                I 255 AND 0= IF CR THEN
                I 15  AND 0= IF CR I . SPACE THEN
                I 3   AND 0= IF ."  " THEN
                2DUP I -ROT BETH
                IF I C@ 2 .0R SPACE ELSE ." -- " THEN
            LOOP 2DROP
        ]HEX
    ELSE DROP ." Пусто." 
    THEN CR
    ;
