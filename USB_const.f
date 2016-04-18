\ констатнты USB

DECIMAL
4096 CONSTANT PATH_MAX          \ из linux/limits.h

HEX 
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

USB_ENDPOINT_IN  USB_TYPE_VENDOR OR USB_RECIP_DEVICE OR CONSTANT EPread
USB_ENDPOINT_OUT USB_TYPE_VENDOR OR USB_RECIP_DEVICE OR CONSTANT EPwrite

DECIMAL
