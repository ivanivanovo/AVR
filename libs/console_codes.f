\ https://en.wikipedia.org/wiki/ANSI_escape_code#3/4_bit
\ https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit

\ \ Атрибуты =============
\ 0   нормальный режим
\ 1   жирный
\ 4   подчеркнутый
\ 5   мигающий
\ 7   инвертированные цвета
\ 8   невидимый
\  цвет  ===================
  0 CONSTANT Black     \ черный
  1 CONSTANT Red       \ красный
  2 CONSTANT Green     \ зеленый
  3 CONSTANT Yellow    \ желтый
  4 CONSTANT Blue      \ синий
  5 CONSTANT Magenta   \ пурпурный
  6 CONSTANT Cyan      \ голубой
  7 CONSTANT White     \ белый
30 CONSTANT FG \ шрифт +цвет
40 CONSTANT BG \ фон +цвет
\ \ цвет фона =============
\ 40  черный
\ 41  красный
\ 42  зеленый
\ 43  желтый
\ 44  синий
\ 45  пурпурный
\ 46  голубой
\ 47  белый

0x1B CONSTANT ESC
: ESC> ( adr u --) \ отправить ESCAPE-последовательность
    ESC EMIT TYPE
    ;
: defoltText  \ вернуть обычные настройки 
    S" [0m"  ESC>
    ;

\eof
Примеры использования:
S" [31;1;4m красный, жирный, подчеркнутый" ESC> defoltText \ красный, жирный, подчеркнутый
S" [31;4m красный, подчеркнутый" ESC> defoltText \ красный, подчеркнутый
S" [31;1m красный, жирный" ESC> defoltText \ красный, жирный

S" [33;1;4m" ESC> S" желтый, жирный, подчеркнутый" type defoltText \ желтый, жирный, подчеркнутый
S" [33;4m" ESC> S" желтый, подчеркнутый" type defoltText \ желтый, подчеркнутый
S" [33;1m" ESC> S" желтый, жирный" type defoltText \ желтый, жирный

