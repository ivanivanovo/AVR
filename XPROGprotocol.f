
DECIMAL
0x50 CONSTANT     CMD_XPROG                      \ 
0x51 CONSTANT     CMD_XPROG_SETMODE              \ 
        \ Команды XPROMG
0x01 CONSTANT     XPRG_CMD_ENTER_PROGMODE        
0x02 CONSTANT     XPRG_CMD_LEAVE_PROGMODE        
0x03 CONSTANT     XPRG_CMD_ERASE                 
0x04 CONSTANT     XPRG_CMD_WRITE_MEM             
0x05 CONSTANT     XPRG_CMD_READ_MEM              
0x06 CONSTANT     XPRG_CMD_CRC                   
0x07 CONSTANT     XPRG_CMD_SET_PARAM             
        \  Типы памяти
   1 CONSTANT     XPRG_MEM_TYPE_APPL          
   2 CONSTANT     XPRG_MEM_TYPE_BOOT          
   3 CONSTANT     XPRG_MEM_TYPE_EEPROM        
   4 CONSTANT     XPRG_MEM_TYPE_FUSE          
   5 CONSTANT     XPRG_MEM_TYPE_LOCKBITS      
   6 CONSTANT     XPRG_MEM_TYPE_USERSIG       
   7 CONSTANT     XPRG_MEM_TYPE_PRODSIG       

   8 CONSTANT     XPRG_MEM_TYPE_DATAMEM            

        \ Типы очистки
   1 CONSTANT     XPRG_ERASE_CHIP             
   2 CONSTANT     XPRG_ERASE_APP              
   3 CONSTANT     XPRG_ERASE_BOOT             
   4 CONSTANT     XPRG_ERASE_EEPROM           
   5 CONSTANT     XPRG_ERASE_APP_PAGE         
   6 CONSTANT     XPRG_ERASE_BOOT_PAGE        
   7 CONSTANT     XPRG_ERASE_EEPROM_PAGE      
   8 CONSTANT     XPRG_ERASE_USERSIG          
        \ Флаги режима записи
\    0 CONSTANT     XPRG_MEM_WRITE_ERASE        
\    1 CONSTANT     XPRG_MEM_WRITE_WRITE        
        \ Типы CRC
   1 CONSTANT     XPRG_CRC_APP                
   2 CONSTANT     XPRG_CRC_BOOT               
   3 CONSTANT     XPRG_CRC_FLASH              
\         \ Коды ошибки
\    0 CONSTANT     XPRG_ERR_OK                 
\    1 CONSTANT     XPRG_ERR_FAILED             
\    2 CONSTANT     XPRG_ERR_COLLISION          
\    3 CONSTANT     XPRG_ERR_TIMEOUT            
\         \ Параметры XPROG разного размера
\         \ 4-байтные адреса
\ 0x01 CONSTANT     XPRG_PARAM_NVMBASE             
\         \ 2-байтный размер страницы
\ 0x02 CONSTANT     XPRG_PARAM_EEPPAGESIZE         
\ 0x03 CONSTANT     XPRG_PARAM_NVMCMD_REG          
\ 0x04 CONSTANT     XPRG_PARAM_NVMCSR_REG          
\ 0x05 CONSTANT     XPRG_PARAM_UNKNOWN_1           

0x00 CONSTANT     XPRG_PROTOCOL_PDI              
0x01 CONSTANT     XPRG_PROTOCOL_JTAG             
0x02 CONSTANT     XPRG_PROTOCOL_TPI              

\    2 CONSTANT     XPRG_PAGEMODE_WRITE        \ (1 << 1)
\    1 CONSTANT     XPRG_PAGEMODE_ERASE        \ (1 << 0)
