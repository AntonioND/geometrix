;###############################################################################
;
;    Geometrix - A simple puzzle game for Game Boy and Game Boy Color.
;
;    Copyright (c) 2015, 2018 Antonio Niño Díaz (AntonioND/SkyLyrac)
;
;    SPDX-License-Identifier: GPL-3.0-or-later
;
;###############################################################################

    INCLUDE "hardware.inc"
    INCLUDE "engine.inc"

    INCLUDE "room_game.inc"
    INCLUDE "text.inc"

;--------------------------------------------------------------------------

    SECTION "Room High Scores Variables",WRAM0

;--------------------------------------------------------------------------

SwapScoreWRAM:      DS  3*9 ; BCD, 5 digits, LSB first
TimeScoreWRAM:      DS  3*9

ScoreCursor_X:      DS  1
ScoreCursor_Y:      DS  1

    DEF HIGH_SCORES_SPACE_TILE    EQU 181
    DEF HIGH_SCORES_SELECT_TILE   EQU 189 ; ARROW

;--------------------------------------------------------------------------

    SECTION "SRAM High Score Data",SRAM,BANK[0]

;--------------------------------------------------------------------------

    DEF MAGIC_STRING_LENGTH EQU 16

SRAM_START:

MagicStringSRAM:    DS  MAGIC_STRING_LENGTH ; See MAGIC_STRING

SwapScoreSRAM:      DS  3*9 ; BCD, 5 digits, LSB first
TimeScoreSRAM:      DS  3*9

CheckSumSRAM:       DS  1 ; Sum of all previous bytes (not the magic string)

SRAM_END:

    DEF SRAM_DATA_SIZE  EQU SRAM_END-SRAM_START

;--------------------------------------------------------------------------

    SECTION "High Scores Game Code Data",ROMX

;--------------------------------------------------------------------------

MAGIC_STRING: ; MAGIC_STRING_LENGTH
    DB  "ANTONIO 02112015"

HighScoresBGMapData: ; tilemap first, attr map second
    INCBIN	"data/high_score_bg_map.bin"

    DEF HIGH_SCORES_BG_MAP_WIDTH   EQU 20
    DEF HIGH_SCORES_BG_MAP_HEIGHT  EQU 18

;--------------------------------------------------------------------------

HighScoresHandlerVBL:

;    call    rom_bank_push
    call    gbt_update
;    call    rom_bank_pop

    ret

;--------------------------------------------------------------------------

LoadMenuScreen:

    ; Black screen
    call    SetPalettesAllBlack

    ; Disable interrupts
    di

    ; Load BG
    call    LoadMenuTiles

    xor     a,a
    ldh     [rVBK],a
    ld      de,$9800
    ld      hl,HighScoresBGMapData
    ld      a,HIGH_SCORES_BG_MAP_HEIGHT
.loop_vbk0:
    push    af
    ld      bc,HIGH_SCORES_BG_MAP_WIDTH
    call    vram_copy
    push    hl
    ld      hl,32-HIGH_SCORES_BG_MAP_WIDTH
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    pop     af
    dec     a
    jr      nz,.loop_vbk0

    ld      a,[EnabledGBC]
    and     a,a
    jr      z,.skip_attr

    ld      a,1
    ldh     [rVBK],a
    ld      de,$9800
    ld      hl,HighScoresBGMapData+HIGH_SCORES_BG_MAP_WIDTH*HIGH_SCORES_BG_MAP_HEIGHT
    ld      a,HIGH_SCORES_BG_MAP_HEIGHT
.loop_vbk1:
    push    af
    ld      bc,HIGH_SCORES_BG_MAP_WIDTH
    call    vram_copy
    push    hl
    ld      hl,32-HIGH_SCORES_BG_MAP_WIDTH
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    pop     af
    dec     a
    jr      nz,.loop_vbk1

