\ запуск forth-assembler через qforth 0.7.9
\ символическую ссылку на этот файл положи в ~/.config/под именем gforth0
\ тогда gforth сам его найдет и прицепит ДО выполнения остальной части команды
warnings CONSTANT WARNING
WARNING OFF
\ sh rm -rf ~/.cache/gforth/386/libcc-tmp \ включать если требуется обновление с-библиотек
\ ================ Системные функции  =========================================
\ требуется доустановить libtool
\ sudo apt-get install libtool-bin
c-library forAVR
    \c #include <unistd.h>
        \ char *getcwd(char *buf, size_t size);
        c-function getcwd getcwd a n -- a
        \ char *get_current_dir_name(void);
        c-function get_current_dir_name get_current_dir_name  -- a 
        \ int usleep (useconds_t usec); 
        \ c-function usleep usleep n -- n
        \ int access(const char *pathname, int mode);
        c-function access access a n -- n
    \c #include <sys/time.h>
        \ int gettimeofday(struct timeval *tv, struct timezone *tz);
        c-function gettimeofday gettimeofday a a -- n
    \c #include <time.h>
        \ char *ctime(const time_t *timep);
        c-function ctime ctime a -- a
        \ struct tm *localtime_r(const time_t *restrict timer, struct tm *restrict result); 
        c-function localtime_r localtime_r a a -- a
    \c #include <stdlib.h>
        \ int system(const char *command);     
        c-function system_ system a -- n
    \c #include <termios.h>
        \ int tcgetattr(int fd, struct termios *termios_p);
        c-function tcgetattr tcgetattr n a -- n
        \ int tcsetattr(int fd, int optional_actions, struct termios *termios_p);
        c-function tcsetattr tcsetattr n n a -- n   
        \ int cfsetispeed(struct termios *termios_p, speed_t speed); 
        c-function cfsetispeed cfsetispeed a n -- n
        \ int cfsetospeed(struct termios *termios_p, speed_t speed); 
        c-function cfsetospeed cfsetospeed a n -- n
    \c #include <sys/stat.h>
    \c #include <sys/types.h>
        \ int mkdir(const char *pathname, mode_t mode);
        c-function mkdir mkdir a n -- n
end-c-library


c-library libUSB
    S" usb-1.0" add-lib
    \c #include <libusb-1.0/libusb.h>
        \ int LIBUSB_CALL libusb_init(libusb_context **ctx);
        c-function libusb_init libusb_init a -- n
        \ void LIBUSB_CALL libusb_set_debug(libusb_context *ctx, int level);
        c-function libusb_set_debug libusb_set_debug a n -- void
        \ ssize_t LIBUSB_CALL libusb_get_device_list(libusb_context *ctx, libusb_device ***list);
        c-function libusb_get_device_list libusb_get_device_list a a -- n

        \ libusb_device_handle * LIBUSB_CALL libusb_open_device_with_vid_pid(
        \ libusb_context *ctx, uint16_t vendor_id, uint16_t product_id);
        c-function libusb_open_device_with_vid_pid libusb_open_device_with_vid_pid a n n -- a

        \ int LIBUSB_CALL libusb_get_device_descriptor(libusb_device *dev,  struct libusb_device_descriptor *desc);
        c-function libusb_get_device_descriptor libusb_get_device_descriptor a a -- n
        \ void LIBUSB_CALL libusb_close(libusb_device_handle *dev_handle);
        c-function libusb_close libusb_close a -- void
        \ int LIBUSB_CALL libusb_control_transfer(libusb_device_handle *dev_handle, 
        \ uint8_t request_type, uint8_t bRequest, uint16_t wValue, uint16_t wIndex,
        \ unsigned char *data, uint16_t wLength, unsigned int timeout);
        c-function libusb_control_transfer libusb_control_transfer a n n n n a n n -- n
        \ int LIBUSB_CALL libusb_get_string_descriptor_ascii(libusb_device_handle *dev,
        \ uint8_t desc_index, unsigned char *data, int length);
        c-function libusb_get_string_descriptor_ascii libusb_get_string_descriptor_ascii a n a n -- n
        \ int LIBUSB_CALL libusb_open(libusb_device *dev, libusb_device_handle **handle);
        c-function libusb_open libusb_open a a -- n
        \ int LIBUSB_CALL libusb_bulk_transfer(libusb_device_handle *dev_handle,
        \ unsigned char endpoint, unsigned char *data, int length,
        \ int *actual_length, unsigned int timeout);
        c-function libusb_bulk_transfer libusb_bulk_transfer a n a n a n -- n
        \ int LIBUSB_CALL libusb_get_active_config_descriptor(libusb_device *dev,
        \ struct libusb_config_descriptor **config);
        c-function libusb_get_active_config_descriptor libusb_get_active_config_descriptor a a -- n
        \ int LIBUSB_CALL libusb_set_auto_detach_kernel_driver(libusb_device_handle *dev, int enable);
        c-function libusb_set_auto_detach_kernel_driver libusb_set_auto_detach_kernel_driver a n -- n
        \ int LIBUSB_CALL libusb_claim_interface(libusb_device_handle *dev,int interface_number);
        c-function libusb_claim_interface libusb_claim_interface a n -- n

end-c-library

