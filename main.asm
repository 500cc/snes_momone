.include "header.inc"
.include "snes_init.asm"

;8bit
.define program_counter $0000
.define key_buffer $0001
.define move_flag $0002

;16bit
.define momone_global_x $0010
.define momone_local_x $0014
.define momone_global_y $0012
.define camera_x $0018
.define ground_collision $0004
.define doubled_gravity $001a
.define gravity $001c
.define metadata_offset $0020
.define metadata_base $1000


v_blank:
    sep #$30
    lda move_flag
    cmp #$01
    bne stop
    lda program_counter
    and #$18
    lsr
    inc a
    jmp end_check_running
    stop:
    lda #$05
    end_check_running:

    pha
    rep #$20
    lda camera_x
    sep #$20
    sta $210d
    rep #$20
    xba
    sep #$20
    sta $210d
    pla

    sep #$30
    stz $2102
    stz $2103
    ldx momone_local_x
    stx $2104
    ldy momone_global_y
    sty $2104
    sta $2104
    lda #$30
    sta $2104

    stz key_buffer
    lda #$00

    rti

.macro enable_video
    sep #$20
    lda #$20
    sta $2101
    lda #$11
    sta $2105 ;set bg mode
    lda #$04
    sta $2107 ;set bg1 option

    lda #$08
    sta $2108

    lda #$21
    sta $210b ;set bg1 character data zone

    lda #$13
    sta $212c ;set main screen
    lda #$ff
    sta $210e ;set bg1 scroll
    sta $210e
    sta $2110
    sta $2110

    lda #$0f
    sta $2100 ;start display
    lda #$81
    sta $4200 ;enable nmi and controller
.endm

.macro load_resource
    rep #$10
    sep #$20
    lda #$80
    ldx #palette_momone
    ldy #$20
    jsr load_palette

    rep #$10
    sep #$20
    lda #$00
    ldx #palette_bg
    ldy #$04
    jsr load_palette

    rep #$10
    sep #$20
    lda #$10
    ldx #palette_bg2
    ldy #$0d
    jsr load_palette

    rep #$30
    lda #$10
    ldx #pattern_momone
    jsr load_block

    rep #$30 ;set a,x,y to 16bit
    lda #$50
    ldx #pattern_momone + $180
    jsr load_block

    rep #$30
    lda #$90
    ldx #pattern_momone + $300
    jsr load_block

    rep #$30
    lda #$d0
    ldx #pattern_momone + $480
    jsr load_block

    rep #$30
    lda #$2010
    ldx #pattern_bg
    ldy #$40
    jsr load_pattern

    rep #$30
    lda #$1020
    ldx #pattern_bg2
    ldy #$40
    jsr load_pattern

    rep #$30
    lda #$1120
    ldx #pattern_bg2
    ldy #$40
    jsr load_pattern
.endm

.macro init_ram
    sep #$20
    stz program_counter
    stz key_buffer
    stz move_flag
    rep #$20
    stz momone_global_x
    stz momone_local_x
    stz camera_x
    stz doubled_gravity
    lda #$80
    sta momone_global_y

    rep #$30
    lda #metadata_base
    ldy #$80
    ldx #level1_metadata
    jsr load_metadata
.endm

.macro init_momone_oam
    rep #$20
    lda #$00
    sta $2102
    sep #$20
    lda #$50
    sta $2104
    sta $2104
    lda #$05
    sta $2104
    lda #$30
    sta $2104

    rep #$20
    lda #$0100
    sta $2102
    sep #$20
    lda #$02
    sta $2104
.endm

.macro momone_move
    sep #$20
    rep #$10
    ldx momone_global_x
    ;ldy momone_global_y
    stz move_flag
    lda key_buffer

    pha
    and #$01
    cmp #$01
    bne not_move_right
    inx
    lda #$01
    sta move_flag
    not_move_right:
    pla
    and #$02
    cmp #$02
    bne not_move_left
    dex
    lda #$01
    sta move_flag
    not_move_left:

    stx momone_global_x
    ;sty momone_global_y

    rep #$20
    cpx #$74
    bcc move_sprite
    cpx #$0175
    bcs move_sprite
    txa
    sec
    sbc #$74
    sta camera_x
    sep #$10
    ldx #$74
    stx momone_local_x
    jmp end_move_sprite
    move_sprite:
    sep #$10
    stx momone_local_x
    end_move_sprite:
.endm

