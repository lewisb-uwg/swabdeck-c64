

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

; variables
SRC=$C0
SRC_HI=SRC+1
DEST=SRC_HI+1
DEST_HI=DEST+1
LOOP_TICK=DEST_HI+1

; params for ADD_TO_X_COORDINATE
X_TEMP=LOOP_TICK+1
SPRITE_MASK = X_TEMP + 1
X_INCR_VAL = SPRITE_MASK + 1

; next variable should be two later...


; animation/motion speed constants
; The idea here is the main loop operates on a wrap-around tick of 256.
; the 1's patterns here determine the speed, e.g., FASTEST_SPEED happens
; every-other tick, HALF_SPEED every fourth tick, etc.
FASTEST_SPEED         = %00000001
HALF_SPEED            = %00000011
QUARTER_SPEED         = %00000111
1_8TH_SPEED           = %00001111
1_16TH_SPEED          = %00011111
1_32ND_SPEED          = %00111111
1_64TH_SPEED          = %01111111
SLOWEST_SPEED         = %11111111


; performs a bitwise-NOT on the accumulator contents
defm invert_acc
        eor #$FF
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
        jsr UPDATE_SEAGULL

        ; update the coconut's location and animation

        ; increment the loop tick (note it rolls over automatically)
        lda LOOP_TICK
        adc #1
        sta LOOP_TICK

        ; for now, infinite game loop
        lda #0
        beq main_game_loop

        rts

; moves a sprite by incrementing its x-coordinate. DOES NOT WRAP!

; inputs:
; (X_TEMP): contains the X-value we're incrementing
; (X_INCR_VAL): the amount to increment x. 255 max (8-bit limit)
; (SPRITE_MASK): bit set for the sprite getting incremented
;
; outputs:
; (X_TEMP): is the new low byte of the caller's x-position
; $D010: appropriate sprite bit is set/unset as needed
ADD_TO_X_COORDINATE
        ldy #0
        lda X_TEMP
        adc X_INCR_VAL
        sta X_TEMP ; note: does not reset carry flag
        bcc @end ; if c=0, nothing more required

        ; c=1, we have to deal with the high bits
        lda SPRITE_MASK
        and $D010 ; contains the hi bits of sprite x-locations
        bne @clear_hi_bit

@set_hi_bit
        lda $D010
        ora SPRITE_MASK
        jmp @mod_hi_bit

@clear_hi_bit
        lda SPRITE_MASK
        invert_acc
        and $D010
@mod_hi_bit    
        sta $D010
@end    rts

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

; advances the seagull to the right (wrapping if necessary),
; and switches between animation frames
UPDATE_SEAGULL
        ; switch animation frame
        lda LOOP_TICK
        and #SLOWEST_SPEED ; and with the speed
        cmp #SLOWEST_SPEED ; see if the result matches the speed
        bne @movement ; skip animation on no match (it's not yet time to fire)
        
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
        lda LOOP_TICK
        and #SLOWEST_SPEED
        cmp #SLOWEST_SPEED
        bne @end
        
        ; perform the movement
        ldy #0
        lda #%00000010
        sta SPRITE_MASK
        lda seagull_x_ptr
        sta X_TEMP
        lda #1
        sta X_INCR_VAL
        jsr ADD_TO_X_COORDINATE
        lda X_TEMP
        sta seagull_x_ptr
 
@end    rts