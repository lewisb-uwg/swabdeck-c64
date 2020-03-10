

; 10 SYS (2080)

; color constants
WHITE=$01
BLACK=$00
GREY2=$0C
VIOLET=$04
CYAN=$03
BLUE=$06
BROWN=$09

; addresses of VIC-related stuff
SCREEN_RAM=$0400
SCREEN_DATA=$9C00
CHAR_DATA_MULTIPLIER=($3800/$0800)<<1

; 256-byte blocks of screen data, used
; to unroll the screen setup and avoid
; nasty 2-byte addition
sd_block_1 = SCREEN_DATA
sd_block_2 = SCREEN_DATA + 256
sd_block_3 = SCREEN_DATA + 512
sd_block_4 = SCREEN_DATA + 768

; start of sprite pixel data, as a VIC offset
sprite_data=$2E80/64

; Sprite 0 (Pirate/player avatar) constants
pirate_data_ptr = $07F8
pirate_x_ptr = $D000
pirate_y_ptr = $D001
pirate_standing=sprite_data
pirate_running=sprite_data+1

; Sprite 1 (seagull) constants
seagull_data_ptr = $07F9
seagull_wings_up=sprite_data+2
seagull_wings_down=sprite_data+3
seagull_x_ptr = $D002
seagull_y_ptr = $D003

; Sprite 2 (the "coconut") constants
coconut_data_ptr = $07FA
coconut_x_ptr = $D004
coconut_y_ptr = $D005
coconut_horz=sprite_data+4
coconut_vert=sprite_data+5

; variables in the zero page
SRC=$00C0
SRC_HI=SRC+1
DEST=SRC_HI+1
DEST_HI=DEST+1
LOOP_TICK=DEST_HI+1

; animation/motion speed constants
; The idea here is the main loop operates on a wrap-around tick of 256.
; AND-ing a speed constant with the current tick means the action fires
; if the result is nonzero. Each speed effectively represents one bit of the
; counter and, e.g., bit-2 is twice as fast as bit-3, is twice as fast as bit-4,
; etc.
FASTEST_SPEED         = %00000001
HALF_SPEED            = %00000010
QUARTER_SPPED         = %00000100
1_8TH_SPEED           = %00001000
1_16TH_SPEED          = %00010000
1_32ND_SPEED          = %00100000
1_64TH_SPEED          = %01000000
SLOWEST_SPEED         = %10000000

; advances the seagull to the right (wrapping if necessary),
; and switches between animation frames
; /1 : current loop tick
; /2 : animation speed
; /3 : movement speed
defm update_seagull
        ; switch animation frame
        lda /1
        and #/2
        beq @movement ; skip animation if equal (AND result of zero)
        
        ; perform the animation

        ; pick the appropriate animation, based on contents
        ; of seagull_data_ptr
        lda seagull_data_ptr
        cmp #seagull_wings_up
        beq @choose_wings_down
@choose_wings_up
        lda #seagull_wings_up
        sta seagull_data_ptr
        jmp @movement

@choose_wings_down
        lda #seagull_wings_down
        sta seagull_data_ptr
        jmp @movement

@movement
        nop
        endm

