\ попытка сделать библиотеку
\ нужно определить
\ 1) Регистры: (из младших)  rin, rout   
\              (r16 или старше)  
\ 2) Пин: 
\ 3) Флаг:  fTransfert, fLink
\ 4) "У" как указатель буфера 
BitsIn yl
    2 #BitIs b4 \ бит заполнения буфера

: finger8 finger 7 + 7 true xor and org ; \ перенос фингера на кратную позицию
\ выделение памяти для буфера приёма/передачи
ram[   
       finger8 8 take InBufOut \ для приёма и выдачи ( Адрес буфера должен быть кратен 8.)
]ram    

\ ============ прерывания! ===============================
code USItransfertint
    in rin,sreg push rin
        in  rin,USIDR   \ принять байт из приёмника
        out USIDR,rout  \ отдать байт передатчику
        set_b USIOIF    \ погасить флаг
        st  rin,y+      \ сохранить принятое в буфере
        ldd rout,y+3    \ подготовить байт для передачи 
        if_b b4   
            clr_b b4 set_b fTransfert  \ признак конца передачи
        then
    pop rin out sreg,rin
    reti 
     c;
USI_OVFaddr vector> USItransfertint  

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
                     
                     then
                then
            then
        then
    then     
    ret c;
code Answer \ ответ на запрос
    in r,InBufOut 
    cpi r,0
    if= \ читать
        in r,InBufOut 1+ 
        cpi r,1 ( 0 1 adrL adrH)
        if= \ выдать по адресу RAM
            in xL,InBufOut 2 + 
            in xH,InBufOut 3 + 
            ld r,x+ out USIDR,r
            ld r,x+ out rout,r
            ld r,x+ out InBufOut 4 +,r
            ld r,x  out InBufOut 5 +,r
        else 
        then
    else cpi r,1 ( 1 byte addrL addrH  )
        if= \ писать в RAM
            in xL,InBufOut 2 + 
            in xH,InBufOut 3 + 
            in r,InBufOut 1 +
            st x,r
        then
    then     

    ret c;
    
code Transfert?
    skip_b fTransfert ret \ ничего нет - выход
    clr_b fTransfert
    if_nb fLink 
        rcall CheckLink 
    else \ обработка запроса, подготовка ответа
        rcall Answer
    then
    ret c;    
    
    
    
\ ============ отладочные инструменты ====================
: tryConnect ( -- f ) \ истина если коннект успешен
    TRUE
    40 0
    do
        24 36 66 129 usb>spi drop \ запрос коннекта
        100 pause 
        0 0 0 0 usb>spi \ получение ответа
       drop \ 4 = 
         rbuf  @  405029505  <>
         if DROP FALSE LEAVE then 
    loop
    ;
SCK_MIN value SCKnow \ текущая скорость тактирования
0 VALUE OnLine \ флаг усановленной связи
: RESETup (  -- ) \
    SCKnow 0 powerup 50 pause
    SCKnow 1 powerup 100 pause 
   \ cr SCKnow .
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
: cmdAddr   ( cmd0 cmd1 addrL addrH -- n) \ послать команду с адресом и 
    \ получить ответ на предыдущий запрос
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
\ : aaa PCMSK fromRAM  ;
\ : ada TadcL fromRAM  ;
\ 200 pause OnDebug   
    

