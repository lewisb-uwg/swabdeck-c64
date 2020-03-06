; these are the start addresses of the four
; 250-char blocks in screen ram. Breaking it
; up this way makes the math to insert bytes directly
; MUCH easier
screen_ram_block_1=$0400
screen_ram_block_2=$04FB
screen_ram_block_3=$05F5
screen_ram_block_4=$07E8

screen_ram_block_size=250

DRAW_SCREEN
        ldy #0
        lda screen_ram
