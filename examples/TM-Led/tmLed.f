
\ знакомство форта с AVR
S" ~iva/AVR/asmAVR.f" INCLUDED \ ассемблер, дизассемблер и другое
 0x 910A CONSTANT device \ Процессор ATtiny2313
S" ~iva/AVR/selectAVR.f" INCLUDED \ набор команд для данного микроконтроллера
DECIMAL
\ далее уже сам проект
1000000 CONSTANT CLK \ тактовая частота

\ ====================== ПОРТЫ ================================================
    BitsIn PortB
        1 #BitIs GRN        \ выход для зеленого светодиода
    BitsIn ddrB
        1 #BitIs dGRN       \ выход для зеленого светодиода

\ ====================== РЕГИСТРЫ =============================================
 r3  register: (0)        \ хранилище нуля

\ ====================== библиотеки ===========================================
#def sek 50 * chskTime \ перевод секунд в тики таймера
#def mnt 60 * sek  \ перевод минут  в тики таймера
2 CONSTANT #timers
#def TIFR0 TIFR
S" ~iva/AVR/libs/timers.f"    INCLUDED

\ ====================== подпрограммы =========================================
code Mig \ мигни разок
    _/ GRN ldiW X,1 sek 32 / rcall Delay: \_ GRN
    ret c;

\ ====================== подзадачи ============================================
code Migni
    \ постоянно мигать
    begin  
        rcall Mig ldiW X,1 sek  rcall Delay: \ индикация режима
    again
    c;

\ ====================== главный ==============================================
code main <VECTOR 0
    \ инициализация регистровых констант
        clr (0) 
    \ общая настройка
        _/ ACD  \ отключить аналоговый компаратор
    \ выходы
        _/ dGRN   \ выход светодиода
    \ таймеры
    \ T0 используется для тактирования
        \ делаем       v--50гц
        ldi r,clk 1024 50 * /  DUP 255 > [IF] .( Частота таймера0 недостижима :() CR QUIT [THEN]
        mov OCR0A,r
        ldi r,{b WGM01 }     mov TCCR0A,r \ режим CTC
        mov TCNT0,(0) \ обнулить таймер0
        ldi r,{b CS02 CS00 } mov TCCR0B,r \ 1024
    rcall Migni \ запуск задачи мигания
    begin \ рабочий цикл
        rcall time
    again 
    c;
\ main val?


HEX-SAVE tmLed.hex \ выложим скомпилированную прошивку    
chip!
\ ============ прошивка чипа! =================================================
\ SzCntrl
CodeType label: EndBootable
finger CONSTANT EndApp

.( ROM =) EndBootable .  cr
.( RAM =) RAM[ finger ]RAM SRAM_START - . cr