.skip_attr:

    xor     a,a
    ldh     [rSCX],a
    ldh     [rSCY],a

    ; Load text tiles
    call    LoadText

    ; Load scores and cursor
    call    ScoresRefresh
    call    ScoreCursorRefresh

    ; Load palettes
    ld      b,144
    call    wait_ly

    call    LoadMenuPalettes

    ; Enable interrupts
    ld      a,IEF_VBLANK
    ldh     [rIE],a

    ld      bc,HighScoresHandlerVBL
    call    irq_set_VBL

    ei

    ; Screen configuration
    ld      a,[LCDCF_GBC_MODE]
    or      a,LCDCF_BG9800|LCDCF_ON
    ldh     [rLCDC],a

    ; Done
    ret

;--------------------------------------------------------------------------

RecordsReset:

    ; Clear memory
    ld      a,CART_RAM_ENABLE
    ld      [$0000],a

    ld      d,0
    ld      hl,MagicStringSRAM
    ld      bc,$2000 ;SRAM_DATA_SIZE
    call    memset

    ld      hl,MAGIC_STRING ; src
    ld      de,MagicStringSRAM ; dst
    ld      bc,MAGIC_STRING_LENGTH
    call    memcopy

    ; Checksum of all 0 is 0, so don't care about it...

    ld      a,CART_RAM_DISABLE
    ld      [$0000],a

    ret

;--------------------------------------------------------------------------

RecordsSaveWithChecksum:

    ld      a,CART_RAM_ENABLE
    ld      [$0000],a

    ld      hl,SwapScoreWRAM ; src
    ld      de,SwapScoreSRAM ; dst
    ld      bc,3*9*2
    call    memcopy

    ld      a,CART_RAM_DISABLE
    ld      [$0000],a

    ; Sum scores
    ld      hl,SwapScoreWRAM
    ld      c,0
    ld      b,3*9*2 ; total bytes
.loop_add:
    ld      a,[hl+]
    add     a,c
    ld      c,a
    dec     b
    jr      nz,.loop_add

    ld      a,CART_RAM_ENABLE
    ld      [$0000],a

    ; Save checksum
    ld      a,c
    ld      [CheckSumSRAM],a

    ; Ok!
    ld      a,CART_RAM_DISABLE
    ld      [$0000],a

    ret

;--------------------------------------------------------------------------

RecordsCheckIntegrityAndRead:: ; Check and read to wram

    ld      a,CART_RAM_ENABLE
    ld      [$0000],a

    ; Check magic string
    ld      c,0 ; set to != 0 if there is any difference
    ld      b,MAGIC_STRING_LENGTH
    ld      de,MagicStringSRAM
    ld      hl,MAGIC_STRING
.loop_check:
    ld      a,[de]
    inc     de
    sub     a,[hl]
    inc     hl
    or      a,c
    ld      c,a
    dec     b
    jr      nz,.loop_check

    ld      a,c
    and     a,a
    jr      nz,.error ; magic string error

    ; Sum scores
    ld      hl,SwapScoreSRAM
    ld      c,0
    ld      b,3*9*2 ; total bytes
.loop_add:
    ld      a,[hl+]
    add     a,c
    ld      c,a
    dec     b
    jr      nz,.loop_add

    ; Get checksum
    ld      a,[CheckSumSRAM]
    cp      a,c
    jr      nz,.error

    ; Ok!
    ld      a,CART_RAM_DISABLE
    ld      [$0000],a

    jr      .end

.error:

    call    RecordsReset

.end:

    ; Read

    ld      a,CART_RAM_ENABLE
    ld      [$0000],a

    ld      hl,SwapScoreSRAM ; Source
    ld      de,SwapScoreWRAM ; Dest
    ld      bc,3*9*2
    call    memcopy

    ld      a,CART_RAM_DISABLE
    ld      [$0000],a

    ret

;--------------------------------------------------------------------------

