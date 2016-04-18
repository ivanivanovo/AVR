\ структура opcodes
\ автор: ~iva дата: 2010 ревизия: 1
\ ======== ИНФО ================================================================
\ структура opcodes
\ ==============================================================================
\ cmd: ADC    Rd, Rr ; ---v         Opcode: 000111rdddddrrrr      
\ ============================================================== слова доступа==
\ adr               поле связи (link)   CELL обязательно            @
\ 000111000000000   клише               CELL обязательно            clishe
\ 111111000000000   маска               CELL обязательно            mask
\ u"ADC"            шаблон              C-STRING обязательно        mnemo
\ u"Rd"             id1                 C-STRING обязательно      1 op.id
\ 000000111110000   маска 1 оператора   CELL   обязательно        1 op.mask
\ xt0               слово-обработчик    CELL   обязательно        1 op.exec  
\ u"Rr"             id1                 C-STRING обязательно      2 op.id
\ 000001000001111   маска 2 оператора   CELL   обязательно        2 op.mask
\ xt1               слово-обработчик    CELL   обязательно        2 op.exec 
\ ======== ЗАДАЧИ ==============================================================
\ ======== ПОДКЛЮЧАЕМЫЕ ФАЙЛЫ и слова нужные не только здесь ===================
S" ~iva/AVR/toolbox.f"     INCLUDED \ инструментальные слова


\ ======== КОНСТАНТЫ И ПЕРЕМЕННЫЕ ==============================================
VOCABULARY DASSM    \ словарь для команд ассемблера
VARIABLE opcodes    \ начало цепного списка opcodes
\ ======== СЛУЖЕБНЫЕ СЛОВА ДЛЯ ОПРЕДЕЛЕНИЯ ГЛАВНЫХ СЛОВ ========================
: <DASSM SAVE-VOCS  ALSO DASSM DEFINITIONS ; 
: DASSM>  RESTORE-VOCS ; 
\ ============ слова навигации в структуре opcodes =============================
: clishe ( adr-link -- adr-clishe) \ дать адрес клише команды
    CELL+ ;
: mask ( adr-link -- adr-mask) \ дать адрес маски команды
    clishe CELL+ ;
: mnemo ( adr-link -- adr-str) \ дать адрес строки со счетчиком = мнемоника
    mask CELL+ ;
