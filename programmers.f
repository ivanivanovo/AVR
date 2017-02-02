\ Сборник программаторов
\ пробежаться по всем известным программаторам,
\ найти подключенные,
\ а среди них, тех что с чипом
\ и если сигнатура чипа совпадает с целевой - прошить его
WARNING OFF
    [WITHOUT?] MARKER S" lib/include/core-ext.f" INCLUDED [THEN]
WARNING ON

\ переменные для кусковой записи
\ если они не определны (=0), то пишется все что есть
0  VALUE FlashSRCAddr   \ начальный адрес источника для записи
0  VALUE FlashStartAddr \ начальный адрес записи
0  VALUE FlashNumWrite  \ количество байт для записи
0  VALUE E2SRCAddr      \ начальный адрес источника для записи
0  VALUE E2StartAddr    \ начальный адрес записи
0  VALUE E2NumWrite     \ количество байт для записи

: FlashFullWrite \ полная запись
    ROM[   SEG @  wender  0 ]ROM   TO FlashStartAddr TO FlashNumWrite TO FlashSRCAddr
    ;
: E2FullWrite \ полная запись
    EPROM[ SEG @  wender  0 ]EPROM TO E2StartAddr    TO E2NumWrite    TO E2SRCAddr
    ;

0 VALUE USBdevs \ общее количество  USBустройств

: addUSB1 ( ) \ подключение библиотеки 
    C" LIBUSB_LOG_LEVEL_NONE" FIND  NIP 0= IF S" ~iva/AVR/USB1.f" INCLUDED THEN
    ;

: USB1 ( -- f ) \ активизировать библиотеку USB, 
    \ f=FALSE в случае неуспеха
    \ f= общее количество  USBустройств
    ['] addUSB1 CATCH 0= 
    IF C" initUSB" FIND DROP EXECUTE \ инциализировать и получить список устройств
    ELSE FALSE
    THEN
    ;

DEFER PreProg  \ действия перед программированием чипа
DEFER PostProg \ действия после программирования чипа
:NONAME ; \ пустое действие
DUP IS PreProg IS PostProg

: chip! ( --) \ записать в чип
    S" ~iva/AVR/prog.f" INCLUDED
    USB1 ?DUP
    IF  TO USBdevs
        \ попытка через UsbTiny
        S" ~iva/AVR/USBtiny1.f" INCLUDED
        \ попытка через AVRISP_mk2
        S" ~iva/AVR/AVRISP_mk2.f" INCLUDED 
    THEN
    ; 



#def {QUIT}  .( Прошу пана:) CR  EndedLoop THROW

: chip: ( ) \ войти в режим программирования, но не программировать
    ['] {QUIT} IS PreProg
    chip!  
    ;

: chip!: ( ) \  запрограммировать и остаться  в чипе
    ['] {QUIT} IS PostProg
    chip!
    ;

\EOF
\ ======== интерактивная работа с чипом до записи =========================
\ срабатывает 1 раз на первом подходящем чипе
 chip:  \ ключевое слово
    \ пример что делать
    flash_ 0 wender dumpchip cr \ посмотреть 
    EPROM[ 0x123 w>seg ]Eprom \ изменить
    theprog cr \ зашить

chip:  eprom_ 0 E2END 1+ dumpchip  cr
\ ======== автозапись ==================================================
\ срабатывает на каждом подходящем чипе
\ если используются известные слова можно использовать конструкцию :NONAME IS
   :NONAME  EPROM[ 0x5523 w>seg ]Eprom  ; IS PreProg
\ если используются слова специфические для режима программирования чипа
\ и известные только в этом режиме  - используется запись #def и привязка IS
   #def {post} eprom_ 0 16 dumpchip
   ' {post}  IS PostProg
 chip! \ ключевое слово
\ ======== интерактивная работа с чипом после записи =========================
\ срабатывает 1 раз на первом подходящем чипе
 chip!:  \ ключевое слово
    flash_ 0 wender dumpchip \ пример что делать

     