: USE BL WORD DROP ;
: (( ; 
: )) ;  
: <( DROP ; 
CREATE sysPad 200 ALLOT
: system ( c-addr u -- ior)
    sysPad SWAP DUP >R CMOVE 0 sysPad R> + !
    sysPad system_
    ;    
\ ================ MULTITASK pthread ==========================================
REQUIRE unix/pthread.fs
\ : ttk  10 0 do i . DUP ms loop DROP ;  
\ 1024 newtask constant tid
\ ' ttk tid initiate
\ 1200 ms 
\ ' ttk execute-task constant tid1
: TASK: ( xt "name" --)
    CONSTANT ; \ task=name=xt
: START ( u task -- tid)
    stacksize4 newtask4 DUP >R -ROT
    2 R> PASS EXECUTE ;
: STOP ( tid -- )
    kill ;
: SUSPEND ( tid -- )
    halt ;
: RESUME ( tid -- )
    restart ;
: PAUSE ( ms -- )
    MS pause ;    
\ ================ MULTITASK pthread ==========================================

\ ================ NOTFOUNDS ==================================================
' NOOP DUP DUP RECTYPE: RECTYPE-NoFnd \ тут нечего делать, все сделал NOTFOUND
: REC-NoFnd ( c-addr u -- RECTYPE-NoFnd | RECTYPE-NULL ) 
    S" NOTFOUND" SFIND 
    IF EXECUTE ( c-addr u -- | RECTYPE-NULL )
        DEPTH 
        IF DUP RECTYPE-NULL = IF EXIT THEN \ сработал замыкающий NOTFOUND - продолжить распознавание
        THEN
        RECTYPE-NoFnd EXIT \ сработал один из NOTFOUND - распознано  
    ELSE DROP 2DROP  THEN
    RECTYPE-NULL  ; \ нет NOTFOUND-ов

' REC-NoFnd GET-RECOGNIZERs
1+ SET-RECOGNIZERs

: NOTFOUND ( adr u -- rectype-null ) 
    2DROP RECTYPE-NULL ; \ последний из NOTFOUND-s, замыкающий цепочку

: NOTFOUND ( adr u -- ) \ попытка обработать ненайденное слово, как имя файла
    ['] REQUIRED CATCH IF NOTFOUND THEN
    ;
\ ================ NOTFOUNDS ==================================================

\ ================ Пути поиска файлов =========================================
CREATE CurDir    255 ALLOT \ абсолютный путь
CREATE RootPoint 255 ALLOT \ точка для относительных путей
CREATE FASMpoint 255 ALLOT \ точка подключения forth-assembler

: COUNTZ ( adr -- adr u) \ размер строки с нулем на конце
    0 BEGIN 2DUP + C@ WHILE 1+ REPEAT 
    ;

get_current_dir_name COUNTZ  CurDir C! CurDir COUNT CMOVE \ выяснить текущий путь
CHAR / CurDir COUNT + C! CurDir COUNT 1+ SWAP 1- C! \ закрыть его слешем

: CurDir+ ( adr u -- adr' u') \ добавить строку к текущему пути
    >R CurDir COUNT + R@ CMOVE
    CurDir COUNT R> +
    ;
: with ( adr u  --) \ добавить путь поиска к остальным
    fpath also-path
    ;
    CurDir COUNT with
    
    CurDir COUNT TUCK S" beq/" SEARCH 
    [IF] \ проект beq/ 
        NIP - RootPoint C! 
        CurDir 1+ RootPoint COUNT CMOVE 
        RootPoint COUNT FASMpoint C!
                  FASMpoint COUNT CMOVE
        S" beq/libs/fasm/" 
    [ELSE] \ прочие
        2DROP DROP
        S" ~/spf-4.21/devel/"  
    [THEN] TUCK FASMpoint COUNT + SWAP CMOVE
        FASMpoint COUNT ROT + SWAP 1- C!

: INCLUDED ( adr u -- ) \ 
    OVER DUP C@ [CHAR] ~ =
    SWAP 1+  C@ [CHAR] / = 0= AND
    if  FASMpoint COUNT DUP >R PAD SWAP CMOVE
        R@ PAD + SWAP DUP R> + >R CMOVE
        PAD R>
    then
    INCLUDED
    ;

: REQUIRE ( "word" "file_name" -- ) \ если нету word, подключить file_name
    BL WORD FIND NIP \ поискать word
    IF BL WORD DROP EXIT THEN \ есть - употребить file_name
    REQUIRE  \  если нет - запросить файл
    ;
\ ================ Пути поиска файлов =========================================

\ ================ прочее =====================================================
\ отложить исполнение до получения параметров
\ работает в gforth  
defer coder
: DOexit R> 1 coder ; 
:NONAME ; DUP @  CONSTANT nonam1  CELL+ @ CONSTANT nonam2
: DOAFTER>  S" DOexit  [ nonam1 , nonam2 , ]" EVALUATE ; IMMEDIATE
                         \ кусок :NONAME/    

: -- +FIELD ; \ для структур
: 1+! ( adr --) DUP @ 1+ SWAP ! ;
: 2- ( u -- u-2) 2 - ;
: 2+ ( u -- u-2) 2 + ;
\ 
: \EOF  ( -- ) \ Заканчивает трансляцию текущего потока
    BEGIN REFILL 0= UNTIL
    POSTPONE \
    ;

\ : VECT ( "name"--) CREATE ['] ABORT , DOES> @ EXECUTE ; === не сделано :(

\ WARNING ON

