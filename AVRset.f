DECIMAL
S" ~iva/AVR/labels.f"    INCLUDED    \ для работы с метками и другое
S" ~iva/AVR/intel-hex.f" INCLUDED    \ для загрузки и выгрузки hex-файлов и другое
S" ~iva/AVR/data.f"      INCLUDED    \ таблицы и строки

DECIMAL
0 VALUE opcode      \ обрабатываемый код операции
0 VALUE MASKA       \ текущая битовая маска
TRUE DUP 1 RSHIFT XOR CONSTANT 1HIG \ число с 1 в самом старшем разряде
VARIABLE запятая    \ флаг разрешающий/запрещающий печать запятой
0 VALUE f-2W        \ флаг широкого (в два слова) кода операции
0 VALUE _code       \ хранилище недособранного кода
0 VALUE DIS/ASM     \ флаг режима


VARIABLE operator
CREATE BLS HERE 80 DUP ALLOT BL FILL \ куча пробелов
: n+>S ( adr u n --) \ вписать строку adr-u в поле шириной n
    >R 2DUP SYMBOLS R>  \ adr u s n \ s=числу реальных символов
    SWAP - >R +>S   BLS R> DUP 0< IF DROP 1 THEN +>S  ;
: ,? S" ," запятая @ AND +>S ;

\ ========== слова-обработчики операндов =======================================
: ASM! FALSE TO DIS/ASM ; \ установить режим ассемблирования
: DIS! TRUE  TO DIS/ASM ; \ установить режим дизассемблирования
: DIS> POSTPONE DIS/ASM POSTPONE IF ; IMMEDIATE 
: ASM> POSTPONE EXIT POSTPONE THEN ; IMMEDIATE
: ссыпать ( opcode mask -- u) \ собрать по маске биты из opcode в число
    \ маска имеет единицы в разрядах соответствующих разрядам числа рассыпаным
    \ в opcode, т.е. разряда могут быть и не подряд
    0 -ROT 1HIG
    CELL 8 * 0 
    DO \ цикл по всем битам ячейки
        \ u' opc m 1
        >R  \ u' opc m
        DUP R@ AND
        IF  ROT \ opc m u'
            1 LSHIFT 
            ROT DUP R@ AND
            IF SWAP 1+ SWAP THEN
            ROT
        THEN
        R> 1 RSHIFT
    LOOP
    DROP 2DROP
    ;
: LSB ( n -- n' bit) \ отделить младший бит от числа u, с сохранением знака
     DUP 2/ SWAP 1 AND ;
: ULSB ( u -- u' bit) \ отделить младший бит от числа u, без знака
     DUP 1 RSHIFT SWAP 1 AND ;
: рассыпать ( u mask -- opcode') \ рассыпать биты числа n по opcode' согласно
    \ маски положения
    0 ( u m op=0)
    CELL 8 * 0 
    DO \ цикл по всем битам ячейки
        ( u m op)
        1 RSHIFT >R ( u m)
        \ рассыпаем
        ULSB IF SWAP ULSB 1HIG * R> OR >R SWAP THEN
        R> 
    LOOP 
    NIP SWAP ABORT" Слишком большое число в операнде." 
    ;    

: ~id? ( adr u adr-link -- f ) \ есть-ли в данном opcode операнд с похожим id
    >R  
    R@ 1 op.id COUNT 2OVER SEARCH NIP NIP -ROT
    R> 2 op.id COUNT 2SWAP SEARCH NIP NIP
    OR    
    ;

: подходит? ( adr-link -- f)
    DUP mnemo COUNT 2V@ COMPARE 
    IF DROP FALSE
    ELSE 2V> 2>R
         2V@  ROT ~id?
         2R> 2>V
    THEN 
    ;
: refind-op ( adr u -- adr-link |0) \ найти оператор с тем же именем что и 
\ текущий, но с id опеанда равного строке adr u
    2>V operator @ DUP 0 > \ V: adr u 
    IF 
        mnemo COUNT 2>V \ V: adr u name id
        operator \ opcodes
        BEGIN  
            @ DUP IF DUP подходит? ELSE TRUE THEN 
        UNTIL  V>DROP V>DROP    
    ELSE \ 0 или псевдокоманда, искать нет смысла
        DROP V>DROP 0 \ нечего искать - выход с 0
    THEN      
    ;
    
: get-operand ( -- n) opcode MASKA ссыпать ;
HEX[
: .) ( n --) <# 0 #S #> +>S ; \ выдать число без пробела в конце
: label-HEX.) ( n --) ,? DUP label>name ?DUP 
        IF +>S DROP ELSE DROP S" 0x" +>S HEX[ .)  ]HEX THEN   ;
: RAM. RAM[ label-HEX.) ]RAM ;
: REG. +fReg RAM. ; \ 23.01.2014
: pac ( n -- ) MASKA DUP 0FFFF > f-2W OR TO f-2W
    рассыпать _code OR TO _code ;
]HEX

