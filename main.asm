.include "header.inc"
.include "snes_init.asm"

;8bit
.define program_counter $0000
.define key_buffer $0001
.define move_state $0002
.define jump_flag $0003
.define jump_counter $0005
.define reverse_flag $0008
.define jump_enable $0009
.define upper_left_collision $000a
.define upper_right_collision $000b
.define middle_left_collision $000c
.define middle_right_collision $000d
.define lower_left_collision $000e
.define lower_right_collision $000f

;16bit
.define momone_global_x $0010
.define momone_local_x $0014
.define momone_global_y $0012
.define camera_x $0018
.define doubled_gravity $001a
.define gravity $001c
.define metadata_offset $0020
.define metadata_base $1000
.define level_address $0030
.define temp $0040


v_blank:
    sep #$30
    lda move_state
    cmp #$00 ;if move_state==stop
    beq +
        lda program_counter
        and #$18
        lsr
        inc a
        jmp ++
+
        lda #$45
++
    ldx jump_flag
    cpx #$01 ;if jump_flag!=true
    bne +
        lda #$41
+
    ldx reverse_flag
    cpx #$40 ;if reverse_flag!=true
    bne +
        dec a
+
    pha
    rep #$20
    lda camera_x
    sep #$20
    sta $210d
    rep #$20
    xba
    sep #$20
    sta $210d
    rep #$20
    lda camera_x
    lsr
    sep #$20
    sta $210f
    rep #$20
    xba
    sep #$20
    sta $210f
    pla

    sep #$30
    stz $2102
    stz $2103
    ldx momone_local_x
    stx $2104
    ldy momone_global_y
    sty $2104
    sta $2104
    lda reverse_flag
    clc
    adc #$30
    sta $2104

    rep #$20
    lda #$0100
    sta $2102
    lda momone_global_x
    bpl +
        sep #$20
        lda #$03
        jmp ++
+
        sep #$20
        lda #$02
++
    sta $2104

    stz key_buffer
    lda #$00

    rti

.macro enable_video
    sep #$20
    lda #$20
    sta $2101
    lda #$31
    sta $2105 ;set bg mode
    lda #$31
    sta $2107 ;set bg1 tilemap zone

    lda #$39
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
    ldx #palette_bg2
    ldy #$20
    jsr load_palette

    rep #$10
    sep #$20
    lda #$10
    ldx #palette_bg1
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
    lda #$410
    ldx #pattern_momone + $600
    jsr load_block

    rep #$30
    lda #$450
    ldx #pattern_momone + $780
    jsr load_block

    rep #$30
    lda #$2020
    ldx #pattern_bg2
    ldy #$40
    jsr load_pattern

    rep #$30
    lda #$2120
    ldx #pattern_bg2 + $40
    ldy #$40
    jsr load_pattern

    rep #$30
    lda #$2040
    ldx #pattern_bg2 + $80
    ldy #$40
    jsr load_pattern

    rep #$30
    lda #$2140
    ldx #pattern_bg2 + $c0
    ldy #$40
    jsr load_pattern

    rep #$30
    lda #$1020
    ldx #pattern_bg1
    ldy #$40
    jsr load_pattern

    rep #$30
    lda #$1120
    ldx #pattern_bg1 + $40
    ldy #$40
    jsr load_pattern
.endm

.macro load_chamber
    rep #$30
    lda #$80
    sta $2115
    ldx #$3000
    stx $2116
    ldx #$00
    lda #$08
    sta temp

-
        lda #$c000
--
            xba
            ldy #$00
            bit metadata_base,x
            beq +
                ldy #$0402
+
            sty $2118
            xba
            lsr
            lsr
            cmp #$00
        bne --

        inx
        inx
        txa
        and #$0f
        cmp temp
        bne +
            txa
            clc
            adc #$08
            tax
+

        cpx #$100
    bcc -

    lda temp
    cmp #$08
    bne +
        ldx #$3400
        stx $2116
        stz temp
        ldx #$08
        jmp -
