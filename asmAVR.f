\ #!  /home/ivanov/spf-4.20/spf4
DECIMAL
\ ассемблер для AVR
\ автор: ~iva дата: 8.03.2010 ревизия:0
\ ======== ИНФО ================================================================
\ 
\ ======== ЗАДАЧИ ==============================================================
\ принять текст и интерпретировать его как форт-ассемблер AVR
\ ======== ПОДКЛЮЧАЕМЫЕ ФАЙЛЫ и слова нужные не только здесь ===================
S" ~iva/AVR/disAVR.f" INCLUDED \ дизассемблер и другие
\ ======== КОНСТАНТЫ И ПЕРЕМЕННЫЕ ==============================================
VARIABLE CODING? \ счётчик состояния кодирования
0 CODING? !
\ ======== СЛУЖЕБНЫЕ СЛОВА ДЛЯ ОПРЕДЕЛЕНИЯ ГЛАВНЫХ СЛОВ ========================


: >codebuf ( u --)  
    DUP TRUE 16 LSHIFT AND  
    IF WORD-SPLIT W>Seg W>Seg  
    ELSE W>Seg 
    THEN ;
 
: operand-exe ( j*x operator op# -- i*x) \ выполнить обработчик операнда
    ASM!
    op.exec @ EXECUTE ;
: operand! ( j*x operator op# -- i*x) 
    2DUP op.mask @ TO MASKA operand-exe 
    ;
: comby ( j*x -- i*x)
    operator @  ?DUP \ взять из operator адрес статьи ПРЕдыдущего оператора
        \ если не 0, то 
        IF  DUP  0< 
            IF   \ псевдокоманда!
               0 operator ! \ взял-выкинул ДО выполнения (защита от рекурсии)
               NEGATE EXECUTE
            ELSE \ команда ассемблера
                \ выполнить его слова-обработчики операндов,
                DUP >R 2 operand! R@ 1 operand!  
                \ получить клише,
                R> clishe @
                    f-2W 16 AND LSHIFT   \ если широкий - сдвинуть клише
                \ скрестить результат с клише,
                \ и записать в codebuf
                _code OR >codebuf 
                0 TO _code FALSE TO f-2W
                0 operator ! \ взял-выкинул ПОСЛЕ выполнения (защита от рекурсии)
            THEN
        THEN
    ;
:NONAME ( j*x operator -- i*x) \ на стеке лежат операнды!!!
     \ выполнить отложенный оператор 
     \ отложить текущий оператор до отработки его опреандов
     >R 
        BEGIN \ выполнять comby, до тех пор пока operator не равен 0
            operator @ 
        WHILE    
            comby
        REPEAT 
     R> operator ! \ текущую команду отложить для последующей обработки
     ; IS coder  

: FILTER ( adr u -- adr' u')  \ изменить строку
    DUP 0 > 
    IF  OVER + SWAP 
        DO  I C@ 
            DUP [CHAR] , = 
            IF DROP BL EMIT>S  \ баним запятые пробелом
            ELSE \ DUP [CHAR] - = IF BL EMIT>S THEN \ пробел ПЕРЕД минусом \ он и так сам получается
                DUP EMIT>S ( копируем символ)  
                [CHAR] + = IF BL EMIT>S THEN \ пробел ПОСЛЕ плюса
            THEN
        LOOP
        S@ \ 2dup type cr
    ELSE DROP 0
    THEN
    ;
\ ======== ГЛАВНЫЕ СЛОВА =======================================================
\ : (@) ; \ нечто, что уже лежит на стеке. 
\ Используется для отметки мест параметров в макросах с параметрами.

: C[ ( --) \ включить фильтрацию
    0 coder 
    CODING? @ 0= IF <DASSM THEN \ подключить словарь ассемблирования
    1 CODING? +! 
    BEGIN 
        CODING? @ 
    WHILE 
        NEW>S \ подготовить место
            SOURCE >IN @ OVER >IN ! /STRING \  взять остаток строки из входного потока и передвинуть указатель 
            FILTER
            EVALUATE  
        S>DROP \ освободить место
        REFILL 
    WHILE REPEAT
    THEN
    ;

VARIABLE codeDep \ контроль изменения глубины стека
<DASSM \ в словарь ассемблирования
    : ]C ( )  \ выключить фильтрацию
        0 coder 
        CODING? @ 0 > if -1 CODING? +! then
        CODING? @ 0 = IF  DASSM> THEN \ отключить словарь ассемблирования
        ; 
    : C;  ]C  \ завершить  кодирование
        DEPTH codeDep @ - 
        DUP 0 < ABORT" В коде нехватает операндов." 
        ABORT" В коде лишние операнды." 
        ;   
    
    WARNING @ FALSE WARNING !
    : NOTFOUND ( adr u -- ) \ попытка обработать ненайденное слово, как внутреннюю метку
        2DUP + 1- C@ [CHAR] : = \ двоеточие в конце?
        IF \ да - делаем маркер 
            2>R \ отложить строку с именем
            ]C \ завершить предыдущий оператор
                MarkType finger 2R> 1- !label(S): \ маркер с именем без двоеточия в конце
                0 THROW \ разрешение исключения
            C[    
        ELSE  NOTFOUND THEN
        ;
    WARNING !    
DASSM>

: CODE ( <"Name"> --) \ начать новое определение именем "Name"
    CODING? @ ABORT" Предыдущее определение не завершено."
    DEPTH codeDep ! \ запомнить глубину стека
    CodeType label:  C[  
    ;

\ ======== ТЕСТЫ И ПРИМЕРЫ =====================================================
\ HEX
\ ALSO DASSM 
\ SAVE-VOCS VOCS 32 DUMP CR
\ PREVIOUS PREVIOUS DEFINITIONS ORDER
\ RESTORE-VOCS ORDER

\ CR DECIMAL  S" tst-tn26.asm"  INCLUDED  \ CATCH . CR
\    SEG @ wender  dis \ 
\ CR CR SEE-CODE ara
  
