
\ минимальная реализация работы с USB 
[WITHOUT?] USB_TYPE_STANDARD S" ~iva/AVR/USB_const.f" INCLUDED [THEN]

DECIMAL

 USE libusb-0.1.so.4 \ libusb.so \ используем библиотеку libusb 0.1

\  usb_init();         \ инициализирует USB библиотеку
\  usb_find_busses();  \ ищет все доступные USB шины, возвращает число изменений в подключениях с последнего вызова функции
\  usb_find_devices(); \ ищет все доступные USB устройства, возвращает число изменений в подключениях с последнего вызова функции
\  usb_open(*dev)      \ возвращает ручку устройства
\  usb_close(*udev)    \ закрывает устройство, 0 - нормально, <0 - ошибка
\  usb_control_msg(ручка, тип_запроса, код_запроса, значение, индекс, адрес_буфера, размер_буфера, таймаут)  \ посылка управляющего сообщения, возвращает число записаных/считаных байт, если <0 - ошибка 
 \ int usb_control_msg(usb_dev_handle *dev, int requesttype, int request, int value, int index, char *bytes, int size, int timeout);
\  usb_strerror()       \ возвращает строку ASCIIZ с описанием ошибки
\  
0 VALUE hdev                \ ручка программатора


: printErrorUSB ( ) 
    (( )) usb_strerror ASCIIZ>  TYPE CR 0 TO hdev ; 

: initUSB ( -- *bus) \ инициализирует библиотеку, ищет шины и устройства, 
\ возвращает адрес структуры usb_bus
    (( )) usb_init         DROP \ 0<  IF ." init:" printErrorUSB ABORT THEN
    (( )) usb_find_busses  DROP \ 0<  IF ." bus:"  printErrorUSB ABORT THEN
    (( )) usb_find_devices DROP \ 0<  IF ." dev:"  printErrorUSB ABORT THEN
    (( )) usb_get_busses  \ возвращает адрес структуры usb_bus
    \ DUP 0<  IF ." getBus:" printErrorUSB ABORT THEN
    ;
\ ползанье по структурам  
: .next ( *bus|*devices -- *bus'|*devices'|0) @ ; \ адрес следующей структуры
: .prev ( *bus|*devices -- *bus'|*devices'|0) CELL+ @ ; \ адрес предыдущей структуры
: .name ( *bus|*devices -- *str) \ адрес строки
    2 CELLS + ;
: maxLenStr ( -- u ) \ максимальная длина строки
    PATH_MAX 1+ ;
: .devices ( *bus -- *devices) \ адрес структуры devices   
    .name maxLenStr + ALIGNED @ ;
: .descriptor ( *dev -- *descriptor) \ адрес дескриптора из структуры dev 
    .name maxLenStr + ALIGNED CELL+ ;
: .idVendor  ( *dev -- u ) \ VID в структуре dev.descriptor
    8 + W@ ;
: .idProduct ( *dev -- u ) \ PID в структуре dev.descriptor
    10 + W@ ;

0 value BusName
: findDevice ( .idVendor .idProduct -- dev|0) \ искать устройство по id
    2>R ( R: .idVendor .idProduct )
    initUSB   ( *bus)
    BEGIN DUP \ цикл по всем шинам
        DUP .name to BusName
    .devices  ( *bus *devices)
        BEGIN DUP \ цикл по всем устройствам на шине
\        cr ." bus: " BusName ASCIIZ> type  DUP ."  dev: " .name ASCIIZ> type
            .descriptor
            DUP .idVendor SWAP .idProduct   \ получить .idVendor и .idProduct
\        ."  VID/PID: " OVER .hex ." /" DUP .hex
            2R@ ROT = -ROT = AND \ сравнить с искомыми
            IF 2R> 2DROP NIP EXIT THEN \ НАЙДЕН
            .next ?DUP
        WHILE \ cr ." --dev"  
        REPEAT 
        .next DUP 
    WHILE \ cr ." ==bus" 
    REPEAT 2R> 2DROP ; \ НЕ найден
