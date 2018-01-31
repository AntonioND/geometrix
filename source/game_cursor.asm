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

;--------------------------------------------------------------------------

    SECTION "Cursor Variables",WRAM0

CursorFrame:        DS  1
CursorAnimCount:    DS  1 ; Starts at 10, at 0 it updates
CursorNeedsRefresh: DS  1

CursorHorizontal::  DS  1 ; 0 = vertical, 1 = horizontal
CursorTileX::       DS  1
CursorTileY::       DS  1
CursorX:            DS  1
CursorY:            DS  1

CURSOR_ANIMATION_TICKS  EQU 10

;--------------------------------------------------------------------------

    SECTION "Cursor_Tiles",ROM0

;--------------------------------------------------------------------------

CursorTilesData:
    INCBIN	"data/cursor_tiles.bin"

CursorTilesNumber EQU 3

;--------------------------------------------------------------------------

CursorLoad::

    ; Load

    ld      bc,CursorTilesNumber
    ld      de,0
    ld      hl,CursorTilesData
    call    vram_copy_tiles

    ld      a,(BOARD_COLUMNS-1) / 2
    ld      [CursorTileX],a
    ld      a,BOARD_ROWS - 3 ; 2 rows from bottom
    ld      [CursorTileY],a
    ld      a,1
    ld      [CursorHorizontal],a

    ld      a,10
    ld      [CursorAnimCount],a
    ld      a,0
    ld      [CursorFrame],a

    ld      a,1
    ld      [CursorNeedsRefresh],a

    ret

;--------------------------------------------------------------------------

CursorHide::

    ld      l,0
    call    sprite_get_base_pointer ; hl = dst

    ld      bc,4*8 ; 8 sprites used for cursor
    ld      d,0
    call    memset

    ret

CursorShow::
    ld      a,1
    ld      [CursorNeedsRefresh],a
    call    CursorRefresh
    ret

;--------------------------------------------------------------------------

CursorRefresh::

    ld      a,[CursorNeedsRefresh]
    and     a,a
    ret     z ; need to update?

    xor     a,a
    ld      [CursorNeedsRefresh],a ; flag as updated

    ld      a,[CursorTileX]
    sla     a
    sla     a
    sla     a
    sla     a ; X * 16
    add     a,4+(BOARD_X_OFFSET_TILES*16)
    ld      [CursorX],a

    ld      a,[CursorTileY]
    sla     a
    sla     a
    sla     a
    sla     a ; Y * 16
    add     12+(BOARD_Y_OFFSET_TILES*16)
    ld      [CursorY],a

