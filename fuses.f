\ слова для работы с фузами и локами
VARIABLE FdepL  \ для замера глубины

: FUSE{ ( ) \ начало работы с фузами
    FUSE[ DEPTH FdepL ! \ подключить словарь и запомнить текущую глубину стека
    ;
: LOCK{ ( ) \ начало работы с локами
    LOCK[ DEPTH FdepL ! \ подключить словарь и запомнить текущую глубину стека
    ;
DEFER [1/0]
: }=x ( j*x -- ) \ поименованые биты установить/сбросить в [1/0]    
    BEGIN
        DEPTH FdepL @ - 0 >
    WHILE
        label-find DUP
        IF
            label-value @ [1/0] SWAP B>Seg 
        ELSE
            TRUE ABORT" Неизвестный бит."
        THEN    
    REPEAT    
    RESTORE-VOCS  RESTORE-SEGMENT ;

:NONAME 1 ; \ установить младший бит
: }=1 ( j*x -- ) \ поименованые биты установить в 1    
    LITERAL IS [1/0] }=x  ;    

:NONAME 0 ; \ обнулить младший бит
: }=0 ( j*x -- ) \ поименованые биты сбросить в 0    
    LITERAL IS [1/0] }=x  ;    

: Fuses? ( ) \ показать фузы которые будут записаны
    \ # name = bit    
    FUSE[ labels-map ]FUSE ;
: Locks? ( ) \ показать локи которые будут записаны
    \ # name = bit    
    LOCK[ labels-map ]LOCK ;


\ eof
         
