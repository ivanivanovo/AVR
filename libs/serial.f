\ работа с последовательными портами, средствами ОС
\ структура termios из bits/termios.h
BL WORD #def FIND NIP 0= [IF] S" AVR/toolbox.fs" INCLUDED [THEN]

#def NCCS 32
0
CELL        -- c_iflag  \ input mode flags 
CELL        -- c_oflag  \ output mode flags 
CELL        -- c_cflag  \ control mode flags
CELL        -- c_lflag  \ local mode flags 
1 CHARS     -- c_line   \ line discipline 
NCCS CHARS  -- c_cc     \ control characters 
CELL        -- c_ispeed \ input speed 
CELL        -- c_ospeed \ output speed 
CONSTANT termios \ общий размер структуры

\ c_cc characters 
#def VINTR      0   \ Interrupt	    CTRL-C
#def VQUIT      1   \ Quit	        CTRL-Z
#def VERASE     2   \ Erase	        Backspace (BS)
#def VKILL      3   \ Kill-line	    CTRL-U
#def VEOF       4   \ End-of-file	CTRL-D
#def VTIME      5   \ Time to wait for data (tenths of seconds)
#def VMIN       6   \ Minimum number of characters to read
#def VSWTC      7
#def VSTART     8   \ Start flow    CTRL-Q (XON)
#def VSTOP      9   \ Stop flow     CTRL-S (XOFF)
#def VSUSP      10
#def VEOL       11  \ End-of-line   Carriage return (CR)
#def VREPRINT   12
#def VDISCARD   13
#def VWERASE    14
#def VLNEXT     15
#def VEOL2      16  \ Second end-of-line    Line feed (LF)

\ c_iflag bits 
#def IGNBRK    OCT> 0000001 \ Ignore break condition
#def BRKINT    OCT>	0000002 \ Send a SIGINT when a break condition is detected
#def IGNPAR    OCT>	0000004 \ Ignore parity errors
#def PARMRK    OCT>	0000010 \ Mark parity errors
#def INPCK     OCT>	0000020 \ Enable parity check 
#def ISTRIP    OCT>	0000040 \ Strip parity bits
#def INLCR     OCT>	0000100 \ Map NL to CR
#def IGNCR     OCT>	0000200 \ Ignore CR
#def ICRNL     OCT>	0000400 \ Map CR to NL
#def IUCLC     OCT>	0001000 \ Map uppercase to lowercase
#def IXON      OCT>	0002000 \ Enable software flow control (outgoing)
#def IXANY     OCT>	0004000 \ Allow any character to start flow again
#def IXOFF     OCT>	0010000 \ Enable software flow control (incoming)
#def IMAXBEL   OCT>	0020000 \ Echo BEL on input line too long
#def IUTF8     OCT>	0040000

\ c_oflag bits 
#def OPOST	    OCT> 0000001 \ Postprocess output (not set = raw output)
#def OLCUC	    OCT> 0000002 \ Map lowercase to uppercase
#def ONLCR	    OCT> 0000004 \ Map NL to CR-NL
#def OCRNL	    OCT> 0000010 \ Map CR to NL
#def ONOCR	    OCT> 0000020 \ No CR output at column 0
#def ONLRET	    OCT> 0000040 \ NL performs CR function
#def OFILL	    OCT> 0000100 \ Use fill characters for delay
#def OFDEL	    OCT> 0000200 \ Fill character is DEL
#def NLDLY	    OCT> 0000400 \ Mask for delay time needed between lines
#def   NL0	    OCT> 0000000 \ No delay for NLs
#def   NL1	    OCT> 0000400 \ Delay further output after newline for 100 milliseconds
#def CRDLY	    OCT> 0003000 \ Mask for delay time needed to return carriage to left column
#def   CR0	    OCT> 0000000 \ No delay for CRs
#def   CR1	    OCT> 0001000 \ Delay after CRs depending on current column position
#def   CR2	    OCT> 0002000 \ Delay 100 milliseconds after sending CRs
#def   CR3	    OCT> 0003000 \ Delay 150 milliseconds after sending CRs
#def TABDLY	    OCT> 0014000 \ Mask for delay time needed after TABs
#def   TAB0	    OCT> 0000000 \ No delay for TABs
#def   TAB1	    OCT> 0004000 \ Delay after TABs depending on current column position
#def   TAB2	    OCT> 0010000 \ Delay 100 milliseconds after sending TABs
#def   TAB3	    OCT> 0014000 \ Expand TAB characters to spaces
#def BSDLY	    OCT> 0020000 \ Mask for delay time needed after BSs
#def   BS0	    OCT> 0000000 \ No delay for BSs
#def   BS1	    OCT> 0020000 \ Delay 50 milliseconds after sending BSs
#def FFDLY	    OCT> 0100000 \ Mask for delay time needed after FFs
#def   FF0	    OCT> 0000000 \ No delay for FFs
#def   FF1	    OCT> 0100000 \ Delay 2 seconds after sending FFs
#def VTDLY	    OCT> 0040000 \ Mask for delay time needed after VTs
#def   VT0	    OCT> 0000000 \ No delay for VTs
#def   VT1	    OCT> 0040000 \ Delay 2 seconds after sending VTs

