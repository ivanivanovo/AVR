\ пакетные линейные буферы FIFO
\ структура буферов:
\  имя---v
\  чистый размер буфера, под данные
\  индексЧтения=смещение от начала буфера до размера непрочитаного пакета
\  индексЗаписи=смещение от начала свободной области буфера
\   размерПакета1, байт1пакета1, .., байтN1пакета1,   
\   размерПакета2, байт1пакета2, ..........., байтN2пакета2,
\   ...
\   размерПакетаX, байт1пакетаX, ........, байтNXпакетаX,
\   ..........последний_байт буфера
\             
\ 
\ полный размер буфера в памяти = размер_буфера+3 байта 
\ имя---v    имя+3---v
\      Size,Rid,Wid:Body...
\ имя буфера указывает на байт размера буфера
\ 
\ ==== сервисные утилиты =====================
\ BufP:     ( size "name"  --)             \ выделить память под пакетный буфер
\ ==== рабочие утилиты =====================
\ IniBufP   ( Y=addrBuf r=Size -- )        \ инициация буфера
\ RsizeBufP ( Y=addrBuf -- Y=addrBuf r=u Z)\ сколько места есть для чтения
\ WsizeBufP ( Y=addrBuf -- Y=addrBuf r=u Z)\ сколько места есть для записи
\ PressBufP ( Y=addrBuf -- Y=addrBuf t)    \ выжать воду из буфера
\ WaddrBufP ( Y=addrBuf -- Y=addrPac )     \ выдать адрес W пакета
\ RaddrBufP ( Y=addrBuf -- Y=addrPac )     \ выдать адрес R пакета
\ WriteBufP ( Y=addrBuf r=b rH=n -- t)     \ записать байт в позицию n(>0) последнего пакет буфера
\ ReadBufP  ( Y=addrBuf     rH=n -- r=byte t c)  \ выдать n-ый[1..N] байт из текущего пакета
\ WendBufP  ( Y=addrBuf --)                \ переместить индекс W за пакет
\ RendBufP  ( Y=addrBuf --)                \ переместить индекс R за пакет


#def BufP  \ либа загружена
Finger VALUE StartLibBufP \ учет размера кода  
\ ==== макросы =============================
#def add_Yr  add yL r   adc yH  (0)  \ сложить регистровую пару с регистром
#def sub_Yr  sub yL r   sbc yH  (0)  \ вычесть регистровую пару с регистром
#def add_YrH add yL rH  adc yH  (0)  \ сложить регистровую пару с регистром
#def sub_YrH sub yL rH  sbc yH  (0)  \ вычесть регистровую пару с регистром

#def (S) 0
#def (R) 1
#def (W) 2
#def (B) 3


: BufP: ( size "name"  --) \ выделить память под пакетный буфер
    3 + take \ 3 байта под индексы S, R, W
    ;

code IniBufP ( Y=addrBuf r=Size -- Y=addrBuf r=Size ) \ инициация буфера
    st Y,r  std Y+(R),(0)  std Y+(W),(0) \ очистить и образмерить
    ret c;


\ вызывать должен "писатель":
\ "читетель" не может знать, что идет запись,
\ а писатель знает, что ни кто не читает (т.к. нечего)
code PressBufP ( Y=addrBuf - Y=addrBuf t) \ выжать воду из буфера
    \ попытаться сжать буфер
    \ если R=W>0, то
    \ а) перенести уже принятые данные в начало буфера
    \ б) R=W=0
    pushW R
        set \ пессиместический прогноз
        ldd rH,Y+(W)  ldd r,Y+(R) \ Y=addrBuf r=Rid rH=Wid
        cp r,rH
        if_nC \ Rid>=Wid можно
            std Y+(R),rH \ R=W
            tst rH
            if \ Wid>0 нужно
                ldd r,Y+(S)  ldd rH,Y+(W)
                sub r,rH \ r=S-W
                \ r=N rH=Wid
                if_nZ \ N>0 требуется перенести данные
                    pushW X pushW Y
                        adiw Y,(B) 
                        movW X,Y add_YrH \ X=addrBody Y=addrPac r=N
                        for ld rH,Y+ st X+,rH  next r \ перенос пакета
                    popW Y popW X
                then    
                \ сначала W=0 (получится W<R), потом R=0, итого R=W=0
                    std Y+(W),(0) std Y+(R),(0) \ сбросить индексы
                clt \ перенос состоялся!
            then
        then
    popW R 
    \ t=0 сжатие удалось 
    \ t=1 сжатие не удалось 
    \ Y=addrBuf
    ret c; \ PressBufP val?

code RsizeBufP ( Y=addrBuf -- Y=addrBuf r=u sreg.Z) \ сколько места есть для чтения
    push rH
        ldd rH,Y+(R) \ обязательно сначала читаем R, так как ..
\ .. здесь может вклиниться прерывание и перенести W и R в 0
        ldd r,Y+(W) 
        c; \ r=W-R ----V
