12000 rem sfx for dropping a coconut
12010 poke 54296, 15: rem main vol at max
12020 poke 54277, 15*1+3: rem attack and decay, ch1
12030 poke 54278, 10*16+4: rem sustain and release, ch1
12040 poke 54276, 16+4+1: rem triangle, ring, and enable ch1
12050 rem poke 54274, 71: poke 54275, 5: rem 33% dc for ch1
12060 poke 54290, 128+1: rem noise and enable ch3
12065 poke 54287, 14: poke 54286, 24: rem ch3 frequ
12070 rem poke 54287, 71: poke 54286, 5: rem dc for ch3
12080 rem poke 54291, 15*1+3: rem ch3 attack and decay
12090 rem poke 53292, 10*16+4: rem sus and rel, ch3
12560 poke 54273, 16: poke 54272, 195: rem ch1 frequ
12570 for I=1 to 3000: next I: rem delay
12580 poke 54276, 0: rem ch1 off