\ ------------------------------------------------------------------------------
: op.id ( adr-link № -- adr-id) \ дать адрес идентификатора №-ого операнда
    SWAP mnemo COUNT + 
    BEGIN ( # adr-op.id)
        SWAP 1- ?DUP 
    WHILE    
        SWAP COUNT + 2 CELLS +
    REPEAT ;
: op.mask ( adr-link № -- adr-mask) \ дать адрес маски №-ого операнда
    op.id COUNT + ;    
: op.exec ( adr-link № -- adr-exec) \ дать адрес xt обработчика №-ого операнда
    op.mask CELL+ ;    
\ ============ слова для создания структуры opcodes ============================
: <<- ( adr --) DUP @ 1 LSHIFT SWAP ! \ сдвинуть на 1 разряд переменную
    ; 
[WITHOUT?] 1+! \ если в системе не определено, то определим
: 1+! ( adr --) DUP @ 1+ SWAP ! ; \ увеличить переменную на 1
[THEN]
: op.mask<<- ( adr-link --) \ сдвинуть на 1 разряд маски операндов opcode-s
   \ взвести цикл по операндам
    3 1 DO \ adr-link
            DUP I op.mask  <<-         
        LOOP 
    DROP ;   
: <<<  ( adr-link --) \ сдвинуть на 1 разряд все маски структуры opcode-s
    >R 
        R@ clishe <<-
        R@ mask   <<-
    R>     op.mask<<-
    ;
: искать-id ( char adr-opcode -- № TRUE | CHAR FALSE) 
    \ искать в текущем opcode операнд с id=char
    SWAP >R \ запомнить char
    3   BEGIN 1- DUP
        WHILE ( adr-op #) 
            2DUP op.id R@ SWAP COUNT OVER + SWAP
            DO ( adr-op # char)
                I C@ OVER = IF DROP 0 LEAVE THEN 
            LOOP 0= IF NIP TRUE R> DROP EXIT THEN
        REPEAT R> FALSE
    ; 
: operands ( char --) \ обработать операнд с id=char
    \ если есть => отметить текущую позицию единичкой
    \ если такого нет => ругаться
    opcodes @ искать-id  
            IF opcodes @ SWAP op.mask  1+! \ отметить 
            ELSE  ABORT" символ не найден."
            THEN 
    ;

: -comma ( u-adr  -- u'-adr) \ убрать замыкающую запятую
    DUP >R 
    COUNT + 1- C@ [CHAR] , = IF R@ C@ 1- R@ C! THEN 
    R> ;
: пусто ; \ пустое слово для отсутствующих операндов
: -op ( --) S" нет" str! 0 , ['] пусто , ; \ нет операнда
: next-op ( -- c-adr f)
    BL WORD -comma DUP
    COUNT S" ;" COMPARE 
    ;    
: save-op ( c-adr --) \ создать запись операнда
    DUP COUNT str! \ id операнда
    0 ,            \ маска операнда 
    FIND 0= -321 AND THROW \ вылет, если не найдено слово-обработчик
    , ; \ обработчик операнда

\ =========== сервисные слова для просмотра структуры ==========================
: CMD> ( adr-link --) \ показать структуру
    ." ================================" CR
    BIN[ DUP clishe @ 32 .0R ."  <-клише" CR
         DUP mask   @ 32 .0R ."  <-маска" CR 
         DUP mnemo COUNT TYPE CR
          3  1 DO
                DUP I op.id  COUNT TYPE CR \ id оператора
                DUP I op.mask @ 32 .0R  CR \ его маска
                DUP I op.exec @ HEX[ 8 .0R ]HEX CR \ его обработчик
              LOOP DROP
    ]BIN    
    ." ================================" CR ;
\ пример использования
\ c[ ' sbrc >body cmd> ]c

: #CMD> ( n --) \ показать n-ую структуру, считая от последнего введенного
    opcodes SWAP
    0 DO @ LOOP
    CMD> ;
: listCMD ( -- ) \ показать список введённых команд
    opcodes 
    BEGIN 
        @ >R 
        R@ mnemo COUNT TYPE SPACE
        R@ 1 op.id COUNT 2DUP S" нет" COMPARE  
        IF TYPE  
           R@ 2 op.id COUNT 2DUP S" нет" COMPARE  
           IF ." , " TYPE ELSE 2DROP THEN 
        ELSE 2DROP THEN CR
        R@ clishe @ R@ mask @ OR 
        R> SWAP
    WHILE REPEAT
    DROP
    ;

\ ======== ГЛАВНЫЕ СЛОВА =======================================================
DEFER coder  

: cmd: ( <"name" text;> --) 
    >IN @ 
    <DASSM CREATE DASSM> \ команды создаются в словаре DASSM
        opcodes @ HERE opcodes ! , \ ввести в цепь
        \ opcodes теперь указывает на текущее определение \ link
        65536 , 65536 , \ клише, маска 
        ( по умолчанию 0x10000, т.е. на 1 больше 0xFFFF, 
        это позволит описывать псевдокоманды, не имеющих opcode)
    >IN ! BL WORD COUNT str!  \ мнемоника
        0 BEGIN next-op WHILE save-op 1+ REPEAT DROP  \ запись операндов
        2 SWAP - \ скольких нет?
          BEGIN DUP 0 > WHILE -op 1- REPEAT DROP  \ запись отсутствующих 
    DOES>  coder
    ; 
: Opcode: ( "bits-symbols" -- )  \ разобрать код операции на составляющие
    BL WORD COUNT \ adr u 
    OVER + SWAP \ подготовка цикла 
    DO \ цикл по символам строки (I указатель на символ)
        opcodes @ <<< 
        I C@ 
           DUP [CHAR] 0 = 
           IF opcodes @ mask 1+!  DROP
           ELSE 
                DUP [CHAR] 1 = 
                IF opcodes @ mask 1+!  opcodes @ clishe 1+!  DROP
                ELSE operands 
                THEN     
           THEN
    LOOP 
    ;
: ext: ( "bits-symbols" -- )  \ расширить код операции с учетом новой информации
    \ расширяются только маски операндов, так как "опознание" происходит 
    \ в любом случае по маш.слову (16 бит), а выделение операндов из кода 
    \ операции - по полному коду (16 или 32 бита (если есть расширение))
    BL WORD COUNT \ adr u 
    OVER + SWAP \ подготовка цикла 
    DO \ цикл по символам строки (I указатель на символ)
        opcodes @ op.mask<<- \ сдвинуть маски операндов
        I C@ operands 
    LOOP 
   ; 
\ ======== ТЕСТЫ И ПРИМЕРЫ =====================================================

