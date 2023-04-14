( *************************** )
( * LAPACZ  v1.0 (20230414) * )
( * For VolksForth, AtariXL * )
( * To load, run KERNEL and * )
( *  INCLUDE" H1:LAPACZ.F"  * )
( *  RUN                    * )
( * To reload, FORGET TASK  * )
( * and INCLUDE" again.     * )
( *************************** )

CLEARSTACK
DECIMAL

: TASK  ; ( FORGET helper )
: <BUG  ; ( pseudo-breakpoint )
: <TODO ;
: <UNTESTED ;
: <NOT-IMPLEMENTED ;

: CLS ( -- ) &125 EMIT ;

CLS
CR .( Please wait... )

&0   CONSTANT #DEBUG  ( 0=None 1=Some )
&999 CONSTANT #DELAY  ( LOOP DELAY )
&46  CONSTANT #BG     ( . FIELD )
&120 CONSTANT #MINE   ( TO COLLECT ) 
&79  CONSTANT #PL     ( PLAYER HEAD )
&20  CONSTANT #BD     ( PLAYER BODY )
&82  CONSTANT #LMARGN ( LEFT MARGIN )        
&632 CONSTANT #STICK0 ( TWO BYTES? )      
&752 CONSTANT #CRSIN  ( TWO BYTES? ) 
&20  CONSTANT #SIZE   ( PLAYFIELD  )
&10  CONSTANT #MAXAV  ( MAX AV #MINE )
&89  C@ &256 * &88 C@ + \\ 
     CONSTANT #SCR    ( SCREEN )
&23  CONSTANT #ROWS 
&40  CONSTANT #COLS
#ROWS #COLS * \\
     CONSTANT #SCRSIZE  

VARIABLE A$   ( AVAILABLE )   
VARIABLE P$   ( COLLECTED )   
VARIABLE T$   ( TIME )
VARIABLE X$   ( CURRENT X )        
VARIABLE Y$   ( CURRENT Y )   
VARIABLE LX$  ( LAST X )   
VARIABLE LY$  ( LAST Y )   
VARIABLE SX$ ( LAST STICK )   
VARIABLE SY$ ( LAST STICK )   

: 0! ( a -- ) 0 SWAP ! ;

: != 0= IF 1 ELSE 0 THEN ; ( flip 0-1 )

: RANDOM ( n -- 0..n-1 )
  $D20A C@ $100 *
  $D20A C@ +
  UM* NIP ;

: SOUND <NOT-IMPLEMENTED ;

: BUZZ ( -- ) &253 EMIT ;         

: PAPER ( -- )
  $0E &710 C! ( bg )
  0 &709 C!   ( fg )
  1 #CRSIN C! 
  0 #LMARGN C! ;

: DROPNOTQ ( -- ) KEY ASCII Q = IF BYE THEN ;

: ASSERT ( a  -- ) IF ." +" ELSE ." -" THEN ;
: ASSERT= ( a b -- )  = ASSERT ;
: SUM09.TEST ( ---)  0 &10 0 DO I + LOOP &45 ASSERT= ;  

: WHEN ( a b -- a a b ) OVER SWAP ;

: I>A ( i -- a ) 
  &127 WHEN > IF &128 - 1 ( i-128 inverse ) ELSE
  &64  WHEN < IF &32  + 0 ( i+32  noinv   ) ELSE
  &96  WHEN < IF &64  - 0 ( i-64  noinv   ) ELSE
  0 THEN THEN THEN        ( i     noinv )
  &128 * + ;
  
: I>A.TEST ( -- )
  &0    I>A &32  ASSERT= ( space  ) 
  &1    I>A &33  ASSERT= ( !      )
  &14   I>A &46  ASSERT= ( .      )
  &16   I>A &48  ASSERT= ( 0      )
  &33   I>A &65  ASSERT= ( A      )  
  &47   I>A &79  ASSERT= ( O      )
  &63   I>A &95  ASSERT= ( _      )
  &64   I>A &0   ASSERT= ( ctrl+, ) 
  &95   I>A &31  ASSERT= ( rghtar )
  &96   I>A &96  ASSERT= ( ctrl+. )
  &97   I>A &97  ASSERT= ( a      )
  &127  I>A &127 ASSERT= ( tab    )
  &128  I>A &128 ASSERT= ( neg sp ) 
  &155  I>A &155 ASSERT= ( eol    ) 
  &156  I>A &156 ASSERT= ( del ln )
  &157  I>A &157 ASSERT= ( ins ln )
  &158  I>A &158 ASSERT= ( ct+tab )
  &159  I>A &159 ASSERT= ( ^tab   )
  &161  I>A &193 ASSERT= ( neg A  ) <BUG
  &241  I>A &241 ASSERT= ( neg q  ) 
  &253  I>A &253 ASSERT= ( buzzer )
  &254  I>A &254 ASSERT= ( del ch )
  &255  I>A &255 ASSERT= ( ins ch ) ;
  
: PRTSCR ( -- ) <UNTESTED 
  #SCRSIZE #SCR + #SCR DO
    I C@ I>A EMIT
  LOOP ;

: ? ( x -- y ) @ . ;

: LOC ( col row -- c )  
  SWAP #SCR + SWAP #COLS * + C@ I>A ;

: EMIT-AT ( col row char -- ) 
  AT? >R >R
  ROT ROT AT EMIT
  R> R> AT ;

: EMIT-AT.TEST ( -- ) 
  &0  &0  &65  EMIT-AT &0  &0  LOC &65  ASSERT=
  &1  &1  &66  EMIT-AT &1  &1  LOC &66  ASSERT=
  &1  &38 &209 EMIT-AT &1  &38 LOC &209 ASSERT= <BUG ( neg Q )
  &20 &10 &67  EMIT-AT &10 &20 LOC &67  ASSERT= 
  &15 &19 &20  EMIT-AT &19 &15 LOC &20  ASSERT= ;

: GET-STICK ( m -- yd xd ) ( m=0 non-sticky, 1=keep last )
  #STICK0 C@

  DUP &14 = IF   -1     0   ELSE
    DUP &13 = IF    1     0   ELSE
    DUP &7  = IF    0     1   ELSE 
    DUP &11 = IF    0    -1   ELSE 
    DUP &15 = IF  SX$ @ SY$ @ ELSE
    0 0 
  THEN THEN THEN THEN THEN
  ROT DROP ROT
  ( x y m )

  ( stick if m=1, keep going if 0 )
  1 = IF 
    2DUP 
    SY$ ! SX$ ! 
  THEN ;
 
: GET-STICK.TEST1 ( -- )
  SX$ 0! SY$ 0!
  100 0 DO
    1 GET-STICK
    CR . .
  LOOP ;

: GET-STICK.TEST0 ( -- )
  SX$ 0! SY$ 0!
  100 0 DO
    0 GET-STICK
    CR . .
  LOOP ;

: KEEP-SIZE ( x -- x )
  0 MAX
  #SIZE 1 -
  MIN ;

: WRAP ( x -- x )
  <NOT-IMPLEMENTED ( wrap instead of stopping at edge )
  ;

:  2KEEP-SIZE ( x y -- x' y' )
  KEEP-SIZE SWAP KEEP-SIZE SWAP ;

: KEEP-SIZE.TEST ( -- )
  -1 KEEP-SIZE 0 ASSERT=
  -9 KEEP-SIZE 0 ASSERT=
  0  DUP KEEP-SIZE ASSERT=
  1  DUP KEEP-SIZE ASSERT=
  10 DUP KEEP-SIZE ASSERT=
  19 DUP KEEP-SIZE ASSERT=
  20 KEEP-SIZE 19 ASSERT= 
  21 KEEP-SIZE 19 ASSERT= ;

: TEST ( -- )
  CR CR ." *** Running tests... "
  CR ." SUM09 "     SUM09.TEST     SPACE .S
  CR ." EMIT-AT "   EMIT-AT.TEST   SPACE .S
  CR ." I>A "       I>A.TEST       SPACE .S
  CR ." KEEP-SIZE " KEEP-SIZE.TEST SPACE .S 
  CR ." GET-STICK.TEST0 (SKIPPED) " 
  CR ." GET-STICK.TEST1 (SKIPPED) " 
  CR CR ;

: SETUP ( -- )
  DECIMAL
  A$ 0! T$ 0! X$ 0! Y$ 0! LX$ 0! LY$ 0! P$ 0! SX$ 0! SY$ 0!
  PAPER
  CLS
  #SIZE 0 DO
    #SIZE 0 DO #BG EMIT LOOP
    CR
  LOOP
  BEGIN
    #SIZE 1+ RANDOM X$ !
    #SIZE 1+ RANDOM Y$ !
    Y$ @ X$ @ LOC #BG = IF 
      X$ @ Y$ @ #MINE EMIT-AT ( better )
      1 A$ +!
    THEN
  #MAXAV A$ @ = UNTIL
  #SIZE 1+ RANDOM X$ !
  #SIZE 1+ RANDOM Y$ !
;

: GAME-LOOP ( -- )
  BEGIN

    X$ @ Y$ @
    1 GET-STICK  ( y x yd xd )
    ROT + ROT ROT + 
    ( y+yd x+xd )
    2KEEP-SIZE ( y' x' -- y x )
    2DUP ( y x -- y x y x )
    X$ ! Y$ !  ( y x ) 

    LOC #MINE = IF 
      1 P$ +!
     -1 A$ +!
    THEN ( -- )
    
    X$ @ Y$ @ #PL EMIT-AT  ( player to new position )

    ( erase old position if different )
    LX$ @ X$ @ = 
    LY$ @ Y$ @ = 
    AND 0= IF
      LX$ @ LY$ @ #BG EMIT-AT ( use #BD for pseudo-tail ) <NOT-IMPLEMENTED
    THEN

    X$ @ LX$ ! 
    Y$ @ LY$ !

    1 T$ +! ( inc. time counter )

    &20 &0 AT ." Time:"   T$ ? SPACE 
    &21 &0 AT ." Points:" P$ ? SPACE

    #DEBUG &1 = IF
      &1 &21 AT ." To get:" A$ ?           SPACE
      &2 &21 AT ."  X,  Y:" X$ ? Y$ ?      SPACE
      &3 &21 AT ." LX, LY:" LX$ ? LY$ ?    SPACE
      &21 &0 AT ." Depth:"  DEPTH .        SPACE 
      &22 &0 AT ." Stack:" .S              SPACE
    ELSE
      #DELAY 0 DO LOOP ( delay loop, adapt to the real hardware ) <TODO
    THEN


  &10 P$ @ =
  UNTIL ;

: HIGH-SCORE ( -- ) 
  &3 &23 AT ." CONGRATULATIONS!"
  &7 &23 AT ." TIME: " T$ ? 
  &22 &0 AT ." Press any key to exit..."
  KEY DROP CLS ;

: RUN ( -- )
  SETUP
  GAME-LOOP
  HIGH-SCORE ;       

CR .( RUN to execute, TEST to test. ) CR CR

\\ REFERENCES

( https://www.atariarchives.org/mapping/appendix10.php )
( https://tajemnice.atari8.info > 2_91 > 2_91_5linii.html original code, Atari Basic )
\\ 1 POKE 82,0:GRAPHICS 0:POKE 752,2:FOR I=0 TO 19:? " ....................":NEXT I:A=0:LX=1:LY=1:P=0:T=0
\\ 2 X=INT(RND(0)*20)+1:Y=INT(RND(0)*20)+1:LOCATE X,Y,C:IF C=46 THEN POSITION X,Y:? "x":A=A+1:SOUND 0,A*10,10,10-A
\\ 3 ON A<10 GOTO 2:X=1:Y=1:IF P=10 THEN POSITION 25,5:? "GRATULACJE!":POSITION 25,7:? "CZAS:";T:POSITION 0,21:END 
\\ 4 S=STICK(0):X=X+(S=7)-(S=11):X=X+(X<1)-(X>20):Y=Y+(S=13)-(S=14):Y=Y+(Y<0)-(Y>19):LOCATE X,Y,C:IF C=120 THEN P=P+1:? CHR$(253)
\\ 5 POSITION X,Y:? "O":T=T+1:POSITION 30,5:? 10-P;" ":POSITION LX,LY:? ".":LX=X:LY=Y:ON P=10 GOTO 3:GOTO 4
( https://www.complang.tuwien.ac.at/forth/forth-dimensions/FD-V2.pdf )
( https://atariwiki.org/wiki/Wiki.jsp?page=STROQ )

( EOF )
