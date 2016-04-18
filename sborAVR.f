DECIMAL
\ слова для унификации кода и удобства написания программ
: (IF) POSTPONE IF ; IMMEDIATE
: (THEN) POSTPONE THEN ; IMMEDIATE
ALSO DASSM
: VECTOR> ( adr <"name"> -- ) \ приписывает вектор к name 

        BL WORD COUNT EVALUATE
        finger >R
        (SWAP) finger! 
\        RJMP  0 coder 
        GOTO  0 coder 
        R> finger!
    ;  
PREVIOUS  
: NOADR ( )
    TRUE ABORT" Неверный адрес." ;
\ =====================================
SAVE-VOCS ALSO DASSM DEFINITIONS
\ нижеследующие слова будут работать только в режиме ассемблирования
\ 16-ти битные операции: 
\ Младший байт по младшему адресу; 
\ Старший байт в порт пишется первым, читается последним;
\ Пара представляется младшим адресом.

: DUPLET ( a b -- a b a+1 b+1  )
        OVER 1+ OVER 1+  \ продублировать и модифицировать операнды (старший сверху)
    ;    

: LDIW ( j*x <"Rd,k"> -- i*x) \ загрузка пары регистров константой
    DOAFTER> ( Rd k --)
        OVER >R     \ скопировать Rd в R-стек
        BYTE-SPLIT  \ разчленить K на байты
        R> 1+ (SWAP) 
        LDI LDI     \ дважды выполнить загрузку по байту
    ;
: CLRW ( <"Rd"> --) \ очистит регистровую пару
    DOAFTER> ( Rd -- )
    DUP CLR 1+ CLR
    ;
: ORW ( <"Rd Rr"> -- ) \ логическое ИЛИ регистровых пар
    DOAFTER> ( Rd Rr -- )
    DUPLET  OR OR
    ;
: ANDW ( <"Rd Rr"> -- ) \ логическое И регистровых пар
    DOAFTER> ( Rd Rr -- )
    DUPLET  AND AND
    ;
: COMW ( <"Rd"> --) \ инвертирование пары регистров
    DOAFTER> ( Rd -- )
    DUP 1+ COM COM
    ;
: ADDI ( <"Rd k"> --)
    DOAFTER> ( Rd k -- )
    DUP 255 > abort" Операнд больше байта"
    NEGATE (LB) ( Rd lowByte[-k] --)
    subi
    ;
: SUBIW ( <"Rd k"> -- )
    DOAFTER> ( Rd k -- )
    DUP 65535 > abort" Операнд больше двух байт"
    >R
    DUP 1+ (SWAP) ( Rd+1 Rd --)
    R@ (HB) (SWAP) R> (LB) ( Rd+1 highByte[k] Rd lowByte[k] --)
    subi sbci
    ;
: ADDIW ( <"Rd k"> -- )
    DOAFTER> ( Rd k -- )
    DUP 65535 > abort" Операнд больше двух байт"
    NEGATE 0xFFFF (AND)
    SUBIW
    ;
: ADDW ( <"Rd Rr"> -- )
    DOAFTER> ( Rd Rr -- )
    DUPLET 2SWAP add adc
    ;
: SUBW ( <"Rd Rr"> -- )
    DOAFTER> ( Rd Rr -- )
    DUPLET 2SWAP sub sbc
    ;
: ASRW ( <"Rd"> --) \ арифметический сдвиг пары регистров
    DOAFTER> ( Rd -- )
    DUP 1+ asr ror
    ;
: LSRW ( <"Rd"> --) \ логический сдвиг пары регистров вправо
    DOAFTER> ( Rd -- )
    DUP 1+ lsr ror
    ;    
: LSLW ( <"Rd"> --) \ логический сдвиг пары регистров влево
    DOAFTER> ( Rd -- )
    DUP 1+ (SWAP) lsl rol
    ;    
: RORW ( <"Rd"> --) \ циклический сдвиг пары регистров вправо
    DOAFTER> ( Rd -- )
    DUP 1+ ror ror
    ;    
: ROLW ( <"Rd"> --) \ циклический сдвиг пары регистров влево
    DOAFTER> ( Rd -- )
    DUP 1+ (SWAP) rol rol
    ;    

WARNING OFF
[WITH?] LDS \ вариант при наличии LDS и STS
: IN ( <"Rd Port"> --) \ в зависимости от адреса порта скомпилировать
    \ команду IN, MOV или LDS
    DOAFTER> ( Rd Port --)
        DUP IFREG  MOV EXIF;
        DUP IFnear IN  EXIF;
        DUP IFfar  LDS EXIF;
        NOADR ;
: OUT ( <"Port Rr"> --) \ в зависимости от адреса порта скомпилировать
    \ команду OUT или STS
    DOAFTER> ( Port Rr --)
        OVER IFREG  MOV EXIF;
        OVER IFnear OUT EXIF; 
        OVER IFfar  STS EXIF;
        NOADR ;

