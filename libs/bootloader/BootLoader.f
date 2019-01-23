\ загрузчик 
[NOT?] ESC> [IF] S" console_codes.f" INCLUDED [THEN]
[NOT?] 2VARIABLE [IF] S" lib/include/double.f" INCLUDED [THEN]

4 CONSTANT WDatMax  \ максимальный размер пакета данных, в словах
2VARIABLE fprgWad   \ adr u полученного пыжа, u используется как флаг
VARIABLE fNewBoot   \ флаг необходимости сменить загрузчик 
0 VALUE fidext      \ fileid файла сценария
0 VALUE OldSig      \ старая сигнатура
[NOT?] LastBoot [IF] 0 CONSTANT LastBoot [THEN]   \ адрес перехода после загрузки

\ из-за ATtiny441-841 у которых стирается сразу 4 страницы
\ придеться проверять размеры и брать в работу больший из них
\ max CONSTANT (PAGESIZE) \ Words
\ загрузчик в чипе тоже должен это проверять и учитывать
\ ==================== либы ==========================================================

\ =============== система программирования ===================================
: (B>W) ( ofs -- ofsW) 2/ ; \ перевод байтов в слова
: (W>B) ( ofsW -- ofs) 2* ; \ перевод слов в байты

\ структура для сборки пакета программирования
0
1 -- prgS       \ семафор программирования
1 -- cmd        \ флаги команды
1 -- ZLpoint    \ адрес записи младший байт
1 -- ZHpoint    \ адрес записи старший байт
1 -- ZEpoint    \ адрес записи дополнительный старший байт
WDatMax (W>B) -- Wdat \ WDatMax*2  байт данных
CONSTANT StructPrg


DEFER Boot> ( adr u --) \ отправка пакета
\ ' xBoot> IS Boot> \ по умолчанию используется из iwLink.f
\ ' Boot>. IS Boot> \ для тестирования протокола программирования
{b fVec } CONSTANT bVec
{b fRst } CONSTANT bRst
{b fWrt } CONSTANT bWrt
{b fXor } CONSTANT bXor

: Boot>. ( adr u --) \ показка пакетов 
    HEX[ 
        OVER  C@ DUP 2 ,0R >S
        DUP prgVsig = 
        IF DROP ." sig: " S@ TYPE ." | " DROP cmd @ 8 .0R  ELSE
            DUP prgUID  = 
            IF DROP ." uid: " S@ TYPE ." | " DROP cmd @ 8 .0R  ELSE
                prgCMD01 =
                IF ." prg: " S@ TYPE ." | "  \ prg
                    OVER  cmd C@ \ cmd
                    DUP bVec AND IF ." v" ELSE ." ." THEN
                    DUP bRst AND IF ." r" ELSE ." ." THEN
                    DUP bWrt AND IF ." w" ELSE ." ." THEN
                        bXor AND IF ." x" ELSE ." ." THEN
                    ." | "
                    2 /STRING
                    OVER @ 0xFFFFFF AND ." 0x" 6 .0R ."  |" SPACE
                    3 /STRING
                    OVER + SWAP 
                    ?DO I C@  2 .0R  SPACE    LOOP
                ELSE 2DROP
                THEN
            THEN
        THEN
        S>DROP 
    ]HEX CR
    ;
' Boot>. is Boot> \ показать пакеты программирования

: WaitPrgWad ( --) \ ждать пыжика от программируемого чипа
    fprgWad @ IF exit THEN \ не ждать
    getMs 2000 + \ засечь время
    begin \ контроль времени ожидания
        getMs OVER  > ABORT" нет ответа"
        fprgWad @ \ проверить получение
        2 PAUSE
    until
    DROP
    fprgWad 2@ DROP
    1+ W@ SigLoader <>  fNewBoot !
    0 0 fprgWad 2!  \ погасить его
    ." ." \ показать получение
    ;

