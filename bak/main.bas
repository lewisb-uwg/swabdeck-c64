0   rem chardata should begin at line 30000
5   rem spritedata should begin at line 40000
10   rem screen routine should begin at line 50000
15  rem constants/game state
20  BS=5: rem Bird Speed
25  CD=12288: rem chardata start address
30  SD=CD-(64*6): rem sprite data start address
35  P1=SD: P2=SD+64: rem pirate animation frame addresses
40  NF=16: rem max frames in the global animation loop; should be div-by-8
45  P=1: X=2: Y=3: E=4: S=5: rem "fields" of the CN() coconut array: P=ptr, X,Y=coords, E=enable mask, R=state
48 rem coconut states: 0: ready to plan, 1: ready to drop, 2: dropping, 3: on deck
50  rem game state variables
55  PX=60: PY=188: rem pirate x,y coords
60  B1=SD+128: B2=SD+192: rem bird animation frame addresses
65  BX=30: BY=50: rem bird x,y coords
70  FR=0: rem current frame in the global animation loop
75  dim CN(4,5): rem coconut objects: CN(i,1)->pixel ptr, CN(i,2)->X, CN(i,3)->Y
80  for I=1 to 4: CN(I,P)=2041+I: CN(I,X)=CN(I,Y)=0: next: rem init the coconuts
85  C1=B2+64: C2=C1+64: rem coconut animation frame addresses
90  C(1,E)=4: C(2,E)=8: C(3,E)=16: C(4,E)=32: rem enable masks for 53269
95  for I=1 to 4: CN(I,R)=0: next: rem mark all as ready to plan
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
170 gosub 9500:rem render coconuts
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
3600 for I=1 to 4
3610 poke CN(I,P), C1/64: rem init coconut to 1st frame
3620 poke 53269, peek(53269) and (not(CN(I,E))): rem clear enable bits
3630 next
3800 return
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
6025 if PX<48 then PX=48: rem MIN X
6030 if KB=13 then PX=PX+5: rem S is right
6035 if PX <= 255 then poke 53248, PX: POKE 53264, PEEK(53264) AND 14
6038 IF PX>296 THEN PX=296: REM MAX X
6039 if PX>255 THEN POKE 53248, PX-255: POKE 53264, PEEK(53264) OR 1
6040 return
7000 rem move bird
7010 BX = BX+BS 
7011 if BX>346 then BX=0: gosub 8000: rem reset BX and start a new coconut drop plan 
7012 if BX>255 then POKE 53250, BX-255: POKE 53264, PEEK(53264) OR 2: goto 7030
7021 POKE 53250, BX: POKE 53264, PEEK(53264) AND 13
7030 gosub 9000: rem check for coconut drop
7100 return
8000 rem plan for coconuts (decides which will drop, and at what X, this pass of the bird)
8010 for I=1 to 4
8020 if C(I,R)=0 then C(I,R)=1: C(I,X)=I*50: C(I,Y)=BY: rem defined drop zones...for now
8030 next I
8040 return
9000 rem check for coconut drop
9010 for I=1 to 4
9020 if C(I,X)<BX then goto 9100: rem dont drop if bird not to drop zone
9030 if C(I,R)<>1 then goto 9100: rem dont drop if coconut not ready
9040 C(I,R)=2: rem move to the dropping state
9050 poke 53269, peek(53269) or CN(I,E): rem enable the sprite
9100 next 
9110 return
9500 rem render coconuts
9510 for I=1 to 4
9520 if C(I,R)<>2 goto 9700
9530 C(I,Y)=C(I,Y)+10
9540 if C(I,Y)>=(PY+24) then C(I,Y)=PY+24: C(I,R)=3: rem it hit the deck
9700 next
9710 return