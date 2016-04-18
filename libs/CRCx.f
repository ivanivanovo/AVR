\ Варианты вычисления CRC при битовом и байтовом доступе
\ Начальный значения при том и другом доступе различны для сходимости результатов



0x31 CONSTANT Polynomial8
\ класический вариант
: CRC8f ( adr u -- crc8) \ подсчет контрольной суммы
  OVER + SWAP
  0xFF -ROT \ \ начальное значение №1
\  0xAC -ROT \ \ начальное значение №2
  do \ цикл по байтам
    I C@  XOR 
      8 0 do \ цикл по битам
            1 LSHIFT 
            DUP 0x100 AND
            if Polynomial8 XOR then
          loop
  loop  
  0xFF AND
  ;
\ S" 123456789"  CRC8f  .uhex .( <---CRC8f) cr
\ S" 1"  CRC8f  .uhex .( <---CRC8f) cr
\ S" 123456789" 2DUP + 0x0 SWAP C! 1+ CRC8f  .uhex .( <---CRC8f) cr
\ S" 123456789" 2DUP + 0xF7 SWAP C! 1+ CRC8f  .uhex .( <---CRC8f) cr

\ вариант который показывает причину разницы
: CRC8f' ( adr u -- crc8) \ подсчет контрольной суммы
  1+
  OVER + SWAP
  0xff -ROT \ -------------------------!
  do \ цикл по байтам
      8 0 do \ цикл по битам
            1 LSHIFT 
            DUP 0x100 AND
            if Polynomial8 XOR then
          loop
    I C@  XOR 
  loop  
  0xFF AND
  ;
\ S" 123456789"  CRC8f'  .uhex .( <---CRC8f') cr

\ вариант класический, но с измененным начальным значением
\ для сосвместимости с битовым доступом
: CRC8f" ( adr u -- crc8) \ подсчет контрольной суммы
  OVER + SWAP
  0xAC -ROT \ -------------------------!
  do \ цикл по байтам
    I C@  XOR 
      8 0 do \ цикл по битам
            1 LSHIFT 
            DUP 0x100 AND
            if Polynomial8 XOR then
          loop
  loop  
  0xFF AND
  ;
\ S" 123456789"  CRC8f"  .uhex .( <---CRC8f") cr

VARIABLE shiftByte
\ битовый вариант, реализует класическое деление полиномов
: CRC8b ( adr u -- crc8) \ подсчет контрольной суммы
  OVER + SWAP
\  0xFC -ROT \ начальное значение №1
  0xFF -ROT \ начальное значение №2
  do \ цикл по байтам
      I C@ shiftByte C!
      8 0 do \ цикл по битам
            1 LSHIFT 
            shiftByte C@ 1 LSHIFT DUP shiftByte C! 0x100 AND if 1+ then
            DUP 0x100 AND
            if Polynomial8 XOR then
          loop
  loop  
  8 0 do \ цикл по 0 битам
        1 LSHIFT 
        DUP 0x100 AND
        if Polynomial8 XOR then
      loop
  0xFF AND
  ;
\ S" 123456789"  CRC8b  .uhex .( <---CRC8b) cr
\  S" 123456789" 2DUP + 0x0 SWAP C! 1+ CRC8b  .uhex .( <---CRC8b) cr

VARIABLE _CRC_  \ регистр CRC
VARIABLE _MASK_ \ маска старшего бита
VARIABLE _Poly_ \ полином

: CRC<<bit ( 1/0 --)
  _CRC_ @ 
  1 LSHIFT + \ вдвинули бит в регистр
  _CRC_ @ _MASK_ @ AND if _Poly_ @ XOR then 
  _CRC_ !
  ;

\ проверка сообщения с CRC на равенство нулю
: CRC8chZero ( adr u -- crc8) \ подсчет контрольной суммы
  0xFF _CRC_ ! \ начальное значение
  Polynomial8 _Poly_ !
  0x80  _MASK_ !
  OVER + SWAP
  do \ цикл по байтам
      I C@ 
      8 0 do \ цикл по битам
            DUP 1 LSHIFT SWAP
            _MASK_ @ AND 7 RSHIFT \ выделить старший бит 
            CRC<<bit
          loop
      drop
  loop  
   _CRC_ C@
  ;
\ S" 123456789)"  CRC8chZero  .uhex .( <---CRC8chZero) cr



0x1021 CONSTANT PolynomialCCITT
: CRC16 ( adr u -- crc16) \ подсчет контрольной суммы
  OVER + SWAP
  0xFFFF -ROT  \ начальное значение №1
\  0x1d0f -ROT \ начальное значение №2
  do \ цикл по байтам
    I C@ 8 LSHIFT XOR 
      8 0 do \ цикл по битам
            1 LSHIFT 
            DUP 0x10000 AND
            if PolynomialCCITT XOR then
          loop
  loop  
  0xFFFF AND
  ;
 \ S" 123456789" CRC16  .uhex .( <---CRC16) cr
 \ S" 123456789__" OVER 9 + 0xb129 SWAP W!   CRC16  .uhex .( <---CRC16-Z) cr

