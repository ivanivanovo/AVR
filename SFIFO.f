\ создание и работа со строчными буферами FIFO
\ структура буфера:
\ name--v  адрес начала буфера
\      size, idxR, idxW, u[____],u[_________],...
\             \_idxR____/   смещение от адреса idxR до счетчика первой несчитанной строки
\                    \_idxW__________________/ смещение от адреса idxW до свободного места

4 CELLS CONSTANT costSFIFO \ дополнительный размер для служебного пользования

: AidxR ( buf -- adr_idxR)
    1 CELLS + 
    ;
: AidxW ( buf -- adr_idxW)
    2 CELLS + 
    ;
: clrSFIFO ( buf --) \ очистка буфера
    >R
    2 CELLS R@ AidxR ! \ начальное смещение чтения
    1 CELLS R> AidxW ! \ начальное смещение записи
    ;
: checkSize ( u buf -- f) \ f=false, если u байт не поместятся в buf
    DUP @ \ size
    SWAP AidxW @  ROT + 
    < ABORT" Перполнение буфера SFIFO."
    ;






: SFIFO: ( size  "name"-- ) \ создание строчного буфера FIFO, размером size
    CREATE  DUP  costSFIFO + ALLOCATE THROW >R 
    R@ ,  \ адрес выделенной памяти под буфер 
    R@ !  \ запомнить size  
    R> clrSFIFO
    ( "name" --> adr)
    DOES> @  
    ;

: SFIFO! ( adr u buf -- ) \ положить строку adr u в буфер SFIFO buf
    2DUP checkSize \ проверить возможность записи
    ( adr u buf )
    AidxW DUP >R ( adr u adr_idxW) DUP @ + ( adr u adr') ALIGNED
    2DUP !   ( adr u adr') \ записать u
    CELL+ 2DUP + >R SWAP CMOVE \ записать в буфер
    R> R@ - R> ! \ сдвинуть указатель записи
    ;

: SFIFO@ ( buf -- adr u) \ вернуть очередную строку из буфера, если буфер пуст adr=buf, u=0
    DUP AidxR  @  \ сравнить указатели
    OVER AidxW @ 
    > 
    IF DUP clrSFIFO 0 \ буфер пуст 
    ELSE
        AidxR DUP >R @  \ idxR  (R:adr_idxR)
        R@ + DUP CELL+ SWAP @ \ adr u
        2DUP + R@ - ALIGNED R> ! \ сдвинуть указатель чтения
    THEN
    ;



\eof
64 SFIFO: tt
64 SFIFO: tt1
tt 64 dump cr
hex
S" 12345" tt sfifo!
S" abcdefg" tt sfifo!
tt 40 dump cr cr
tt sfifo@ type
tt 40 dump cr cr
tt sfifo@ type
tt 40 dump cr
