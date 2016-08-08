
\ минимальная реализация работы с libUSB-1.0 
[WITHOUT?] USB_TYPE_STANDARD S" ~iva/AVR/USB_const.f" INCLUDED [THEN]
[WITHOUT?] LIBUSB_LOG_LEVEL_INFO S" ~iva/AVR/libusbx_structures.f" INCLUDED [THEN]

DECIMAL
\ USE libusb-1.0.so.0  \ используем библиотеку libusb 1.0
USE libusb-1.0.so  \ используем библиотеку libusb 1.0
VARIABLE &ctx 0 &ctx ! \ переменная контекст 
#def ctx &ctx @
VARIABLE &listDev \ переменная указывающая на список USB устройств в системе
#def listDev &listDev @
VARIABLE &hand
#def hand &hand @
VARIABLE  &CnfDesc  
#def CnfDesc &CnfDesc @


0 VALUE USB_TIMEOUT \ No default USB Timeout
LIBUSB_LOG_LEVEL_INFO VALUE dbgLevel \ отладочный уровень

libusb_device_descriptor ALLOCATE THROW VALUE DevDesc \ взяли память из кучи под один экземпляр struct

\ libusb_config_descriptor   ALLOCATE THROW VALUE CnfDesc \ взяли память из кучи под один экземпляр struct
\ libusb_interface_descriptor  ALLOCATE THROW VALUE InDesc \ взяли память из кучи под один экземпляр struct
\ 
\ 0
\   CELL -- *altsetting  \ указатель на массив struct libusb_interface_descriptor
\   CELL -- num_altsetting   
\ CONSTANT libusb_interface 
\ libusb_interface   ALLOCATE THROW VALUE interface \ взяли память из кучи под один экземпляр struct
\ libusb_endpoint_descriptor ALLOCATE THROW VALUE EpDesc \ взяли память из кучи под один экземпляр struct
\ 
\    (( &ctx )) libusb_init DROp \ libusb_init(&ctx); 
\    (( ctx  &listDev )) libusb_get_device_list \ count = libusb_get_device_list(ctx, &listDev)
\    cr . cr
\     \ libusb_get_device_descriptor(device, &desc)
\    desc libusb_device_descriptor dump
\    cr

: errorUSB ( u -- ) \ обработка ошибок
  ?DUP LIBUSB_SUCCESS = IF EXIT THEN
  DUP  LIBUSB_ERROR_IO = ABORT" libusb - ошибка ввода-вывода."
  DUP  LIBUSB_ERROR_INVALID_PARAM = ABORT" libusb - неверные параметры."
  DUP  LIBUSB_ERROR_ACCESS = ABORT" libusb - отказано в доступе."
  DUP  LIBUSB_ERROR_NO_DEVICE = ABORT" libusb - устройство отключено."
  DUP  LIBUSB_ERROR_NOT_FOUND = ABORT" libusb - объект не найден."
  DUP  LIBUSB_ERROR_BUSY = ABORT" libusb - ресурс занят."
  DUP  LIBUSB_ERROR_TIMEOUT = ABORT" libusb - время вышло."
  DUP  LIBUSB_ERROR_OVERFLOW = ABORT" libusb - переполнение приемного буфера."
  DUP  LIBUSB_ERROR_PIPE = ABORT" libusb - ошибка канала."
  DUP  LIBUSB_ERROR_INTERRUPTED = ABORT" libusb - операция прервана."
  DUP  LIBUSB_ERROR_NO_MEM = ABORT" libusb - нехватает памяти."
  DUP  LIBUSB_ERROR_NOT_SUPPORTED = ABORT" libusb - неизвестная ошибка."
  ABORT" libusb - неизвестная ошибка."
    ;
: tickErr ( n - n) \ выделить ошибки 
  DUP 0< IF errorUSB then
  ;
: initUSB ( -- u) \ начало работы с библиотекой
    \ u=число обнаруженных устройств
    ctx 0= 
    if (( &ctx )) libusb_init errorUSB 
       (( ctx dbgLevel )) libusb_set_debug DROP \ включить отладочную информацию 
    then
    (( ctx  &listDev )) libusb_get_device_list \ получить список всех устройств
    ;

: findDevice ( .idVendor .idProduct -- dev|0) \ искать первое устройство с указанными id
   initUSB 
   IF ctx -ROT 3 <( )) libusb_open_device_with_vid_pid
   ELSE 0 THEN
   ;     
