
\ минимальная реализация работы с USB для программатора USBTiny
\ iva 10.11.2010 --
DECIMAL
64 CONSTANT size-rbuf        \ размер буфера
CREATE rbuf size-rbuf ALLOT   \ буфер чтения
\ size-rbuf ALLOCATE THROW CONSTANT rbuf \ буфер в "куче"
0 VALUE hdev                \ ручка программатора
0 VALUE chank               \ размер куска для записи

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
HEX 
\ определители UsbTiny
1781 CONSTANT UsbTinyVid  
0C9F CONSTANT UsbTinyPid 
\ Тип запроса, битовая маска
\ bmRequestType 1 байт [7..0] \ согласно  Агуров стр.97
    \  [7] направление передачи
    0080 CONSTANT USB_ENDPOINT_IN   \ от устройства к хосту
    0000 CONSTANT USB_ENDPOINT_OUT  \ от хоста к устройству   
    \ [6:5] коды типа запросов
    0000 CONSTANT USB_TYPE_STANDARD \ (0x00 << 5)   стандартный запрос
    0020 CONSTANT USB_TYPE_CLASS    \ (0x01 << 5)   специфический запрос для данного класса  
    0040 CONSTANT USB_TYPE_VENDOR   \ (0x02 << 5)   специфический запрос изготовителя
    0060 CONSTANT USB_TYPE_RESERVED \ (0x03 << 5)   зарезервирован
    \ [4:0] код получателя
    0000 CONSTANT USB_RECIP_DEVICE      \ устройство   
    0001 CONSTANT USB_RECIP_INTERFACE   \ интерфейс
    0002 CONSTANT USB_RECIP_ENDPOINT    \ конечная точка
    0003 CONSTANT USB_RECIP_OTHER       \ другой

\ Коды запросов
    \   Стандартные запросы
    0000 CONSTANT USB_REQ_GET_STATUS  \ см. Агуров стр.97
    0001 CONSTANT USB_REQ_CLEAR_FEATURE  
    \ 0x02 зарезервировано
    0003 CONSTANT USB_REQ_SET_FEATURE  
    \ 0x04 зарезервировано
    0005 CONSTANT USB_REQ_SET_ADDRESS  
    0006 CONSTANT USB_REQ_GET_DESCRIPTOR 
    0007 CONSTANT USB_REQ_SET_DESCRIPTOR 
    0008 CONSTANT USB_REQ_GET_CONFIGURATION 
    0009 CONSTANT USB_REQ_SET_CONFIGURATION 
    000A CONSTANT USB_REQ_GET_INTERFACE  
    000B CONSTANT USB_REQ_SET_INTERFACE  
    000C CONSTANT USB_REQ_SYNCH_FRAME  

DECIMAL
\ Коды запросов определённых для USBtiny
    \ общие запросы
    00 CONSTANT USBTINY_ECHO    \ echo test
    01 CONSTANT USBTINY_READ    \ read byte (wIndex:address)
    02 CONSTANT USBTINY_WRITE   \ write byte (wIndex:address, wValue:value)
    03 CONSTANT USBTINY_CLR     \ clear bit (wIndex:address, wValue:bitno)
    04 CONSTANT USBTINY_SET     \ set bit (wIndex:address, wValue:bitno)

    \ запросы программирования
    05 CONSTANT USBTINY_powerUP         \ apply power (wValue:SCK-period, wIndex:RESET)
    06 CONSTANT USBTINY_powerDOWN       \ remove power from chip
    07 CONSTANT USBTINY_SPI             \ issue SPI command (wValue:c1c0, wIndex:c3c2)
    08 CONSTANT USBTINY_POLL_BYTES      \ set poll bytes for write (wValue:p1p2)
    09 CONSTANT USBTINY_FLASH_READ      \ read flash (wIndex:address)
    10 CONSTANT USBTINY_FLASH_WRITE     \ write flash (wIndex:address, wValue:timeout)
    11 CONSTANT USBTINY_EEPROM_READ     \ read eeprom (wIndex:address)
    12 CONSTANT USBTINY_EEPROM_WRITE    \ write eeprom (wIndex:address, wValue:timeout)

