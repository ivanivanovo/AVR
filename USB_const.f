\ констатнты и структуры USB
\ книга: 
\ Агуров П.В. Интерфейсы USB. Практика использования и программирования. --СПб.: БХВ-Петербург, 2004. - 576с.:ил.
\ ISBN 5-94157-202-6
DECIMAL
4096 CONSTANT PATH_MAX          \ из linux/limits.h

HEX 

\ стандартные типы дескрипторов
    0001 CONSTANT USB_DEVICE_DESCRIPTOR_TYPE        \ стандартный дескриптор устройства
    0002 CONSTANT USB_CONFIGURATION_DESCRIPTOR_TYPE \ стандартный дескриптор конфигурации
    0003 CONSTANT USB_STRING_DESCRIPTOR_TYPE        \ стандартный дескриптор строки
    0004 CONSTANT USB_INTERFACE_DESCRIPTOR_TYPE     \ стандартный дескриптор интерфейса
    0005 CONSTANT USB_ENDPOINT_DESCRIPTOR_TYPE      \ стандартный дескриптор конечной точки

\ дополнительные типы дескрипторов
    0006 CONSTANT DEVICE_QUALIFIER                  \ уточняющий дескриптор устройства
    0007 CONSTANT OTHER_SPEED_CONFIGURATION         \ дескриптор дополнительной конфигурации
    0008 CONSTANT INTERFACE_POWER                   \ дескриптор управления питанием интерфейса
    0009 CONSTANT OTG                               \ дескриптор OTG
    000A CONSTANT DEBUG                             \ дескриптор отладочный
    000B CONSTANT INTERFACE_ASSOCIATION             \ дополнительный дескриптор интерфейса

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

\ дескрипторы начинаются как правило одинаково, вот это начало и вынесено отдельно,
\ что бы не повторяться
\ типичное начало дескрипторов
0 
    1 -- bLength            \ размер этого дескриптора в байтах
    1 -- bDescriptorType    \ тип дескриптора (USB_xx_DESCRIPTOR_TYPE)
CONSTANT head_usb_descriptor

\ типичное начало длинных дескрипторов
head_usb_descriptor
    2 -- wTotalLength        \ общий объем данных (в байтах) возвращаемый для данного дескриптора
CONSTANT head_usb_long_descriptor



\ стандартный дескриптор USB устройства
head_usb_descriptor
    2 -- bcdUSB             \ номер верси спецификации USB в формате BCD
    1 -- bDeviceClass       \ код класса USB-устройства
    1 -- bDeviceSubClass    \ код подкласса USB-устройства
    1 -- bDeviceProtocol    \ код протокола USB-устройства
    1 -- bMaxPacketSize0    \ максимальный размер пакета для нулевой конечной точки
    2 -- idVendor           \ идентификатор производителя
    2 -- idProduct          \ идентификатор продукта
    2 -- bcdDevice          \ номер версии USB-устройства в формате BCD
    1 -- iManufacturer      \ индекс дескриптора строки, описывающей изготовителя
    1 -- iProduct           \ индекс дескриптора строки, описывающей продукт
    1 -- iSerialNumber      \ индекс дескриптора строки, содержащей серийный номер USB-устройства
    1 -- bNumConfigurations \ количество возможных конфигураций USB-устройства
CONSTANT usb_device_descriptor

\ стандартный дескриптор конфигурации USB
head_usb_long_descriptor
    1 -- bNumInterfaces      \ количество интерфейсов, поддерживаемой данной конфигурации
    1 -- bConfigurationValue \ идентификатор конфигурации, используемой при вызове SET_CONFIGURATION для установки данной конфигурации 
    1 -- iConfiguration      \ индекс дескриптора строки, описывающей данную конфигурацию 
    1 -- bmAttributes        \ характеристики конфигурации
    1 -- MaxPower            \ код мощности (квант=2мА), потребляемой USB-устройством от шины
CONSTANT usb_config_descriptor 

\ стандартный дескриптор интерфейса USB
head_usb_descriptor
    1 -- bInterfaceNumber    \ номер данного интерфейса (нумеруется с 0) в наборе интерфейсов, поддерживаемых в данной конфигурации
    1 -- bAlternateSetting   \ альтернативный номер интерфейса
    1 -- bNumEndpoints       \ число конечных точек для этого интерфейса без учета нулевой конечной точки
    1 -- bInterfaceClass     \ код класса интерфейса
    1 -- bInterfaceSubClass  \ код подкласса интерфейса
    1 -- bInterfaceProtocol  \ код протокола интерфейса
    1 -- iInterface          \ индекс дескриптора строки, описывающейинтерфейс
CONSTANT usb_interface_descriptor 

\ стандартный дескриптор USB конечной точки
head_usb_descriptor
    1 -- bEndpointAddress    \ код адреса конечной точки
    1 -- bAttributes         \ атрибуты конечной точки
    2 -- wMaxPacketSize      \ максимальный размер пакета для конечной точки
    1 -- bInterval           \ интервал опроса (в миллисекундах) конечной точки при передачи данных
CONSTANT usb_endpoint_descriptor 

\ дескриптор строки
head_usb_descriptor
80 2* -- bString             \ строка из N байт или N/2 символов Unicode
CONSTANT usb_string_descriptor 


DECIMAL