+
.endm

.macro init_ram
    sep #$20
    stz program_counter
    stz key_buffer
    stz move_state
    stz reverse_flag
    stz upper_left_collision
    stz middle_left_collision
    stz lower_left_collision
    stz upper_right_collision
    stz middle_right_collision
    stz lower_right_collision
    rep #$20
    stz momone_local_x
    lda #$10
    sta doubled_gravity

    rep #$30
    lda #metadata_base
    ldx level_address
    ldy #$100
    jsr load_metadata
.endm

.macro init_momone_oam
    rep #$20
    lda #$00
    sta $2102
    sep #$20
    lda momone_local_x
    sta $2104
    lda momone_global_y
    sta $2104
    lda #$05
    sta $2104
    lda #$30
    sta $2104

    rep #$20
    lda #$100
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
    stz move_state
    lda key_buffer

    pha
    and #$01
    cmp #$01 ;if right_key!=pressed
    bne +
        inx
        inx
        lda #$01
        sta move_state
        stz reverse_flag
+
    pla
    and #$02
    cmp #$02 ;if left_key!=pressed
    bne +
        dex
        dex
        lda #$02
        sta move_state
        lda #$40
        sta reverse_flag
+

    stx momone_global_x

    rep #$30
    lda momone_global_x
    cmp #$03ec
    bcc +
    bmi ++
        lda level_address
        clc
        adc #$100
        sta level_address
        lda #$80
        sta momone_global_y
        lda #$20
        sta momone_global_x
        stz camera_x
        jmp level_start
++
        lda #level1
        sta level_address
        sec
        sbc #$100
        lda #$80
        sta momone_global_y
        lda #$3cc
        sta momone_global_x
        lda #$300
        sta camera_x
        jmp level_start
+

    momone_collision_x

    sep #$20
    lda key_buffer
    and #$80
    ora jump_flag
    cmp #$00
    bne +
        lda #$01
        sta jump_enable
+

    sep #$20
    rep #$10
    lda key_buffer
    and #$80
    cmp #$80 ;if jump_key!=pressed
    bne ++
        lda jump_flag
        cmp #$01 ;if jump_flag==true
        beq +
            lda jump_enable
            cmp #$01
            bne +++
            stz jump_enable
            ldy #$08
            sty doubled_gravity
            lda #$0c
            sta jump_counter
            jmp +++
+
        lda jump_counter
        cmp #$00 ;if jump_counter==0
        beq +++
        ldy #$07
        sty doubled_gravity
        dec jump_counter
        jmp +++
++
        stz jump_counter
+++

    rep #$30
    lda momone_global_y
    ldx doubled_gravity
    inx
    cpx #$1a ;if doubled_gravity<1a
    bcc +
        ldx #$1a
+
    stx doubled_gravity
    pha
    lda doubled_gravity
    lsr
    sta gravity
    pla
    clc
    adc gravity
    sec
    sbc #$08
    sta momone_global_y

    momone_collision_y

    ;sty momone_global_y

    ldx momone_global_x

    rep #$20
    cpx #$74 ;if momone_global_x<74
    bcc +
        cpx #$0375 ;if momone_global_x>=375
        bcs +
            txa
            sec
            sbc #$74
            sta camera_x
            sep #$10
            ldx #$74
            stx momone_local_x
            jmp ++
+
        sep #$10
        stx momone_local_x
++
.endm

.macro momone_collision_x

    sep #$20
    lda move_state
    cmp #$02 ;if move_state!=left
    bne ++

        rep #$30
        ldx #$06
        ldy #$01
        jsr check_collision
        sep #$20
        sta upper_left_collision

        rep #$30
        ldx #$06
        ldy #$10
        jsr check_collision
        sep #$20
        sta middle_left_collision

        rep #$30
        ldx #$06
        ldy #$20
        jsr check_collision
        sep #$20
        sta lower_left_collision

        sep #$20
        lda lower_left_collision
        and jump_flag
        ora middle_left_collision
        ora upper_left_collision
        cmp #$00 ;if left_collision==false
        beq +
            rep #$30
            lda momone_global_x
            and #$fff0
            clc
            adc #$0b
            sta momone_global_x
