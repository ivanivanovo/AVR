\ таблица значений для датчика температуры LMT01
\ OutData = 0 выдача результата в импульсах датчиков
\ OutData = 1 выдача результата в 1/100 градусах Цельсия
\ OutData = 2 выдача результата в градусах Цельсия в формате 1.8.7

\ в программе отпределить формат вывода OutData:
\   1 CONSTANT OutData
\ после получения числа импульсов с датчика LMT01,
\ скормить его через пару R макросу Celsius, потом 
\ получить температуру в выбранном формате, опять-же в R

finger CONSTANT StartLMT01_LUT
OutData 
[IF]
    \ Таблица соответствия количества имульсов температуре
    REQUIRE t{ data.f
    DECIMAL
    \ прямая реализация таблицы
    \ t{    26  181  338  494  651  808  966 \ -50... +10
    \     1125 1284 1443 1602 1762 1923 2084 \ +20... +80
    \     2245 2407 2569 2731 2893 3057 3218 \ +90... +150
    \         }words LUT
    \ \ LUT val?
    \ сравнивать исходное число с каждым значением из таблицы,
    \ пока исходное не окажется меньше табличного

    \ байтная реализация таблицы
    0 VALUE preVal 
    3 CONSTANT stepTbl    
    OutData 1 = 
    [IF] #def scaleK 1000 8 LSHIFT \ масштабный коэффициент 
    [THEN]
    OutData 2 = 
    [IF] #def scaleK 5 16 LSHIFT \ масштабный коэффициент
    [THEN]
    
    : d# ( # -- #-preVal kL kH ) \ значения таблицы
    \ #-preVal шаг от предыдущего значения
    \ k - 2-байтное значение коэффициента 
        DUP preVal - SWAP TO preVal
        DUP 255 >  abort" Больше байта!" 
        scaleK \ масштабный коэффициент
        OVER  /mod >R  OVER 2/ < 0= 1 AND R> + \ деление с округлением результата 
        word-split abort" Больше слова!"
        byte-split 
        ;
    \ таблица соответствий
    t{    26 d#  181 d#  338 d#  494 d#  651 d#  808 d#  966 d#  \ -50... +10
        1125 d# 1284 d# 1443 d# 1602 d# 1762 d# 1923 d# 2084 d#  \ +20... +80
        2245 d# 2407 d# 2569 d# 2731 d# 2893 d# 3057 d# 3218 d#  \ +90... +150
        }bytes dLUT
    \ dLUT hex[ see ]hex  cr
    \ dLUT see  cr
    \ из исходного числа вычитать каждое значение из таблицы, 
    \ пока не получится отрицательное число rest
    \ Celsius=(i-5)*10 - |rest|*10/Di - общая формула
    \ i   - позиция в таблице [0..20]
    \ Di  - дельта i-тая 
    \ Celsius=(i-5)*10 - |rest|*Ki  - расчетная формула
    \ Ki  - i-тый коэффициент
    #def ii*5  c[ mov rH,ii lsl ii lsl ii add ii,rH ]c
    #def ii*10 c[ lsl ii mov rH,ii lsl ii lsl ii add ii,rH ]c

    #def tH r0
    #def rA X
    #def rB r
    code M16*8 ( rA rb -- A*B ) \ 16-ти и 8-ми разрядные сомножители, 24-разрядный результат
    \ rA - номер младшего регистра пары первого сомножителя
    \ rb - байт второго сомножителя
    \ результат замещает сомножители
    \ старший->rA младший->rb    
        pushW tH \ служебная пара
        push ii
            clrW tH  ldi ii,8  lsr rB
            for 
                if_c addW tH,rA then rorW tH ror rB
            next ii
            movW rA,tH
        pop ii popW tH
        ret c;

    #def X*r rcall M16*8
    OutData 1 =
    [IF] \ выдача результата в 1/100 градусах Цельсия
        code Celsius100 ( R=RAW -- R=Celsius) \ перевод в градусы Цельсия
            clr ii ldiW Z,dLUT
            begin LPM x,Z  sub r,x sbc rH,(0) \ проход по dLUT
            while_nb C inc ii adiW Z,stepTbl repeat
            neg r \ положительное число которое надо умножить на k и вычесть
            adiW Z,1 LPM x,Z+ LPM xH,Z \ X=k
            X*r \ Xr=вычитаемое (B)
            \ xH=b3 xL=b2 r=b1 - 24 бита
            push xH push x push r   
            mov r,ii ldiW X,1000 X*r \ xr=ii*1000
            ldi rH,5000 (LB) sub r,rH 
            ldi rH,5000 (HB) sbc x,rH 
            \ xr=уменьшаемое (A) (ii*1000-5000)=(ii-5)*1000
            \ x=a3 r=a2 - 16 бит
            pop rH  neg rH    \ rH=a1-b0 (a0=0)
            pop rH  sbc r,rH  \  r=a2-b2-c 
            pop rH  sbc x,rH  \  x=a3-b3-c
            mov rH,x \ R=A-B  (16 бит)
            ret c;
            #def Celsius c[ rcall Celsius100 ]c
    [THEN]
    OutData 2 =
    [IF] \ выдача результата в градусах Цельсия в формате 1.8.7
        code Celsius1.8.7 ( R=RAW -- R=Celsius) \ перевод в градусы Цельсия
            clr ii ldiW Z,dLUT
            begin LPM x,Z  sub r,x sbc rH,(0) \ проход по dLUT
            while_nb C inc ii adiW Z,stepTbl repeat
            subi ii,5  ii*5 \ ii=старший байт целой части в формате 1.8.7 
            neg r \ положительное число которое надо умножить на k и вычесть
            adiW Z,1 LPM x,Z+ LPM xH,Z \ X=k
            X*r \ X=вычитаемое
            neg xL sbc ii,xH 
            mov rH,ii mov r,x
            ret c;
            #def Celsius c[ rcall Celsius1.8.7 ]c
    [THEN]

[ELSE] #def Celsius \ ничего не делать
[THEN]

finger StartLMT01_LUT - . .( <==== Размер LMT01_LUT) CR