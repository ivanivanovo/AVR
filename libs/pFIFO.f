\ пакетные кольцевые буферы FIFO с хвостиком
\ ревизия 16 янв 2018
\ хвостик нужен, чтобы избежать фрагментации пакетов
\ структура буферов (определяется писателем):
\  имя---v
\  чистый размер кольцевого буфера, под данные
\  индексЧтения=смещение от начала буфера до размера непрочитаного пакета
\  индексЗаписи=смещение от начала до свободной области буфера
\   размерПакета1, байт1пакета1, .., байтN1пакета1,   
\   размерПакета2, байт1пакета2, ..........., байтN2пакета2,
\   ...
\   размерПакетаX, байт1пакетаX, ........, байтNXпакетаX,
\   ..........последний_байт кольца буфера
\   хвостик, куда пишутся байты последнего пакета, вылезающего за пределы кольца          
\   размер хвостика должен быть больше или равен максимальному размеру пакета

\ При чтении: индексЧтения=индексЗаписи, означает "нечего читать".
\ При записи: всегда индексЧтения<>индексЗаписи.

\ полный размер буфера в памяти = размер_кольца+размер_хвоста+3 байта 
\ имя---v    имя+3---v
\      Size,Rid,Wid:Body...
\ имя буфера указывает на байт размера буфера
\ 
\ ==== сервисные утилиты =====================
\ BufP:     ( size "name"  --)             \ выделить память под пакетный буфер
\ ==== рабочие утилиты =====================
\ IniBufP   ( Y=addrBuf r=Size   -- Y=addrBuf r=Size )          \ инициация буфера
\ RsizeBufP ( Y=addrBuf          -- Y=addrBuf r=u Z)            \ сколько БАЙТ есть для чтения
\ WsizeBufP ( Y=addrBuf          -- Y=addrBuf r=u Z)            \ сколько места есть для записи ДАННЫХ
\ WaddrBufP ( Y=addrBuf          -- Y=addrPac )                 \ выдать адрес W пакета, индекс указывает на счетчик будущего пакета
\ RaddrBufP ( Y=addrBuf          -- Y=addrPac )                 \ выдать адрес R пакета, индекс указывает на счетчик пакета
\ WriteBufP ( Y=addrBuf r=b rH=n -- Y=addrBuf r=b rH=n t)       \ записать байт в позицию n(>0) последнего пакет буфера
\ ReadBufP  ( Y=addrBuf     rH=n -- Y=addrBuf rH=n r=byte t c)  \ выдать n-ый[1..N] байт из текущего пакета
\ WendBufP  ( Y=addrBuf          -- Y=addrBuf)                  \ переместить индекс W за пакет
\ RendBufP  ( Y=addrBuf          -- Y=addrBuf)                  \ переместить индекс R за пакет
\ WtakeBuf  ( Y=addrBuf r=u      -- Y=addrPack|Buf r=u t )      \ зарезервировать для прямой записи u байт ДАННЫХ в буфере addrBuf

\ 12.10.2018 
\ Введена защита от переноса W из-за пустого пакета.

#def BufP  \ либа загружена
Finger VALUE StartLibBufP \ учет размера кода  
\ ==== макросы =============================
#def add_Yr  add yL r   adc yH  (0)  \ сложить регистровую пару с регистром
#def sub_Yr  sub yL r   sbc yH  (0)  \ вычесть регистровую пару с регистром
#def add_YrH add yL rH  adc yH  (0)  \ сложить регистровую пару с регистром
#def sub_YrH sub yL rH  sbc yH  (0)  \ вычесть регистровую пару с регистром

#def (Sz) 0 \ смещение размера от начала буфера
#def (Ri) 1 \ смещение индекса от начала буфера
#def (Wi) 2 \ смещение индекса от начала буфера
#def (Dt) 3 \ смещение данных  от начала буфера

#def TailSize ( size -- TailSize )  MaxSizePack MIN
\ размер хвоста не больше максимального пакета
\ и не больше основного тела
: BufP: ( size "name"  --) \ выделить память под пакетный буфер
    DUP TailSize + 3 + take \ +хвост +3 байта под индексы S, R, W 
    ;

code IniBufP ( Y=addrBuf r=Size -- Y=addrBuf r=Size ) \ инициация буфера
    st Y,r  std Y+(Ri),(0)  std Y+(Wi),(0) std Y+(Dt),(0) \ очистить и образмерить
    ret c;