: -XYZ+ ( adr u -- )
    DIS> ,?  +>S 
    ASM> refind-op DUP 0= ABORT" Синтаксическая ошибка." 
    operator ! ;

: sb  ( --) DIS> ,? get-operand .)
            ASM> 7 AND pac  ; 
: A   ( --) DIS>  get-operand  RAM. \ .) 
            ASM>  pac  ; 
: K!  ( --) DIS> ,? get-operand .) 
            ASM> pac ;
 : !K! ( --) 
    DIS> K!
    ASM>  TRUE XOR 255 AND pac ;
: X   ( --) S" X"     
    DIS> ,?  +>S 
    ASM> refind-op ?DUP IF operator ! ELSE 26 +fReg THEN ;
: Y   ( --) S" Y"
    DIS> ,?  +>S 
    ASM> refind-op ?DUP IF operator ! ELSE 28 +fReg THEN ;
: Z   ( --) S" Z" 
    DIS> ,?  +>S 
    ASM> refind-op ?DUP IF operator ! ELSE 30 +fReg THEN ;

: X+  ( --) S" X+" -XYZ+ ; 
: -X  ( --) S" -X" -XYZ+ ; 
: Y+  ( --) S" Y+" -XYZ+ ;
: -Y  ( --) S" -Y" -XYZ+ ; 
: Z+  ( --) S" Z+" -XYZ+ ; 
: -Z  ( --) S" -Z" -XYZ+ ;
: Y+q ( --) DIS> Y+ get-operand .) 
            ASM> pac ; 
: Z+q ( --) DIS> Z+ get-operand .) 
            ASM> pac ; 
: ?.  ( --) DIS> ,? opcode S" 0x" +>S HEX[ .) ]HEX 
            ASM> ;

: Rd  ( --) DIS> get-operand REG. 
            ASM> -fReg pac ;  \ 23.01.2014 
: Rr  ( --) Rd ; 
: k   ( --) \ абсолютный адрес в пространстве ROM, всегда >0
            \ здесь считается в байтах, а записывается в словах (2байта)
            \ из-за этого появились 2/ и 2*
            DIS> get-operand 2* label-HEX.) 
            ASM> 2/ pac ;
: сгрудить ( 010110010101 -- 0..00111..1) \ сгрудить все единицы
     DUP ссыпать  ;
: -k  ( --)  \ число может быть как положительным, так и отрицательным
            DIS> \ размножение знакового разряда
                 ( adr -- adr )
                 MASKA сгрудить 1 OVER #bits 1- LSHIFT
                 get-operand AND 0 > DUP ROT XOR AND
                 get-operand OR 
                 2* OVER SEG @ - + label-HEX.)
            ASM> finger 2+ - 2/
                 \ проверка диапазона
                 DUP 
                 MASKA сгрудить DUP >R #bits 1- 0 DO 2/ LOOP 
                    \ здесь отрицательное число должно превратится в -1,
                    \ а положительное в 0. Иначе - вне диапазона маски -/+.
                    DUP -1 <> SWAP 0 <> AND ABORT" Слишком далёкий переход."
                 R> AND \ обрезка по [маске]
                 pac ;
