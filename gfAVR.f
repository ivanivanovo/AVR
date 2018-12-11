\ запуск forth-assembler через qforth

\ ================ Системные функции  =========================================
\ требуется доустановить libtool
\ sudo apt-get install libtool-bin
\c #include <unistd.h>
    \ char *getcwd(char *buf, size_t size);
    c-function getcwd getcwd a n -- a
    \ char *get_current_dir_name(void);
    c-function get_current_dir_name get_current_dir_name  -- a 

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
    c-function system system a -- n
: (( ; 
: )) ;   
\ ================ Пути поиска файлов =========================================
0 VALUE LenDir
CREATE CurDir 200 ALLOT
: COUNTZ ( adr -- adr u) \ размер строки с нулем на конце
    0 BEGIN 2DUP + C@ WHILE 1+ REPEAT 
    ;
get_current_dir_name COUNTZ  TO LenDir CurDir LenDir CMOVE \ выяснить текущий путь
CHAR / CurDir LenDir + C! LenDir 1+ TO LenDir \ закрыть его слешем
: CurDir+ ( adr u -- adr' u') \ добавить строку к текущему пути
    >R CurDir LenDir + R@ CMOVE
    CurDir LenDir R> +
    ;
: with ( adr u  --) \ добавить путь поиска к остальным
    fpath also-path
    ;

S" ~/spf-4.21/devel/~iva/AVR" with
.( Пути поиска файлов:) CR
fpath .path 
CR
CR
: INCLUDED ( adr u -- )
    2DUP S" ~iva" SEARCH
    if 2DROP
        S" ~/spf-4.21/devel/" DUP >R PAD SWAP CMOVE
        R@ PAD + SWAP DUP R> + >R CMOVE
        PAD R>
    else 2DROP
    then
    CR 2dup ." ===>" type ." <===" 
    INCLUDED
    ;
: REQUIRE ( "word" "file nsme" -- ) \ пропустить word для совместимости
    BL WORD DROP REQUIRE
    ;
: -- +FIELD ; \ для структур

: 1+! ( adr --) DUP @ 1+ SWAP ! ;

: NOTFOUND ( adr u --)
-2 throw
\    compiler-notfound1
    ;

: \EOF  ( -- ) \ Заканчивает трансляцию текущего потока
    BEGIN REFILL 0= UNTIL
    POSTPONE \
    ;

: (SWAP) SWAP ;

CR CR .( ========== ЗАГРУЗКА AVR ========) 
S" ~iva/AVR/asmAVR.f" INCLUDED
\ отложить исполнение до получения параметров
: DOexit R> 1 coder ; 
:NONAME ; DUP @  CONSTANT nonam1  CELL+ @ CONSTANT nonam2
\ работает в gforth  
#def DOAFTER>  DOexit  [ nonam1 , nonam2 , ] 
                         \ кусок :NONAME/    

\ CR CR .( ========== проба AVR ========) 
\ 0x9207 CONSTANT device \ Процессор ATtiny44
\  S" selectAVR.f" INCLUDED \ набор команд для данного микроконтроллера
\ DECIMAL

\ S" tst.f" INCLUDED
