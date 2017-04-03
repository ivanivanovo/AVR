\ пакетные кольцевые буферы FIFO с хвостиком
\ ревизия 11 окт 2016
\ хвостик нужен, чтобы избежать фрагментации пакетов
\ структура буферов (определяется писателем):
\  имя---v
\  чистый размер кольцевого буфера, под данные
\  индексЧтения=смещение от начала буфера до размера непрочитаного пакета
\  индексЗаписи=смещение от начала свободной области буфера
\   размерПакета1, байт1пакета1, .., байтN1пакета1,   
\   размерПакета2, байт1пакета2, ..........., байтN2пакета2,
\   ...
\   размерПакетаX, байт1пакетаX, ........, байтNXпакетаX,
\   ..........последний_байт кольца буфера
\   хвостик, куда пишутся байты последнего пакета, вылезающего за пределы кольца          
\   размер хвостика должен быть больше или равен максимальному размеру пакета

\ полный размер буфера в памяти = размер_кольца+размер_хвоста+3 байта 
\ имя---v    имя+3---v
\      Size,Rid,Wid:Body...
\ имя буфера указывает на байт размера буфера
\ 
\ ==== сервисные утилиты =====================
\ BufP:     ( size "name"  --)             \ выделить память под пакетный буфер
\ ==== рабочие утилиты =====================
\ IniBufP   ( Y=addrBuf r=Size   -- Y=addrBuf r=Size )          \ инициация буфера
\ RsizeBufP ( Y=addrBuf          -- Y=addrBuf r=u Z)            \ сколько места есть для чтения
\ WsizeBufP ( Y=addrBuf          -- Y=addrBuf r=u Z)            \ сколько места есть для записи
\ WaddrBufP ( Y=addrBuf          -- Y=addrPac )                 \ выдать адрес W пакета
\ RaddrBufP ( Y=addrBuf          -- Y=addrPac )                 \ выдать адрес R пакета
\ WriteBufP ( Y=addrBuf r=b rH=n -- Y=addrBuf r=b rH=n t)       \ записать байт в позицию n(>0) последнего пакет буфера
\ ReadBufP  ( Y=addrBuf     rH=n -- Y=addrBuf rH=n r=byte t c)  \ выдать n-ый[1..N] байт из текущего пакета
\ WendBufP  ( Y=addrBuf          -- Y=addrBuf)                  \ переместить индекс W за пакет
\ RendBufP  ( Y=addrBuf          -- Y=addrBuf)                  \ переместить индекс R за пакет
\ WtakeBuf  ( Y=addrBuf r=u      -- Y=addrPack|Buf r=u t )      \ зарезервировать для прямой записи u байт в буфере addrBuf

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
    MaxSizePack + 3 + take \ +хвост +3 байта под индексы S, R, W
    ;

code IniBufP ( Y=addrBuf r=Size -- Y=addrBuf r=Size ) \ инициация буфера
    st Y,r  std Y+(R),(0)  std Y+(W),(0) \ очистить и образмерить
    ret c;



code RsizeBufP ( Y=addrBuf -- Y=addrBuf r=u sreg.Z) \ сколько места есть для чтения
    push rH
        ldd r,Y+(W) ldd rH,Y+(R)
        sub r,rH if_c ldd rH,Y+(S) add r,rH then
    pop rH
    ret c;

code WsizeBufP ( Y=addrBuf -- Y=addrBuf r=u sreg.Z) \ сколько места есть для записи
    rcall RsizeBufP 
    push rH
        ldd rH,Y+(S)  dec rH  sub rH,r  mov r,rH
    pop rH    
    \ показывает на 1 меньше, чтобы было куда перенести W
    \ W не должно сесть на R
    ret c;


code WaddrBufP   ( Y=addrBuf -- Y=addrPac ) \ выдать адрес W пакета
    push r  
        ldd r,Y+(W) c; \ ----v
code _addrBufP
        add_Yr  adiw Y,(B)
    pop r
    ret c;
code RaddrBufP   ( Y=addrBuf -- Y=addrPac ) \ выдать адрес R пакета
    push r  
        ldd r,Y+(R)  rjmp _addrBufP c; \ ---^

code WtakeBuf ( Y=addrBuf r=u -- Y=addrPack|Buf r=n t ) 
\ зарезервировать для прямой записи u байт в буфере addrBuf
\ t=0 Y=addrPack 
\ t=1 Y=addrBuf - отказ
    set \ пессимистический прогноз
    cpi r,MaxSizePack 1+ \ контроль размера пакета
    if< \ контроль размера пакета
        push rH
            mov rH,r \ rH=r=u
            rcall WsizeBufP cp rH,r \ u-size
            mov r,rH \ r=rH=u
        pop rH
            if< ( u<size) clt rjmp WaddrBufP  then 
    then
    ret c;

code WriteBufP ( Y=addrBuf r=b rH=n -- Y=addrBuf r=b rH=n t)  \ записать байт в позицию n(>0) последнего пакет буфера
    \ последний записанный байт определяет размер всего пакета
    \ т.е. размер пакета равен последнему n
    \ t=1 - нет места для записи
    pushW Y 
        push r
            mov r,rH rcall WtakeBuf \ проверка возможности записи
        pop r
        if_nT \ можно
            st Y,rH \ записать n в голову пакета
            add_YrH  st Y,r \ записать байт
        then        
    popW Y
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


code _endBufP ( r=Idx -- r=Idx')
    push rH
        add_Yr  ldd rH,Y+(B)  sub_Yr \ rH=n r=Idx  Y=addrBuf
        add r,rH \ Idx+N=x
        ldd rH,Y+(S) cp rH,r if_c sub r,rH then
        inc r     
    pop rH 
    ret c; 

code WendBufP ( Y=addrBuf -- Y=addrBuf )  \ переместить индекс W за пакет
    push r 
        ldd r,Y+(W) rcall _endBufP
        std Y+(W),r \ r=W'
    pop r
    ret c; \ WendBufP val?

code RendBufP ( Y=addrBuf -- Y=addrBuf )  \ переместить индекс R за пакет
    push r 
        ldd r,Y+(R) rcall _endBufP
        std Y+(R),r \ r=R'
    pop r
    ret c; 


\ eof
 finger StartLibBufP - . .( <==== размер либы pFIFO[кольцевого+]) cr



