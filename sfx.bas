12000 rem sfx for dropping a coconut
12010 poke 54296, 15: rem main vol at max
12020 poke 54277, 15*1+3: rem attack and decay, ch1
12030 poke 54278, 10*16+4: rem sustain and release, ch1
12040 poke 54276, 64+1: rem pulse and enable ch1
12050 poke 54274, 71: poke 54275, 5: rem 33% dc for ch1
12060 poke 54273, 16: poke 54272, 195: rem C-4
12070 for I=1 to 1000: next I: rem delay
12080 poke 54276, 0: rem ch1 off