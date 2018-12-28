\ смена загрузчика
\ Взять новый загрузчик, скопировать его в новый сегмент, сдвинув вниз на половину размера памяти
\ добавить автономный копировщик, который сможет самостоятельно переписать код из нижней половины памяти
\ на положенное место
\ используя старый загрузчик записать полученный сегмент в чип (нижнюю половину), сменить вектор сброса, 
\ что бы указывал на копировщик
\ передать управление копировщику
\ передать управление новому загрузчику 


\ создать сегмент для копии
FLASHEND 1+ 2* CONSTANT SizeFlashB
SizeFlashB DUP createSeg: copyBOOT-SEG
: copyBoot[ SAVE-SEGMENT copyBOOT-SEG TO SEG ;
: ]copyBoot RESTORE-SEGMENT ;

copyBoot[ \ сделать сегмент текущим 
0 segA SizeFlashB 0xFF fill \ заполнить сегмент 0xFF

SizeFlashB 2/ VALUE NewBoot \ пометить начало загружаемой области
ROM[ finger ]ROM CONSTANT ROMfinger
\ сделать копию
ROM[ 0 segA ]ROM NewBoot segA ROMfinger MOVE
ROMfinger PAGESIZEb /mod SWAP [IF] 1+ [THEN] CONSTANT cntPage \ количество страниц для записи

ROMfinger NewBoot + \ конец занятой области
org \ отсюда и начнем дозапись кода копировщика

#def wrdL    r0     \ младший байт слова для LPM-SPM
#def wrdH    r1     \ старший байт слова для LPM-SPM
#def iWords  r16    \ счетчик слов
#def iPage   r17    \ счетчик страниц
#def WPsizeB r18 ( +r19) \ константа (2байта), количество байт на странице

\ =============================================================================
\ =                      здесь начинается код копировщика                     =
\ =============================================================================

[NOT?] WDTCR [IF] #def WDTCR WDTCSR [THEN]
finger CONSTANT BeginCopyr
PAGESIZEb BeginCopyr + BeginCopyr PAGESIZEb mod - CONSTANT lastPgSRC
\ копировщик пишет целое количество станиц
\ поэтому в целевую область попадет часть копировщика, 
\ дополняющая размер перемещяемого кода до целой страницы
\ при дальнейшем програмиррование эта часть будет перезаписана
code copyBoot ( --) \ копировщик
    cli \ запретить прерывания
    setPins \ настроить выходы на минимальную работу
    \ скопировать данные из ROM в ROM, начиная с задних адресов
    ldiW X,lastPgSRC  1-  \ X=задний адрес источника, 
    ldiW Y,ROMfinger  1-  \ Y=целевой задний адрес 
    ldiW WPsizeB,PAGESIZEb
    ldi iPage,cntPage \ количество страниц для записи
    for movW Z,X 
            \ заполнение буфера
            ldi iWords,PAGESIZE \ количество слов в буфере
            for lpm wrdH,Z sbiW Z,1 lpm wrdL,Z  
                ldi r,{b SPMEN }  mov SPMCSR,r  SPM 
                sbiW Z,1
            next iWords
        movW X,Z
        \ стереть и записать страницу
        movW Z,Y 
            ldi r,{b PGERS SPMEN } mov SPMCSR,r  SPM 
            ldi r,{b PGWRT SPMEN } mov SPMCSR,r  SPM 
        subW Y,WPsizeB 
    next iPage
    \ уйти в новый загрузчик
    goto 0 
    c;
finger VALUE NewBootEnd


\ направить вектор сброса
0 VECTOR> copyBoot
\ HEX-save copy.hex

\ NewBootEnd BeginCopyr - . .( размер копировщика) CR
]copyBoot \ вернуть рабочий сегмент

