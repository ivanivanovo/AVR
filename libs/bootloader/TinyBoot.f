\ BootLoader
\ без привязки к системе связи
REQUIRE prgCMD01 iwcmd.f
\ нужно объявить буферы приема и предачи 
\ #def inBoot  iwFifoIn \ буфер из которого загрузчик читает пакеты
\ #def outBoot iwFifOut \ буфер куда загрузчик пишет пакеты
\ и подпрограмы 
\ #def iniSysLink iwIni \ инициализация буферов и связи
\ #def BootPac> iwTransmitter \ подпрограмма передачи
\ #def StopInt rcall KillDog \ остановка лишних прерываний

\ из-за ATtiny441-841 у которых стирается сразу 4 страницы
\ придеться проверять размеры и брать в работу больший из них
[FOUND?] ERASESIZE 
[IF]   ERASESIZE PAGESIZE < [IF] .( Караул, ERASESIZE меньше чем PAGESIZE!) CR BYE [THEN]
       ERASESIZE
       RAM[ 
        finger 
            ERASESIZE take pageRAM \ временная страница в памяти
        org \ вернем указатель на место, чтоб bufRAM не крал ОЗУ у основной программы
       ]RAM
[ELSE] PAGESIZE 
[THEN] CONSTANT (PAGESIZE) \ Words
\ загрузчик в чипе тоже должен это проверять и учитывать
\ 1 организовать в RAM виртуальную страницу 
\ 2 принимать данные и помещать их не в буфер записи, а в RAM
\ 3 дать команду на стирание
\ 4 записать данные из RAM постаранично во flash
\ ...


finger constant StartBoot \ маркер начала библиотеки загрузчика

BitsIn rH ( aka cmd)
    0 #BitIs fXor \ флаг разностных данных 
    1 #BitIs fWrt \ флаг записи 
    2 #BitIs fRst \ флаг перезагрузки 
    3 #BitIs fVec \ флаг записи стартового вектора

\ структура пакета программирования
#def (sx)    1       \ семафор
#def (cmd) (sx) 1 +  \ команда
#def (zL)  (sx) 2 +  \ адрес, младший
#def (zH)  (sx) 3 +  \ адрес, старший
#def (rP)  (sx) 4 +  \ адрес, дополнительный
#def (d)   (sx) 5 +  \ данные

\ 
    
BitsIn r0 ( aka SPMCSR)
<bits SPMEN bits> 7 AND #BitIs rSPMEN

\ !!!!!!!!!!!!!!! критическое место !!!!!!!!!!!!!!!!
finger CONSTANT crtBootA
[NOT?] pageRAM
[IF]    \ обычная страница
        code do_WP ( Z=addrPage -- r=action Z=addrPage )
            \ прерывания должны быть уже запрещены!!!
                ldi r,{b PGERS SPMEN } 
        _wp:    rcall 0 \ очистить страницу 
                ldi r,{b PGWRT SPMEN } \ записать страницу 
            c; \ ----v
        code do_SPM ( r=action Z=addr r0:r1=data -- r=action Z=addr r0:r1=x) 
            \ прерывания должны быть уже запрещены!!!
            \ выполнить инструкцию SPM
            mov SPMCSR,r  SPM
            begin mov r0,SPMCSR wait_nb rSPMEN 
            ret c; \ do_SPM val?
finger _wp org c[ rcall do_SPM ]c org
[ELSE]  \ виртуальная, временная страница в ОЗУ
        code do_SPM ( r=action Z=addr r0:r1=data -- r=action Z=addr r0:r1=x)
            \ пишем два байта в ОЗУ
            mov r,zL andi r,(PAGESIZE) 2* 1- \ r=адрес байта внутри страницы
            ldiW X,pageRAM add xL,r clr r adc xH,r
            st X+,r0  st X,r1  \ пишем два байта в ОЗУ 
            ret c;
        code Go_SPM ( r=action Z=addr r0:r1=data -- r=action Z=addr r0:r1=x) 
            \ выполнить инструкцию SPM
            mov SPMCSR,r  SPM
            begin mov r0,SPMCSR wait_nb rSPMEN 
            ret c;
        code do_WP ( Z=addrPage -- r=action Z=addrPage )
            ldi r,{b PGERS SPMEN } rcall Go_SPM \ стереть страницы
            andi zL,(PAGESIZE) 2* 1- INVERT (LB) \ Z->начало ErazedPage
            ldiW X,pageRAM \ X->pageRam
            ldi ii,(PAGESIZE) PAGESIZE / \ сколько записывамых страниц в стираемых
            for \ запись нескольких реальных страниц
                ldi rH,PAGESIZE
                begin ld r0,X+ ld r1,X+
                    ldi r,{b SPMEN } rcall Go_SPM \ записать слово в страницу 
                    dec rH
                while
                    adiW Z,2
                repeat 
                ldi r,{b PGWRT SPMEN } rcall Go_SPM \ записать текущую страницу 
                adiW Z,2 \ Z->начало следующей страницы
            next ii
            ret c;    
[THEN]
\ !!!!!!!!!!!!!!! критическое место !!!!!!!!!!!!!!!!
finger CONSTANT crtBootB