: LDSW ( j*x <"Rd,k"> -- i*x) \ загрузить Rd и Rd+1 данными из адреса k и k+1
    DOAFTER> ( Rd k -- )
    DUPLET 2SWAP LDS LDS ( младший читается первым)
    ;
: STSW ( j*x <"k,Rd"> -- i*x) \ сохранить Rd и Rd+1 по адресу k и k+1 
    DOAFTER> ( k Rd -- )
    DUPLET 
    LowFirstRW (IF) 2SWAP (THEN) ( младший пишется первым, иначе старший пишется первым)
    STS STS
    ;

\ : LDW  ???
\ : STW  ???
\ : LDDW ???
\ : STDW ???

[ELSE] \ вариант при отсутствии LDS и STS
: IN ( <"Rd Port"> --) \ в зависимости от адреса порта скомпилировать
    \ команду IN или MOV
    DOAFTER> ( Rd Port --)
        DUP IFREG  MOV EXIF;
        DUP IFnear IN  EXIF;
        NOADR ;
: OUT ( <"Port Rr"> --) \ в зависимости от адреса порта скомпилировать
    \ команду OUT или STS
    DOAFTER> ( Port Rr --)
        OVER IFREG  MOV EXIF;
        OVER IFnear OUT EXIF; 
        NOADR ;

[THEN]        
[WITH?] MOVW 
\ вариант при наличии MOVW в системе команд
: 2evenReg? ( adr adr --f) \ проверить принадлежат ли эти адреса четным регистрам
    OVER REG? OVER REG? (AND) \ true - оба регистры
    ROT 1 (AND) ROT 1 (AND) (OR) 0= \ true - оба четные
    (AND)
    ;
: 2IN  ( j*x <"Rd Port"> -- i*x) \ загрузка пары
    DOAFTER>
        2DUP 2evenReg? (IF) MOVW EXIF;   \ если оба чётные регистры
        DUPLET 2SWAP IN IN       \ выполнить 2 раза IN  ( младший читается первым)
    ;
: 2OUT ( j*x <"Port Rr"> -- i*x) \ выгрузка пары
    DOAFTER> ( Port Rr --)
        2DUP 2evenReg? (IF) MOVW EXIF;   \ если оба чётные регистры
        DUPLET 
        LowFirstRW (IF) 2SWAP (THEN) ( младший пишется первым, иначе старший пишется первым)
        OUT OUT           \ выполнить 2 раза OUT 
    ;
[ELSE]
\ вариант при отсутствии MOVW в системе команд
: 2IN  ( j*x <"Rd Port"> -- i*x) \ загрузка пары
    DOAFTER>
        DUPLET 2SWAP IN IN       \ выполнить 2 раза IN  ( младший читается первым)
    ;
: 2OUT ( j*x <"Port Rr"> -- i*x) \ выгрузка пары
    DOAFTER> ( Port Rr --)
        DUPLET 
        OUT OUT           \ выполнить 2 раза OUT (старший пишется первым)
    ;
[THEN]
: OUTW 2OUT ; \ псевдоим    
: INW 2IN ; \ псевдоим

: MOV ( <"addr1 addr2"> --) \ в зависимости от адресов операндов скоммпилировать
    \ mov in out sts lds
    DOAFTER>
    DUP IFREG OUT EXIF;
    OVER IFREG IN EXIF;
    ABORT" MOV -- один из операндов должен быть регистром."
    ;
: 2MOV ( <"addr1 addr2"> --) \ в зависимости от адресов операндов скоммпилировать
    \ пары mov in out sts lds для 
    DOAFTER> ( Port Rr --)
    DUP IFREG 2OUT EXIF;
    OVER IFREG 2IN EXIF;
    ABORT" MOV -- один из операндов должен быть регистром."
    ;

: MOVW 2MOV ;
   
WARNING ON

[WITH?] PUSH \ если есть PUSH и POP
: PUSHW ( <"RegL"> ---) \ сохранить на стеке пару регистров
    DOAFTER> ( Rr --)
        DUP 1+ (SWAP) PUSH PUSH ;
: POPW ( <"RegL"> ---) \ востановить из стека пару регистров
    DOAFTER> ( Rr --)
        DUP 1+  POP POP ;
[THEN]
: CPW ( <"Rd Rr"> -- ) \ сравнить пары регистров
    DOAFTER> ( Rd Rr --)
        DUPLET 2SWAP CP CPC ; ( начинать с младшего)
: FOR ( ) \ начало цикла со счётчиком
    BEGIN ;    
: NEXT ( <"reg"> --) \ конец цикла со счётчиком
    DOAFTER> ( reg --)
    DEC  BRNE 1V>  ;

: XCHG ( <"Rd Rr"> --) \ обменять содержимое регистров за 3 такта
    DOAFTER> ( Rd Rr --)
    2DUP (SWAP) 2DUP (SWAP) eor eor eor
    ;
RESTORE-VOCS        