ScorePrint: ; b = LSB, c = CSB, d = MSB, hl = VRAM destination

    ld      a,$0F
    and     a,d
    BCD2Tile
    ld      [hl+],a

    ld      a,$F0
    and     a,c
    swap    a
    BCD2Tile
    ld      [hl+],a
    ld      a,$0F
    and     a,c
    BCD2Tile
    ld      [hl+],a

    ld      a,$F0
    and     a,b
    swap    a
    BCD2Tile
    ld      [hl+],a
    ld      a,$0F
    and     a,b
    BCD2Tile
    ld      [hl],a

    ret

;--------------------------------------------------------------------------

ScoresRefresh: ; Interrupts should be disabled

    ; There's time enough to do one column per VBL

    ; Swap mode

    ld      b,144
    call    wait_ly

    ld      a,0
    ld      hl,$9800 + 32*9 + 4
.loop_swap:
    push    af
    push    hl

    ld      e,a
    ld      d,0
    ld      hl,SwapScoreWRAM
    add     hl,de
    add     hl,de
    add     hl,de ; SwapScoreWRAM + index * 3

    ld      a,[hl+]
    ld      b,a
    ld      a,[hl+]
    ld      c,a
    ld      a,[hl+]
    ld      d,a
    pop     hl

    push    hl
    call    ScorePrint
    pop     hl

    ld      de,32
    add     hl,de

    pop     af
    inc     a
    cp      a,9
    jr      nz,.loop_swap

    ; Time mode

    ld      b,144
    call    wait_ly

    ld      a,0
    ld      hl,$9800 + 32*9 + 11
.loop_time:
    push    af
    push    hl

    ld      e,a
    ld      d,0
    ld      hl,TimeScoreWRAM
    add     hl,de
    add     hl,de
    add     hl,de ; TimeScoreWRAM + index * 3

    ld      a,[hl+]
    ld      b,a
    ld      a,[hl+]
    ld      c,a
    ld      a,[hl+]
    ld      d,a
    pop     hl

    push    hl
    call    ScorePrint
    pop     hl

    ld      de,32
    add     hl,de

    pop     af
    inc     a
    cp      a,9
    jr      nz,.loop_time

    ret

;--------------------------------------------------------------------------

ScoreDEisHigherThanHL:

    push    hl
    push    de

    inc     hl
    inc     hl
    inc     de
    inc     de

    ld      b,0
.loop:
    ld      a,[de]
    cp      a,[hl]
    jr      z,.the_same
    jr      nc,.higher
    jr  .lower_or_equal ; Lower
.the_same:
    dec     de
    dec     hl

    dec     b
    jr      nz,.loop

.lower_or_equal:
    xor     a,a

    pop     de
    pop     hl

    ret

.higher:
    ld      a,1

    pop     de
    pop     hl

    ret

;--------------------------------------------------------------------------

ScoreAdd:

    ld      a,[GameMode]
    cp      a,GAME_MODE_SWAP_LIMIT
    jr      nz,.time
    ; Swap
    ld      a,3
    ld      [ScoreCursor_X],a
    ld      hl,SwapScoreWRAM
    jr      .begin_check
.time:
    ; Time
    ld      a,10
    ld      [ScoreCursor_X],a
    ld      hl,TimeScoreWRAM
    jr      .begin_check

.begin_check:

    ; Start comparing the score with each score in the list

    ld      a,0
.loop_find_position:
    push    af
    push    hl
    ld      de,ScoreCounter
    call    ScoreDEisHigherThanHL
    and     a,a
    jr      z,.continue

    ; This position is lower than the new score!

        ; Set the cursor
        pop     hl ; hl = pointer to write address
        pop     af
        ld      b,a ; b = current score index

        add     a,9 ; Base Y
        ld      [ScoreCursor_Y],a

        ; Displace all lower scores
        ; ------------------------

        ; b = current score index
        ; hl = pointer to write score

        push    hl

        ld      a,8
        sub     a,b ; 8 - index
        ld      b,a
        add     a,a
        add     a,b ; (8-index) * 3 bytes

        push    af

        ld      a,[GameMode]
        cp      a,GAME_MODE_SWAP_LIMIT
        jr      nz,.time_end_ptr
        ; Swap
        ld      hl,SwapScoreWRAM+(9*3)-1
        ld      de,SwapScoreWRAM+((9-1)*3)-1
        jr      .done_end_ptr
