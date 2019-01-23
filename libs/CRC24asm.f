\ ====== прерывания не должны изменять эти регистры ===========================
\ ====== или использовать их как константы ====================================
WARNING @
    WARNING OFF
    #def iByte  r16     \ счетчик/текущий байт ================================
    #def rPol   r17     \ полином =============================================
WARNING !
\ =============================================================================
\ подсчёт контрольной суммы CRC24, сдвиг влево
\ 0x864CFB  \ полином
\ 0xB704CE  \ начальное значение
code CRC24flash ( Z=adr R=u -- Z=adr+u NUM[0..2]=CRC24 ) 
\ вход:  адрес строки (Z) и ее счётчик (R)
    push iByte push rPol 
        ldi rPol,0xB7  mov Num2,rPol \ начальное значение 
        ldi rPol,0x04  mov Num1,rPol \ начальное значение 
        ldi rPol,0xCE  mov Num0,rPol \ начальное значение 
        begin \ цикл по байтам
            LPM iByte,Z+  eor Num2,iByte \ получить новый байт
            ldi iByte,8
            for \ цикл по битам
                lsl Num0 rol Num1 rol Num2
                if_c ldi rPol,0x86 eor Num2,rPol 
                     ldi rPol,0x4C eor Num1,rPol 
                     ldi rPol,0xFB eor Num0,rPol 
                then
            next iByte
            sbiW R,1
        wait0 
    pop rPol pop iByte 
    ret c;

\ CRC24flash val?


\eof
code tstCRC
\    ldiW Z,CRC24flash  ldiW R,tstCRC CRC24flash -
    ldiW Z,0  ldiW R,Sign
    rcall CRC24flash
    mov r16,Num0
    mov r17,Num1
    mov r18,Num2
    ret c;