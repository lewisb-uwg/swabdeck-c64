100 rem game setup
110 gosub 1000: rem configure multicolor mode
120 rem load character data
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