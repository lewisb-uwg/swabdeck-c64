

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
SPRITE_X_HI_TEMP = X_INCR_VAL + 1

; bit 0 is 'S' key, bit 1 is 'A' key. Set if just pressed, unset otherwise. 
INPUT_FLAGS = SPRITE_X_HI_TEMP + 1

; next variable should be two later...


; animation/motion speed constants
; The idea here is the main loop operates on a wrap-around tick of 256.
; the 1's patterns here determine the speed, e.g., FASTEST_SPEED happens
; every-other tick, HALF_SPEED every fourth tick, etc.
FASTEST_SPEED         = %00000000
HALF_SPEED            = %00000001
QUARTER_SPEED         = %00000011
1_8TH_SPEED           = %00000111
1_16TH_SPEED          = %00001111
1_32ND_SPEED          = %00011111
1_64TH_SPEED          = %00111111
1_128TH_SPEED         = %01111111
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
PROGRAM_START
        ; setup phase
        ;jsr COPY_SCREEN_DATA_TO_SCREEN_RAM
        ;jsr ENABLE_MULTICOLOR_CHAR_MODE
        ;jsr SET_SHARED_SCREEN_COLORS
        ;jsr REDIRECT_TO_CUSTOM_CHARSET
        ;jsr APPLY_PER_CHAR_COLORS
        jsr INITIALIZE_PIRATE_SPRITE
        jsr INITIALIZE_SEAGULL_SPRITE
        jsr INITIALIZE_COCONUT_SPRITE
        set_common_multicolor_sprite_colors
        enable_sprites

        ; init the loop tick
        lda #$00
        sta LOOP_TICK ; init loop tick to zero

init_raster_interrupt
        ; this from http://c64-wiki.com/wiki/Raster_interrupt

        ; switch off interrupts from CIA-1
        lda #%01111111
        sta $DC0D

        ;clear most significant bit in VIC's raster register
        and $D011
        sta $D011

        ; set the raster line number where interrupt should occur
        lda #0 ; beginning of screen refresh?
        sta $D012

        ; set the interrupt vector to point to the service routine
        lda #<main_game_loop
        sta $0314
        lda #>main_game_loop
        sta $0315

        ; enable raster interrupt signals from VIC
        lda #%00000001
        sta $D01A

        ; return to BASIC
        rts 
        

main_game_loop
        ; update the pirate's location and animation
        jsr UPDATE_PIRATE

        ; update the seagull's location and animation
        jsr UPDATE_SEAGULL

        ; update the coconut's location and animation

        ; increment the loop tick (note it rolls over automatically)
        clc
        lda LOOP_TICK
        adc #1
        sta LOOP_TICK

        ; for now, infinite game loop
        ;lda #0
        ;beq main_game_loop

        ;rts
        ; acknowledge the interrupt by clearing the VIC's interrupt flag
        asl $D019
        
        ; jump into the KERNAL's normal interrupt service routine
        jmp $EA31

; Will clip to x=0 automatically.
;
; inputs:
; X_TEMP: contains the X-value we're decrementing
; X_INCR_VAL: the amount to decrement x, between 0 and 127 (8-bit limit)
; SPRITE_MASK: bit set for the sprite getting incremented
; SPRITE_X_HI_TEMP: byte to hold the high bit ($D010-style) of the
;                   sprite's x-coordinat. Initialize with $D010
; outputs:
; X_TEMP: is the new low byte of the caller's x-position
; SPRITE_X_HI_TEMP: appropriate sprite hi bit is set/unset as needed. It
;                   guarantees to preserve other sprites' hi bits, so it can
;                   be copied directly back to $D010 if needed.
SUBTRACT_FROM_X_COORDINATE
        ; performe the subtraction on X_TEMP
        clc
        clv
        lda #0 ; clear N flag
        lda X_TEMP
        sbc X_INCR_VAL

        ; if no negative generated, we're done
        bpl @end

@negative_result
        ; if hi bit not set, clip to 0
        lda SPRITE_X_HI_TEMP
        and SPRITE_MASK
        beq @handle_hi_bit

        ; clip to zero
        lda #0 
        sta X_TEMP
        jmp @end

