

; 10 SYS (2080)

BLACK=$00
GREY2=$0C
VIOLET=$04
SCREEN_RAM=$0400
SCREEN_DATA=$9C00
CHAR_DATA_MULTIPLIER=($3800/$0800)<<1

sd_block_1 = $9C00
sd_block_2 = $9C00 + 256
sd_block_3 = $9C00 + 512
sd_block_4 = $9C00 + 768

; variables in the zero page
SRC=$00C0
SRC_HI=SRC+1
DEST=SRC_HI+1
DEST_HI=DEST+1

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
        rts
        
REDIRECT_TO_CUSTOM_CHARSET
        ;lda $D018
        ;and $F1
        ;ora #CHAR_DATA_MULTIPLIER
        ;ora $0E
        lda #28
        sta $D018
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