.macro momone_collision
    rep #$30
    lda momone_global_y
    ldx doubled_gravity
    inx
    cpx #$0a
    bcc not_clip
    ldx #$0a
    not_clip:
    stx doubled_gravity
    pha
    lda doubled_gravity
    lsr
    sta gravity
    pla
    clc
    adc gravity
    sta momone_global_y

    rep #$30
    lda #$08
    jsr check_ground_collision
    sta ground_collision
    rep #$30
    lda #$10
    jsr check_ground_collision
    ora ground_collision
    sta ground_collision

    rep #$30
    lda ground_collision
    cmp #$00
    beq end_adjust
    lda momone_global_y
    and #$f0
    stz doubled_gravity
    sta momone_global_y
    end_adjust:
.endm

.bank 0 slot 0
.org 0
.section "main"

palette_momone:
    .incbin "resources/palette_momone.bin"
pattern_momone:
    .incbin "resources/pattern_momone.bin"
palette_bg:
    .incbin "resources/palette_bg.bin"
pattern_bg:
    .incbin "resources/pattern_bg.bin"
palette_bg2:
    .incbin "resources/palette_ishigaki.bin"
pattern_bg2:
    .incbin "resources/pattern_ishigaki.bin"
level1:
    .incbin "resources/level.bin"
level1_metadata:
    .incbin "resources/metadata.bin"

start:
    snes_init

    load_resource

    ;set bg tilemap
    rep #$30
    lda #$400
    ldx #level1
    ldy #$400
    jsr load_pattern

    ;BG tilemap
    ldx #$0800
    stx $2116

    rep #$20
    lda #$01
    sta $2118
    inc a
    sta $2118

    ;set oam
    init_momone_oam

    init_ram

    ;lda $4201
    ;ora #$80
    ;sta $4201

    enable_video

mainloop:
    sep #$20

    ;get key
    lda $4219
    and #$03
    sta key_buffer
    lda #$00

    momone_move

    momone_collision

    ;increment program counter
    sep #$20
    inc program_counter

    ;if you use this, you have to disable wai
    ;sep #$20
    ;lda $213f
    ;lda $2137
    ;lda $213d
    ;sta $30

    wai
    jmp mainloop

load_palette:
    rep #$10
    sep #$20
    pha
    phx
    phy

    sty $4305 ;set size
    stx $4302 ;set src address
    sta $2121 ;set dst address
    lda #$80
    sta $4304 ;set bank of a
    stz $4300 ;set inclement mode
    lda #$22
    sta $4301 ;set dst register
    lda #$01
    sta $420b ;start DMA transfer

    ply
    plx
    pla
    rts

load_pattern:
    rep #$30
    pha
    phx
    phy

    sty $4305 ;set size
    stx $4302 ;set src address
    sep #$10
    ldy #$80
    sty $2115 ;set video port
    sta $2116 ;set dst address
    sep #$20
    lda #$80
    sta $4304 ;set bank of a
    lda #$01
    sta $4300 ;set inclement mode
    lda #$18
    sta $4301 ;set dst register
    lda #$01
    sta $420b ;start DMA transfer

    rep #$30
    ply
    plx
    pla
    rts

load_block:
    rep #$30
    pha
    phx
    ldy #$04
    phy

    load_block_loop:
    ldy #$60
    jsr load_pattern

    rep #$30
    ply
    dey
    clc
    adc #$100
    pha
    txa
    clc
    adc #$60
    tax
    pla
    phy
    cpy #$00
    bne load_block_loop
    ply
    plx
    pla
    rts

load_metadata:
    rep #$30
    pha
    phx
    phy

    sty $4305 ;set size
    stx $4302 ;set src address
    sta $2181
    sep #$20
    lda #$7e
    sta $2183
    lda #$80
    sta $4301
    sta $4304 ;set bank of a
    stz $4300 ;set inclement mode
    lda #$01
    sta $420b ;start DMA transfer

    rep #$30
    ply
    plx
    pla
    rts

check_ground_collision:
    rep #$30
    clc
    adc momone_global_x
    lsr
    lsr
    lsr
    lsr
    pha
    lsr
    lsr
    lsr

    pha
    lda momone_global_y
    clc
    adc #$20
    and #$f0
    lsr
    lsr
    sta metadata_offset
    pla
    clc
    adc metadata_offset

    tax

    pla
    and #$07
    tay
    lda #$80
    right_shift:
    cpy #$00
    beq end_right_shift
    lsr
    dey
    jmp right_shift
    end_right_shift:
    and metadata_base,x
    cmp #$00
    beq enbool
    lda #$01
    enbool:
    rts
.ends