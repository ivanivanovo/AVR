#!  /home/ivanov/spf-4.20/spf4  
\ знакомство форта с AVR
S" AVR/asmAVR.f" INCLUDED \ ассемблер, дизассемблер и другое
0x 9108 CONSTANT device \ Процессор ATtiny25
S" AVR/selectAVR.f" INCLUDED \ набор команд для данного микроконтроллера
DECIMAL
\ далее уже сам проект

4000000 CONSTANT cpuCLK \ тактовая частота

\ описание флагов
BitsIn GPIOR0 \ флаги
    _BitIs fCap     \ 1=capture, 0=free
    _BitIs fMaster  
    _BitIs fAlarm  
    _BitIs fSync 
    _BitIs fTx 
BitsIn GPIOR1 \ флаги USIdebuger
    _BitIs fLink
    _BitIs fTransfert
       
\ описание портов
BitsIn PinB
    2 #BitIs bid \ пин шины данных
    
BitsIn PortB
    4 #BitIs Alarm \ временно, для индикации СД
    
\ описание регистров
\ === общего назначения ====
\ r0  register: 
\ r1  register: 
\ r2  register: 
\ r3  register: 
\ r4  register: 
\ r5  register: 
\ r6  register: 
\ r7  register: 
 r8  register: sADC
    \ r9  register: sADCh
 r10 register: rin
 r11 register: rout
 r12 register: rADC
    \ r13 register: rADCh
 r14 register: iSreg 
 r15 register: idat
\ === загрузочные ====
 r16 register: iStBit
 r17 register: stByte
\ r18 register: 
\ r19 register: 
\ r20 register: 
\ r21 register: 
\ r22 register: 
\ r23 register: 

\ === пары ====
\ r24,r25 как R
\ X  register: 
\ Y  register: указатель буфера приёма-передач
BitsIn yl
    2 #BitIs b4
    \ r29  - 
\ r30,r31 как указатель Z, доступ к памяти и косвенный вызов подпрограмм

eprom[
\    1 take CrtByte
]eprom

ram[ SRAM_START org
\        allot_w stEve1
        7 array InBufOut \ для приёма и выдачи
 InBufOut 7 AND [IF] cr .( Адрес буфера InBufOut дложен быть кратен 8.) quit [then]       
]ram    
\ ============ таблицы ===================================

\ ============ прерывания! ===============================
TCNT0 PORT: TCNTi
OCR0A PORT: OCRi
OVF0addr constant iOVaddr
OC0Aaddr constant iCompAddr
PCI0addr constant iEdgeAddr
\ S" iware.f" INCLUDED \ подключить библиотеку i-ware 

code USItransfertint
    in  rin,USIDR 
    out USIDR,rout
    set_b USIOIF
    st  rin,y+
    ldd rout,y+3     
    if_b b4 clr_b b4 set_b fTransfert then
    reti c;
USI_OVFaddr vector> USItransfertint  

code ADCint  \ преобразование завершено
    inW rADC,ADCl \ принять результат
\    add sADC,rADC add sADC 1+,rADC 1+ \ усреднение
\    lsr sADC 1+ ror sADC
    set_b ADSC    \ запустить новое измерение
    reti c;
ADCCaddr vector>  ADCint
  
\ ============ подпрограммы ==============================
code CheckLink \ тестирование связи
\ в случае приёма правильной последовательности чисел, сформировать ответ
\ и получив верный ответ - считать связь установленной.
\ разрыв связи не фиксируется, флаг обнуляется только через RESET.
    in r,InBufOut cpi r,24
    if= in r,InBufOut 1+ cpi r,36
        if= in r,InBufOut 2+ cpi r,66
            if= in r,InBufOut 3 + cpi r,129
                if=
                    ldi r,129 out USIDR,r
                    ldi r,66  out rout,r
                    ldi r,36  out InBufOut 4 +,r
                    ldi r,24  out InBufOut 5 +,r
                else cpi r,153
                     if= set_b fLink
                         set_b alarm 
                     else clr_b alarm then
                then
            then
        then
    then     
    ret c;
code Answer \ ответ на запрос
    in r,InBufOut cpi r,0
    if= in r,InBufOut 1+ cpi r,1
        if= \ выдать по адресу RAM
            in xL,InBufOut 2 + 
            in xH,InBufOut 3 + 
            ld r,x+ out USIDR,r
            ld r,x+ out rout,r
            ld r,x+ out InBufOut 4 +,r
            ld r,x  out InBufOut 5 +,r
        then
    then     

    ret c;
\ ============ программа =================================
code main
\    nop
    begin
        if_b fTransfert
            clr_b fTransfert
            if_nb fLink 
                rcall CheckLink 
            else \ обработка запроса, подготовка ответа
                rcall Answer
            then
        then
    again
    
    c;
\ ============ инициализация! ============================
<bits
BitsIn r
  PORF  #BitIs rPORF
  EXTRF #BitIs rEXTRF
  BORF  #BitIs rBORF
  WDRF  #BitIs rWDRF
