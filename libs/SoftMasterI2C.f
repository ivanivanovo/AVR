\ Программный МАСТЕР I2C
\ Нормальная работа возможна при наличии на шине только одного (этого) мастера,
\ т.е. никто иной не имеет права вмешиваться в протокол обмена.
\ Никаких коллизий и арбитража, так как для этого необходима 
\ аппаратная поддержка, увы.
\ 
\ Чтение.
\ S-AR-sNACK-P - нет данных для чтения
\     \sACK-sN-mNACK-P - пакет не влезет в буфер мастера, пакет остается у слейва
\             \mACK -[sBYTE-mACK]*(N-1)-sBYTE-mNACK-P - ошибка CRC, повтор 
\                                             \mACK-P - чтение пакета, слейв сбрасывает пакет
\ 
\ Запись пока не кончится пакет, в случае отказа слейва принимать (NACK), повторение с начала.
\ S-AW-sNACK-P - некому принимать, мастер сбрасывает пакет
\     \sACK -mN-sNACK-P - пакет не влезет в буфер слейва, пакет остается у мастера
\              \sACK-[mBYTE-sACK]*(N-1)-mBYTE-sNACK-P - ошибка приема пакета (CRC<>0), пакет остается у мастера
\                                            \sACK-P -  успешная запись пакета, мастер сбрасывает пакет

.( SoftMasterI2C.f --- НЕТ защиты от ошибок ВАЩЕ!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!) CR

\ ============== ресурсы =======================================================
\ --- задействованные выводы ----
\ pSDA       - пин линии данных
\ pSCL       - пин линии сторобирования
\ dSDA       - бит направления 
\ dSCL       - бит направления 
\ --- константы ---
    2 CONSTANT I2CadrIW \ адрес всех устройств передающих и принимающих пакеты iw через шину I2C
    I2CadrIW 1 LSHIFT CONSTANT I2CadrIW-W \ адресный байт пакета записи
    I2CadrIW-W 1+     CONSTANT I2CadrIW-R \ адресный байт пакета чтения
\ --- регистры ---
\ (0)        - (...r15) хранитель 0
\ ri2c       - (...r15) рабочий регистр I2C
\ ii2c       - (r16...) счетчик I2C
\ statI2C    - (r16...) статусный регистр


finger CONSTANT StartLibI2C
RAM[ finger CONSTANT StartLibI2Cram ]RAM

#def /SCL \_ dSCL \ отпустить
#def \SCL _/ dSCL \ захватить
#def /SDA \_ dSDA \ отпустить
#def \SDA _/ dSDA \ захватить

#def noFlashOnSDA skip_nb pSDA /SDA skip_b pSDA \SDA \ антивсплеск SDA при смене хозяина линии
\ рабочие названия рабочих регистров
#def A  r
#def B  rH
#def AB R \ пара A и B

0 value @@
: >PAD> ( adr u --adrPad u) >R PAD R@ CMOVE PAD R> ; \ представить строку в PADе
#def :take ( n  --) finger TO @@  finger>    MarkType @@ MarkX >PAD> !label(S):  \ занять память и промаркировать это место
#def ret!  (  -- )  RAM[ 2 :take ]RAM  c[ pop r  mov @@,r  pop r  mov @@ 1+,r ]c \ запомнить адрес вызывателя
#def ret@  (  -- )  c[ mov r,@@ 1+  push r  mov r,@@  push r ]c \ вернуть адрес вызывателя

3 Packs  CONSTANT rxI2CSize  \ размер буфера приема I2C
6 Packs  CONSTANT I2CtxSize  \ размер буфера передачи I2C
\ еще нужно добавть 2 байта к хвосту, так как при передаче
\ пакета iw максимального размера 
\ он займет в буфере I2C на 2 байта больше (AdrRW и N)

RAM[ 
    rxI2CSize BufP: rxI2C   2 finger> \ буфер приема +2 к хвосту
    I2CtxSize BufP: I2Ctx   2 finger> \ буфер передачи +2 к хвосту
    1 take cntByte  \ счетчик байтов
    1 take cntRByte \ количество оставшихся байт для чтения
    ]RAM

