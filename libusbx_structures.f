\ константы и структуры специфичные для libusbx

\ коды уровней логирования
0 CONSTANT LIBUSB_LOG_LEVEL_NONE    \ нет сообщений
1 CONSTANT LIBUSB_LOG_LEVEL_ERROR   \ сообщения об ошибках выводятся в stderr
2 CONSTANT LIBUSB_LOG_LEVEL_WARNING \ сообщения об ошибках и предупреждениях выводятся в stderr
3 CONSTANT LIBUSB_LOG_LEVEL_INFO    \ информационные пакеты выводятся в stdout, а ошибки и предупреждения в stderr
4 CONSTANT LIBUSB_LOG_LEVEL_DEBUG   \ отладочные и информационные пакеты выводятся в stdout, а ошибки и предупреждения в stderr

\ коды ошибок libusb
 0  CONSTANT LIBUSB_SUCCESS              \ нет ошибок
-1  CONSTANT LIBUSB_ERROR_IO             \ ошибка ввода вывода
-2  CONSTANT LIBUSB_ERROR_INVALID_PARAM  \ неверный параметр
-3  CONSTANT LIBUSB_ERROR_ACCESS         \ отказ в доступе
-4  CONSTANT LIBUSB_ERROR_NO_DEVICE      \ нет устройства
-5  CONSTANT LIBUSB_ERROR_NOT_FOUND      \ объект не найден
-6  CONSTANT LIBUSB_ERROR_BUSY           \ ресурс занят
-7  CONSTANT LIBUSB_ERROR_TIMEOUT        \ время кончилось
-8  CONSTANT LIBUSB_ERROR_OVERFLOW       \ переполнение
-9  CONSTANT LIBUSB_ERROR_PIPE           \ ошибка канала
-10 CONSTANT LIBUSB_ERROR_INTERRUPTED    \ системный вызов прерван
-11 CONSTANT LIBUSB_ERROR_NO_MEM         \ недостаточно памяти
-12 CONSTANT LIBUSB_ERROR_NOT_SUPPORTED  \ операция не поддерживается
\ ..
-99 CONSTANT LIBUSB_ERROR_OTHER          \ иная ошибка

\ варианты вопросов к определению возможностей libusb на данной платформе
\ функцией libusb_has_capability() >0 true, 0-false
 0       CONSTANT LIBUSB_CAP_HAS_CAPABILITY \ libusb может проверять свои возможности?
 1       CONSTANT LIBUSB_CAP_HAS_HOTPLUG    \ есть поддержка горячей замены устройств?
 0x100   CONSTANT LIBUSB_CAP_HAS_HID_ACCESS \ есть доступ к HID без участия пользователя?
 0x101   CONSTANT LIBUSB_CAP_SUPPORTS_DETACH_KERNEL_DRIVER \ возможно отключать драйвер ядра?


\ стандартный дескриптор USB устройства
usb_device_descriptor 
 CONSTANT libusb_device_descriptor

\ стандартный дескриптор конфигурации USB
usb_config_descriptor   
   ALIGNED 
   CELL -- *interface \ указатель на массив struct libusb_interface
   CELL -- *CND_extra \ указатель на байтовый массив
   CELL --  CND_extra_length 
 CONSTANT libusb_config_descriptor 

\ стандартный дескриптор интерфейса USB
usb_interface_descriptor
   ALIGNED 
   CELL -- *endpoint  \ указатель на массив struct libusb_endpoint_descriptor 
   CELL -- *IND_extra  \ указатель на байтовый массив
   CELL --  IND_extra_length   
 CONSTANT libusb_interface_descriptor 

\ стандартный дескриптор USB конечной точки
usb_endpoint_descriptor
   1 -- bRefresh        \ 
   1 -- bSynchAddress   \ 
   ALIGNED
   CELL -- *EPD_extra  \ указатель на байтовый массив
   CELL -- EPD_extra_length  
 CONSTANT libusb_endpoint_descriptor 

\ стуктура версии libusb
0 
   2 -- major
   2 -- minor
   2 -- micro
   2 -- nano
   CELL -- *rc \ ссылка на строку суфикс релиз-кандидата
   CELL -- *describe \ For ABI compatibility only.
 CONSTANT libusb_version




