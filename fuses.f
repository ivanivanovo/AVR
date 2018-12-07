\ слова для работы с фузами и локами
VARIABLE FdepL  \ для замера глубины

: FUSE{ ( ) \ начало работы с фузами
    FUSE[ DEPTH FdepL ! \ подключить словарь и запомнить текущую глубину стека
    ;
: LOCK{ ( ) \ начало работы с локами
    LOCK[ DEPTH FdepL ! \ подключить словарь и запомнить текущую глубину стека
    ;
: }=x ( j*x 1|0-- ) \ поименованые биты установить/сбросить в 1|0    
    >R
    BEGIN
        DEPTH FdepL @ - 0 >
    WHILE
        label-find DUP
        IF
            label-value @ R@ SWAP B>Seg 
        ELSE
            TRUE ABORT" Неизвестный бит."
        THEN    
    REPEAT    
    R> DROP
    RESTORE-VOCS  RESTORE-SEGMENT ;

: }=1 ( j*x -- ) \ поименованые биты установить в 1    
    1 }=x  ;    

: }=0 ( j*x -- ) \ поименованые биты сбросить в 0    
    0 }=x  ;    

: Fuses? ( ) \ показать фузы которые будут записаны
    \ # name = bit    
    FUSE[ labels-map ]FUSE ;
: Locks? ( ) \ показать локи которые будут записаны
    \ # name = bit    
    LOCK[ labels-map ]LOCK ;


\ eof
         
