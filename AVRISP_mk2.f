

MARKER ALLDROP \ для удаления нижеследующего

256  TO size-rBuf \ размер буфера чтения, может быть 1-256, ограничено протоколом 
size-rBuf 2* VALUE szUBuf \ размер буфера пакетов
0 VALUE UBuf \ буфер пакетов, внутри которого размещен буфер чтения rBuf
\ буфер (со счетчиком) приема и передачи
szUBuf ALLOCATE THROW TO UBuf
VARIABLE Tred \ количество байт пересылки


HEX 
\ определители AVRISP_mk2
03eb CONSTANT AVRISP_mk2_Vid  
2104 CONSTANT AVRISP_mk2_Pid 

0 VALUE EPin
0 VALUE EPout
0 VALUE EPoutSize

\ 0 VALUE EPout
\ 80 EP# OR VALUE EPin \ libusb 0x82 или для JUNGO 0x83 
\ 0 VALUE EPin \  JUNGO 0x83 

  
: SetEPoutSize ( endpoint_descriptor -- ) \ установить размер EP 
  wMaxPacketSize c@ TO EPoutSize
  ;

: SetEpAdr ( ) \ установить адреса конечных точек по дескрипторам
  (( dev &CnfDesc )) libusb_get_active_config_descriptor errorUSB
  CnfDesc *interface  @ @ bNumEndpoints c@  \ количество конечных точек
  IF
    CnfDesc *interface  @ @ *endpoint @ DUP bEndpointAddress C@  \ первый адрес
    DUP 0x80 AND IF TO EPin DROP ELSE TO EPout SetEPoutSize THEN
    CnfDesc *interface  @ @ *endpoint @ libusb_endpoint_descriptor + DUP bEndpointAddress C@ \ второй адрес 
    DUP 0x80 AND IF TO EPin DROP ELSE TO EPout SetEPoutSize THEN
  THEN
  ; 

DECIMAL

0 TO USB_TIMEOUT

UBuf szUBuf  0 fill \ очистка буфера
\ UBuf szUBuf dump cr
: >bulk> (  -- )
    EPin 0= IF SetEpAdr THEN
    (( hand EPout UBuf Tred @  Tred USB_TIMEOUT )) libusb_bulk_transfer  errorusb \ передать 
    \ нулевой завершающий пакет, если нужно
    Tred @ EPoutSize mod 0= if (( hand EPout UBuf 0 Tred USB_TIMEOUT )) libusb_bulk_transfer  errorusb then 
 1 pause  \ ХЗ?, но помогает от ошибок, когда программатор подключен через внешний хаб, 
    (( hand EPin  UBuf szUBuf  Tred USB_TIMEOUT )) libusb_bulk_transfer  errorusb \ принять
    ;

: UBuf> ( --) \ передать/принять буфер
    >bulk> 
    ;
: clrbuf ( ) \ чистка буфера
    0 Tred ! ;
: c>buf ( c --) \ запомнить символ
    UBuf Tred @ + c! 
    Tred 1+!
    ;
: shwBuf ( )
  UBuf Tred @ dump SPACE Tred @ .
  ;



\ осуществить программирование
ProgInterface ISPprog = [IF] S" ISPprog.f" INCLUDED [THEN]
ProgInterface PDIprog = [IF] S" Xprog.f"   INCLUDED [THEN] 

AVRISP_mk2_Vid AVRISP_mk2_Pid findUSBprog
EndedLoop <>
[IF]
  UBuf FREE THROW \ освободить память
  ALLDROP \ и забыть все это
[THEN] 