\  c_cflag bit meaning 
#def  CBAUD     OCT> 0010017    \ Bit mask for baud rate
#def  B0        OCT> 0000000    \ hang up 
#def  B50       OCT> 0000001    \ 50 baud
#def  B75       OCT> 0000002    \ 75 baud
#def  B110      OCT> 0000003    \ 110 baud
#def  B134      OCT> 0000004    \ 134 baud
#def  B150      OCT> 0000005    \ 150 baud
#def  B200      OCT> 0000006    \ 200 baud
#def  B300      OCT> 0000007    \ 300 baud
#def  B600      OCT> 0000010    \ 600 baud
#def  B1200     OCT> 0000011    \ 1,200 baud
#def  B1800     OCT> 0000012    \ 1,800 baud
#def  B2400     OCT> 0000013    \ 2,400 baud
#def  B4800     OCT> 0000014    \ 4,800 baud
#def  B9600     OCT> 0000015    \ 9,600 baud
#def  B19200    OCT> 0000016    \ 19,200 baud
#def  B38400    OCT> 0000017    \ 38,400 baud
#def  EXTA  B19200
#def  EXTB  B38400
#def  CSIZE     OCT> 0000060 \ Bit mask for data bits
#def    CS5     OCT> 0000000 \ 5 data bits
#def    CS6     OCT> 0000020 \ 6 data bits
#def    CS7     OCT> 0000040 \ 7 data bits
#def    CS8     OCT> 0000060 \ 8 data bits
#def  CSTOPB    OCT> 0000100 \ 2 stop bits (1 otherwise)
#def  CREAD     OCT> 0000200 \ Enable receiver
#def  PARENB    OCT> 0000400 \ Enable parity bit
#def  PARODD    OCT> 0001000 \ Use odd parity instead of even
#def  HUPCL     OCT> 0002000 \ Hangup (drop DTR) on last close
#def  CLOCAL    OCT> 0004000 \ Local line - do not change "owner" of port
#def  CBAUDEX   OCT> 0010000
#def  B57600    OCT> 0010001    \ 57,600 baud
#def  B115200   OCT> 0010002    \ 115,200 baud
#def  B230400   OCT> 0010003    \ 230,400 baud
#def  B460800   OCT> 0010004    \ 460,800 baud
#def  B500000   OCT> 0010005    \ 500,000 baud
#def  B576000   OCT> 0010006    \ 576,000 baud
#def  B921600   OCT> 0010007    \ 921,600 baud
#def  B1000000  OCT> 0010010    \ 100,0000 baud
#def  B1152000  OCT> 0010011    \ 115,2000 baud
#def  B1500000  OCT> 0010012    \ 1'500,000 baud
#def  B2000000  OCT> 0010013    \ 2'000,000 baud
#def  B2500000  OCT> 0010014    \ 2'500,000 baud
#def  B3000000  OCT> 0010015    \ 3'000,000 baud
#def  B3500000  OCT> 0010016    \ 3'500,000 baud
#def  B4000000  OCT> 0010017    \ 4'000,000 baud
#def  CIBAUD    OCT> 002003600000   \ input baud rate (not used) 
#def  CMSPAR    OCT> 010000000000   \ mark or space (stick) parity 
#def  CRTSCTS   OCT> 020000000000   \ flow control 

