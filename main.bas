  0 rem chardata should begin at line 30000
  1 rem spritedata should begin at line 40000
 10 rem constants
 20 CD=12288: rem where we'll put the chardata
100 rem game setup
110 gosub 1000: rem configure multicolor mode
120 gosub 2000: rem load character data
130 gosub 50000: rem draw screen
140 rem main game loop
150 rem render pirate
160 rem render bird
170 rem render coconuts
180 rem check collisions
190 rem check for endgame
200 rem goto 140
210 end
1000 rem configure multicolor mode
1010 poke 53270, peek(53270) or 16: rem activate multicolor mode
1020 poke 53282, 12: rem 01 color is dark grayh
1030 poke 53282, 4: rem 10 color is purple
1040 return
2000 rem load character data
2010 for C=CD+(0*8) to CD+(16*8) step 8: rem start char to end char
2020 for I=0 to 7: read P: poke C+I,P: next I
2030 next C
2040 poke 53272, 28: rem redirect to the new charset
2050 return