CURSOR_CORNER_TILE      EQU 0
CURSOR_VERTICAL_TILE    EQU 1
CURSOR_HORIZONTAL_TILE  EQU 2

    ld      a,[CursorHorizontal]
    and     a,a
    jp      z,.vertical

    ; Horizontal
    ; ----------

        ; Top Left
        ld      hl,CursorFrame
        ld      a,[CursorX]
        sub     a,[hl]
        ld      b,a
        ld      a,[CursorY]
        sub     a,[hl]
        ld      c,a
        ld      l,0
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_CORNER_TILE
        ld      [hl+],a ; Tile
        ld      a,0
        ld      [hl+],a ; Params

        ; Down Left
        ld      hl,CursorFrame
        ld      a,[CursorX]
        sub     a,[hl]
        ld      b,a
        ld      a,[CursorY]
        add     a,[hl]
        add     a,16
        ld      c,a
        ld      l,1
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_CORNER_TILE
        ld      [hl+],a ; Tile
        ld      a,OAMF_YFLIP
        ld      [hl+],a ; Params

        ; Top
        ld      hl,CursorFrame
        ld      a,[CursorX]
        add     a,12
        ld      b,a
        ld      a,[CursorY]
        sub     a,[hl]
        ld      c,a
        ld      l,2
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_HORIZONTAL_TILE
        ld      [hl+],a ; Tile
        ld      a,0
        ld      [hl+],a ; Params

        ld      hl,CursorFrame
        ld      a,[CursorX]
        add     a,12+8
        ld      b,a
        ld      a,[CursorY]
        sub     a,[hl]
        ld      c,a
        ld      l,3
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_HORIZONTAL_TILE
        ld      [hl+],a ; Tile
        ld      a,OAMF_XFLIP
        ld      [hl+],a ; Params

        ; Bottom
        ld      hl,CursorFrame
        ld      a,[CursorX]
        add     a,12
        ld      b,a
        ld      a,[CursorY]
        add     a,[hl]
        add     a,16
        ld      c,a
        ld      l,4
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_HORIZONTAL_TILE
        ld      [hl+],a ; Tile
        ld      a,OAMF_YFLIP
        ld      [hl+],a ; Params

        ld      hl,CursorFrame
        ld      a,[CursorX]
        add     a,12+8
        ld      b,a
        ld      a,[CursorY]
        add     a,[hl]
        add     a,16
        ld      c,a
        ld      l,5
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_HORIZONTAL_TILE
        ld      [hl+],a ; Tile
        ld      a,OAMF_XFLIP|OAMF_YFLIP
        ld      [hl+],a ; Params

        ; Top Right
        ld      hl,CursorFrame
        ld      a,[CursorX]
        add     a,[hl]
        add     a,12+20
        ld      b,a
        ld      a,[CursorY]
        sub     a,[hl]
        ld      c,a
        ld      l,6
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_CORNER_TILE
        ld      [hl+],a ; Tile
        ld      a,OAMF_XFLIP
        ld      [hl+],a ; Params

        ; Down Left
        ld      hl,CursorFrame
        ld      a,[CursorX]
        add     a,[hl]
        add     a,12+20
        ld      b,a
        ld      a,[CursorY]
        add     a,[hl]
        add     a,16
        ld      c,a
        ld      l,7
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_CORNER_TILE
        ld      [hl+],a ; Tile
        ld      a,OAMF_XFLIP|OAMF_YFLIP
        ld      [hl+],a ; Params

    ret

.vertical:

    ; Vertical
    ; --------

        ; Top Left
        ld      hl,CursorFrame
        ld      a,[CursorX]
        sub     a,[hl]
        ld      b,a
        ld      a,[CursorY]
        sub     a,[hl]
        ld      c,a
        ld      l,0
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_CORNER_TILE
        ld      [hl+],a ; Tile
        ld      a,0
        ld      [hl+],a ; Params

        ; Top Right
        ld      hl,CursorFrame
        ld      a,[CursorX]
        add     a,[hl]
        add     a,16
        ld      b,a
        ld      a,[CursorY]
        sub     a,[hl]
        ld      c,a
        ld      l,1
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_CORNER_TILE
        ld      [hl+],a ; Tile
        ld      a,OAMF_XFLIP
        ld      [hl+],a ; Params

        ; Left
        ld      hl,CursorFrame
        ld      a,[CursorX]
        sub     a,[hl]
        ld      b,a
        ld      a,[CursorY]
        add     a,12
        ld      c,a
        ld      l,2
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_VERTICAL_TILE
        ld      [hl+],a ; Tile
        ld      a,0
        ld      [hl+],a ; Params

        ld      hl,CursorFrame
        ld      a,[CursorX]
        sub     a,[hl]
        ld      b,a
        ld      a,[CursorY]
        add     a,12+8
        ld      c,a
        ld      l,3
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_VERTICAL_TILE
        ld      [hl+],a ; Tile
        ld      a,OAMF_YFLIP
        ld      [hl+],a ; Params

        ; Right
        ld      hl,CursorFrame
        ld      a,[CursorX]
        add     a,[hl]
        add     a,16
        ld      b,a
        ld      a,[CursorY]
        add     a,12
        ld      c,a
        ld      l,4
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_VERTICAL_TILE
        ld      [hl+],a ; Tile
        ld      a,OAMF_XFLIP
        ld      [hl+],a ; Params

        ld      hl,CursorFrame
        ld      a,[CursorX]
        add     a,[hl]
        add     a,16
        ld      b,a
        ld      a,[CursorY]
        add     a,12+8
        ld      c,a
        ld      l,5
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_VERTICAL_TILE
        ld      [hl+],a ; Tile
        ld      a,OAMF_XFLIP|OAMF_YFLIP
        ld      [hl+],a ; Params

        ; Bottom Left
        ld      hl,CursorFrame
        ld      a,[CursorX]
        sub     a,[hl]
        ld      b,a
        ld      a,[CursorY]
        add     a,12+20
        add     a,[hl]
        ld      c,a
        ld      l,6
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_CORNER_TILE
        ld      [hl+],a ; Tile
        ld      a,OAMF_YFLIP
        ld      [hl+],a ; Params

        ; Bottom Right
        ld      hl,CursorFrame
        ld      a,[CursorX]
        add     a,[hl]
        add     a,16
        ld      b,a
        ld      a,[CursorY]
        add     a,12+20
        add     a,[hl]
        ld      c,a
        ld      l,7
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_CORNER_TILE
        ld      [hl+],a ; Tile
        ld      a,OAMF_XFLIP|OAMF_YFLIP
        ld      [hl+],a ; Params

    ret

