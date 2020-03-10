

; 10 SYS (2080)


BLACK=$00
GREY2=$0C
VIOLET=$04
CYAN=$03
BLUE=$06
BROWN=$09
SCREEN_RAM=$0400
SCREEN_DATA=$9C00
CHAR_DATA_MULTIPLIER=($3800/$0800)<<1

sd_block_1 = $9C00
sd_block_2 = $9C00 + 256
sd_block_3 = $9C00 + 512
sd_block_4 = $9C00 + 768

pirate_data_ptr = $07F8
pirate_x_ptr = $D000
pirate_y_ptr = $D001

sprite_data=$2E80
pirate_standing=sprite_data/64

; variables in the zero page
SRC=$00C0
SRC_HI=SRC+1
DEST=SRC_HI+1
DEST_HI=DEST+1

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
        ; sprite 0 is multicolor, sprites 1 and 2 are high-resolution
        lda #$01
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

        jsr COPY_SCREEN_DATA_TO_SCREEN_RAM
        jsr ENABLE_MULTICOLOR_CHAR_MODE
        jsr SET_SHARED_SCREEN_COLORS
        jsr REDIRECT_TO_CUSTOM_CHARSET
        jsr APPLY_PER_CHAR_COLORS
        jsr INITIALIZE_PIRATE_SPRITE
        set_common_multicolor_sprite_colors
        enable_sprites
        rts

INITIALIZE_PIRATE_SPRITE
        ; set the pirate's 10 color
        lda #BROWN
        sta $D027

        ; tell VIC where the first pirate frame is
        lda #pirate_standing
        sta pirate_data_ptr

        ; initial pirate x
        lda #60
        sta pirate_x_ptr

        ; initial pirate y
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