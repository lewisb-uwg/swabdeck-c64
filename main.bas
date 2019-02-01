  0 rem chardata should begin at line 30000
  1 rem spritedata should begin at line 40000
 10 rem constants/game state
 15 BS=5: rem Bird Speed
 20 CD=12288: rem chardata start address
 30 SD=CD-(64*6): rem sprite data start address
 40 P1=SD: P2=SD+64: rem pirate animation frame addresses
 41 NF=16: rem max frames in the global animation loop; should be div-by-8
 43 rem game state variables
 45 PX=60: PY=150: rem pirate x,y coords
 50 B1=SD+128: B2=SD+192: rem bird animation frame addresses
 55 BX=30: BY=80: rem bird x,y coords
 60 FR=0: rem current frame in the global animation loop
100 rem game setup
105 poke 53281,0: rem black background
110 rem gosub 1000: rem configure multicolor mode
120 gosub 2000: rem load character data
130 gosub 50000: rem draw screen
135 gosub 3000: rem load sprite data
138 gosub 3500: rem configure sprites
140 rem main game loop
145 gosub 6000: rem handle keyboard input
150 gosub 4000: rem render current pirate frame
155 gosub 7000: rem move bird
160 gosub 5000: rem render current bird frame
170 rem render coconuts
180 rem check collisions
190 rem check for endgame
195 FR = FR+1: if FR=NF then FR=0: rem update current animation frame
200 goto 140
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
3050 return
3500 rem configure sprites
3501 poke 53285,3: rem sprite 01 color = cyan
3510 poke 53286,6: rem sprite 11 color = blue
3520 poke 2040,P1/64: rem initial pirate frame
3530 poke 2041,B1/64: rem initial bird frame
3540 poke 53269,3: rem perma-enable pirate and bird sprites
3550 poke 53248,PX: poke 53249,PY: rem initial pirate locs
3560 poke 53276,3: rem all sprites in multicolor mode
3570 poke 53287,9: rem pirate's 10 color = brown
3580 poke 53250,BX: poke 53251,BY: rem initial bird locs
3590 poke 53288,1: rem bird's color = white
3600 return
4000 rem render current pirate frame
4010 if FR=4 or FR=12 then poke 2040,P2/64
4020 if FR=0 or FR=8 then poke 2040,P1/64
4030 return
5000 rem render current bird frame
5010 for I=0 to NF step 2
5020 if FR=I then poke 2041,B1/64: goto 5050
5030 next I
5040 poke 2041,B2/64
5050 return
6000 rem handle keyboard input
6010 KB=peek(203)
6020 if KB=10 then PX=PX-5: rem A is left
6025 if PX<5 then PX=5: rem MIN X
6030 if KB=13 then PX=PX+5: rem S is right
6035 if PX <= 255 then poke 53248, PX: POKE 53264, PEEK(53264) AND 14
6038 IF PX>327 THEN PX=327: REM MAX X
6039 if PX>255 THEN POKE 53248, PX-255: POKE 53264, PEEK(53264) OR 1
6040 return
7000 rem move bird
7010 BX = BX+BS 
7011 if BX>346 then BX=0: rem MAX X 
7012 if BX>255 then POKE 53250, BX-255: POKE 53264, PEEK(53264) OR 2: goto 7030
7021 POKE 53250, BX: POKE 53264, PEEK(53264) AND 13
7030 return