0 VALUE dev \ текущее устройство
VARIABLE VPid VARIABLE _Vid  \ Vid Pid в одном флаконе
CREATE ListDevs 16 CELLS ALLOT   \ мешок искомых устройств

: findDevices ( .idVendor .idProduct -- n|0) \ искать все устройства по id
    VPid 2!
    0 initUSB
    0 ?DO \ цикл по найденым устройствам
        listDev I CELLS + @ TO dev
        (( dev DevDesc )) libusb_get_device_descriptor errorUSB
\    I .  DevDesc DUP idVendor w@ .hex  ." /"  idProduct w@ .hex  dev 6 cells + @ .
        DevDesc idVendor w@ DevDesc idProduct w@ 
        VPid 2@ D=  
        IF dev OVER CELLS ListDevs + ! 1+  \ положить устройство в мешок
        THEN 
    LOOP
    ;

: devs ( # -- dev|0) \ достать устройство # из мешка
  CELLS listDevs + @
  ;

:NONAME
  (( hand )) libusb_close errorUSB \ закрыть
  ; IS closeUsbDev

: usb_control> ( reqid val index -- n)
    >R >R >R
    hand  \ ручка
    EPread \ тип запроса
    2  <(  R> R> R>  rbuf size-rbuf USB_TIMEOUT )) libusb_control_transfer tickErr
          \ код запроса
             \ значение
               \ индекс
    ;

0x63 NEGATE CONSTANT EndedLoop

: RunUSBprog ( -- err ) \ 
    \ err - код завершения chip!!
    (( dev &hand )) libusb_open errorUSB \ открыть 
    ." Programmer: " 
    hand  DevDesc iProduct w@ 2 <( pad 20 )) libusb_get_string_descriptor_ascii tickErr 
    PAD SWAP TYPE  ."  - " \ выдать имя программатора
    
    ['] chip!! CATCH DUP 0= \ попробовать его использовать
    IF  (( hand )) libusb_close errorUSB  THEN \ закрыть
    ;

( jjjiikk;
 ) 
: findUSBprog ( vid pid -- err) \ ищет USB-програматоры
    0 -ROT \ код завершения по умолчанию
    VPid 2!
    USBdevs 0
    ?DO
        listDev I CELLS + @ TO dev
        (( dev DevDesc )) libusb_get_device_descriptor errorUSB
        DevDesc idVendor w@ DevDesc idProduct w@ 
        VPid 2@ D=  
        IF 
          RunUSBprog \ отработать по найденному устройству
          EndedLoop = IF DROP EndedLoop LEAVE THEN \ досрочный выход по требованию
        THEN 
    LOOP
    ; 

\eof 
 








\ 0x403 0x6001 finddevices .( Найдено FTDI: ) . cr \ FTDI
\ 0x1781 0x0c9f finddevices .( Найдено usbTiny: ) . cr \ usbTiny
.( ====================================== ) cr
 0x03eb 0x2104 finddevices .( Найдено: ) . .( AVR ISP mkII )cr \ AVR ISP mkII
(( 0 devs &hand )) libusb_open errorUSB \ открыть из мешка
\ (( hand  2 ubuf 8 tred 50 )) libusb_bulk_transfer  errorUSB ubuf 10 dump cr tred @ . cr
\ (( hand 82 ubuf 8 tred 50 )) libusb_bulk_transfer  errorUSB ubuf 10 dump cr tred @ . cr



\eof
(( 0 devs devdesc )) libusb_get_device_descriptor errorUSB devdesc idVendor w@ .hex
(( ctx LIBUSB_LOG_LEVEL_INFO )) libusb_set_debug
(( 0 devs )) libusb_get_device_speed . \ узнать скорость
(( 1 devs )) libusb_get_device_address . \ узнать адрес

(( dev &hand )) libusb_open errorUSB \ открыть 
(( 0 devs &hand )) libusb_open errorUSB \ открыть из мешка
(( hand  0 )) libusb_kernel_driver_active tickErr . \ проверить наличие системного драйвера на интерфейсе 0
(( hand true )) libusb_set_auto_detach_kernel_driver errorUSB \ автоотключение-подключение системного драйвера

(( hand )) libusb_reset_device errorUSB

(( hand 2 pad 1 pad 50 )) libusb_bulk_transfer  errorUSB
(( hand 2 UBuf 8 tred 50 )) libusb_bulk_transfer  errorUSB

(( hand )) libusb_close errorUSB \ закрыть

(( list )) libusb_free_device_list .

(( ctx )) libusb_exit .
