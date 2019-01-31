  0 rem chardata should begin at line 30000
  1 rem spritedata should begin at line 40000
 10 rem constants
 20 CD=12288: rem chardata start address
 30 SD=CD-(64*6): rem sprite data start address
 40 P1=SD: P2=SD+64: rem pirate animation frame addresses
 45 PX=30: PY=200: rem pirate x,y coords
 50 B1=SD+128: B2=SD+192: rem bird animation frame addresses
 55 BX=30: BY=80: rem bird x,y coords
100 rem game setup
110 rem gosub 1000: rem configure multicolor mode
120 gosub 2000: rem load character data
130 gosub 50000: rem draw screen
135 gosub 3000: rem load sprite data
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
2040 rem poke 53272, 28: rem redirect to the new charset
2050 return
3000 rem load sprite data
3010 for I=SD to SD+(64*6)-1
3020 read P
3030 poke I, P
3040 next I
3045 poke 2040,P1/64: rem initial pirate frame
3048 poke 2041,B1/64: rem initial bird frame
3049 poke 53269,3: rem perma-enable pirate and bird sprites
3050 poke 53248,PX: poke 53249,PY: rem initial pirate locs
3060 poke 53250,BX: poke 53251,BY: rem initial bird locs
3100 return
