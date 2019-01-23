\ USI в двухпроводном режиме
\ мультимастер
\ приемо-передатчик
\ автор: ~iva март 2016
\ формат приема-передачи:
\ [Start]byte[CRC0]....byte[CRC0][stoP]
\ после получения [stoP], проверяется последний принятый бит CRC0
\ если 0 - брак, 1 - Ок
\ формат должен быть совместим с модулями TWI

\ ============== ресурсы =======================================================
\ --- задействованные выводы ----
\ pSDA       - пин линии данных
\ pSCL       - пин линии сторобирования
\ dSDA       - бит направления 
\ dSCL       - бит направления 
\ --- константы ---
\ USItxSize - размер буфера передачи        
\ rxUSISize - размер буфера приёма 
\ minCLK    - \ константа минимальной длительности импульса USI, в тактах CPU
\ --- регистры ---
\ (0)        - (...r15) хранитель 0
\ USIcrc8    - (...r15) учет CRC
\ cntByte    - (...r15) счетчик байт USI
\ USIstatus  - (r16...) статусный регистр


\ 32 CONSTANT rxUSISize \ размер буфера приема USI
\ 32 CONSTANT USItxSize \ размер буфера передачи USI
\ 16 CONSTANT MaxSizePack \ максимальный размер пакета

[NOT?] BufP [IF] S" pFIFO.f" INCLUDED [THEN]

BitsIn USIDR   
    0 #BitIs dr0   \ входной  бит регистра
    7 #BitIs dr7   \ выходной бит регистра 
BitsIn USIstatus \ статусный регистр (16..)
    \ 0-3 биты счетчик принятых бит
    3 #BitIs fByte  \ передано 8 бит
    4 #BitIs fUSI   \ флаг USI

    6 #BitIs fB     \ флаг приема байта
    7 #BitIs f9     \ флаг приема бита


RAM[ 
    [NOT?] USItx [IF] USItxSize BufP: USItx [THEN] \ буфер передачи
    [NOT?] rxUSI [IF] rxUSISize BufP: rxUSI [THEN] \ буфер приема
    ]RAM


\ рабочие названия рабочих регистров
#def A  r
#def B  rH
#def AB R \ пара A и B

Finger VALUE StartLib_USI  \ маркер начала  либы

code USIdisable \ отключить USI
    \_ dSDA  \_ dSCL \ освободить линии
    ldi A {b USISIF USIOIF USIPF } out USISR A \ гасим флаги и инициализируем счетчик 
    out USICR,(0)
    ret c;

code ListenUSI ( -- ) \ слушать линии
    clr cntByte \ счетчик оборотов цикла
    begin
        skip_b  pSCL goto ListenUSI \ ждать 1 на SCL
        skip_nb USIPF  ret \ выход по флагу
        skip_nb USISIF ret \ выход по флагу
        dec cntByte \ 256 оборотов при 1 на SCL
    wait0
    ret c; \ ListenUSI val? \ выход по оборотам

code USIreset \ инициация после сброса
    \ инициация буферов
    ldiW Y,USItx  ldi A,USItxSize rcall iniBufP \ инициация буфера передачи
    ldiW Y,rxUSI  ldi A,rxUSISize rcall iniBufP \ инициация буфера приема
    \ начало
    \_ dSDA 
    ldi A,{b USISIF USIOIF USIPF } out USISR,A \ гасим флаги и инициализируем счетчик 
    _/ SCL _/ dSCL  \ в худшем случае PF или USICNT[0..3]=1
    \ двухпроводный режим с захватом SCL по старту
    \ без прерываний
    ldi A,{b USIWM0 USICS1 } out USICR,A 
    rcall ListenUSI
    clr USIstatus clr cntByte mov USISR,(0) 
    \ аппаратные флаги сохранены, счетчики и программные флаги сброшены
    _/ USIWM1 \ с захватом SCL по переполнению
    \ pSDA=1  вход
    \ pSCL=1  выходной
    \ режим slave
    ret c; \ USIreset val?

\ =========================== продпрограммы ===================================
code NextByteTx ( -- c ) \ следующий байт для передачи
\ верно если RsizeBufP>0
    mov B,cntByte inc B
    \ B=номер следующего байт [1...n]
    ldiW Y,USItx  rcall ReadBufP 
    \ c=1 если запрошеннй байт отсутствует в пакете
    if_nC \ еще есть
        out USIDR,A \ байт помещен в выходной регистр
        \ обнулить cntBit и запомнить бит для передачи
        andi USIstatus,{b f9 fB } 
        skip_nb dr7 _/ fUSI 
    then 
    ret c;

