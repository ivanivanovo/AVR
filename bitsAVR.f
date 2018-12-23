\ дополнительные слова ассемблера AVR для работы с битами
DECIMAL
BitsIn SREG
    _bitIs C \ бит переноса
    _bitIs Z \ бит нулевого результата
    _bitIs N \ бит отрицательного результата
    _bitIs V \ бит дополнения до двух
    _bitIs S \ бит знака результата
    _bitIs H \ бит полупереноса
    _bitIs T \ бит свободный
    _bitIs I \ бит разрешение прерываний

: (SWAP) SWAP ; \ версия SWAP из Forth
: (AND)  AND  ; \ версия AND  из Forth
: (OR)   OR   ; \ версия OR   из Forth

: EXIF; ( ) \ выход по завершению IF
    POSTPONE EXIT POSTPONE THEN ; IMMEDIATE

\ отложить исполнение до получения параметров
\ работает только в spf
[WITHOUT?] DOAFTER> : DOAFTER> ( )  R> 1 coder ; [THEN]

: .1V ( )
   0 BEGIN ['] 1V> CATCH 0= WHILE DUP . SWAP 1+ REPEAT
   0 ?DO 1>V LOOP 
   ;
: SWAP.1V ( V: orig1 orig2 -- orig2 orig1)
   1V> 1V> SWAP 1>V 1>V ;
: ADR_BIT ( u -- adr bit) \ выделяет из u адрес регистра/порта и номер бита
    DUP fReg AND >R -fReg \ отделить признак регистра
    DUP 8 / \ получить адрес
        R> OR \ востановить признак регистра
    SWAP 7 AND \ получить номер  
    ;
: bitmaska ( # -- maska) \ переводит номер бита в маску, где в нужном разряде 1
    1 SWAP LSHIFT ;    
: Reg? ( adr --  f) \ f=true если регистр
    fReg AND ; \ 23.01.2014
    
: BitPort? ( adr -- f) \ f=true если биты в порту доступны
    0 31 BETH ;
: Near? ( adr -- f) \ f=true если близкий порт
    0 63 BETH ;
: SReg? ( adr -- f ) \ если системный регистр
    SREG = ;
ALSO DASSM
    : Far?  ( adr -- f ) \ f=true если дальний порт или адрес в области RAM
        64 RAMEND BETH ;
PREVIOUS
: NOBIT ( )
    TRUE  ABORT" Адрес этого бита недоступен для битовых команд." ;

: IFREG   POSTPONE Reg?     POSTPONE IF ; IMMEDIATE
: IFnear  POSTPONE Near?    POSTPONE IF ; IMMEDIATE
: IFbPORT POSTPONE BitPort? POSTPONE IF ; IMMEDIATE
: IFSREG  POSTPONE SReg?    POSTPONE IF ; IMMEDIATE
: IFfar   POSTPONE Far?     POSTPONE IF ; IMMEDIATE

VARIABLE DEPold \ хранение предыдущей глубины стека

: {b ( ) \ запомнить глубину стека для обработки списка битов
    <BITS  DEPTH DEPold ! ;

<BITS  PREVIOUS \ слова в битовый словарь, но без поиска в нём
    : } ( bit bit ...bit  -- u) \  собрать биты по именам в одну маску
        BITS> \ отключить битовый словарь
        DEPTH DEPold @ - \ вычислить изменение глубины стека, узнать число битов
        0 0 -ROT 
        ?DO SWAP 7 AND bitmaska OR LOOP \ сложить биты в маску
        ;
BITS> 


\ =====================================
SAVE-VOCS ALSO DASSM DEFINITIONS
\ нижеследующие слова будут работать только в режиме ассемблирования

: SET_B ( "BIT" --) \ установить бит "BIT"=1
    <BITS DOAFTER>  BITS> ADR_BIT 
        OVER   IFREG (SWAP) -fReg (SWAP) bitmaska SBR  EXIF; \ если бит расположен в регистре
        OVER   IFbPORT SBI           EXIF; \ если бит расположен в порту
        (SWAP) IFSREG  BSET          EXIF; \ если бит расположен в SREG
        NOBIT ; 

: CLR_B ( "BIT" --) \ сбросить бит "BIT"=0
    <BITS DOAFTER>  BITS>  ADR_BIT
        OVER   IFREG   bitmaska CBR  EXIF; \ если бит расположен в регистре
        OVER   IFbPORT CBI           EXIF; \ если бит расположен в порту
        (SWAP) IFSREG  BCLR          EXIF; \ если бит расположен в SREG
        NOBIT ; 

: _/    SET_B ;
: \_    CLR_B ;

: T>BIT ( "BIT" --) \ загрузить Т в бит с именем  "BIT"
    <BITS DOAFTER> BITS>  ADR_BIT
        OVER   IFREG   BLD                            EXIF; \ если бит расположен в регистре
        OVER   IFbPORT 2DUP CBI  BRTC finger 4 +  SBI EXIF; \ если бит расположен в порту 
        (SWAP) IFSREG  DUP BCLR  BRTC finger 4 + BSET EXIF; \ если бит расположен в SREG
        NOBIT ;
: BIT>T ( "BIT" --) \ сохранить бит с именем  "BIT" в T
    <BITS DOAFTER> BITS>   ADR_BIT
        OVER   IFREG   BST                            EXIF; \ если бит расположен в регистре
        OVER   IFbPORT CLT SBIC SET                   EXIF; \ если бит расположен в порту
        (SWAP) IFSREG  CLT BRBC finger 4 + SET        EXIF; \ если бит расположен в SREG
        NOBIT ; 

: SKIP_B ( "BIT" --) \ пропустить следующую комаду если "BIT"=1
    <BITS DOAFTER> BITS>  ADR_BIT
        OVER   IFREG   SBRS EXIF; \ если бит расположен в регистре
        OVER   IFbPORT SBIS EXIF; \ если бит расположен в порту
        (SWAP) IFSREG TRUE ABORT" для системных бит команда неприменима." EXIF;
        NOBIT ;
: SKIP_NB ( "BIT" --) \ пропустить следующую команду если "BIT"=0
    <BITS DOAFTER> BITS>  ADR_BIT
        OVER   IFREG   SBRC EXIF; \ если бит расположен в регистре
        OVER   IFbPORT SBIC EXIF;  \ если бит расположен в порту
        (SWAP) IFSREG TRUE ABORT" для системных бит команда неприменима." EXIF;
        NOBIT ; 

0 VALUE stMark
: MarkX ( -- adr u ) \ выдать строку внутренней метки от счетчика
    S" m" >S  stMark <# 0 #S #> +>S S@ S>DROP
    stMark 1+ TO stMark
    ;

: ItMark ( addr --) \ отметить это место маркером
    DUP label-find 0=
    IF MarkType (SWAP) Label_ MarkX str! \ определить новую внутреннюю метку
    ELSE DROP \ использовать уже имеющуюся
    THEN
    ;
: (BEGIN) ( V: -- orig ) \ запомнить это место
    \ скомпилировать предыдущую команду
    DOAFTER> 
    finger 1>V  
    ;    
: BEGIN ( V: -- orig ) \ запомнить это место и пометить его 
    (BEGIN)  finger ItMark
    ;    
    
[FOUND?] JMP 
[IF]
: GOTO  (  )  \  выбрать между командами ближнего и дальнего перехода.
    DOAFTER>
    finger OVER - ABS 4095 > IF JMP ELSE RJMP THEN 
    ;
[ELSE]
: GOTO (  ) \ создать переход на метку
    RJMP ;
[THEN]
: AGAIN ( V: -- orig ) \ создать переход на метку
    DOAFTER>
    1V> GOTO ;
 : (pre) ( -- adr) ( V: -- orig )
    \ подготовить переход
     (BEGIN)   finger   ;
: (IF_B) ( BIT --) ( V: -- orig )
    ADR_BIT \ adr bit
        OVER   IFREG   SBRS (pre)  GOTO    EXIF; \ если бит расположен в регистре
        OVER   IFbPORT SBIS (pre)  GOTO    EXIF; \ если бит расположен в порту
        (SWAP) IFSREG  BRBC finger DUP 1>V EXIF; \ если бит расположен в SREG 
        NOBIT ;
: IF_B ( "BIT" -- ) ( V: -- orig )
    <BITS DOAFTER> BITS> ( BIT --) (IF_B) ;
    
: (IF_NB) ( BIT --) ( V: -- orig )
    ADR_BIT \ adr bit
        OVER   IFREG   SBRC (pre)  GOTO    EXIF; \ если бит расположен в регистре
        OVER   IFbPORT SBIC (pre)  GOTO    EXIF; \ если бит расположен в порту
        (SWAP) IFSREG  BRBS finger DUP 1>V EXIF; \ если бит расположен в SREG
        NOBIT ;
    
: IF_NB ( "BIT" -- ) ( V: -- orig )
    <BITS DOAFTER> BITS> ( BIT --)  (IF_NB) ;
    

: UNTIL_B  ( "BIT" -- ) ( V: orign-- ) \ ждать установки бита повторяя цикл
    <BITS DOAFTER> BITS> ( BIT --)
    ADR_BIT \ adr bit
        OVER   IFREG   SBRS GOTO 1V> EXIF; \ если бит расположен в регистре
        OVER   IFbPORT SBIS GOTO 1V> EXIF; \ если бит расположен в порту
        (SWAP) IFSREG  BRBC 1V>      EXIF; \ если бит расположен в SREG
        NOBIT ;
: WAIT_B  UNTIL_B ; \ мне так понятнее
: UNTIL_NB  ( "BIT" -- ) ( V: orign-- )  \ ждать сброса бита повторяя цикл
    <BITS DOAFTER> BITS> ( BIT --)
    ADR_BIT \ adr bit
        OVER   IFREG   SBRC GOTO 1V> EXIF; \ если бит расположен в регистре
        OVER   IFbPORT SBIC GOTO 1V> EXIF; \ если бит расположен в порту
        (SWAP) IFSREG  BRBS 1V>      EXIF; \ если бит расположен в SREG
        NOBIT ;
: WAIT_NB UNTIL_NB ; \ мне так понятнее

: UNTIL ( ) ( V: orign-- )  \ повторять цикл, пока 0 (Z=1)
    \ ждать результата отличного от нуля
    DOAFTER> BREQ 1V> ;
: WAIT  UNTIL ; \ ждать результата отличного от нуля
: WAIT0 ( ) ( V: orign-- )  \ повторять цикл, пока НЕ 0
    \ ждать нулевого результата
    DOAFTER> BRNE 1V> ;


: THEN ( V: orign-- )   \ разрешить ссылку вперед   на "сюда" 
    \ скомпилировать предыдущую команду
    DOAFTER> 
    finger DUP ItMark  DUP          \ запомнить "сюда" 
           1V> finger!  \ переставить finger
           fingerA W@   \ прочитать что за команда там находится
           find-opcode 0 2operator 2! \ подготовить её к повторному исполнения
                                  \ с реальным значением
           comby  \ записать команду перехода на "сюда"
    finger! ;           \ восстановить finger
    
: ELSE ( V: orig1 -- orig2  )
    \ подготовить ссылку вперед   на "туда"
    \ разрешить ссылку вперед   на "сюда"
    \ скомпилировать предыдущую команду
    DOAFTER> 
    1V> finger 1>V 1>V \ перестановка маркеров
    GOTO finger  \ заготовка для безусловного перехода на после "THEN"
    THEN   \ разрешение ссылки от предыдущего "IF"
    ;
: WHILE_B ( "BIT" -- ) ( V: orig1 -- orig2 orig1 )
    \ выполнять тело цикла, пока "BIT"=1
    <BITS DOAFTER> BITS> ( BIT --)
    (IF_B) SWAP.1V ;
: WHILE_NB ( "BIT" -- ) ( V: orig1 -- orig2 orig1 )
    \ выполнять тело цикла, пока "BIT"=0
    <BITS DOAFTER> BITS> ( BIT --)
    (IF_NB) SWAP.1V ;
: WHILE ( ) ( V: orig1 -- orig2 orig1 ) \ выполнять тело цикла, 
    \ пока результат отличен от нуля (бит Z=0)
    DOAFTER> [ <BITS Z BITS> ] LITERAL
    (IF_NB) SWAP.1V ;
: REPEAT ( V: orig1 orig2  -- ) \ разрешение WHILE и возврат к BEGIN
     AGAIN  
     THEN ;

\ дополнительные слова для красивости     
: IF_C  (pre) BRCC  ; \ Выполнить если перенос установлен
    : IF< IF_C ;
: IF_NC (pre) BRCS  ; \ Выполнить если перенос очищен
    : IF>= IF_NC ;
: IF_Z  (pre) BRNE  ; \ Выполнить если флаг нулевого результата установлен
    : IF= IF_Z ;
    : IF0 IF_Z ;
: IF_NZ (pre) BREQ  ; \ Выполнить если флаг нулевого результата сброшен
    : IF<> IF_NZ ;
    : IF  IF_NZ ;
: IF_NN (pre) BRMI  ; \ Выполнить если флаг отрицательного результата сброшен 
: IF_N  (pre) BRPL  ; \ Выполнить если флаг отрицательного результата установлен
: IF_NV (pre) BRVS  ; \ Выполнить если флаг переполнения очищен установлен
: IF_V  (pre) BRVC  ; \ Выполнить если флаг переполнения установлен
: IF_NS (pre) BRLT  ; \ Выполнить если больше или равно (со знаком)
: IF_S  (pre) BRGE  ; \ Выполнить если меньше нуля (со знаком)
: IF_NH (pre) BRHS  ; \ Выполнить если флаг внутреннего переноса сброшен 
: IF_H  (pre) BRHC  ; \ Выполнить если флаг внутреннего переноса установлен
: IF_T  (pre) BRTC  ; \ Выполнить если флаг T установлен
: IF_NT (pre) BRTS  ; \ Выполнить если флаг T сброшен 
: IF_NI (pre) BRIE  ; \ Выполнить если прерывания запрещены 
: IF_I  (pre) BRID  ; \ Выполнить если прерывания разрешены

RESTORE-VOCS    
   

