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

    SECTION "High Credits Code Data",ROMX

;--------------------------------------------------------------------------


CreditsBGMapData: ; tilemap first, attr map second
    INCBIN	"data/credits_bg_map.bin"

    DEF CREDITS_BG_MAP_WIDTH   EQU 20
    DEF CREDITS_BG_MAP_HEIGHT  EQU 18

;--------------------------------------------------------------------------

CreditsHandlerVBL:

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
    ld      hl,CreditsBGMapData
    ld      a,CREDITS_BG_MAP_HEIGHT
.loop_vbk0:
    push    af
    ld      bc,CREDITS_BG_MAP_WIDTH
    call    vram_copy
    push    hl
    ld      hl,32-CREDITS_BG_MAP_WIDTH
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
    ld      hl,CreditsBGMapData+CREDITS_BG_MAP_WIDTH*CREDITS_BG_MAP_HEIGHT
    ld      a,CREDITS_BG_MAP_HEIGHT
.loop_vbk1:
    push    af
    ld      bc,CREDITS_BG_MAP_WIDTH
    call    vram_copy
    push    hl
    ld      hl,32-CREDITS_BG_MAP_WIDTH
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

    ; Load palettes
    ld      b,144
    call    wait_ly

    call    LoadMenuPalettes

    ; Enable interrupts
    ld      a,IEF_VBLANK
    ldh     [rIE],a

    ld      bc,CreditsHandlerVBL
    call    irq_set_VBL

    ei

    ; Screen configuration
    ld      a,[LCDCF_GBC_MODE]
    or      a,LCDCF_BG9800|LCDCF_ON
    ldh     [rLCDC],a

    ; Done
    ret

;--------------------------------------------------------------------------

CreditsScreenMainLoop::

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

    ld      a,[joy_pressed]
    and     a,a
    jr      z,.loop ; if any key pressed, exit

    ; End loop
    call    gbt_stop

    ; Disable interrupts
    di

    ret
