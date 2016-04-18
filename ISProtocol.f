
DECIMAL
\ \                                          0     1        2            3

#def #Programming_Enable                     0xAC 0x53     0x00         0x00
#def #Chip_Erase ( Program Memory/EEPROM)    0xAC 0x80     0x00         0x00
#def #RDY/BSY                                0xF0 0x00     0x00         0x00 \ =byte out
\ Load Extended Address byte                0x4D 0x00     Ext-adr      0x00

    #def (<->) ( b a c -- c aH aL b) -ROT byte-split SWAP  ROT \ чехарда на стеке

\ Load Program Memory Page, High byte       0x48 adrMSB   adrLSB       byte
#def #Load_Program_Memory_Page,High_byte ( byte adr -- ) 0x48  (<->)         \ byte 
\ Load Program Memory Page, Low byte        0x40 adrMSB   adrLSB       byte
0x40 CONSTANT cmd0_Load_Program_Memory_Page
#def #Load_Program_Memory_Page,Low_byte ( byte adr -- )  0x40  (<->)         \ byte 
\ Write Program Memory Page                 0x4C adrMSB   adrLSB       0x00
0x4C CONSTANT cmd0_Write_Program_Memory_Page
#def #Write_Program_Memory_Page ( adrB -- )  0x4C SWAP byte-split SWAP  0x00
\ Read Program Memory, High byte          0x28 adrMSB   adrLSB       byte out
\ Read Program Memory, Low byte           0x20 adrMSB   adrLSB       byte out
0x20 CONSTANT cmd0_Read_Program_Memory


\ Write EEPROM Memory                     0xC0 0x00     00aaaaaa     byte in
0xC0 CONSTANT cmd0_Write_EEPROM_Memory
#def #Write_EEPROM_Memory ( byte adr -- )    0xC0         (<->)              \ byte
\ Load EEPROM Memory Page (page access)   0xC1 0x00     0000000aa    byte 
0xC1 CONSTANT cmd0_Load_EEPROM_Memory_Page
\ Write EEPROM Memory Page (page access)    0xC2 0x00     00aaaa00     0x00
0xC2 CONSTANT cmd0_Write_EEPROM_Memory_Page 
#def #Write_EEPROM_Memory_Page ( adr -- )    0xC2 0x00     ROT ( adr)   0x00
\ Read EEPROM Memory                      0xA0 0x00     00aaaaaa     byte out
0xA0 CONSTANT cmd0_Read_EEPROM_Memory

#def #Write_Lock_bits ( b --)                0xAC 0xE0     ROT    0     SWAP \ =byte in
#def #Write_Fuse_bits  ( b --)               0xAC 0xA0     ROT    0     SWAP \ =byte in
#def #Write_Fuse_High_bits ( b --)           0xAC 0xA8     ROT    0     SWAP \ =byte in
#def #Write_Extended_Fuse_bits ( b --)       0xAC 0xA4     ROT    0     SWAP \ =byte in

#def #Read_Lock_bits                         0x58 0x00     0x00         0x00 \ =byte out
#def #Read_Signature_Byte ( a -- b)          0x30 0x00     ROT ( a)     0x00 \ =byte out
#def #Read_Fuse_bits                         0x50 0x00     0x00         0x00 \ =byte out
#def #Read_Fuse_High_bits                    0x58 0x08     0x00         0x00 \ =byte out
#def #Read_Extended_Fuse_bits                0x50 0x08     0x00         0x00 \ =byte out

#def #Read_Calibration_Byte  ( a -- b)       0x38 0x00     ROT ( a)     0x00 \ =byte out

\ Версия вторая 
\ *** [ Константы основных команд ] ***
#def     CMD_SIGN_ON                    0x01 \ 
#def     CMD_SET_PARAMETER              0x02 \ 
#def     CMD_GET_PARAMETER              0x03 \ 
#def     CMD_OSCCAL                     0x05 \ 
#def     CMD_LOAD_ADDRESS               0x06 \ 
#def     CMD_FIRMWARE_UPGRADE           0x07 \ 
#def     CMD_RESET_PROTECTION           0x0A \ 
\ *** [ Константы команд ISP ] ***
#def     CMD_ENTER_PROGMODE_ISP         0x10 \ 
#def     CMD_LEAVE_PROGMODE_ISP         0x11 \ 
#def     CMD_CHIP_ERASE_ISP             0x12 \ 
#def     CMD_PROGRAM_FLASH_ISP          0x13 \ 
#def     CMD_READ_FLASH_ISP             0x14 \ 
#def     CMD_PROGRAM_EEPROM_ISP         0x15 \ 
#def     CMD_READ_EEPROM_ISP            0x16 \ 
#def     CMD_PROGRAM_FUSE_ISP           0x17 \ 
#def     CMD_READ_FUSE_ISP              0x18 \ 
#def     CMD_PROGRAM_LOCK_ISP           0x19 \ 
#def     CMD_READ_LOCK_ISP              0x1A \ 
#def     CMD_READ_SIGNATURE_ISP         0x1B \ 
#def     CMD_READ_OSCCAL_ISP            0x1C \ 
#def     CMD_SPI_MULTI                  0x1D \ 

\  *** [ Константы состояния ] ***
#def     STATUS_CMD_OK                  0x00 \ успешное завершение (Success), команда выполнилась успешно.
\     Предупреждения (Warnings)
#def     STATUS_CMD_TOUT                0x80 \ Истек таймаут команды.
#def     STATUS_RDY_BSY_TOUT            0x81 \ Истек таймаут опроса вывода готовности/занятости (RDY/nBSY pin).
#def     STATUS_SET_PARAM_MISSING       0x82 \ Команда установки параметра устройства потерпела ошибку в процессе выполнения.
\     Ошибки (Errors)
#def     STATUS_CMD_FAILED              0xC0 \ Команда завершилась с ошибкой.
#def     STATUS_CMD_UNKNOWN             0xC9 \ Неизвестная команда.
\     Статус
#def     STATUS_ISP_READY               0x00 \ 
#def     STATUS_CONN_FAIL_MOSI          0x01 \ 
#def     STATUS_CONN_FAIL_RST           0x02 \ 
#def     STATUS_CONN_FAIL_SCK           0x04 \ 
#def     STATUS_TGT_NOT_DETECTED        0x10 \ 
#def     STATUS_TGT_REVERSE_INSERTED    0x20 \ 
\ *** [ Константы параметров ] ***
#def     PARAM_BUILD_NUMBER_LOW         0x80 \ Номер сборки firmware, младший байт. R
#def     PARAM_BUILD_NUMBER_HIGH        0x81 \ Номер сборки firmware, старший байт. R
#def     PARAM_HW_VER                   0x90 \ Версия аппаратуры.   R
#def     PARAM_SW_MAJOR                 0x91 \ Номер версии firmware главного управляющего MCU, байт мажор. R
#def     PARAM_SW_MINOR                 0x92 \ Номер версии firmware главного управляющего MCU, байт минор. R
#def     PARAM_VTARGET                  0x94 \ Напряжение питания цели (target, программируемый микроконтроллер).   RW
#def     PARAM_SCK_DURATION             0x98 \ Длительность периода ISP SCK.    R
#def     PARAM_RESET_POLARITY           0x9E \ Полярность сигнала сброс - на каком логическом уровне он активен, лог. 0 или лог. 1. W
#def     PARAM_STATUS_TGT_CONN          0xA1 \ Состояние подключения к target.  R
#def     PARAM_DISCHARGEDELAY           0xA4 \ Задержка с состоянием сигнала сброса в высоком сопротивлении.    W