.time_end_ptr:
        ; Time
        ld      hl,TimeScoreWRAM+(9*3)-1
        ld      de,TimeScoreWRAM+((9-1)*3)-1
.done_end_ptr:

        ; hl = pointer to end of scores = dest
        ; de = pointer to end-1 of scores = source
        pop     bc ; b = bytes

.loop_copy:
        ld      a,b
        and     a,a
        jr      z,.end_copy
        ld      a,[de]
        dec     de
        ld      [hl-],a
        dec     b
        jr      .loop_copy

.end_copy:
        pop     hl

        ; Write new score
        ; ---------------

        ; hl = pointer to write score
        ld      de,ScoreCounter
        REPT    3
        ld      a,[de]
        inc     de
        ld      [hl+],a
        ENDR
        ; Exit
        jr      .end_write

.continue:
    pop     hl
    pop     af

    inc     hl
    inc     hl
    inc     hl
    inc     a
    cp      a,9
    jr      nz,.loop_find_position
    ; End loop

    jr      .end_no_write

.end_write:
    ; Save to SRAM
    call    RecordsSaveWithChecksum
    ret

.end_no_write:
    call    ScoreCursorHide
    ret

;--------------------------------------------------------------------------

ScoreCursorRefresh: ; Interrupts should be disabled

    ld      a,[ScoreCursor_Y]
    ld      l,a
    ld      h,0
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl ; ScoreCursor_Y * 32

    ld      de,$9800
    add     hl,de ; base + ScoreCursor_Y * 32

    ld      a,[ScoreCursor_X]
    ld      e,a
    ld      d,0
    add     hl,de ; base + ScoreCursor_Y * 32 + ScoreCursor_X

    ld      b,144
    call    wait_ly

    ld      a,HIGH_SCORES_SELECT_TILE
    ld      [hl],a
    ld      de,6
    add     hl,de
    ld      [hl],a

    ret

;--------------------------------------------------------------------------

ScoreCursorHide: ; set on the bottom right of the screen (outside)

    ld      a,20
    ld      [ScoreCursor_X],a
    ld      a,18
    ld      [ScoreCursor_Y],a
    ret

;--------------------------------------------------------------------------

HighScoresHandle:

    ; Check if reset data
    ld      a,[joy_held]
    and     a,PAD_SELECT|PAD_START
    cp      a,PAD_SELECT|PAD_START
    jr      nz,.dont_reset_data
    call    ScoreCursorHide ; Hide recent-score cursor
    call    RecordsReset
    call    RecordsCheckIntegrityAndRead
    call    LoadMenuScreen ; reload screen
.dont_reset_data:

    ret

;--------------------------------------------------------------------------

HighScoresScreenMainLoop:: ; if a=1, check to add a new score

    push    af
    call    ScoreCursorHide
    pop     af
    and     a,a
    call    nz,ScoreAdd ; add the last score and change cursor position

    call    LoadMenuScreen

    ld      de,SongCreditsHighScores_data
    ld      a,6
    ld      bc,BANK(SongCreditsHighScores_data)
    call    gbt_play

    ; Game loop
.loop:
    call    wait_vbl
    call    scan_keys
    call    KeyAutorepeatHandle

    call    HighScoresHandle

    ld      a,[joy_pressed]
    and     a,PAD_A|PAD_B
    jr      z,.loop ; if A or B are pressed, exit

    ; End loop
    call    gbt_stop

    ; Disable interrupts
    di

    ret
