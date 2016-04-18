S" lib/include/float.f" INCLUDED
\ вычисление таблиц
S" 3.141592653E0" >FLOAT 0= THROW FCONSTANT PI
PI FDUP F+ FCONSTANT 2PI

: S>F ( n --) ( F: -- r)
    S>D D>F ;
: F>S ( -- n) ( F: r -- ) 
    F>D D>S ;
: Sin ( n m --) ( F: -- r) \ энный отсчёт из m отсчётов по кругу 360град.
    2PI S>F F/
    S>F F* FSIN
    ;
: SinPi ( n m --) ( F: -- r) \ энный отсчёт из m отсчётов за полпериода.
    PI S>F F/
    S>F F* FSIN
    ;
: [Sin] ( min max -- ) ( F: r1-- r2) \ min<=r2<=max      
    OVER - 2/ DUP S>F F* + S>F F+   ;
: TabSin ( min max # -- adr u ) \ выдать # значений [синуса]
    NEW>S
    DUP 0 
    DO  I OVER Sin >R 2DUP [Sin] R> FROUND F>S 
        PAD C! PAD 1 +>S   
    LOOP DROP 2DROP S@ S>DROP ;

: TabSinPi ( Max # -- adr u ) \ выдать # значений полупериода [синуса]
    NEW>S
    DUP 0 
    DO I 1+ OVER SinPi OVER s>f F*  FROUND F>S 
       PAD C! PAD 1 +>S    
    LOOP 2DROP S@ S>DROP
    ;

: TabMeandr ( min max # -- adr u ) \ выдать # значений [меандра]
    NEW>S
    DUP 0 
    DO  ( min max #) i over 2/ > if over else rot dup >r -rot r> then
        PAD C! PAD 1 +>S   
    LOOP DROP 2DROP S@ S>DROP ;

: [Tre] ( min max -- ) ( F: r1-- r2) \ min<=r2<=max      
    over - s>f f* s>f f+   ;

: Tre ( n m --) ( F: -- r) \ энный отсчёт из m отсчётов [0/n\m] 
    over 4 * s>f dup  s>f f/ ( F: 4n/m)
    2DUP 4 / > 
    if  3 * 4 / >
        IF 4 S>F F-
        ELSE 2 s>f fswap f- 
        THEN
    ELSE 2DROP
    then  \ fdup f.
    ;
: TabTre ( min max # -- adr u ) \ выдать # значений [треугольник]
    NEW>S
    DUP 0 
    DO  i over tre >R 2DUP [Sin] R> FLOOR F>S
        PAD C! PAD 1 +>S   
    LOOP  DROP 2DROP S@ S>DROP ;
: Pil ( n m --) ( F: -- r) \ энный отсчёт из m отсчётов [0/n|m] 
    swap s>f  s>f f/
 \   fdup f.
    ;
: TabPil ( min max # -- adr u ) \ выдать # значений [пила]
    NEW>S
    DUP 0 
    DO  i over Pil >R 2DUP [tre] R> FROUND F>S
        PAD C! PAD 1 +>S   
    LOOP  DROP 2DROP S@ S>DROP ;
    
: F^ ( r1 r2 -- r1^r2 ) \ возведение в степень
    FSWAP FLN F* Fexp 
    ;
: _TabExp_ ( a b n <newstr> -- ) ( Str: table) \ выдать экспоненту как таблицу из n точек от а<>0 до b
    \ если a<b - возрастающая экспонента
    \ если a>b - спадающая экспонента
    \ если a=b - горизонтальная прямая
    \ y(i)=a*(b/a)^(i/n), где i=[0..n]
    -ROT 2DUP 2>R OVER s>f s>f s>f  F/ ( D: n) ( F: a b/a)
    DUP 1 s>f s>f F/ F^ \ ( D: n) ( F: a (b/a)^1/n ) 
    FSWAP 
    2R>  
    >   IF FDUP FROUND f>s PAD C! PAD 1 +>S
             1 
        ELSE 0 THEN
    DO FOVER F* FDUP FROUND f>s PAD C! PAD 1 +>S 
    LOOP FDROP FDROP 
    ;
: TabExp ( a b n -- adr u ) \ выдать экспоненту как таблицу из n точек от а<>0 до b
    NEW>S _TabExp_ S@ S>DROP ;
    
: _TabLog_ ( a b n <newstr> -- ) ( Str: table) \ выдать логарифмичеускую кривую как таблицу из n точек от а<>0 до b
    \ 0<a<b - возрастание по логарифмическому закону
    \ Y(i)=b*(ln(i)-ln(a))/(ln(n)-ln(a)) = b*ln(i/a)/ln(n/a) =  b*log(i/a;n/a)
    \
    \ иной вариант (a может равнятся 0)
    \ Y(i)=(b-a)*ln(i)/ln(n)+a     
    \ 0<=a<b - возрастание по логарифмическому закону
    >R OVER - s>f R> \ (D: a n ) ( F: b-a)
    DUP s>f FLN F/ \ ( F: (b-a)/ln(n))
    0 DO \ (D: a n ) ( F: (b-a)/ln(n))
        I 1+ s>f FLN FOVER F* FROUND f>s   
        OVER + 
        PAD C! PAD 1 +>S
    LOOP FDROP DROP 
    ;
: TabLog ( a b n -- adr u ) \ выдать логарифмичеускую кривую как таблицу из n точек от а<>0 до b
    NEW>S _TabLog_  S@ S>DROP ; 
: TabLog\ ( a b n -- adr u ) \ выдать логарифмичеускую кривую как таблицу из n точек от а>b до b
    NEW>S 
    -ROT SWAP ROT
    _TabLog_  
    S@ NEW>S ( adr n )
    0 SWAP 1- DO ( adr )
         DUP I + C@  PAD C! PAD 1 +>S
          -1 +LOOP DROP
    S@ 
    S>DROP  
    S>DROP ; 

: TabPiano ( min max # -- adr u) \ выдать огибающую звука фортепиано (типа)
    3DUP 
    NEW>S _TabExp_ S@ DROP >R
    NEW>S _TabLog_ R> S@ \ adr1 adr2 n
    NEW>S 
    0 SWAP 1- DO ( adr1 adr2 )
         2DUP I + C@ SWAP I + C@ + 2/ PAD C! PAD 1 +>S
          -1 +LOOP 2DROP
    S@ S>DROP  S>DROP S>DROP
        ; 

: TabLin ( a b n -- adr u ) \ выдать линию как таблицу из n точек от а<>0 до b
    \ если a<b - возрастающая линия
    \ если a>b - спадающая линия
    \ если a=b - горизонтальная линия
    \ y(i)=a+i*(b-a)/(n-1), где i=[0..n-1]
    NEW>S
    DUP >R 1- s>f
    OVER - s>f FSWAP F/
    s>f FSWAP \ (F: a (b-a)/(n-1)
    R> 0 DO
            FOVER FOVER
            I s>f F*  F+ FROUND 
            FROUND f>s PAD C! PAD 1 +>S
         LOOP FDROP FDROP S@ S>DROP
    ;
: see-tab ( adr u --)
    0 -ROT
    OVER + SWAP
    DO I C@ 4 .R  1+ DUP 16 = IF CR DROP 0 THEN LOOP DROP CR ;    
    
\ ========= формирование кода для семисегментрного индикатора ==================
HERE 9 ALLOT constant str7seg \ резервирование места для строки расположения сегментов

: map7Seg ( <str> --) \ запомнить расположение сегментов в байте
    BL WORD COUNT str7seg ! str7seg 1+ 8 CMOVE
    ;
map7Seg ABCDEFGH \ нормальное расположение сегментов в байте, нулевой бит СЛЕВА

: symFind ( sym adr u -- n) \ n позиция символа sym в строке adr u
    0 -rot
    over + swap
    do \ sym j
        over i c@ = if leave else 1+ then 
    loop
    nip ;
    
: cod7s ( addr u -- byte) \ преобразовать строку в код семисегментного индикатора
    0 -rot
    over + swap
    do
        i c@ str7Seg count symfind dup 7 > abort" сегмент не найден"
        1 swap lshift +
    loop ;
: (0) S" ABCDEF"  cod7s ; \ 0
: (1) S" BC"      cod7s ; \ 1
: (2) S" ABGED"   cod7s ; \ 2
: (3) S" ABGCD"   cod7s ; \ 3
: (4) S" FGBC"    cod7s ; \ 4
: (5) S" AFGCD"   cod7s ; \ 5
: (6) S" AFGCDE"  cod7s ; \ 6
: (7) S" ABC"     cod7s ; \ 7
: (8) S" ABCDEFG" cod7s ; \ 8
: (9) S" ABCDFG"  cod7s ; \ 9

: (A) S" ABCEFG"  cod7s ; \ A
: (B) S" CDEFG"   cod7s ; \ B
: (C) S" ADEF"    cod7s ; \ C
: (D) S" BCDEG"   cod7s ; \ D
: (E) S" ADEFG"   cod7s ; \ E
: (F) S" AEFG"    cod7s ; \ F

: (t) S" FGED"    cod7s ; \ t
: (r) S" EG"      cod7s ; \ r  
: (n) S" CGE"     cod7s ; \ n
: (.) S" H"       cod7s ; \ .
: ()  0 ; \ пусто

: (cod7s) ( <str> -- byte) \ взять строку из входного потока, преобразовать
    BL WORD COUNT cod7s ;
\ (cod7s) FGED ( t) \ пример использования
: (0-9) ( -- коды от 0 до 9 )
    (0) (1) (2) (3) (4) (5) (6) (7) (8) (9)  ;
: (0-F) ( -- коды от 0 до F )
    (0) (1) (2) (3) (4) (5) (6) (7) (8) (9) (A) (B) (C) (D) (E) (F) ;
    

    
