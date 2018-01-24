\ полезные подпрограмки
\ для копирования и правки под конкретный проект

\ ======== работа а ЕЕПРОМ =====================================================
code SPMe ( c  addr -- c  addr ) \ запись в EPROM)
     \      rH   rL    rH  rL
     skip_nb eepe   rjmp   SPMe \ ждать готовности
     out eearL,rL     out eedr,rH \ установка адреса и байта
     cli
        set_b  eempe   set_b  eepe \ запись
     sei
     ret c;

code LPMe ( addr -- addr c)  \ загрузка из EPROM)
     \       rL      rL  rH
     skip_nb eepe   rjmp LPMe
     out eearL,rL  set_b eere
     in  rH,eedr
     ret c;

\ ======== арифметика ==========================================================
         \ r1 r0   r2 r1 r0
code Mul ( c1 c0 --h  l  c0) \ умножение 8*8 ( 58 циклов + возврат )
     \ вход:   r0,r1 - сомножители
     \ выход:  r2-старший r1-младший байт произведениия
     \ измена: ii
     clr  r2    \ очистка старшего (1)
     ldi  ii,8 \ взвод цикла (1)
     lsr  r1    \ (1)
    \ [3]
     for
        if_c add r2,r0  then \ (2)
        ror r2  ror r1  \ (1) (1)
     next ii \ (1) 7*(2) (1)
     \ 8*(5)+7*(2)+(1)=(55)
     \ (3)+(55)=(58)
     ret  c; \ на 8МГц примерно 8мкс

         \ r1 r0   r2 r1 r0
code Mul8 ( c1 c0 --h  l  c0) \ умножение 8*8 ( ? циклов + возврат )
     \ вход:   r0,r1 - сомножители
     \ выход:  r2-старший r1-младший байт произведениия
     clr  r2    \ очистка старшего (1)
     lsr  r1    \ (1)
        if_c add r2,r0  then \ (2)
        ror r2  ror r1 \ (2)
        if_c add r2,r0  then \ (2)
        ror r2  ror r1 \ (2)
        if_c add r2,r0  then \ (2)
        ror r2  ror r1 \ (2)
        if_c add r2,r0  then \ (2)
        ror r2  ror r1 \ (2)
        if_c add r2,r0  then \ (2)
        ror r2  ror r1 \ (2)
        if_c add r2,r0  then \ (2)
        ror r2  ror r1 \ (2)
        if_c add r2,r0  then \ (2)
        ror r2  ror r1 \ (2)
        if_c add r2,r0  then \ (2)
        ror r2  ror r1 \ (2) == (32)
        \ 2+32=(34)
     ret  c; \ на 8МГц примерно 4мкс

         \  r0   r2 r1 r0
code 10* (  c0 --h  l  c0) \ умножение u8 на 10 ( 14 циклов + возврат )
    sub r2,r2       \ 1 
    mov r1,r0       \ 1
    lsl r1 rol r2   \ 2
    lsl r1 rol r2   \ 2
    lsl r1 rol r2   \ 2 r2=r0*8
    lsl r0          \ 1 r0=r0*2
    if_c inc r2 then  \ 2
    add r1,r0       \ 1
    if_c inc r2 then  \ 2   
    \ 14 циклов
    ret c; 

code M16*8 ( mH mL y  -- rH rM rL ) \ умножение 16*8 
     \       r2 r1 r0    r2 r1 r0
     \ вход:   r0,r1,r2 - сомножители
     \ выход:  r2-старший r1-средний r0-младший байт произведениия
     push r in r,sreg push r push r4 push r3
     push r2
     rcall Mul mov r3,r1 mov r4,r2 \ mL*y -> r4H r3L
     pop r1
     rcall Mul \ mH*y -> r2H r1L
     add r1,r4  clr r4  adc r2,r4  mov r0,r3
     pop r3 pop r4 pop r out sreg,r pop r
     ret c;