; /1 : destination address
; /2 : immediate value (sans #)
defm store_2_byte_value
        ; store the low byte
        lda #</2
        sta /1

        ; store the hi byte
        ldy #1
        lda #>/2
        sta /1,Y
        endm

; /1 : src address
defm set_src
        ldy #0
        lda #>/1
        sta SRC_HI
        lda #</1
        sta SRC
        endm

; /1 : dest address
defm set_dest
        ldy #0
        lda #>/1
        sta DEST_HI
        lda #</1
        sta DEST
        endm

defm enable_sprites
        ; all sprites were designed as multicolor,
        ; even though 1 and 2 only use a single color
        lda #$07
        sta $D01C

        ; turn on sprites 0, 1, and 2
        lda #$07
        sta $D015
        endm

defm set_common_multicolor_sprite_colors        
        ; 01 shared color #0
        lda #CYAN
        sta $D025

        ; 11 shared color #1
        lda #BLUE
        sta $D026

        endm

; 10 SYS (2049)

; 10 SYS (2064)

*=$0801

        BYTE    $0E, $08, $0A, $00, $9E, $20, $28,  $32, $30, $36, $34, $29, $00, $00, $00



; program entrance
*=$0810

        ; setup phase
        jsr COPY_SCREEN_DATA_TO_SCREEN_RAM
        jsr ENABLE_MULTICOLOR_CHAR_MODE
        jsr SET_SHARED_SCREEN_COLORS
        jsr REDIRECT_TO_CUSTOM_CHARSET
        jsr APPLY_PER_CHAR_COLORS
        jsr INITIALIZE_PIRATE_SPRITE
        jsr INITIALIZE_SEAGULL_SPRITE
        jsr INITIALIZE_COCONUT_SPRITE
        set_common_multicolor_sprite_colors
        enable_sprites

        ; main game loop
        lda #$00
        sta LOOP_TICK ; init loop tick to zero
main_game_loop
        ; update the pirate's location and animation

        ; update the seagull's location and animation
        update_seagull LOOP_TICK,HALF_SPEED,HALF_SPEED

        ; update the coconut's location and animation

        ; increment the loop tick (note it rolls over automatically)
        lda LOOP_TICK
        adc #1
        sta LOOP_TICK

        ; for now, infinite game loop
        lda #0
        beq main_game_loop

        rts

INITIALIZE_COCONUT_SPRITE ; sprite 2
        ; set the coconut's 10 color
        lda #WHITE
        sta $D029

        ; tell VIC where the first coconut frame is
        lda #coconut_horz
        sta coconut_data_ptr
        
        ; inital coconut x (TODO: change once animations begin)
        lda #60
        sta coconut_x_ptr

        ; initial coconut y (TODO: change once animations begin)
        lda #100
        sta coconut_y_ptr
        rts

INITIALIZE_SEAGULL_SPRITE ; sprite 1
        ; set the gull's 10 color
        lda #WHITE
        sta $D028

        ; tell VIC where the first gull frame is
        lda #seagull_wings_down
        sta seagull_data_ptr

        ; initial gull x (TODO: change once animations begin)
        lda #60
        sta seagull_x_ptr

        ; initial gull y (note: should never change)
        lda #50
        sta seagull_y_ptr
        rts

INITIALIZE_PIRATE_SPRITE ; sprite 2
        ; set the pirate's 10 color
        lda #BROWN
        sta $D027

        ; tell VIC where the first pirate frame is
        lda #pirate_standing
        sta pirate_data_ptr

        ; initial pirate x
        lda #60
        sta pirate_x_ptr

        ; initial pirate y (note: should never change)
        lda #188
        sta pirate_y_ptr
        rts
      
REDIRECT_TO_CUSTOM_CHARSET
        lda #28
        sta $D018
        rts

APPLY_PER_CHAR_COLORS
        set_dest $D800
        set_src $9800
        jsr MOVE_256_BYTES

        set_dest $D900
        set_src $9900
        jsr MOVE_256_BYTES

        set_dest $DA00
        set_src $9A00
        jsr MOVE_256_BYTES

        set_dest $DB00
        set_src $9B00
        jsr MOVE_256_BYTES

        rts

; copies _screen_data to the the screen ram at $0400
; even though screen data is only 1000 bytes, it will copy 1024!!!
COPY_SCREEN_DATA_TO_SCREEN_RAM
        ; first 256-byte block is $0400-$04FF, from
        set_dest $0400
        set_src sd_block_1
        jsr MOVE_256_BYTES
        
        ; second 256-byte block is $0500-$05FF
        set_dest $0500
        set_src sd_block_2
        jsr MOVE_256_BYTES

        ; third 256-byte block is $0600-$06FF
        set_dest $0600
        set_src sd_block_3
        jsr MOVE_256_BYTES

        ; fourth 256-byte block is $0700-$07FF
        set_dest $0700
        set_src sd_block_4
        jsr MOVE_256_BYTES

        rts

; copies 256 tyes from SRC to DEST
; SRC: first (low) byte of address containing the source address
; DEST: first (low) byte of address containing the destination address
; corrupts registers A and Y
MOVE_256_BYTES
        ldy #0
@loop   lda (SRC),Y
        sta (DEST),Y
        iny ; note that this will rollover to zero at "y=256"
        bne @loop
        rts



; lda will be corrupted
ENABLE_MULTICOLOR_CHAR_MODE
        lda $D016
        ora #16
        sta $D016
        rts

; lda will be corrupted
SET_SHARED_SCREEN_COLORS
        ; set the 00 color
        lda #BLACK
        sta $D021

        ; set the 01 color
        lda #GREY2
        sta $D022

        ; set the 10 color
        lda #VIOLET
        sta $D023

        rts