USB_ENDPOINT_IN  USB_TYPE_VENDOR OR USB_RECIP_DEVICE OR CONSTANT EPread
USB_ENDPOINT_OUT USB_TYPE_VENDOR OR USB_RECIP_DEVICE OR CONSTANT EPwrite

\ Flags to indicate how to set RESET on power up
0 CONSTANT RESET_LOW 
1 CONSTANT RESET_HIGH 

\ The SCK speed can be set by avrdude, to allow programming of slow-clocked parts
1   CONSTANT SCK_MIN        \ usec delay (target clock >= 4 MHz)
250 CONSTANT SCK_MAX        \ usec (target clock >= 16 KHz)
\ 10  CONSTANT SCK_DEFAULT    \ usec (target clock >= 0.4 MHz)

\ Какой максимальный объем данных, мы хотим послать в одном пакете USB?
128 CONSTANT CHUNK_SIZE \ должно быть степенью 2, но меньше чем 256

\ The default USB Timeout
50 CONSTANT USB_TIMEOUT    \ msec

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
: .name ( *bus|*devices -- adr u) \ строка
    2 CELLS + ASCIIZ> ;
: .devices ( *bus -- *devices) \ адрес структуры devices   
    .name ASCIIZ>> @ ;
: .descriptor ( *dev -- *descriptor) \ адрес дескриптора из структуры dev 
    .name ASCIIZ>> CELL+ ;
: .idVendor  ( *dev -- u ) \ VID в структуре dev.descriptor
    8 + W@ ;
: .idProduct ( *dev -- u ) \ PID в структуре dev.descriptor
    10 + W@ ;

: findDevice ( .idVendor .idProduct -- dev|0) \ искать устройство по id
    2>R ( R: .idVendor .idProduct )
    initUSB   ( *bus)
    BEGIN DUP \ цикл по всем шинам
    .devices  ( *bus *devices)         \ DUP ." dev: ".name type cr
        BEGIN DUP \ цикл по всем устройствам на шине
            .descriptor  
            DUP .idVendor SWAP .idProduct   \ получить .idVendor и .idProduct
            2R@ ROT = -ROT = AND \ сравнить с искомыми
            IF 2R> 2DROP NIP EXIT THEN \ НАЙДЕН
            .next ?DUP
        WHILE \ cr ." --dev"  
        REPEAT 
        .next DUP 
    WHILE \ cr ." ==bus" 
    REPEAT 2R> 2DROP ; \ НЕ найден

: openUsbTiny ( ) \ открытие программатора
    hdev 0=
    IF UsbTinyVid UsbTinyPid  findDevice 
        ?DUP 
        IF 1 <( )) usb_open  DUP 0 > 
            IF TO hdev ELSE printErrorUSB ABORT THEN
        ELSE TRUE ABORT" USBtiny не найден"  
        THEN   
    THEN
    ;
: closeUsbTiny ( ) \ закрытие программатора
    hdev 
    IF (( hdev )) usb_close DROP 0 TO hdev THEN
    ;
: CheckUsbTiny ( ) \ проверка наличия программатора и его переподключения
    hdev 0=
    IF openUsbTiny   
    ELSE  (( )) usb_find_busses  (( )) usb_find_devices OR \ были ли изменения 
        IF closeUsbTiny openUsbTiny THEN \ если ДА, то закрыть и переоткрыть
    THEN
    ;

: usb_control ( reqid val index -- n)
    >R >R >R
    CheckUsbTiny \ проверить/подключить
    hdev  \ ручка
    EPread \ тип запроса
    2 <( R> R> R> rbuf size-rbuf USB_TIMEOUT )) usb_control_msg 
          \ код запроса
             \ значение
               \ индекс
    DUP 0 < IF  printErrorUSB ABORT THEN
    ;