code RsizeBufP ( Y=addrBuf -- Y=addrBuf r=u sreg.Z) \ сколько места есть для чтения
    \ показывает сколько БАЙТ доступно для чтения (вместе со служебными N)
    push rH
        ldd r,Y+(Wi) ldd rH,Y+(Ri)
        sub r,rH if_c ldd rH,Y+(Sz) add r,rH then
    pop rH
    ret c;

code WsizeBufP ( Y=addrBuf -- Y=addrBuf r=u sreg.Z) \ сколько места есть для записи
    \ показывает сколько есть места для чисто ДАННЫХ (без служебных N и W)
    rcall RsizeBufP 
    push rH
        ldd rH,Y+(Sz)  subi rH,2  sub rH,r  mov r,rH if_c clr r then
                              \ учет служебных байт, 1 для счетчика и 1 для переноса индекса W 
                              \ ( W не должно сесть на R) 
    pop rH    
    ret c;


code WaddrBufP   ( Y=addrBuf -- Y=addrPac ) \ выдать адрес W пакета
    push r  
        ldd r,Y+(Wi) c; \ ----v
code _addrBufP
        add_Yr  adiw Y,(Dt) \ индекс указывает на счетчик пакета
    pop r
    ret c;
code RaddrBufP   ( Y=addrBuf -- Y=addrPac ) \ выдать адрес R пакета
    push r  
        ldd r,Y+(Ri)  rjmp _addrBufP c; \ ---^

code WtakeBuf ( Y=addrBuf r=u -- Y=addrPack|Buf r=u t ) 
\ зарезервировать для прямой записи u байт ДАННЫХ в буфере addrBuf
\ t=0 Y=addrPack 
\ t=1 Y=addrBuf - отказ
    set \ пессимистический прогноз
    cpi r,MaxSizePack 1+ \ контроль размера пакета
    if< \ контроль размера пакета
        push rH
            mov rH,r \ rH=u 
            rcall WsizeBufP cp r,rH \ size-u
            mov r,rH \ r=u
        pop rH
            if_nC ( u=<size) clt rjmp WaddrBufP  then 
    then
    ret c;

code WriteBufP ( Y=addrBuf r=b rH=n -- Y=addrBuf r=b rH=n t)  
    \ записать байт в позицию n(>0) последнего пакет буфера
    \ последний записанный байт определяет размер всего пакета
    \ т.е. размер пакета равен последнему n
    \ t=1 - нет места для записи
    pushW Y 
        push r
            mov r,rH rcall WtakeBuf \ проверка возможности записи
        pop r
        if_nT \ можно
            st Y,rH \ записать n в счетчик пакета
            add_YrH  st Y,r \ записать байт
        then        
    popW Y
    ret c;

code ReadBufP ( Y=addrBuf  rH=n -- Y=addrBuf rH=n r=byte t c )  
    \ выдать n-ый[1..N] байт из текущего пакета
    \ t=1 это последний байт пакета
    \ c=1 перелет за пределы пакета
    clt  \ оптимистический прогноз
    pushW Y
        ldd r,Y+(Ri) add_Yr ldd r,Y+(Dt) \ r=N 
        add_YrH 
        cp r,rH if= set then \ n=N=>T=1
        ldd r,Y+(Dt) \ r=byte(n)
    popW Y
    ret c;


code _endBufP ( r=Idx -- r=Idx')
    push rH
        add_Yr  ldd rH,Y+(Dt)  sub_Yr \ rH=n r=Idx  Y=addrBuf
        tst rH
        if_nZ \ защита от пустого пакета
            add r,rH \ Idx+N=x
            ldd rH,Y+(Sz) dec rH \ rH=максимальный индекс (maxIdx=Size-1)
            cp r,rH \ (x-maxIdx)
            if_c inc r else sub r,rH then
        then
    pop rH 
    ret c; 

code WendBufP ( Y=addrBuf -- Y=addrBuf )  \ переместить индекс W за пакет
    push r 
        ldd r,Y+(Wi) rcall _endBufP
        add_Yr  std Y+(Dt),(0) sub_Yr \ n'=0
        std Y+(Wi),r \ r=W'
    pop r
    ret c; \ WendBufP val?

code RendBufP ( Y=addrBuf -- Y=addrBuf )  \ переместить индекс R за пакет
    push r 
        ldd r,Y+(Ri) rcall _endBufP
        std Y+(Ri),r \ r=R'
    pop r
    ret c; 


\eof
finger StartLibBufP - . .( <==== размер либы pFIFO[кольцевого+]) cr