\ c_lflag bits 
#def  ISIG      OCT> 0000001 \ Enable SIGINTR, SIGSUSP, SIGDSUSP, and SIGQUIT signals
#def  ICANON    OCT> 0000002 \ Enable canonical input (else raw)
#def  XCASE     OCT> 0000004 \ Map uppercase \lowercase (obsolete)
#def  ECHO      OCT> 0000010 \ Enable echoing of input characters
#def  ECHOE     OCT> 0000020 \ Echo erase character as BS-SP-BS
#def  ECHOK     OCT> 0000040 \ Echo NL after kill character
#def  ECHONL    OCT> 0000100 \ Echo NL
#def  NOFLSH    OCT> 0000200 \ Disable flushing of input buffers after interrupt or quit characters
#def  TOSTOP    OCT> 0000400 \ Send SIGTTOU for background output\ c_lflag bits 
#def  ECHOCTL   OCT> 0001000 \ Echo control characters as ^char and delete as ~?
#def  ECHOPRT   OCT> 0002000 \ Echo erased character as character erased
#def  ECHOKE    OCT> 0004000 \ BS-SP-BS entire line on line kill
#def  FLUSHO    OCT> 0010000 \ Output being flushed
#def  PENDIN    OCT> 0040000 \ Retype pending input at next read or input char
#def  IEXTEN    OCT> 0100000 \ Enable extended functions
#def  EXTPROC   OCT> 0200000


#def 	TCSANOW		0   \ Make changes now without waiting for data to complete
#def 	TCSADRAIN	1   \ Wait until everything has been transmitted
#def 	TCSAFLUSH	2   \ Flush input and output buffers and make the change\ tcsetattr uses these 


0 value fd  \ файловый дескриптор
VARIABLE _fd \ временный дескриптор
termios ALLOCATE THROW VALUE options \ взяли память из кучи под один экземпляр termios

: |  POSTPONE LITERAL  ['] OR COMPILE, ; IMMEDIATE
: ~& POSTPONE LITERAL ['] INVERT COMPILE, ['] AND COMPILE, ; IMMEDIATE

: iniCom ( adr u baud -- ) \ открыть порт, на нужной скорости, режим - raw
    -ROT R/W OPEN-FILE THROW TO fd
    fd _fd ! 
    fd 100 > if (( fd )) fileno to fd then
    (( fd options )) tcgetattr THROW
    DUP 1 <( options  SWAP )) cfsetispeed  THROW
        1 <( options  SWAP )) cfsetospeed  THROW
        \ установить флаги ввода
            0 IGNPAR | \ игнорировать парити
            options c_iflag !   \ записать флаги ввода
        \ установить флаги вывода
            0 options c_oflag !     \ сбросить все флаги вывода
        \ установить флаги управления
        options c_cflag @ 
            CLOCAL | CREAD |   \ Enable the receiver and set local mode
            PARENB ~& CSTOPB ~& CSIZE ~&  CS8 | \ 8N1
            CRTSCTS ~& \  disable hardware flow control
            options c_cflag !   \ записать флаги управления
        \ установить  флаги локального режима
            0 options c_lflag !     \ сбросить все локальные флаги
        \ установить  время ожидания и количество символов
        0 options c_cc VTIME  + C! \ время ожидания символов 0/10 сек
        0 options c_cc VMIN   + C! \ минимальное число символов 0
    (( fd TCSANOW options )) tcsetattr THROW
    _fd @ TO fd
    ;
\ S" /dev/ttyUSB0" 15 iniCom \ открыть на скорости 38400
\ S" /dev/ttyUSB2" B38400 iniCom \ открыть на скорости 38400

: checkFile ( adr u -- ) \
    R/W OPEN-FILE THROW
    ;  