0 VALUE adrPrgWad
#def ldZPrgWad  c[ ldiW Z,adrPrgWad ]c
code Flash2RAM ( Z=AddrFlash Y=AddrRam r=n --)
\ скопировать n байт из Flash в RAM 
    for lpm r0,Z+ st Y+,r0 next r
    ret c;



code prgWad> (  -- ) \ пыж прогамматора
        ldi r,4 ldiW Y,outBoot rcall WtakeBuf
        if_t ret then
        st Y+,r \ запись n в голову пакета
ldZ:    ldZPrgWad rcall Flash2RAM
        ldiW Y,outBoot goto WendBufP  \ передвинуть индекс записи 
        c;  \ prgWad> val?

0 VALUE VectBoot
#def Vect->X   c[ ldiW X,VectBoot ]c \ получить стартовый вектор
code >BootPac ( -- ) \ обработка входящих пакетов программатора
    ldiW Y,inBoot rcall RsizeBufP if0 ret then
    rcall RaddrBufP \ получить адрес пакета
[FOUND?] PreBoot [IF] PreBoot [THEN]   
    ldd rH,y+(sx) \ получить семафор
    cpi rH,prgCMD01
    if= ldd rH,y+(cmd) \ cmd
        \ получить адрес
        ldd zL,y+(zL)  ldd zH,y+(zH)  
        [FOUND?] RAMPZ [IF]  ldd r0,y+(rP) mov RAMPZ,r0 [THEN]
       ( Z=adr Y->Pac rH=cmd ) \ команда и данные для flash
        ld ii,Y    \ ii=размер пакета
        adiw Y,(d) \ Y->data
        if_b fVec 
mVect:      Vect->X \ получить стартовый вектор
            std Y+0,xL std y+1,xH \ записать в данные стартовый вектор загрузчика
            StopInt \ остановить лишние прерывания      
        then
        skip_nb fRst icall \ мягкий выход (код НЕ зависит от положения)
        subi ii,sizePrgPac sizeCRC +  \ размер поля данных в байтах
        cli
            lsr ii \ ii=количество данных, в словах
            if \ Y->data
            \ положить данные из пакета в буфер записи страницы
                begin
                    ld r0,Y+  ld r1,Y+
                    if_b fXor \ если пришли разностные данные 
                        lpm r,Z+ eor r0,r \ обратить их
                        lpm r,Z  eor r1,r
                        sbiw Z,1
                    then
                    ldi r,{b SPMEN }  rcall do_SPM \ записать во временный буфер
                    dec ii
                while
                    adiw Z,2
                repeat
            then
            skip_nb fWrt rcall do_WP  \ стереть и записать атомарно
        sei rcall prgWad>
    then
    ldiW Y,inBoot goto RendBufP
    c;

\ ============ инициализация! ============================
code iniBoot \ стартовая инициализация
    \ инициализация регистровых констант
    \ инициализировать систему связи
    rcall iniSysLink
    sei  c; \ iniBoot val_
code BootLoader 
    \ цикл ожидания команд
    begin 
        rcall >BootPac  \ проверить и принять пакет
        rcall BootPac>  \ проверить и запустить передачу
    again
    c;   \ val?
0  VECTOR> iniBoot \ стартовый вектор сейчас указывает на загрузчик
 finger
    0 SegA W@ TO VectBoot \ получить стартовый вектор ("rjmp iniBoot")
    mVect org  Vect->X  \ поместить в код
 org

finger  CONSTANT EndBoot
sizePrgWad take (prgWad) fingerAlign \ выровнять указатель на случай нечетного sizePrgWad
(prgWad) TO adrPrgWad \ образ пыжа
EndBoot StartBoot - sizePrgWad + CONSTANT SizeBoot 
finger  CONSTANT EndBootWad 

0 CONSTANT StartCRCboot \ начало контролируемой области загрузчика
EndBoot StartCRCboot - CONSTANT SizeLoader \ размер загрузчика
StartCRCboot SegA SizeLoader CRC16 CONSTANT SigLoader \ сигнатура полного загрузчика

finger \ сигнатура и CRC теперь известны,
    ldZ org  ldZPrgWad 
    (prgWad) org \ помещаем реальные данные в код
        prgWad C>SEG  
        SigLoader W>SEG
        (prgWad) SegA 3 crc8b C>SEG
org
\ prgWad> val?
\ (prgWad) HEX[ val? ]HEX

FUSE{ SELFPRGEN }=0 \ разрешить самопрограммирование

\ Запомнить вектора для загрузчика
ROM_FREE DUP createSeg: BOOT-SEG
    0 SegA      \ откуда
    BOOT-SEG @  \ куда
    ROM_FREE    \ скока
    CMOVE       \ скопировать

\ SigLoader .hex .( <--SigLoader) cr
S" copyBoot.f"     INCLUDED \ на случай смены старого загрузчика, запись идет в отдельный сегмент
 \ SizeBoot . .( <==== размер чисто загрузчика) cr 
  SizeLoader sizePrgWad + . .( <==== полный размер загрузчика) cr