code _sizeBufP
        sub r,rH 
        if< clr r then \ страховка от момента R>W при переносе индексов
    pop rH 
    ret c;
code WsizeBufP ( Y=addrBuf -- Y=addrBuf r=u sreg.Z) \ сколько места есть для записи
    push rH
        ldd r,Y+(S)  ldd rH,Y+(W) goto _sizeBufP \ r=S-W
    c;

code WaddrBufP   ( Y=addrBuf -- Y=addrPac ) \ выдать адрес W пакета
    push r  
        ldd r,Y+(W) c;
code _addrBufP
        add_Yr  adiw Y,(B)
    pop r
    ret c;
code RaddrBufP   ( Y=addrBuf -- Y=addrPac ) \ выдать адрес R пакета
    push r  
        ldd r,Y+(R)  goto _addrBufP c; \ ---^


\ code WriteBufP ( Y=addrBuf r=b rH=n -- Y=addrBuf r=b rH=n t)  \ записать байт в позицию n(>0) последнего пакет буфера
\     \ последний записанный байт определяет размер всего пакета
\     \ т.е. размер пакета равен последнему n
\     \ t=1 - нет места для записи
\     clt  \ оптимистический прогноз     
\     push r
\         rcall WsizeBufP  cp rH,r \ n-u
\     pop r
\     if_nC \ u<=n нехватает, чтоб хватало нужно u>n
\         rcall PressBufP \ попытка освободить
\     then    
\     if_nt \ есть место 
\        pushW Y
\             rcall WaddrBufP  st Y,rH \ 
\             add_YrH  st Y,r
\        popW Y
\     then
\     ret c;
code WriteBufP ( Y=addrBuf r=b rH=n -- Y=addrBuf r=b rH=n t)  \ записать байт в позицию n(>0) последнего пакет буфера
    \ последний записанный байт определяет размер всего пакета
    \ т.е. размер пакета равен последнему n
    \ t=1 - нет места для записи
    rcall PressBufP \ попытка освободить..
    \ выполняется при каждой записи, что бы получить 
    \ эффект кольцевого буфера - по прочтении пакета, появляется место для записи
    \ иначе один непрочитанный пакет в конце пустого буфера вызовет 
    \ ложное переполнение буфера
    \ переполнение все равно возможно, но только если 
    \ скорость записи превышает скорость чтения
    set  \ пессимистический прогноз     
    push r
        rcall WsizeBufP  cp rH,r \ n-u
    pop r
    if_C \ u>n есть место 
       pushW Y
            rcall WaddrBufP  st Y,rH \ 
            add_YrH  st Y,r
       popW Y
       clt
    then
    ret c;

code ReadBufP ( Y=addrBuf  rH=n -- Y=addrBuf rH=n r=byte t c )  \ выдать n-ый[1..N] байт из текущего пакета
    \ t=1 это последний байт пакета
    \ c=1 перелет за пределы пакета
    clt  \ оптимистический прогноз
    pushW Y
        ldd r,Y+(R) add_Yr ldd r,Y+(B) \ r=N 
        add_YrH 
        cp r,rH if= set then \ n=N=>T=1
        ldd r,Y+(B) \ r=byte(n)
    popW Y
    ret c;

code WendBufP ( Y=addrBuf -- Y=addrBuf )  \ переместить индекс W за пакет
    pushW R 
        ldd r,Y+(W) 
        add_Yr ldd rH,Y+(B) sub_Yr \ rH=n r=W 
        \ Y=addrBuf
        inc rH  add rH,r   \ rH=W+n+1
        std Y+(W),rH \ rH=Wid'
    popW R
    ret c; \ WendBufP val?

code RendBufP ( Y=addrBuf -- Y=addrBuf )  \ переместить индекс R за пакет
    pushW R 
        ldd r,Y+(R) ldd rH,Y+(W) 
        cp r,rH
        if \ R<>W 
            add_Yr  ldd rH,Y+(B)  sub_Yr \ rH=n r=R 
            \ Y=addrBuf
            inc rH  add rH,r   \ rH=R+n+1
            std Y+(R),rH \ rH=R'
        then \ Y=addrBuf
    popW R
    ret c; 

code WtakeBuf ( Y=addrBuf r=u -- Y=addrPack|Buf t ) 
\ зарезервировать для прямой записи u байт в буфере addrBuf
\ t=0 Y=addrPack 
\ t=1 Y=addrBuf - отказ
    rcall PressBufP \ превентивное сжатие буфера
    set \ пессимистический прогноз
    push rH
        mov rH,r \ rH=r=u
        rcall WsizeBufP \ r=size rH=u
        cp rH,r \ u-size
        mov r,rH \ r=rH=u
        if< ( u<size) rcall WaddrBufP st Y+,r clt then 
    pop rH
    ret c;

\ eof
finger StartLibBufP - . .( <==== размер либы pFIFO) cr