: xBoot> ( adr u --) \ отправка пакета
    \ по умолчанию используется поключенный интерфейс (UART,USB)
     >FIFO 
    \ OutPacks SFIFO! 
    WaitPrgWad \ ждать пыжика от программируемого чипа
    ;
 ' xBoot> IS Boot>

 

: Boot>f ( adr u -- ) \ отправить пакет программирования в файл
    fidext 
    IF  fprgWad @ IF S" x" ELSE S" w" THEN  >S \ новая строка
        OVER prgS C@ prgCMD01 =
        IF  OVER cmd C@
            bWrt AND IF [CHAR] p S@ DROP C! THEN
        THEN
        OVER + SWAP ?DO I C@ HEX[ 2 ,0R ]HEX +>S LOOP
        S@ fidext WRITE-LINE THROW S>DROP 
    ELSE 2DROP
    THEN
    ;


: packBoot[ ( adr cmd --) \ шапка пакета программирования
    NEW>S
    prgCMD01 EMIT>S
    EMIT>S
    |3 ROT EMIT>S SWAP EMIT>S EMIT>S
    ;

: ]packBoot ( f -- ) \ завершение и отправка пакета
    \ f=true ждать ответного пыжа
    \ f=false не ждать ответного пыжа
    0= DUP fprgWad 2!
    S@  Boot>   S>DROP  \ отправка пакета
    ;
: PingBoot ( -- ) \ проверочный пакет программатора
    0 0 packBoot[  \ простая запись
    TRUE ]packBoot \ что-б ждал пыжика
    ;

: GoBoot ( adr --) \ выход из загрузчика по adr
    (B>W) bRst packBoot[ 
    FALSE ]packBoot \ что-б не ждал пыжика
    ;    

FLASHEND 1+     CONSTANT FlashSize  \ размер памяти в словах
FlashSize (W>B) CONSTANT FlashSizeB \ размер памяти в байтах

FlashSizeB DUP createSeg: Img-SEG \ сегмент образа прошивки чипа
: Img[ SAVE-SEGMENT Img-SEG TO SEG ;
: ]Img RESTORE-SEGMENT ;
: ImgWender ( -- b) Img[ wender ]Img ;
: clrImg Img[ 0 SegA SEG-SIZE @ TRUE FILL ]Img ; \ очистить образ
clrImg \ очистить образ

FlashSize DUP createSeg: Msk-SEG \ сегмент маски образа
\ Один байт маски соответствует одному слову в образе
\ если по смещению (в словах) в маске FALSE - данных в образе нет
\ если по смещению (в словах) в маске TRUE  - данным в образе можно верить
: Msk[ SAVE-SEGMENT Msk-SEG TO SEG ;
: ]Msk RESTORE-SEGMENT ;
: clrMsk Msk[ 0 SegA SEG-SIZE @ FALSE FILL ]Msk ; \ очистить маску
clrMsk \ очистить маску

