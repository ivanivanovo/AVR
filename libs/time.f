\ про время

CREATE TimeVal  2 cells allot
CREATE TimeZone 2 cells allot
0
CELL -- _sec     \ секунды 0 до 59
CELL -- _min     \ минуты 0 до 59
CELL -- _hour    \ часы от 0 до 23
CELL -- _mday    \ день месяца от 1 до 31
CELL -- _mon     \ месяц  от 0 до 11
CELL -- _year    \ число лет, прошедших с 1900
CELL -- _wday    \ Число дней, прошедших с воскресенья, от 0 до 6
CELL -- _yday    \ Количество дней, прошедших с 1 января, от 0 до 365
CELL -- _isdst   \ Значение флага положительно, если "летнее" время учитывается, 0, если нет, и отрицательно, если информация недоступна. 
CELL -- _gmtoff  \ Seconds east of UTC
CELL -- _zone    \ Timezone abbreviation
CONSTANT size_tm

size_tm ALLOCATE THROW VALUE tm

: getTime ( -- usec sec  ) \ получить системное время
    (( TimeVal   TimeZone  )) gettimeofday THROW
    TimeVal 2@ 
    ;
: getMs ( -- ms ) \ выдать текущие милисекунды
    getTime 3600 24 * mod 1000 * swap 1000 / +
    ;

: ctime ( UTC -- adr u) \ преобразовать число секунд в строку даты-времени
    0 SWAP TimeVal 2! 
    (( TimeVal )) ctime ASCIIZ> 
    1- ;
: localtime ( UTC -- adr ) \ разместить дату-время в календарной структуре
    0 SWAP TimeVal 2! 
    (( timeval tm )) localtime_r
    ;
: time.ms ( ) \ показать текущее время с десятками милисекунд
    gettime localtime DROP
    tm _hour @ 2 .0R ." :"
    tm _min @ 2 .0R ." :"
    tm _sec @ 2 .0R ." ."
    1000 / 3 .0R
    ;
\ getTime NIP gmtime @ .

\ date -d @1399364718
\ Вт. мая  6 12:25:18 MSK 2014

\ (( S" date -d @1399364718" )) system
\ Вт. мая  6 12:25:18 MSK 2014
\ (( timeval )) ctime ASCIIZ> TYPE
\ (( timeval )) gmtime возвращает структуру