: WMEM-USB   ( mem twp adr buf sbuf  -- n) \ записать буфер в память mem
    >R 2>R 2>R
    CheckUsbTiny \ проверить/подключить
    (( hdev EPwrite 2R> 2R> R@ USB_TIMEOUT )) usb_control_msg 
    R> TUCK < IF  printErrorUSB ABORT THEN
    ;




\ ----------void	usb_control             ( int req, int val, int index )
\ int	usb_in                  ( int req, int val, int index, byte_t* buf, int buflen, int umax )
\ int	usb_out                 ( int req, int val, int index, byte_t* buf, int buflen, int umax )

\ int	usbtiny_avr_op          ( *pgm, AVRPART* p, int op, byte_t res[4] )
\ ----------int     usbtiny_open            ( *pgm, char* name )
\ ----------void    usbtiny_close           ( *pgm )
\ void	usbtiny_set_chunk_size  ( int period )
\ int	usbtiny_set_sck_period  ( *pgm, double v )
\ ----------int	    usbtiny_initialize      ( *pgm, AVRPART* p )
\ void	usbtiny_powerdown       ( *pgm )

\ int	usbtiny_cmd             ( *pgm, byte_t cmd[4], byte_t res[4] )

\ int	usbtiny_chip_erase      ( *pgm, AVRPART* p )
\ int	usbtiny_paged_load      ( *pgm, AVRPART* p, AVRMEM* m, int page_size, int n_bytes )
\ int	usbtiny_paged_write     ( *pgm, AVRPART* p, AVRMEM* m, int page_size, int n_bytes )
\ int	usbtiny_read_byte       ( *pgm, AVRPART* p, AVRMEM* m, ulong_t addr, byte_t* value )
\ int	usbtiny_write_byte      ( *pgm, AVRPART* p, AVRMEM* m, ulong_t addr, byte_t value )
\ 


\ \                                          0   1         2            3
\ \ Programming Enable                      0xAC 0x53     0x00         0x00
\ \ Chip Erase (Program Memory/EEPROM)      0xAC 0x80     0x00         0x00
\ \ Poll RDY/BSY                            0xF0 0x00     0x00         byte out
\ Load Extended Address byte              0x4D 0x00     Ext-adr      0x00
\ Load Program Memory Page, High byte     0x48 adrMSB   adrLSB       byte 
\ Load Program Memory Page, Low byte      0x40 adrMSB   adrLSB       byte 
\ Load EEPROM Memory Page (page access)   0xC1 0x00     0000000aa    byte 
\ Read Program Memory, High byte          0x28 adrMSB   adrLSB       byte out
\ Read Program Memory, Low byte           0x20 adrMSB   adrLSB       byte out
\ Read EEPROM Memory                      0xA0 0x00     00aaaaaa     byte out
\ \ Read Lock bits                          0x58 0x00     0x00         byte out
\ \ Read Signature Byte                     0x30 0x00     0000000aa    byte out
\ \ Read Fuse bits                          0x50 0x00     0x00         byte out
\ \ Read Fuse High bits                     0x58 0x08     0x00         byte out
\ \ Read Extended Fuse Bits                 0x50 0x08     0x00         byte out
\ \ Read Calibration Byte                   0x38 0x00     0x0№         byte out
\ \ Write Program Memory Page               0x4C adrMSB   adrLSB       0x00
\ \ Write EEPROM Memory                     0xC0 0x00     00aaaaaa     byte in
\ \ Write EEPROM Memory Page (page access)  0xC2 0x00     00aaaa00     0x00
\ \ Write Lock bits                         0xAC 0xE0     0x00         byte in
\ \ Write Fuse bits                         0xAC 0xA0     0x00         byte in
\ \ Write Fuse High bits                    0xAC 0xA8     0x00         byte in
\ \ Write Extended Fuse Bits                0xAC 0xA4     0x00         byte in