bits>
CODE Ini
    in r,MCUSR \ определить причину сброса
    if_b rPORF \ если по включению
    \ обнулить_память 
        clr r0  ldiw y,SRAM_START  ldiw z,RAMend IOEND -
        begin st y+,r0   sbiw z,1  wait0
    \ обнулить_регистры  
        ldi z,zl 1- 
        begin st z,r0   sbiw z,1   wait0
    then
    \ установка тактовой частоты
        ldi r,{b CLKPCE } out CLKPR,r
        ldi r,1  out CLKPR,r \ 8M/2=4M
    \ иницировать указатель стека
        ldiW r,RAMEND  outW spl,r  
    \ настройки USIdeb
        ldiW y,InBufOut \ указатель на буфер приёма передачи дебагера
    \ общая настройка
        ldi r,{b ACD } out ACSR,r  \ отключить аналоговый компаратор
    \ настройка выходов
        ldi r,{b alarm  PB1 } out ddrb,r
        ldi r,{b   PB0 } out portb,r \ подтянуть вход
    \ прерывания PCINT
        ldi r,{b bid } out PCMSK,r \ разрешить прерывания только от пина шины данных
        ldi r,{b PCIE   } out GIMSK,r \ разрешить PCINT
    \ USI как Slave SPI
        ldi r,{b USIOIE USIWM0 USICS1 } out USICR,r \ прерывание, 3-ware, внешний строб позитив
        set_b USIOIF \ сбросить флаг переполнения
    \ настройка таймеров
        \ собака, 
        \ таймер0, для i-ware
        ldi r, {b CS00 } out TCCR0B,r \ clk=clk
        ldi r,{b TOIE0 } out TIMSK,r  \ разрешить прерывание по переполнению t0
        \ таймер1 
        \ таймер2 
    \ настройка АЦП
\        ldi r,12 out admux,r \ ref=Vcc in=1.1
        ldi r,{b REFS1 } 15 + out admux,r \ ref=1.1V in=TemperSens
        ldi r,{b ADEN ADIE } 7 + out ADCSRA,r \ clk/128
        set_b ADSC \ старт
    sei
    goto main
    C;
 0  VECTOR> Ini
cr
HEX-save boot.hex
\ ============ прошивка чипа! ============================
 fuse{ ckdiv8 SUT0 }=1   \ эти фузы будут разпрограммированы
\ fuse{  SUT0 }=1   \ эти фузы будут разпрограммированы
 fuse{ EESAVE SUT1 }=0   \ эти фузы будут запрограммированы
\ lock{ lb1 lb2 }=0  \ чип будет залочен
\ lock{ lb1 lb2 }=1  \ чип будет разлочен
 chip! \ записать всё

.( ага ) wender . CR
.s cr
\ see-all
\ labels-maps
\ see-code SPItransfert

\ ============ отладочные инструменты ====================
: tryConnect ( -- f ) \ истина если коннект успешен
    TRUE
    10 0
    do
        24 36 66 129 usb>spi drop \ запрос коннекта
        20 pause 
        0 0 0 0 usb>spi \ получение ответа
       drop \ 4 = 
         rbuf  @ 405029505  <>
         if DROP FALSE LEAVE then 
    loop
    ;
SCK_MIN value SCKnow \ текущая скорость тактирования
0 VALUE OnLine \ флаг усановленной связи
: RESETup (  -- ) \
    SCKnow 0 powerup 50 pause
    SCKnow 1 powerup 100 pause 
    ." ." \ прогрессор
    ;
: OnDebug ( -- )
   SCK_MIN to SCKnow
   begin
    RESETup tryConnect 0=
   while
    SCKnow SCK_MAX <    
   while
    SCKnow 2* SCK_MAX min to SCKnow
   repeat
    powerdown ." Не удалось установить связь." cr exit
   then
    24 36 66 153 usb>spi drop \ установить в чипе флаг линка 
    TRUE TO OnLine \ установить в отладчике флаг линка
    ." Связь установлена, SCK=" SCKnow . cr
   ; 
: cmdAddr   ( cmd0 cmd1 addrL addrH -- n) \ послать команду с адресом и получить ответ на предыдущий запрос
    online 0= if ondebug then 
    usb>spi  ;

: NamedBuf ( adr n --) \ показать принятые байты с их именами
    \ adr - адрес первого байта в чипе, n - количество принятых байт
    0 do ( adr')
         dup I + label>name type ." =" rbuf i + c@ . 
      loop drop
      ;
: fromRAM ( adr -- ) \ запросить данные по адресу из ОЗУ
    RAM[
        0 1 rot dup >r byte-split cmdAddr drop \ отправить запрос
        0 1 r@ byte-split cmdAddr \ получить ответ
        r> swap  NamedBuf 
    ]RAM
    ;
: aaa PCMSK fromRAM  ;
: ada sADC fromRAM  ;
\ 200 pause OnDebug   
\ see-code main
\ bye

