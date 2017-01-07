\ имя проекта: буферные инструменты
\ автор:~iva дата:2010 ревизия:1
\ ======== ИНФО ================================================================
\ Система управления буферами (сегментами памяти). Нужно создать их и описать
\ слова для доступа к ним, с соблюдением всех ограничений. 
\ При создании задаются: 
\ начальный размер (>0)
\ максимальный размер (0-без ограничения);
\ определяются:
\ свободный указатель (finger),
\ указатель конца записи (wender).
\ 0 <= свободный указатель < указатель конца записи < максимальный размер.
\ 
\ Указатель записи содержит адрес первого свободного байта куда можно писать,
\ его можно читать, но нельзя изменять. Свободный указатель используется словами
\ доступа для записи и для чтения, его можно и читать и изменять в пределах 
\ определяемых операцией 
\ (от 0, до чтение: <указатель конца записи 
\           запись: =указатель конца записи)
\ При каждой операции записи или чтения свободный указатель(finger) смещается на 
\ величину зависящую от порции записи/чтения, если при записи finger пререходит
\ за указатель конца записи, последний смещается на ту же величину, так что в 
\ итоге finger всегда меньше или равен указателю конца записи.
\ Если при записи происходит выход за пределы отведенной памяти, то последняя 
\ увеличивается кратно текущему размеру, до тех пор пока не упрется
\ в максимальный размер определенный при создании буфера.
\ -----------------структура seg------------------------------------------------
\ max size createSeg: ROM-SEG
\ ------------------------------------------------------------------------------
\ adr       CELL    имя
\ size      CELL    seg-size
\ lim       CELL    seg-lim
\ finger    CELL    seg-finger
\ wender    CELL    seg-wender
\ labels    CELL    seg-labels
\ name      STR     seg-name
\ ------------------------------------------------------------------------------
\ ======== ЗАДАЧИ ==============================================================
\ ======== ПОДКЛЮЧАЕМЫЕ ФАЙЛЫ и слова нужные не только здесь ===================
S" ~iva/AVR/opcodes.f"   INCLUDED \ для работы описанием кодов операции и другое
\ ======== КОНСТАНТЫ И ПЕРЕМЕННЫЕ ==============================================
0 VALUE SEG \ ссылка на структуру текущего сегмента
\ ======== СЛУЖЕБНЫЕ СЛОВА ДЛЯ ОПРЕДЕЛЕНИЯ ГЛАВНЫХ СЛОВ ========================
: seg-size ( -- adr) \ актуальный размер буфера
    SEG CELL+  ;
: seg-lim ( -- u) \ лимит буфера
    seg-size CELL+ @ ;
: seg-finger ( -- adr) \ адрес свободного указателя
    seg-size 2 CELLS + ;
: seg-wender ( -- adr) \ указатель конца записи
    seg-finger CELL+  ;
: seg-labels ( -- adr) \ адрес начала цепочки меток в текущем сегменте
    seg-wender CELL+  ;
: seg-name ( -- adr) \ адрес строки с именем сегмента
    seg-labels CELL+  ;
: ?seg ( -- ) \ показать имя текущего сегмента
    seg-name COUNT TYPE ;    
: resize? ( u --) \ нужно ли и возможно ли изменение размера сегмента?
    seg-size @ OVER <
    \ попытка расширить сегмент
    IF  seg-lim  ?DUP IF OVER < ABORT" Выход за ограничитель сегмента." THEN
        seg-size @ OVER SWAP / 1+ seg-size @ *
        seg-lim ?DUP IF MIN THEN
        \ u new
        SEG @ OVER RESIZE THROW SEG ! seg-size !
    THEN 
    DROP
    ;
: preWrite ( u -- ) \ проверка возможности записи u байт
    seg-finger @  + DUP resize?
    seg-wender @ MAX seg-wender !
    ;
: finger! ( u --) \ установить указатель
    DUP resize?
    seg-finger ! 
    ;
: ORG ( u -- ) \ установить указатель сегмента
    finger! ;

: finger> ( u --) \ передвинуть указатель на u байт
     seg-finger @ + finger! ;    
\ ======== ГЛАВНЫЕ СЛОВА =======================================================
: createSeg: ( limit size "name"--)
    >IN @ >R
        CREATE  DUP >R  ALLOCATE THROW  , R> ,   , 0 , 0 , 0 , 
    R> >IN ! BL WORD COUNT str!  \ имя сегмента
    ;
: fingerA ( -- adr) \ адрес указателя для чтения/записи
     SEG @ seg-finger @ + ;
: wenderA ( -- adr ) \ адрес адреса свободного байта для записи
    SEG @ seg-wender @ + ;
: finger ( -- n) \ указатель для чтения/записи
     seg-finger @  ;
: wender ( -- n ) \ адрес свободного байта для записи
    seg-wender @ ;
: preRead ( n --) \ проверка возможности чтения
    finger + wender > ABORT" Незаписано."
    ;

: fingerAlign ( -- ) \ выровнять указатель на чёт
    finger DUP 1 AND + finger! ;

: >Seg ( n --) \ записать ячейку в буфер
    CELL preWrite
    fingerA ! CELL finger> ;
: W>Seg ( n --) \ записать слово в буфер
    2 preWrite
    fingerA W! 2 finger> ;
: C>Seg ( n --) \ записать байт в буфер
    1 preWrite
    fingerA C! 1 finger> ;
\    : B>Seg ( f # --) \ запись бита #=(0..31)
\        8 CELLS 1- AND 1 SWAP LSHIFT 
\        fingerA @ SWAP
\        ROT IF OR ELSE INVERT AND THEN fingerA !
\        ;
: B>Seg ( f # --) \ запись бита #=(0..)
    8 CELLS /mod >R 1 SWAP LSHIFT 
    fingerA R> CELLS + DUP >R @  SWAP
    ROT IF OR ELSE INVERT AND THEN R> !
    ;

: Seg> ( -- n) \ считать ячейку из буфера 
    CELL preRead
    fingerA @ CELL finger> ;
: Seg>W ( -- n) \ считать слово из буфера 
    2 preRead
    fingerA W@ 2 finger> ;
: Seg>C ( -- n) \ считать байт из буфера 
    1 preRead
    fingerA C@ 1 finger> ;
: Seg>B ( # -- f) \ чтение  бита #=(0..31)
    8 CELLS 1- AND
    fingerA @ SWAP RSHIFT 1 AND 0= 0= ;
: SegA ( n -- addr) \ выдать реальный адрес смещения n
    Seg @ + ;
\ ======== ТЕСТЫ И ПРИМЕРЫ =====================================================
\ 30  22 createSeg: ROM-SEG
\ ROM-SEG TO SEG
\ HEX
\ ROM-SEG 7 CELLS DUMP CR
\ SEG @ 40 DUMP CR
\ 1 >Seg TRUE 3 B>Seg SEG @ 10 DUMP CR