: (k) ( --) DIS> \ RAM[ ['] k CATCH ]RAM THROW
                 RAM[ get-operand label-HEX.)  ]RAM 
            ASM> pac ;
: b   ( --) sb ; 
HEX[
: MASKA-d ( -- n) 1F0 TO MASKA ; 
: MASKA-r ( -- n) 20F TO MASKA ; 
]HEX
: Rdr ( --) DIS> MASKA-d get-operand  MASKA-r get-operand 
                 OVER <> THROW REG. \ вылет по неравенству операндов
            ASM> -fReg DUP MASKA-d pac MASKA-r pac ; 


: R'd ( --) DIS> get-operand 16 + REG. \ R' => R[16..31] 
            ASM> -fReg 16 - 
                DUP 15 > OVER 0 < OR ABORT" Регистр должен быть R[16...31]." 
                pac ;     
: R'r ( --)  R'd ;                 
: R`d ( --) DIS> get-operand 16 + REG. \ R' => R[16..23] 
            ASM> -fReg 16 - 
                DUP 7 > OVER 0 < OR ABORT" Регистр должен быть R[16...23]." 
                pac ;     
: R`r ( --)  R`d ;                 

: R"d ( --) DIS> get-operand 2* REG.   \ R" => R[2,4,...30]
            ASM> -fReg DUP 1 AND ABORT" Регистр должен быть чётным."
                 2/ pac ;       
: R"r ( --)  R"d ;
: R*d ( --) DIS> get-operand 2* 24 + REG. \ R* => R[24,26,28,30] 
            ASM> -fReg 24 - 2/ 
                DUP 3 > OVER 0 < OR ABORT" Только для регистровых пар R[24,26,28,30]."
            pac ;  


\ ======== стандартные регистры микропроцессора ================================

: REGISTER: ( n --)  RAM[ <LABELS RegType SWAP +fReg !label: LABELS> ]RAM ; \ 23.01.2014 регистры помечаются 1 в старшем бите cell
\ : REGISTER: ( n --)  RAM[ <LABELS RegType SWAP         !label: LABELS> ]RAM ;

: PORT: ( n --)
    RAM[ <LABELS PortType SWAP !label: LABELS> ]RAM ; \ 23.01.2014 порты нумеруются от 0
\ : PORT: ( n --)
\    DUP 64 < 32 AND + RAM[ <LABELS PortType SWAP !label: LABELS> ]RAM ;
    

\ 20.10.2013 потребовалась сквозная нумерация бит в смежных байтах 
0  VALUE fBitBase \ базовый адрес для приписывания битов
0  VALUE fNumBit \ номер последнего прописанного бита
: BitsIn ( "name" --) \ подготовиться к нумерации битов в порту "name"
    BIT[ BL WORD COUNT EVALUATE 
    DUP fReg AND >R \ сохранить признак регистра, если есть
    8 * R> OR \ востановить признак регистра
        TO fBitBase 
    -1  TO fNumBit ]BIT ;

: #BitIs ( n "name" --) \ запомнить бит-адрес как "name", прямое указание # бита
    BIT[ DUP TO fNumBit fBitBase + \ вычислить адрес бита
        <BITS BitType SWAP !label: BITS> \ запомнить его под именем "name"
      ]BIT ;
: _bitIs ( "name"-- )  \  запомнить бит-адрес как "name", косвенное указание 
    fNumBit 1+ #BitIs \ сдвинуть и запомнить текущий бит         
    ; 



: FUSE:     ( f n --) FUSE[ DUP BitType SWAP !label: B>Seg ]FUSE ; \ значение f запоминается в памяти
: LOCK:     ( f n --) LOCK[ DUP BitType SWAP !label: B>Seg ]LOCK ; \ значение f запоминается в памяти

\ стандартные имена регистров, битов, портов...
  0 REGISTER: R0   1 REGISTER: R1   2 REGISTER: R2   3 REGISTER: R3  
  4 REGISTER: R4   5 REGISTER: R5   6 REGISTER: R6   7 REGISTER: R7
  8 REGISTER: R8   9 REGISTER: R9  10 REGISTER: R10 11 REGISTER: R11  
 12 REGISTER: R12 13 REGISTER: R13 14 REGISTER: R14 15 REGISTER: R15 

 16 REGISTER: R16 17 REGISTER: R17 18 REGISTER: R18 19 REGISTER: R19 
 20 REGISTER: R20 21 REGISTER: R21 22 REGISTER: R22 23 REGISTER: R23 
 24 REGISTER: R24 25 REGISTER: R25 
 26 REGISTER: R26 27 REGISTER: R27 
 28 REGISTER: R28 29 REGISTER: R29 
 30 REGISTER: R30 31 REGISTER: R31
 
 24 REGISTER: rL  25 REGISTER: rH 
 24 REGISTER: R                    \ рабочая регистровая пара
 26 REGISTER: xL  27 REGISTER: xH  \ дополнительные имена регистра X 
 28 REGISTER: yL  29 REGISTER: yH  \ дополнительные имена регистра Y
 30 REGISTER: zL  31 REGISTER: zH  \ дополнительные имена регистра Z 

 ALSO ASMLABELS  \ DEFINITIONS

\ RAM[    \ 26 также известен как Хl
\         ( 26 Nick X)  26 Nick xL  27 Nick xH   
\         ( 28 Nick Y)  28 Nick yL  29 Nick yH
\         ( 30 Nick Z)  30 Nick zL  31 Nick zH   
\         ]RAM