+
        jmp +++
++
    sep #$20
    lda move_state
    cmp #$00 ;if move_state==stop
    beq +++

        rep #$30
        ldx #$12
        ldy #$01
        jsr check_collision
        sep #$20
        sta upper_right_collision

        rep #$30
        ldx #$12
        ldy #$10
        jsr check_collision
        sep #$20
        sta middle_right_collision

        rep #$30
        ldx #$12
        ldy #$20
        jsr check_collision
        sep #$20
        sta lower_right_collision

        sep #$20
        lda lower_right_collision
        and jump_flag
        ora middle_right_collision
        ora upper_right_collision
        cmp #$00 ;if right_collision==false
        beq +++
            rep #$30
            lda momone_global_x
            and #$fff0
            clc
            adc #$0c
            sta momone_global_x
+++

.endm

.macro momone_collision_y

    rep #$30
    ldx #$12
    ldy #$01
    jsr check_collision
    sep #$20
    sta upper_right_collision

    rep #$30
    ldx #$06
    ldy #$01
    jsr check_collision
    sep #$20
    sta upper_left_collision

    rep #$30
    ldx #$06
    ldy #$20
    jsr check_collision
    sep #$20
    sta lower_left_collision

    rep #$30
    ldx #$12
    ldy #$20
    jsr check_collision
    sep #$20
    sta lower_right_collision

    sep #$20
    lda lower_left_collision
    ora lower_right_collision
    cmp #$00 ;if lower_collision==false
    beq +
        rep #$30
        lda momone_global_y
        and #$f0
        sta momone_global_y
        lda #$10
        sta doubled_gravity
        stz jump_flag
        jmp ++
+
        sep #$20
        lda #$01
        sta jump_flag
++

    sep #$20
    lda upper_left_collision
    ora upper_right_collision
    cmp #$00 ;if upper_collision==false
    beq +
        rep #$30
        lda momone_global_y
        and #$fff0
        clc
        adc #$10
        sta momone_global_y
        lda #$10
        sta doubled_gravity
        stz jump_counter
+
.endm

.bank 0 slot 0
.org 0
.section "main"

palette_momone:
    .incbin "resources/momone_palette.bin"
pattern_momone:
    .incbin "resources/momone_pattern.bin"
palette_bg2:
    .incbin "resources/jinja_palette.bin"
pattern_bg2:
    .incbin "resources/jinja_pattern.bin"
palette_bg1:
    .incbin "resources/stone_palette.bin"
pattern_bg1:
    .incbin "resources/stone_pattern.bin"
level1:
    .incbin "resources/metadata.bin"
    .incbin "resources/metadata_2.bin"

start:
    snes_init

    load_resource
    rep #$30
    lda #level1
    sta level_address

    lda #$80
    sta momone_global_y
    lda #$20
    sta momone_global_x
    stz camera_x

level_start:
    sep #$30
    lda #$8f
    sta $2100

    init_momone_oam

    init_ram

    load_chamber

    ;lda $4201
    ;ora #$80
    ;sta $4201

    enable_video

mainloop:
    sep #$20

    ;get key
    lda $4219
    and #$83
    sta key_buffer
    lda #$00

    momone_move

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

-
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
    bne -
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

check_collision:
    txa
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
    pha

    tya
    clc
    adc momone_global_y
    and #$f0
    sta metadata_offset
    pla
    clc
    adc metadata_offset
    sta metadata_offset

    tax

    pla
    and #$03
    tay
    lda #$c0
-
        cpy #$00 ;if right_shift_counter==0
        beq +
        lsr
        lsr
        dey
        jmp - ;loop
+
    and metadata_base,x
    cmp #$00 ;if collide==false
    beq +
        lda #$01
+
    rts
.ends