@handle_hi_bit
        ; set hi bit to zero
        lda SPRITE_MASK
        invert_acc
        and SPRITE_X_HI_TEMP
        sta SPRITE_X_HI_TEMP

        ; i think that's it? shouldn't X_TEMP be the same?

@end
        rts
        
        

; inputs:
; X_TEMP: contains the X-value we're incrementing
; X_INCR_VAL: the amount to increment x, between 0 and 127 (8-bit limit)
; SPRITE_MASK: bit set for the sprite getting incremented
; SPRITE_X_HI_TEMP: byte to hold the high bit ($D010-style) of the
;                   sprite's x-coordinat. Initialize with $D010
; outputs:
; X_TEMP: is the new low byte of the caller's x-position
; SPRITE_X_HI_TEMP: appropriate sprite hi bit is set/unset as needed. It
;                   guarantees to preserve other sprites' hi bits, so it can
;                   be copied directly back to $D010 if needed.                   
ADD_TO_X_COORDINATE
        ; perform the addition on X_TEMP
        clc
        lda X_TEMP
        adc X_INCR_VAL
        sta X_TEMP

        ; if no carry, we're done
        bcs @carry_result
        rts

@carry_result
        ; here we have to deal with the high bit
        ; see if hi bit is set or not
        lda SPRITE_X_HI_TEMP
        and SPRITE_MASK
        beq @hi_bit_zero

        ; hi bit is 1, unset it
        lda SPRITE_MASK
        invert_acc
        and SPRITE_X_HI_TEMP
        sta SPRITE_X_HI_TEMP
        rts
        
@hi_bit_zero
        ; simply set the hi bit and we're done
        lda SPRITE_X_HI_TEMP
        ora SPRITE_MASK
        sta SPRITE_X_HI_TEMP
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


UPDATE_PIRATE
        lda #0
        sta X_INCR_VAL
        jsr DETERMINE_MOVEMENT_DISTANCE
        lda X_INCR_VAL
        beq @end ; return if X_INCR_VAL hasn't changed
        
        jsr MOVE_PIRATE
        ;jsr ANIMATE_PIRATE
@end    rts

; Polls keyboard and sets X_INCR_VAL based on key pressed
; if 'S' pressed -- X_INCR_VAL gets a positive value
; if 'A' pressed -- X_INCR_VAL gets a negative value
; does NOT perform any min/max clipping
pirate_speed = 1
DETERMINE_MOVEMENT_DISTANCE
        jsr CHECK_FOR_DIRECTIONAL_KEYS
        lda INPUT_FLAGS
        and #%00000010
        beq @check_for_a
        
        ; S was pressed
        lda #pirate_speed
        sta X_INCR_VAL
        rts

@check_for_a
        lda INPUT_FLAGS
        and #%00000001
        beq @end

        ; A was pressed
        lda #0
        clc
        sbc #pirate_speed
        sta X_INCR_VAL
        rts

@end    lda #0
        sta X_INCR_VAL
        rts

; Checks for press of the 'S' key
; input: none
; output: INPUT_FLAGS = %00000010 if 'S' pressed, 
;               %00000001 if 'A' was pressed, $00 otherwise
;
; adapted from http://c64-wiki.com/wiki/Keyboard#Assembler
PRA  = $DC00 ; CIA#1, port register A
DDRA = $DC02 ; CIA#1, data direction register A
PRB  = $DC01 ; CIA#1, port register B
DDRB = $DC03 ; CIA#1, data direction register B
CHECK_FOR_DIRECTIONAL_KEYS
        ; start by checking for 'S'
        lda #0
        sta INPUT_FLAGS

        ;sei ; deactivate interrupts
        lda #%11111111 ; make port A the outputs
        sta DDRA
        
        lda #%00000000 ; make port B the inputs
        sta DDRB

        lda #%11111101 ; testing col1 of the kb matrix
        sta PRA

        lda PRB
        and #%00100000 ; masking row 5
        bne @check_for_A
        lda #%00000010 ; set the bit indicating 'S' was pressed
        sta INPUT_FLAGS