code Div ( делимое делитель -- остаток целое делитель) \ деление 8/8
     \        r1      r0         r2     r1     r0
     \ вход:                 r1 - делимое; r0 - делитель
     \ выход:  r2 - остаток; r1 - целое;   r0 - делитель
     \ измена: Раб
     sub r2,r2 \ очистить остаток и перенос
     ldi r,9
     begin
          rol r1
          dec r     if_z ret then
          rol r2
          sub r2,r0 if_c  add r2,r0 clc else sec then
     again
     c;

\ code Div16/16   ( rHH rHL  rLH rLL  dH dL    --  rHH rHL   rLH rLL  dH dL) ( ~200 тактов) \ беззнаковое 16/16 --> r16 q16
\                   остаток  делимое  делитель --  остаток   частное  делитель
\    clr rHH clr rHL   \ обнуление остатка 
 code Div32/16   ( rHH rHL rLH rLL   dH dL    --  rHH rHL   rLH rLL  dH dL) ( ~200 тактов) \ беззнаковое 32/16 --> r16 q16
\                      делимое        делитель --  остаток   частное  делитель
\      ограничение: делимое/делитель < чем 2^16
        push r in r,sreg push r push ii
        mov r,dH  or r,dL
        if_nz      \ проверка на 0 делителя
          ldi ii,16  ldi r,1
          for
               lsl rLL rol rLH  rol rHL  rol rHH
               sub rHL,dL      sbc rHH,dH
               if_c
                    or rLL,r
                    add rHL,dL  adc rHH,dH
               then
          next ii
          com rLL com rLH  \ инверсия частного
        else
          clr rLL  com rLL  mov rLH,rLL   \ при делении на 0 частное = FFFF
        then
        pop ii pop r out sreg,r pop r
        ret c;


code Div24/24 ( num24   div24    mod24=0 -- num24   div24    mod24 )  ( ~400 тактов)
              \ делимое делитель остаток -- частное делитель остаток
    clr Mod0  clr Mod1  clr Mod2 \ обнулить остаток
\ code Div48/24 ( возможно, но с ограничением: делимое/делитель < чем 2^24 )
    ldi ii,24 \ количество циклов
    for
        lsl Num0  rol Num1  rol Num2  rol Mod0  rol Mod1  rol Mod2 \ сдвиг делимого влево через остаток
        sub Mod0,Div0  sbc Mod1,Div1  sbc Mod2,Div2 \ вычесть из остатка делитель
        if_c \ если остаток меньше делителя
            inc Num0 \ запомнить факт
            add Mod0,Div0  adc Mod1,Div1  adc Mod2,Div2 \ восстановить остаток
        then
    next ii
    com Num0  com Num1  com Num2 \ инвертировать единицы
    ret c; 

              \ r1 r0 -- r2 r1  r0
code bin16BCD ( H   L -- z4 z32 z10) \ двоично-десятичная упаковка 16-битного числа
     \ вход:  r0 - младший байт числа, r1 - старший байт числа
     \ выход: r0 - разряды 1_й и 0_й, r1 - 3_й и 2_й, r2 - 4_й разряд упакованного двоично-десятичного числа
     \ каждая тетрада байтов представляет десятичную цифру 0-9.
     pushX
     push r in r,sreg push r
          mov x,r0   mov xH,r1
          \ старшая цифра
          ser r
          begin
               inc r
               subi x,10000 (LB)
               sbci xH,10000 (HB) \ вычитание 10000
          until_b c
          subi x,-10000 (LB)
          sbci xH,-10000 (HB) \ прибавление 10000
          mov r2,r
          \ 3-я цифра
          ser r
          begin
               inc r
               subi x,1000 (LB)
               sbci xH,10000 (HB)   \ вычитание 1000
          until_b c
          subi x,-1000 (LB)
          sbci xH,-1000 (HB) \ прибавление 1000
          swap r   mov r1,r \ сохранение 3-й цифры в старшей тетраде
          \ 2-я цифра
          ser r
          begin
               inc r
               subi x,100 (LB)
               sbci xH,100 (HB) \ вычитание 100
          until_b c
          subi x,-100 (LB)  \ прибавление 100
          add r1,r \ сохранение 2-й цифры в младшей тетраде
          \ 1-я цифра
          ser r
          begin
               inc r
               subi x,10 \ вычитание 10
          until_b c
          subi x,-10 (LB) \ прибавление 10
          swap r   mov r0,r \ сохранение 1-й цифры в старшей тетраде
          add  r0,xL            \ сохранение младшей цифры
     pop r out sreg,r pop r
     popX
     ret c;