\ =================== станции КА USI ==========================================
code prtTUSI \ обработка протокола TUSI
    \ определение состояния протокольного автомата
    if_b  fB 
        skip_b USIOIF ret
        _/ SCL \ освободить, на случай если был захат портом
        if_nb f9 \ WaitByte ------------------------------------------------------------
            skip_b fByte
            if_b dSDA \ мастер принимает каждый бит
                inc USIstatus \ увеличить счетчик принятых битов
                \ проверить коллизию
                skip_b dr0 \ получен 0..
                if_b fUSI \ .. если передавали 1
                    \ коллизия
                    \_ dSDA \ отобрать погремушку у проигравшего мастера
                    \ слейв, восстановить счетчик фронтов в USISR..
                    mov A,USIstatus ori A,0x78 lsl A  \ A=2*cntBit=b1111.xxxx
                else 
                    \ нет коллизии
                    \_ fUSI skip_nb dr7 _/ fUSI \ запомнить бит для передачи 
                    ldi A,{b USISIF USIOIF USIPF } 14 + 
                then    
                \ если байт передан не полностью..
                \ ..мастер идет на быстрый круг
                \ ..новому слейву ждать следующий USIOIF
            skip_b fByte  \ иначе передан полный байт - провал в else
            else \ байт
                \ сохранить байт
                mov A,USIDR mov B,cntByte inc B ldiW Y,rxUSI rcall WriteBufP
                if_t  ret then \ нет места
                \ байт успешно сохранен 
                \ перейти на прием 9-го бита..
                ldi USIstatus,{b f9 fB } \ ..и сбросить cntBit
                \ запомнить свою роль в fUSI ( мастер=1, слейв=0)
                skip_nb dSDA _/ fUSI
                inc cntByte \ увеличить счетчик байтов
                \ сформировать 9-й бит
                \ проверить CRC
                eor USIcrc8,A
                if  ldi A,Polynomial
                    ldi B,8 
                    for \ цикл по битам
                        lsl USIcrc8 if_c eor USIcrc8,A then
                    next B
                    tst USIcrc8
                then
                if \_ dr7 else _/ dr7 then \ без дрожания линии SDA
                _/ dSDA ( все Мастера!) \ выставить CRC=0 на всеобщее обозрение 
                \ освободить SCL
                ldi A,{b USISIF USIOIF USIPF } 14 +  
            then
        else \ WaitBit9 ------------------------------------------------------------
            \ восстановить роль из fUSI
            skip_b fUSI \_ dSDA \ слейва
            \ прогноз перейти на WaitByte
            \ и запомнить в fUSI принятый бит NoErr
            ldi USIstatus,{b fB }  skip_nb dr0 _/ fUSI
            ldi A,{b USIOIF } \ погасить флаг
            if_b dSDA \ мастеру.. 
                \ .. проверить конец пакета
                rcall NextByteTx
                \ .. перейти на..
                if_c ldi A,{b USIOIF } \ погасить флаг
                     \_ fB _/ f9 \_ SDA _/ dr7 \ .. stoP
                else ldi A,{b USIOIF } 14 +    \ на байт, установить счет 
                then
            then
        then
        out USISR,A \ гасим флаги и инициализируем счетчик
    else
        if_nb f9 
        \ WaitStart -----------------------------------------------------------
            ldiW Y,USItx rcall RsizeBufP
            if \ есть данные, статуем как мастер
                \_ SDA _/ dSDA
            then
        then
    then
    ret c; \ stoP 

code [USI] \ флаговый автомат USI
    if_b USIPF  \ получена стоповая кондиция
        ldi A,{b USIPF }  out USISR,A \ погасить флаги
        andi USIstatus,{b fUSI } \ синхронизация  
        if \ fUSI=1
            \ принять-сбросить пакет
            if_b dSDA
                \_ dSDA
                \ мастер не принимает свой пакет (антиЭхо), но ..
                ldiW Y,USItx rcall RendBufP \ ..скидывает переданный пакет
            else
                ldiW Y,rxUSI rcall WendBufP \ слейв принимает пакет
            then
        then
    then
    \ тут может вклиниться прерывание и возможен пропуск stoP
    \ до прерывания стопа не было, а после - стор и старт одновременно
    \ чревато потерей уже принятого пакета
    if_b USISIF \ получена стартовая кондиция 
        skip_nb USIPF goto [USI] \ доп проверка 
        _/ SCL \ на случай если сам создал Start
        \ линия SCL удерживается флагом USISIF
        ldi USIstatus,{b  fB } \ синхронизация
        ldi B,0xAC mov USIcrc8,B \ подготовить CRC
        clr cntByte rcall NextByteTx \ попытка получить байт для передачи
        rcall RsizeBufP  \ проверить наличие данных
        if \ старт мастера
            _/ dSDA  
            ldi A,{b USISIF  } 14 +    
        else  \ старт слейва 
            \_ dSDA 
            ldi A,{b USISIF  }  
        then
        _/ SDA \ освободить дорогу регистру USIDR
        mov USISR,A \ погасить флаг
        ret
    then    
    rcall prtTUSI \ обработка протокола TUSI
    skip_nb dSDA skip_b pSCL ret \ выход не мастера или SCL=0
    \ если мастер обнаружит 1 на pSCL ..
    minCLK 3 / [IF] ldi A,minCLK 3 / for next A [THEN] \ чуть задержимся
    skip_nb f9 if_nb fB  _/ SDA  ret then \ .. поднимем SDA (stoP)
    \_ SCL  \ .. положим SCL 
    goto [USI] \ и заходим на быстрый круг
    c;

code USIdo \ конечный автомат USI, должен постоянно call из основного цикла
    \ большой круг
    pushW AB pushW Y
        rcall [USI]
    popW Y  popW AB
    ret  c; \ USIdo val?

finger StartLib_USI - . .( <==== размер либы USI) cr

all value dst
#def rst to dst e[ 1 7 dst :dest 0 ]>>


\eof
#def tst to dst e[ 1 7 dst :dest usitest :f ]>>  100 pause r[  1 7 all :dest rxUSI 1 +   10 ]>> sr[  1 7 all :dest USIsr 32 +  1 ]>>