@check_for_A
        lda #%11111101 ; test col1 of the kb matrix
        sta PRA

        lda PRB
        and #%00000100 ; masking row 2
        bne @end
        lda #%00000001 ; set the bit indicating 'A' was pressed
        sta INPUT_FLAGS

@end    ;cli ; reactivate interrupts
        rts

MOVE_PIRATE
        lda LOOP_TICK
        and #FASTEST_SPEED
        cmp #FASTEST_SPEED
        bne @end
                
        ; perform the movement
        lda #%00000001 ; set the SPRITE_MASK
        sta SPRITE_MASK

        lda $D000 ; set X_TEMP
        sta X_TEMP

        ; X_INCR_VAL should already be set

        ; set SPRITE_X_HI_TEMP  
        lda $D010
        sta SPRITE_X_HI_TEMP
        
        lda X_INCR_VAL
        bmi @move_left ; change to @move_left once moving left stuff in place

@move_right
        jsr ADD_TO_X_COORDINATE
        jsr CLIP_TO_PIRATE_X_MAX

@move_left
        jsr SUBTRACT_FROM_X_COORDINATE
        jsr CLIP_TO_PIRATE_X_MIN

        lda X_TEMP
        sta $D000 ; sprite 0 x low byte

        lda SPRITE_X_HI_TEMP ; set the hi bit
        sta $D010

@end    rts

pirate_x_low_byte_max = 41
CLIP_TO_PIRATE_X_MAX
        lda SPRITE_X_HI_TEMP
        and #%00000001
        beq @end ; not at max if hi bit not set

        ; hi bit is set, see if low byte is < pirate_x_low_byte_max
        lda X_TEMP
        cmp #pirate_x_low_byte_max
        bmi @end ; negative result means pirate_x_low_byte_max > X_TEMP, so done

        ; clip X_TEMP to pirate_x_low_byte_max
        lda #pirate_x_low_byte_max
        sta X_TEMP

@end    rts

CLIP_TO_PIRATE_X_MIN
        rts

ANIMATE_PIRATE
        rts

UPDATE_SEAGULL
        jsr ANIMATE_SEAGULL
        jsr MOVE_SEAGULL
        rts

; switches between seagull animation frames
ANIMATE_SEAGULL
        ; switch animation frame
        lda LOOP_TICK
        and #FASTEST_SPEED ; and with the speed
        cmp #FASTEST_SPEED ; see if the result matches the speed
        bne @end ; skip animation on no match (it's not yet time to fire)
        
        ; perform the animation

        ; pick the appropriate animation, based on contents
        ; of seagull_data_ptr
        lda seagull_data_ptr
        cmp #seagull_wings_up
        beq @choose_wings_down
@choose_wings_up
        lda #seagull_wings_up
        sta seagull_data_ptr
        jmp @end

@choose_wings_down
        lda #seagull_wings_down
        sta seagull_data_ptr
@end    rts

; advances the seagull to the right, wrapping around to zero appropriately
MOVE_SEAGULL
        lda LOOP_TICK
        and #FASTEST_SPEED
        cmp #FASTEST_SPEED
        bne @end
                
        ; perform the movement
        lda #%00000010 ; set the sprite mask
        sta SPRITE_MASK

        lda seagull_x_ptr ; set the seagull x low byte
        sta X_TEMP

        lda #1 ; set the increment value
        sta X_INCR_VAL

        lda $D010 ; copy $D010 into SPRITE_X_HI_TEMP
        sta SPRITE_X_HI_TEMP

        jsr ADD_TO_X_COORDINATE

        lda X_TEMP ; copy X_TEMP back into seagull_x_ptr
        sta seagull_x_ptr

        lda SPRITE_X_HI_TEMP
        sta $D010

        ; not gonna check for x-axis wrapping; right now will wrap
        ; at x=512, giving a little bit of respite for player before
        ; the next pass. Also I'm lazy.
@end    rts