: Log2 ( n -- log2[n] ) \ целочисленный логарифм числа
    dup 0 > 0= abort" Должно быть больше 0." 
    0 begin swap 2/ tuck while 1+ repeat nip ;
    
#def AmL R16
#def AmH R17
#def BmL R18
#def BmH R19

#def Am  AmL
#def Bm  BmL

#def CmL rL
#def CmH rH
#def DmL sumL
#def DmH sumH

code Mul_16 ( ) \ 16-ти разрядные сомножители, 32-разрядный результат
\ DmH:DmL:CmH:CmL = AmH:AmL * BmH:BmL
\ DmH:DmL:CmH:CmL - произведение
\ AmH:AmL – множимое
\ BmH:BmL – множитель
\ R1,R0 – вспомогательные регистры 
     \ находим XL*YL = AmL*BmL и заносим его в младшие байты произведения CmH:CmL
     mul AmL,BmL  movW SmL,R0   
     \ находим XH*YH = AmH*BmH и заносим его в старшие байты произведения DmH:DmL
     mul AmH,BmH  movW DmL,R0   
     \ находим XH*YL = AmH*BmL и прибавляем его к байтам DmH:DmL:CmH произведения
     mul AmH,BmL  add CmH,R0  adc DmL,R1  adc DmH,(0)   
     \ находим YH*XL = BmH*AmL и прибавляем его к байтам DmH:DmL:CmH произведения
     mul AmL,BmH  add CmH,R0  adc DmL,R1  adc DmH,(0) 
     ret c; \ Mul_16 val?
                                     
code MULS_16 \ умножение со знаком
\  DmH:DmL:CmH:CmL = AmH:AmL * BmH:BmL 
\  DmH:DmL:CmH:CmL – знаковое произведение 
\  AmH:AmL – знаковое множимое 
\  BmH:BmL – знаковый множитель 
\  R1,R0 – вспомогательные регистры 
    \ находим XLU*YLU = AmL*BmL и заносим его в  младшие байты произведения CmH:CmL 
    mul AmL,BmL  movW CmL,R0 \
    \ находим XHS*YHS = AmH*BmH и заносим его в старшие байты произведения DmH:DmL 
    muls AmH,BmH movW DmL,R0 \ 
    \ находим XHs*YLU = AmH*BmL и прибавляем его к байтам DmH:DmL:CmH произведения 
    mulsu AmH,BmL clr AmH sbci AmH,0 add CmH,R0 adc DmL,R1 adc DmH,AmH 
    \ находим YHS*XLU = BmH*AmL и прибавляем его к  байтам DmH:DmL:CmH произведения 
    mulsu BmH,AmL clr AmH sbci AmH,0 add CmH,R0 adc DmL,R1 adc DmH,AmH 
    ret  c;

#def tH r0
#def rA R
#def rB X
code Mul16 ( rA rB -- A*B ) \ 16-ти разрядные сомножители, 32-разрядный результат
\ rA - номер младшего регистра пары первого сомножителя
\ rB - номер младшего регистра пары второго сомножителя
\ результат замещает сомножители
\ старший->rA младший->rB    
    pushW tH \ служебная пара
    push ii
        clrW tH  ldi ii,16  lsrW rB
        for 
            if_c addW tH,rA then rorW tH rorW rB
        next ii
        movW rA,tH
    pop ii popW tH
    ret c;


code SetStartVect ( X=startVector --)
  ldi r,{b SPMEN }
  ldiW Z,PAGESIZEb  1-
  begin \ цикл копирования стараницы
    lpm r1,Z sbiw Z,1
  while
    lpm r0,Z  rcall do_SPM \ записать слово 
    sbiw Z,1
  repeat
  movW r0,X rcall do_SPM \ записать слово вектора
  goto do_WP c; \ стереть и записать страницу