: Discount ( ofsW u -- ofsW' u') \ сравнить текущий сегмент с образом
    \ ofsW' u' остаток строки с первым не совпадающим словом в начале
    BEGIN 
        OVER (W>B) ImgWender  ( ..ofs wender' )
        DUP 0> -ROT > 0= AND \ wender>0 И ofs НЕ больше wender  
        OVER  0> AND \ И u>0 
        IF  \ получить и сравнить слова
            OVER (W>B) DUP 
            segA  W@
            SWAP Img[ segA W@ ]Img
            =
        ELSE FALSE THEN
    WHILE \ пока сравнимы И одинаковы
        1 /STRING \ перйти к следующему слову
    REPEAT
    ;

: FindImgBoot ( VSign -- ) \ поиск и загруза образа старой прошивки
    Pref >S 2 HEX[ ,R ]HEX +>S Suff +>S 0 EMIT>S S@
    R/O OPEN-FILE 
    if DROP Img[ 0 Seg-wender ! ]Img \ образа нет, прямая загрузка
      clrMsk \ очистить маску
    else \ есть образ, разностная загрузка
        CLOSE-FILE THROW
        Img[ S@ LOAD-AS-HEX wender (B>W) 1- ]Img
        Msk[ 0 SegA SWAP TRUE FILL \ заполнить маску
            ]Msk 
    then S>DROP
    ;

: CreateNewDext ( VSign -- fid ) \ поиск и загрузка сценария прошивки
    Pref >S 
        2 HEX[ ,R ]HEX +>S
            S" to" +>S
                VSign 2 HEX[ ,R ]HEX +>S
                    S" .dext" +>S
                        0 EMIT>S 
    S@ R/W CREATE-FILE THROW  \ создать новый файл
    S>DROP
    ;


80 CONSTANT SizePackLine
SizePackLine ALLOCATE THROW CONSTANT packLine \ приемная строка пакетов
: PlayDext ( fid -- )
    BEGIN
        DUP packLine SizePackLine ROT
        READ-LINE THROW 
    WHILE
        packLine SWAP \ adr u
        DUP 
        IF  OVER C@ >R 1 /STRING
            R@ [CHAR] t = 
            IF 0 S>D 2SWAP >NUMBER 2DROP D>S ." PAUSE " DUP . PAUSE CR
            ELSE  FALSE   
                R@ [CHAR] x =  R@ [CHAR] s = OR 
                OR  DUP fprgWad 2!
                R@ [CHAR] x =
                R@ [CHAR] w = OR
                R@ [CHAR] p = OR
                R@ [CHAR] s = OR 
                IF  Hex2Bin Boot> 
                ELSE 2DROP 
                THEN
            THEN
            R> DROP
        ELSE 2DROP    
        THEN
    REPEAT
    2DROP 
    ;
\ S" hex/palf-10DB4056to10095260.dext" R/O open-file throw  playdext

: PgBegin ( ofsW -- ofsW0 u) \ выравнивает смещение на начало страницы
    \ u - слов до ofsW
    (PAGESIZE) /mod  (PAGESIZE) * SWAP
    ;
: PgEnd ( ofsW -- ofsW u) \ слов до конца страницы
    DUP
    PgBegin NIP (PAGESIZE) SWAP - 
    ;


\ ==========================================================
FALSE VALUE pseudo \ флаг псевдозаписи

: getWord ( ofsW -- w cmd ) \ получить слово и команду для его корректной записи
    pseudo 
    IF DROP 0 bXor \ псевдозапись, страница не изменяется
    ELSE \ реальная запись   
        DUP wender (B>W) < 0=
        IF DROP 0 bXor ELSE
            DUP (W>B) SegA W@ 
\            OVER Img[ wender (B>W) ]Img < 0=
            OVER Msk[ \ проверить наличие данных в образе, по маске 
                org ['] Seg>C CATCH IF FALSE THEN ]Msk 
            0=
            IF NIP 0
            ELSE SWAP (W>B) ( ..w  imgAdr)
                Img[ segA W@ ]Img  ( w w')  
                XOR bXor
            THEN
        THEN
    THEN
    ;

: Word>S ( w --) |2 SWAP EMIT>S EMIT>S ;
: cmdA ( -- adr_cmd) \ получить адрес текущей команды
    S@ DROP cmd 
    ;
: Wrd2Imd ( ofsW -- ) \ копировать слово из текщего сегмента в образ
    pseudo IF DROP ELSE \ ничего не делать
    DUP Msk[ org TRUE C>SEG ]Msk \ отметить факт записи в маске образа
    (W>B) DUP segA W@ \ получить оригинал
    SWAP Img[ org W>SEG ]Img  \ записать в образ
    THEN
    ; 

: [Pack] ( ofsW u -- u1) \ сделать пакет программирования 
    \ u <=WDatMax
    DUP >R \ R:u1=u
    DUP
    IF  OVER DUP getWord >R  SWAP (W>B) R> 
        packBoot[ \ начать пакет
            BEGIN \ ofsW u w
                Word>S  \ дополнить пакет
                OVER Wrd2Imd \ заменить слово в образе
                1 /STRING \ ofs u
                OVER (PAGESIZE) mod  0= IF cmdA C@ bWrt OR cmdA C! THEN
                OVER getWord  \ ofs u w c
                cmdA C@ = \ ofs u w f
                >R OVER R> AND 0= \ выполнять пока не измениться команда 
                \ или не кончатся слова
            UNTIL DROP 
        TRUE ]packBoot \ отправить пакет
    THEN ( ofsW' u') NIP R> SWAP - 
    ;
\ ==========================================================
: (PgLoad) ( ofsW u -- ofsW+u 0   )
    DUP IF  2DUP WDatMax MIN  [Pack]
            /STRING RECURSE 
        THEN 
    ;
: PgLoad ( ofsW u f-- ) \ загрузка одной страницы, u<=(PageSize)
    0= TO pseudo
    (PgLoad) 2DROP
    ;

: [Page] ( #Page -- ) \ запись целой страницы
    (PAGESIZE) *  (PAGESIZE) \ ofsW u
    TRUE PgLoad
    ;

: SetStartVector ( vect cmd f --) \ установка стартового вектора
    >R \ флаг указывает как переписывать остальное векторное поле
    \ FALSE - не переписывать, оставить как есть
    \ TRUE  - привести в соответствие с загружаемым кодом
    0 SWAP packBoot[ |2 SWAP EMIT>S EMIT>S  TRUE ]packBoot \ что-б ждал пыжика
    1 PgEnd R> PgLoad
    ;


: 4>S ( u--)
    |4 
    SWAP 2SWAP SWAP
    EMIT>S EMIT>S EMIT>S EMIT>S
    ;
: setBoot ( u -- )
    4>S
    FALSE ]packBoot \ что-б не ждал пыжика
    PingBoot
    ;
: SignBoot! ( VSign -- ) \ загрузка групповая
    NEW>S prgVsig EMIT>S 
    setBoot 
    ;
: UIDBoot! ( UID -- ) \ загрузка индивидуальная
    NEW>S prgUID EMIT>S 
    setBoot
    ;
: GoBoot(VSign) ( adr --) \ переход по адресу с VSign в параметрах
    (B>W) bRst packBoot[ VSign 4>S FALSE ]packBoot
    ;
: inPage ( ofsW -- #Page) \ определить номер страницы
    (PAGESIZE) / 
    ;
: [PagesBoot] ( ofsW u -- ) \ прогрузка отличных страниц
    BEGIN
        Discount \ отрезать совпадающие части
        DUP 
    WHILE
        OVER inPage [PAGE] \ загрузить одну странице
        OVER (PAGESIZE) MOD (PAGESIZE) SWAP - 
        OVER MIN /STRING \ выровнять на начало следующей страницы
    REPEAT 2DROP
    ;    


: [changeBoot] ( -- ) \ замена загрузчика
    ." ========= смена загрузчика =========" CR 
    copyBoot[
        NewBoot (B>W) NewBootEnd (B>W) OVER -
        [PagesBoot] \ загрузка нового загрузчика и копировщика
    ]copyBoot
        copyBoot GoBoot \ запуск копирования
        S" t1000" fidext WRITE-LINE THROW
    Img[ \ дубляж работы копировщика
        NewBoot segA 0 segA (PAGESIZE) (W>B) cntPage *
        MOVE
    ]Img    
    Msk[ \ отметить дубляж в маске 
        0 SegA (PAGESIZE) cntPage * TRUE FILL
    ]Msk
    ;

: BOOTer? ( -- f ) \ проверить  загрузчик
    fNewBoot  @
    ImgWender 
    IF \ есть образ, сравнение областей, 
        ROM_FREE (B>W) SizeLoader (B>W) OVER - Discount \ исключая векторное поле
        NIP 0>
        OR
    ELSE \ образ неизвестен
        fNewBoot  @ 0=
        IF  \ если загрузчик менять не нужно
            \ скопировать его в образ
            FALSE TO pseudo
            EndBootWad (B>W)  ROM_FREE (B>W)
            DO I Wrd2Imd LOOP
        THEN
    THEN    
    ;

: checkOut ( -- ) \ проверка на корректность 
    \ преобразования старой прошивки в новую
    0 wender ImgWender MIN (B>W) 
    Discount ABORT" Преобразование НЕ корректно!!!"
    DROP
    ;

: SignBoot ( VSign -- )
    DUP VSign = 
    IF ." Загрузка не требуется" DROP CR 
    ELSE
        DUP SignBoot! \ завис примерно 0,5 сек
        DUP FindImgBoot 
        CreateNewDext TO fidext
        ['] Boot>f IS Boot> \ перестройка вывода на файл сценария
        \ фиксировать режим записи
        VectBoot bVec  FALSE SetStartVector
        \ проверить загрузчик
        BOOTer? IF [changeBoot] THEN
        \ прогрузка страниц
        EndBootWad (B>W) wender (B>W) OVER -
            [PagesBoot]
        \ стартовая страница
        0 SegA w@ 0 TRUE SetStartVector \ стартовая страница
        0 Wrd2Imd \ стартовый вектор, прямое дублирование (для прохождения проверки)
        0 ROM_FREE [PagesBoot] \ векторное поле, это нужно если поле больше страницы
        LastBoot GoBoot(VSign) \ переход после загрузки
        checkOut \ проверка перед записью
        \ переставить вывод на печать или программирование
        linkDev IF ['] xBoot> ELSE ['] Boot>. THEN IS Boot>
        \ начать читать сценарий с начала
        0 S>D fidext REPOSITION-FILE THROW
        fidext PlayDext \ прошивка или печать
        fidext CLOSE-FILE THROW 0 TO fidext
        CR ." =========" ."  Загрузка завершена " ." =========" 
    THEN
    CR
    ;

\ запрос сигнатуры текущего устройства
#def Sign? r[ cVID cPID all :dest Signature 4 ]>>

: Boot ( -- ) \ загрузка
    0 TO OldSig
    Sign? \ запросить сигнатуру
    100 PAUSE
    \ ждать ответа 1 секунду
    getMs 1000 + \ засечь время
    begin \ контроль времени ожидания
        getMs OVER  > ABORT" нет ответа сигнатуры"
        OldSig \ 0= \ проверить получение
        2 PAUSE
    until DROP
    OldSig SignBoot
    ;


WARNING @
    WARNING OFF
    : lAP ( adr u --) \ локальный анализатор пакетов 
        \ поймать сигнатуру прошивки
        ?dup 
        if  OVER c@ 4 / DtPac =
            if 2DUP OVER c@ 3 AND 2+ /STRING \ a->nofs
                OVER NOFS@ NIP Signature =
                IF 2 /STRING OVER @ TO OldSig ." Сигнатура в чипе: " OldSig .HEX CR THEN
                2DROP
            then
            lAP
        else drop 
        then ;
    ' lAP IS toolpack

    : lAP ( adr u --) \ локальный анализатор пакетов 
        \ поймать пыжик программирования
        ?dup 
        if  OVER c@ prgCMD01 =
\            if  Boot>. \ пакеты программирования показывать
            if  2DROP \ пакеты программирования не показывать
            else OVER C@ prgWad  ( 0xe8) =
                if fprgWad 2! \ отметить прием пыжа программирования
                ELSE lAP \ дальше по цепочке lAP
                then
            then
        else drop 
        then ;
    ' lAP IS toolpack
WARNING !

CR
S" [33m" ESC>
.( Подсказки:) CR
.(      чтение сигнатуры: Sign? ) CR 
CR
.(      для перепрошивки: Boot ) CR
.(      для обновления определенной сигнатуры: 0x) VSign .hex .( SignBoot ) CR
defoltText CR


