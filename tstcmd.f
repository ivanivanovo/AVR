\ знакомство форта с AVR
S" ~iva/AVR/asmAVR.f" INCLUDED \ ассемблер, дизассемблер и другое

\ 0x 9006 CONSTANT device \ Процессор tn15
\ 0x 9205 CONSTANT device \ Процессор ATmega48PA 
 0x 9307 CONSTANT device \ Процессор ATmega8 )
S" ~iva/AVR/selectAVR.f" INCLUDED \ набор команд для данного микроконтроллера
DECIMAL
\ далее уже сам проект
code AAA \ пример использования «умного» IN
	inw r0,r2 
	inW r0,portB  
\	inW r0,0x60 
	c; 
aaa val?



code BBB \ пример использования «умного» OUT 
	outW r0,r4 
	outW portB,r0 
\	outW 0x60,r0 
	c; 
bbb val?

code DDD
    movw r0,r6
    movw portB,r0
    movw r0,portb
\    mov 0x60,r0
\    mov r0,0x60
    c;
    DDD val?                                                                                         
code EEE
    xchg r0,r2
    addi r16,15
    c;
    eee val?
code Prim5
    tst r0 if dec r0 then
    cpi r16,32 if addi r16,10 else ldi r16,32 then
    ret c; prim5 val?
code prim5bis
    tst r0 if_nb Z dec r0 then
    cpi r16,32 if<> addi r16,10 else ldi r16,32 then
    ret c; prim5bis val?
code prim6 \ счётный цикл
    ldi r16,8
    for inc r0 nop nop next r16
    reti c; prim6 val?

INT0addr vector> prim6
\ 0 val?
r16 register: раб
bitsin r17  _bitIs бит0  5 #BitIs Test  _BitIs плюс
code Prim7
 ldi  раб,{b TOIE1   TOIE0 }    out timsk,раб \ разрешить  прерывания от таймеров
 sbr  раб,{b бит0 test плюс } \ в регистре 16 будут установлены в 1 биты: 0, 5 и 6, остальные не меняются
 cbr  раб,{b бит0 test плюс } \ аналогично, только именованные биты будут сброшены
 ori  r20,{b бит0 плюс test } \ побитовое логическое сложение
 andi r21,{b test бит0 плюс } \ побитовое логическое умножение
 c; prim7 val?  

#def meandr  if_b test clr_b test else set_b test then
#def PushF   mov r3 SREG
#def PopF    mov SREG r3

code prim8
    pushf
        meandr
    popF
    reti c;
    prim8 val?
\eof