;--------------------------------------------------------------------------

CursorAnimate:

    ld      hl,CursorAnimCount
    ld      a,[hl]
    dec     a
    ld      [hl],a
    ret     nz

    ld      a,CURSOR_ANIMATION_TICKS
    ld      [hl],a

    ld      a,[CursorFrame]
    xor     a,1
    ld      [CursorFrame],a

    ld      a,1
    ld      [CursorNeedsRefresh],a

    ret

;--------------------------------------------------------------------------

CursorMovePAD:

    ld      a,[joy_pressed]
    and     a,PAD_B
    jr      z,.b_end
    ld      a,[CursorHorizontal]
    xor     a,1
    ld      [CursorHorizontal],a
    ld      a,1
    ld      [CursorNeedsRefresh],a

    ; Check limits right and down

    ld      a,[CursorHorizontal]
    and     a,a
    jr      z,.vertical

        ; Horizontal
        ld      hl,CursorTileX
        ld      a,[hl]
        cp      a,BOARD_COLUMNS-1
        jr      nz,.b_end
        dec     [hl]

    jr      .b_end
.vertical:

        ; Vertical
        ld      hl,CursorTileY
        ld      a,[hl]
        cp      a,BOARD_ROWS-1
        jr      nz,.b_end
        dec     [hl]

.b_end:

    ; Move

    ld      hl,CursorTileX
    ld      a,[joy_pressed]
    and     a,PAD_LEFT
    jr      z,.left_end
    ld      a,[hl]
    and     a,a
    jr      z,.left_end
    dec     [hl]
    ld      a,1
    ld      [CursorNeedsRefresh],a
.left_end:

    ld      hl,CursorTileX
    ld      a,[joy_pressed]
    and     a,PAD_RIGHT
    jr      z,.right_end
    ld      b,[hl]
    ld      a,[CursorHorizontal]
    add     a,b
    cp      a,BOARD_COLUMNS-1
    jr      z,.right_end
    inc     [hl]
    ld      a,1
    ld      [CursorNeedsRefresh],a
.right_end:

    ld      hl,CursorTileY
    ld      a,[joy_pressed]
    and     a,PAD_UP
    jr      z,.up_end
    ld      a,[hl]
    cp      a,1 ; first row is hidden, can't go there
    jr      z,.up_end
    dec     [hl]
    ld      a,1
    ld      [CursorNeedsRefresh],a
.up_end:

    ld      hl,CursorTileY
    ld      a,[joy_pressed]
    and     a,PAD_DOWN
    jr      z,.down_end
    ld      b,[hl]
    ld      a,[CursorHorizontal]
    ld      c,a
    ld      a,b
    sub     a,c
    cp      a,BOARD_ROWS-2
    jr      z,.down_end
    inc     [hl]
    ld      a,1
    ld      [CursorNeedsRefresh],a
.down_end:

    ret

;--------------------------------------------------------------------------

CursorHandle:: ; returns 1 if 2 blocks has to be changed, 0 if not

    call    CursorMovePAD
    call    CursorAnimate
    call    CursorRefresh

    ; Change 2 blocks
    ld      a,[joy_pressed]
    and     a,PAD_A
    swap    a ; PAD_A = $10 -> swap to $01
    ret