: findX ( adr u -- ) \ проверить наличие файла устройства, напечатать имена живых
    DUP >R PAD SWAP CMOVE R>
    10 0 DO \ u
            PAD OVER + I 0x30 + SWAP C!
            PAD OVER 1+ ['] checkFile CATCH 
            0= if close-file THROW PAD OVER 1+ TYPE CR 
               ELSE 2DROP then
         LOOP DROP
    ;
\ S" /dev/ttyUSB" findX

: toCom ( adr u -- n)
    fd 0= abort" Проинициализируйте порт командой iniCom ( adr u baud -- )"
    fd WRITE-FILE THROW
    ; 
\ s" 123" tocom
2048 CONSTANT sizetReadBuf
sizetReadBuf ALLOcate THROW CONSTANT tReadBuf  

: readCom ( -- adr n ) \ принять строку
    fd 0= abort" Проинициализируйте порт командой iniCom ( adr u baud -- )"
    tReadBuf sizetReadBuf fd  READ-FILE THROW  tReadBuf SWAP
    ;
\ =================== сервис =========================================
: "?" ( u cadr -- u ) \ показать бит если он установлен
    DUP FIND  DROP execute 
    ROT DUP >R AND IF count  type SPACE ELSE DROP THEN R>
    ; 
: =?. ( u cadr -- u ) \ если равны напечатать имя
    DUP FIND DROP EXECUTE
    ROT DUP >R = IF  count  type SPACE ELSE DROP THEN R>
    ;
: =0x. ( adr cadr -- adr ) \ вывести имя-байт
    DUP 5 SPACES COUNT TYPE ." =0x"
    FIND DROP EXECUTE OVER + c@ . CR
    ;

: ShowTermios ( *termios -- ) \ показать структуру termios
    DUP c_iflag @ 
    ." c_iflag bits: " 
        C" IGNBRK"  "?" \ Ignore break condition
        C" BRKINT"  "?" \ Send a SIGINT when a break condition is detected
        C" IGNPAR"  "?" \ Ignore parity errors
        C" PARMRK"  "?" \ Mark parity errors
        C" INPCK"   "?" \ Enable parity check 
        C" ISTRIP"  "?" \ Strip parity bits
        C" INLCR"   "?" \ Map NL to CR
        C" IGNCR"   "?" \ Ignore CR
        C" ICRNL"   "?" \ Map CR to NL
        C" IUCLC"   "?" \ Map uppercase to lowercase
        C" IXON"    "?" \ Enable software flow control (outgoing)
        C" IXANY"   "?" \ Allow any character to start flow again
        C" IXOFF"   "?" \ Enable software flow control (incoming)
        C" IMAXBEL" "?" \ Echo BEL on input line too long
        C" IUTF8"   "?" \
        DROP cr
    DUP c_oflag @ 
    ." c_oflag bits: " 
        C" OPOST"   "?" \ Postprocess output (not set = raw output)
        C" OLCUC"   "?" \ Map lowercase to uppercase
        C" ONLCR"   "?" \ Map NL to CR-NL
        C" OCRNL"   "?" \ Map CR to NL
        C" ONOCR"   "?" \ No CR output at column 0
        C" ONLRET"  "?" \ NL performs CR function
        C" OFILL"   "?" \ Use fill characters for delay
        C" OFDEL"   "?" \ Fill character is DEL
        NLDLY LITERAL OVER AND \ Mask for delay time needed between lines
            C" NL0"     =?. \ No delay for NLs
            C" NL1"     =?. \ Delay further output after newline for 100 milliseconds
            DROP
        CRDLY LITERAL OVER AND \ Mask for delay time needed to return carriage to left column
            C" CR0"     =?. \ No delay for CRs
            C" CR1"     =?. \ Delay after CRs depending on current column position
            C" CR2"     =?. \ Delay 100 milliseconds after sending CRs
            C" CR3"     =?. \ Delay 150 milliseconds after sending CRs
            DROP
        TABDLY LITERAL OVER AND \ Mask for delay time needed after TABs
            C" TAB0"    =?. \ No delay for TABs
            C" TAB1"    =?. \ Delay after TABs depending on current column position
            C" TAB2"    =?. \ Delay 100 milliseconds after sending TABs
            C" TAB3"    =?. \ Expand TAB characters to spaces
            DROP
        BSDLY LITERAL OVER AND \ Mask for delay time needed after BSs
            C" BS0"     =?. \ No delay for BSs
            C" BS1"     =?. \ Delay 50 milliseconds after sending BSs
            DROP
        FFDLY LITERAL OVER AND \ Mask for delay time needed after FFs
            C" FF0"     =?. \ No delay for FFs
            C" FF1"     =?. \ Delay 2 seconds after sending FFs
            DROP
        VTDLY LITERAL OVER AND \ Mask for delay time needed after VTs
            C" VT0"     =?. \ No delay for VTs
            C" VT1"     =?. \ Delay 2 seconds after sending VTs
            DROP
        DROP cr
    DUP c_cflag @ 
    ." c_cflag bits: "
        CBAUD LITERAL OVER AND    \ Bit mask for baud rate
            C" B0"          =?. \ hang up 
            C" B50"         =?. \ 50 baud
            C" B75"         =?. \ 75 baud
            C" B110"        =?. \ 110 baud
            C" B134"        =?. \ 134 baud
            C" B150"        =?. \ 150 baud
            C" B200"        =?. \ 200 baud
            C" B300"        =?. \ 300 baud
            C" B600"        =?. \ 600 baud
            C" B1200"       =?. \ 1,200 baud
            C" B1800"       =?. \ 1,800 baud
            C" B2400"       =?. \ 2,400 baud
            C" B4800"       =?. \ 4,800 baud
            C" B9600"       =?. \ 9,600 baud
            C" B19200"      =?. \ 19,200 baud
            C" B38400"      =?. \ 38,400 baud
            C" B57600"      =?. \ 57,600 baud
            C" B115200"     =?. \ 115,200 baud
            C" B230400"     =?. \ 230,400 baud
            C" B460800"     =?. \ 460,800 baud
            C" B500000"     =?. \ 500,000 baud
            C" B576000"     =?. \ 576,000 baud
            C" B921600"     =?. \ 921,600 baud
            C" B1000000"    =?. \ 100,0000 baud
            C" B1152000"    =?. \ 115,2000 baud
            C" B1500000"    =?. \ 1'500,000 baud
            C" B2000000"    =?. \ 2'000,000 baud
            C" B2500000"    =?. \ 2'500,000 baud
            C" B3000000"    =?. \ 3'000,000 baud
            C" B3500000"    =?. \ 3'500,000 baud
            C" B4000000"    =?. \ 4'000,000 baud
            DROP
        CSIZE LITERAL OVER AND \ Bit mask for data bits
            C" CS5"         =?. \ 5 data bits
            C" CS6"         =?. \ 6 data bits
            C" CS7"         =?. \ 7 data bits
            C" CS8"         =?. \ 8 data bits
            DROP
        C" CSTOPB"  "?" \ 2 stop bits (1 otherwise)
        C" CREAD"   "?" \ Enable receiver
        C" PARENB"  "?" \ Enable parity bit
        C" PARODD"  "?" \ Use odd parity instead of even
        C" HUPCL"   "?" \ Hangup (drop DTR) on last close
        C" CLOCAL"  "?" \ Local line - do not change "owner" of port
        C" CMSPAR"  "?" \ mark or space (stick) parity 
        C" CRTSCTS" "?" \ flow control 
        DROP cr
    DUP c_lflag @ 
    ." c_lflag bits: "
        C" ISIG"    "?" \ Enable SIGINTR, SIGSUSP, SIGDSUSP, and SIGQUIT signals
        C" ICANON"  "?" \ Enable canonical input (else raw)
        C" XCASE"   "?" \ Map uppercase \lowercase (obsolete)
        C" ECHO"    "?" \ Enable echoing of input characters
        C" ECHOE"   "?" \ Echo erase character as BS-SP-BS
        C" ECHOK"   "?" \ Echo NL after kill character
        C" ECHONL"  "?" \ Echo NL
        C" NOFLSH"  "?" \ Disable flushing of input buffers after interrupt or quit characters
        C" TOSTOP"  "?" \ Send SIGTTOU for background output\ c_lflag bits 
        C" ECHOCTL" "?" \ Echo control characters as ^char and delete as ~?
        C" ECHOPRT" "?" \ Echo erased character as character erased
        C" ECHOKE"  "?" \ BS-SP-BS entire line on line kill
        C" FLUSHO"  "?" \ Output being flushed
        C" PENDIN"  "?" \ Retype pending input at next read or input char
        C" IEXTEN"  "?" \ Enable extended functions
        C" EXTPROC" "?" 
        DROP cr
    c_cc \ c_cc characters 
    ." c_cc characters: " cr 
        C" VINTR"      =0x. \ Interrupt	    CTRL-C
        C" VQUIT"      =0x. \ Quit	        CTRL-Z
        C" VERASE"     =0x. \ Erase	        Backspace (BS)
        C" VKILL"      =0x. \ Kill-line	    CTRL-U
        C" VEOF"       =0x. \ End-of-file	CTRL-D
        C" VTIME"      =0x. \ Time to wait for data (tenths of seconds)
        C" VMIN"       =0x. \ Minimum number of characters to read
        C" VSWTC"      =0x. 
        C" VSTART"     =0x. \ Start flow    CTRL-Q (XON)
        C" VSTOP"      =0x. \ Stop flow     CTRL-S (XOFF)
        C" VSUSP"      =0x. 
        C" VEOL"       =0x. \ End-of-line   Carriage return (CR)
        C" VREPRINT"   =0x. 
        C" VDISCARD"   =0x. 
        C" VWERASE"    =0x. 
        C" VLNEXT"     =0x. 
        C" VEOL2"      =0x.   \ Second end-of-line    Line feed (LF)
        DROP
    ;

