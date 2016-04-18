\ подпрограммы сервисного чтения
#def <3< 3 LSHIFT

code HeadChipDtPack ( Y->pack0 --y->data) \ шапка пакета данных чипа
    ldi r,ChipDt 4 *  add r,rH st y+,r  goto AddSRC \ шапка
    c;
code RSignature ( rH=calibr -- ) \ чтение сигнатуры чипа
    ldi r,sizeSgntPac  add r,rH rcall GetBufOut
    if_nt
        rcall HeadChipDtPack
        ldi r,SgntPac 16 * 2 + st y+,r
        clr zH ldi z,0  
                ldi r,{b RSIG SPMEN } mov SPMCSR,r  LPM   st y+,r0 
        ldi z,2 ldi r,{b RSIG SPMEN } mov SPMCSR,r  LPM   st y+,r0 
        ldi z,4 ldi r,{b RSIG SPMEN } mov SPMCSR,r  LPM   st y+,r0 
        goto AddCRC8 \ отправить пакет
    then
    ret c;
code RFuse  ( rH=calibr -- ) \ чтение fuses чипа
    ldi r,sizeFusePac  add r,rH rcall GetBufOut
    if_nt
        rcall HeadChipDtPack
        ldi r,FusePac 16 *  #FUSEs 1- +  st y+,r
        clr zH ldi z,0  
                ldi r,{b RFLB SPMEN } mov SPMCSR,r  LPM   st y+,r0 
        ldi z,3 ldi r,{b RFLB SPMEN } mov SPMCSR,r  LPM   st y+,r0 
        ldi z,2 ldi r,{b RFLB SPMEN } mov SPMCSR,r  LPM   st y+,r0 
        goto AddCRC8 \ отправить пакет
    then
    ret c;
code RLock  ( rH=calibr -- ) \ чтение lock чипа
    ldi r,sizeLockPac  add r,rH rcall GetBufOut
    if_nt
        rcall HeadChipDtPack
        ldi r,LockPac 16 * #LOCKs 1- + st y+,r
        ldiW Z,1 
        ldi r,{b RFLB SPMEN } mov SPMCSR,r  LPM   st y+,r0 
        goto AddCRC8 \ отправить пакет
    then
    ret c;

code RVSign ( rH=calibr -- ) \ чтение VerSign прошивки
    ldi r,sizeVSPac  add r,rH rcall GetBufOut
    if_nt
        rcall HeadChipDtPack
        ldi r,VSPac 16 * 3 + st y+,r \ маркер данных
        ldiW Z,VerSign ldi r,4 
        for LPM st y+,r0 adiw z,1 next r
        goto AddCRC8 \ отправить пакет
    then
    ret c;

code ReadE2 ( y->addr,n rH=calibr -- ) \ прочитать ЕЕПРОМ с addr n байт
    ld zL,Y+ ld zH,y+  ld r,y+
    andi r,7 \ урезать аппетиты [0..7]
    mov ii,r
    add r,rH  addi r,SizeRdE2Pac \ r=размер пакета rh=calibr
    rcall GetBufOut
    if_nt
        \ шапка
        mov r,rH ori r,E2Pac 4 *  st y+,r \ семафор
        rcall AddSRC \ подпись
        st y+,zL  st y+,zH st y+,ii \ адрес и количество
        inc ii \ [1..8]
        for \ данные
            rcall e2LPM st y+,r0 adiw z,1
        next ii
        rcall AddCRC8 \ отправить пакет
    then
    ret c;