BitsIn statI2C
    _BitIs fBusy \ шина занята 
    _BitIs fSi2c \ стартовый байт
    _BitIs fRi2c \ пакет читающий
    _BitIs fIwR  \ флаг приема iw-пакета
    _BitIs fEi2c \ флаг ошибки приема

BitsIn ri2c ( aka adrRW)
    0 #BitIs bitR


code NextByteTx ( -- c=1|c=0;ri2c=A=byte;ii2c=8 ) \ следующий байт для передачи
\ верно если RsizeBufP>0
    mov B,cntByte inc B
    \ B=номер следующего байт [1...n]
    if_b fRi2c \ если чтение
        mov A,cntRbyte subi A,1 mov cntRbyte,r
        ser A  \ n байт 0xFF
    else \ если запись
        ldiW Y,I2Ctx  rcall ReadBufP 
    then
    \ c=1 если запрошеннй байт отсутствует в пакете
    if_nC \ еще есть
        mov ri2c,A \ байт помещен в выходной регистр
        ldi ii2c,8
    then 
    ret c;

code SaveIn ( ri2c -)
    \ учет байт
    mov B,cntByte inc B mov cntByte,B
    if_b fIwR
        cpi B,2 if= mov cntRbyte,ri2c then
    then
    mov A,ri2c ldiW Y,rxI2C 
    rcall WriteBufP t>bit fEi2c \ отказ в записи=ошибка
    ret
    c;

code \SCL/
    \ SDA->b0;b7->SDA
    clc skip_nb pSDA sec \ SDA->c
    noFlashOnSDA
    \SCL
        rol ri2c if_c /SDA else \SDA then \ b->SDA
    /SCL   
    ret c;

code go.. ret! c; \ запомнить адрес возврата
code goI2C
    if_b fBusy 
        \ шина занята
        if_b pSCL  
            tst ii2c
            if_nZ
                \ прием/передача бит
                rcall \SCL/
                \ учет бит
                dec ii2c brne goI2C
                \ принять последний бит
                clc skip_nb pSDA sec \ SDA->c 
                rol ri2c rcall SaveIn
                \ сформировать ACK/NACK мастера
                noFlashOnSDA
                \SCL 
                    \SDA  skip_b fSi2c  skip_b fRi2c  /SDA \ ACK=!fSi2c*fRi2c
                    \_ fSi2c \ используется 1 раз за транзакцию
                /SCL goto goI2C
            else
                ret@ \ возврат по запомненному адресу
            then
        then
    else \ шина свободна
        ldiW Y,I2Ctx rcall RsizeBufP \ проверка наличия данных
        if \ есть данные - начать транзакцию
            \SDA \ Start 
                ldi statI2C,{b fBusy fSi2c } \ mov statI2C,r
                mov cntByte,(0) rcall NextByteTx 
                if_b bitR _/ fRi2c \ пакет чтения
                    cpi r,I2CadrIW-R if= _/ fIwR then
                    ldi r,2 mov cntRbyte,r \ сколько нужно прочитать
                then 
                begin
                    rcall go.. \ передача очередного байта
                while_nb pSDA  \ досрочный выход из цикла если получен NACK
                    rcall NextByteTx
                wait_b C \ выход по концу пакета
                else _/ fEi2c \ досрочный выход=ошибка
                then 
                \ stoP
                \SCL \SDA
                ldiW Y,I2Ctx rcall RendBufP \ скинуть переданный пакет
                ldiW Y,rxI2C  skip_b fEi2c rcall WendBufP \ закончить прием полного пакета
                /SCL rcall go.. 
            /SDA \ -P/ 
            \_ fBusy
        then
    then
    ret c;

code I2Cini
    /SDA \ отпустить шину
    ldiW Y,I2Ctx ldi r,I2CtxSize rcall iniBufP \ инициация буфера передачи
    ldiW Y,rxI2C ldi r,rxI2CSize rcall iniBufP \ инициация буфера приема
    clr statI2C mov cntByte,(0)
    /SCL \ отпустить шину
    ret c;

\eof
CR
finger StartLibI2C - .( LibI2C размеры: Flash= ) 0 .R .( ; )
RAM[ finger ]RAM StartLibI2Cram - .( RAM= ) . CR