: CRC16b ( adr u -- crc16) \ подсчет контрольной суммы
  0x84CF _CRC_ !  \ начальное значение №1
\  0xFFFF _CRC_ ! \ начальное значение №2
  PolynomialCCITT _Poly_ !
  0x8000  _MASK_ !
  OVER + SWAP
  do \ цикл по байтам
      I C@ 
      8 0 do \ цикл по битам
            1 LSHIFT 
            DUP 0x100  AND 8 RSHIFT \ выделить старший бит 
            CRC<<bit
          loop
      drop    
  loop  
  16 0 
  do \ цикл по 0 битам
      0  CRC<<bit
  loop
 _CRC_ W@
  ;
 \ S" 123456789"  CRC16b  .uhex .( <---CRC16b) cr
 \ S" 123456789__" OVER 9 + 0xb129 SWAP W!   CRC16b  .uhex .( <---CRC16b-Z) cr


0x864CFB CONSTANT Polynomial24
: CRC24 ( adr u -- crc24) \ подсчет контрольной суммы
  OVER + SWAP
  0xB704CE  \ начальное значение №1 
\  0x25EF22  \ начальное значение №2
  -ROT
  do \ цикл по байтам
    I C@ 16 LSHIFT XOR 
      8 0 do \ цикл по битам
            1 LSHIFT
            DUP 0x1000000 AND
            if  Polynomial24 XOR then
          loop
  loop  
  0xFFFFFF AND
  ;
 \ S" 123456789"  CRC24  .uhex .( <---CRC24) cr
 \ S" 123456789____" 1- OVER 9 + 0x02cf21 SWAP !  CRC24  .uhex .( <---CRC24-Z) cr

: CRC24b ( adr u  -- crc24) \ подсчет контрольной суммы
  0xB111C9  \ начальное значение №1
\  0xB704CE  \ начальное значение №2
  _CRC_ !
  Polynomial24 _Poly_ !
  0x800000  _MASK_ !
  OVER + SWAP
  do \ цикл по байтам
      I C@ 
      8 0 do \ цикл по битам
            1 LSHIFT 
            DUP 0x100  AND 8 RSHIFT \ выделить старший бит 
            CRC<<bit
          loop
      drop    
  loop  
  24 0 
  do \ цикл по 0 битам
      0  CRC<<bit
  loop
  _CRC_ @ 0xFFFFFF AND
  ;
\ S" 123456789"  CRC24b  .uhex .( <---CRC24b) cr
\ S" 123" over 0xB704CE swap ! 0x0 CRC24b  .uhex .( <---24/0CRC24b) cr



0x04C11DB7 CONSTANT Polynomial32
: CRC32_BZIP2 ( adr u -- crc32) \ подсчет контрольной суммы
  OVER + SWAP
  0xFFFFFFFF  \ начальное значение №1
\  0xC704DD7B  \ начальное значение №2
  -ROT 
  do \ цикл по байтам
    I C@ 24 LSHIFT XOR 
      8 0 do \ цикл по битам
            DUP 1 LSHIFT SWAP
            0x80000000 AND
            if Polynomial32 XOR then
          loop
  loop  
  0xFFFFFFFF XOR \ из-за этого не получается нулевого CRC при проверке
  ;
 \ S" 123456789"  CRC32_BZIP2  .uhex .( <---CRC32_BZIP2) cr
 \ S" 123456789____" OVER 9 + 0x181989fc SWAP ! 2dup dump cr  CRC32_BZIP2  .uhex .( <---CRC32_BZIP2-Z) cr
\ S" 123456789____" OVER 9 + 0xe7e67603 SWAP ! 2dup dump cr  CRC32_BZIP2  .uhex .( <---CRC32_BZIP2-Z) cr

: CRC32_BZIP2b ( adr u  -- crc32) \ подсчет контрольной суммы
  0x46AF6449  \ начальное значение №1
\  0xFFFFFFFF  \ начальное значение №2
  _CRC_ !
  Polynomial32 _Poly_ !
  0x80000000  _MASK_ !
  OVER + SWAP
  do \ цикл по байтам
      I C@ 
      8 0 do \ цикл по битам
            1 LSHIFT 
            DUP 0x100  AND 8 RSHIFT \ выделить старший бит 
            CRC<<bit
          loop
      drop    
  loop  
  32 0 
  do \ цикл по 0 битам
      0  CRC<<bit
  loop
  _CRC_ @ 
  0xFFFFFFFF XOR
  ;
\ S" 123456789"  CRC32_BZIP2b  .uhex .( <---CRC32_BZIP2) cr

\ : findIniCRCb ( --)
\   0xffffffff 0x80000000 
\   do
\       I S" 123456789"  CRC32_BZIP2 0xC8C3A78F = if i .hex leave then
\   loop
\   ;

