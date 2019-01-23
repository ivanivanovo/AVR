\ подсистема таймеров
\ iva 26.04.2017
\ после объявление константы #timers
\   4 CONSTANT #timers \ количество слотов для таймеров
\ в системе будет доступно указанное количество таймеров
\ сработавший таймер деактивируется и освобождается, 
\ если требуется периодичность программа в точке перехода 
\ должна заново активировать свободный таймер
\ (см. примеры в конце файла)
\ если запрошено тамеров больше, чем есть, запрос отклоняется
\ без уведомления
\ для проверки наличия свободных таймеров можно вызвать FreeSlot
\ iva 9.12.2017
\ если есть таймер с такой-же точкой возврата, то Delay: переустанавит 
\ его время
\ можно освободить таймер, отменить действие (0 Delay:)

\ установки секунд и минут зависят от тактирования таймера
\ поэтому задаются в основной программе
\   #def sek 16 * chskTime \ перевод секунд в тики таймера
\   #def mnt 60 * sek  \ перевод минут  в тики таймера


finger CONSTANT startTimres
0
2 -- timeOn \ декрементный счетчик тиков
2 -- point  \ точка перехода после срабатывания таймера
CONSTANT sizeTimers
 RAM[ 1 take NextTimer   \ следующий таймер для проверки
      sizeTimers #timers * take  Timers \ таймеры
 ]RAM


BitsIn r ( aka TIFR0)
    <bits OCF0A 7 (AND) bits> #BitIs rOCF0A

: chskTime ( u -- u) \ проверка возможности установки тайма
    DUP 0xFFFF > ABORT" Слишком большой период." 
    ;

code Time \ вызывать периодически в главном цикле
    mov r,TIFR0 skip_b rOCF0A ret
    \ сработал флаг основного периода таймера
    mov r,NextTimer inc r mov rH,r
    cpi r,#timers
    if= clr rH then  mov NextTimer,rH \ счетчик таймеров
    if= ldi rH,{b OCF0A } mov TIFR0,rH then \ сбросить флаг после проверки всех таймеров
    \ проверить таймеры, по одному за вызов
    ldiW Y,Timers \ Y->0-timer
    begin dec r while  adiW Y,sizeTimers repeat \ переход к нужному таймеру
    ldd rL,Y+0 timeOn  ldd rH,Y+1 timeOn
    sbiw R,1 \ декремент текущего счетчика
    if_nC std Y+0 timeOn,rL std Y+1 timeOn,rH \ сохранить его
        if0 ldd zL,Y+0 point  ldd zH,Y+1 point ijmp  \ перейти на точку
        then
    then 
    ret c; 

code FreeSlot ( --Y=addr t) \ получить адрес свободного таймера
    \ t=0 Y=addrSlot
    \ t=1 Y=addrOver
    clt
    ldiW Y,Timers 
    begin ldd rL,Y+0 timeOn  ldd rH,Y+1 timeOn or rL,rH while \ пропускаем активные
        adiW Y,sizeTimers \ берем следующий
        ldiW R,Timers sizeTimers #timers * +
        cpW Y,R while_b C \ пока не кончатся слоты
    repeat set  then \ выход если все слоты заняты
    ret c;

code FindSlot ( Z=Point -- Y=addr t ) \ найти слот с такой-же точкой возврата
    \ или свободный
    \ t=0 Y=addrSlot
    \ t=1 Y=addrOver
    clt
    ldiW Y,Timers 
    begin ldd rL,Y+0 point  ldd rH,Y+1 point cpW Z,R while \ пропускаем иные
        adiW Y,sizeTimers \ берем следующий
        ldiW R,Timers sizeTimers #timers * +
        cpW Y,R while_b C \ пока не кончатся слоты
    repeat goto FreeSlot  then \ поискать свободный слот
    ret c;

code Delay: ( X=delay R:adr -- ) \ запомнить задержку и адрес возврата
    popW Z \ Z=adr, невозврат в случае неудачи
    rcall FindSlot \ найти такой-же слот или свободный слот
    if_nT \ и заполнить его
        std Y+0 point,zL std Y+1 point,zH
        std Y+0 timeOn,xL std Y+1 timeOn,xH
    then
    ret c; 

\eof \ примеры использования
finger startTimres - .
.( <==== размер timres.f ) cr


code WaitGoodMorning \ пример однократного срабатывания
    ldiW X,4 sek rcall Delay: \ объявление времени таймера
    \ сюда будет переход по срабатыванию таймера
    if_nb fOn
        ldiW Z,GoodBye rcall goPack    
    then
    ret c; 

code Migni \ пример переодичной работы
    begin
        ldiW X,1 sek rcall Delay:
        if_b heat \_ heat else _/ heat then
    again
    c;
    