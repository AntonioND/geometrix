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
    INCLUDE "room_menu.inc"

;-------------------------------------------------------------------------------

    SECTION "Main Vars",WRAM0

;--------------------------------------------------------------------------

PadUpCount:     DS  1 ; when 0, repeat press
PadDownCount:   DS  1
PadLeftCount:   DS  1
PadRightCount:  DS  1

    DEF PAD_AUTOREPEAT_WAIT_INITIAL EQU 10
    DEF PAD_AUTOREPEAT_WAIT_REPEAT  EQU 3

LCDCF_GBC_MODE:: DS  1 ; this is 0 if GBC or LCDCF_BGON if DMG

;--------------------------------------------------------------------------

    SECTION "Main",ROM0

;--------------------------------------------------------------------------

InitKeyAutorepeat:
    ld      a,PAD_AUTOREPEAT_WAIT_INITIAL
    ld      [PadUpCount],a
    ld      [PadDownCount],a
    ld      [PadLeftCount],a
    ld      [PadRightCount],a
    ret

KeyAutorepeatHandle::

    ; Up

    ld      a,[joy_held]
    and     a,PAD_UP
    jr      z,.not_up

        ld      hl,PadUpCount
        dec     [hl]
        jr      nz,.end_up

        ld      [hl],PAD_AUTOREPEAT_WAIT_REPEAT

        ld      a,[joy_pressed]
        or      a,PAD_UP
        ld      [joy_pressed],a

    jr      .end_up
.not_up:
    ld      a,PAD_AUTOREPEAT_WAIT_INITIAL
    ld      [PadUpCount],a
.end_up:

    ; Down

    ld      a,[joy_held]
    and     a,PAD_DOWN
    jr      z,.not_down

        ld      hl,PadDownCount
        dec     [hl]
        jr      nz,.end_down

        ld      [hl],PAD_AUTOREPEAT_WAIT_REPEAT

        ld      a,[joy_pressed]
        or      a,PAD_DOWN
        ld      [joy_pressed],a

    jr      .end_down
.not_down:
    ld      a,PAD_AUTOREPEAT_WAIT_INITIAL
    ld      [PadDownCount],a
.end_down:

    ; Right

    ld      a,[joy_held]
    and     a,PAD_RIGHT
    jr      z,.not_right

        ld      hl,PadRightCount
        dec     [hl]
        jr      nz,.end_right

        ld      [hl],PAD_AUTOREPEAT_WAIT_REPEAT

        ld      a,[joy_pressed]
        or      a,PAD_RIGHT
        ld      [joy_pressed],a

    jr      .end_right
.not_right:
    ld      a,PAD_AUTOREPEAT_WAIT_INITIAL
    ld      [PadRightCount],a
.end_right:

    ; Left

    ld      a,[joy_held]
    and     a,PAD_LEFT
    jr      z,.not_left

        ld      hl,PadLeftCount
        dec     [hl]
        jr      nz,.end_left

        ld      [hl],PAD_AUTOREPEAT_WAIT_REPEAT

        ld      a,[joy_pressed]
        or      a,PAD_LEFT
        ld      [joy_pressed],a

    jr      .end_left
.not_left:
    ld      a,PAD_AUTOREPEAT_WAIT_INITIAL
    ld      [PadLeftCount],a
.end_left:


    ret

;--------------------------------------------------------------------------
;- Main()                                                                 -
;--------------------------------------------------------------------------

Main:

    ld      a,0
    ld      [LCDCF_GBC_MODE],a

    ld      a,[EnabledGBC]
    and     a,a
    jr      nz,.not_gbc
    ld      a,LCDCF_BGON
    ld      [LCDCF_GBC_MODE],a
.not_gbc:

    ld      a,LCDCF_ON
    ldh     [rLCDC],a

    call    InitKeyAutorepeat

    call    RecordsCheckIntegrityAndRead ; Check if everything is 0K or reset data.

.main_menu:
    call    MenuScreenMainLoop
    cp      a,ROOM_GAME_REMOVE_ALL
    jr      z,.game ; a = ROOM_GAME_REMOVE_ALL = GAME_MODE_REMOVE_ALL
    cp      a,ROOM_GAME_SWAP_LIMIT
    jr      z,.game ; a = ROOM_GAME_SWAP_LIMIT = GAME_MODE_SWAP_LIMIT
    cp      a,ROOM_GAME_TIME_LIMIT
    jr      z,.game ; a = ROOM_GAME_TIME_LIMIT = GAME_MODE_TIME_LIMIT
    cp      a,ROOM_HIGH_SCORES
    jr      z,.high_scores_dont_modify
    cp      a,ROOM_CREDITS
    jr      z,.credits
    ret ; Shouldn't happen - reset

.game:
    call    GameScreenMainLoop
    cp      a,GAME_RESULT_NOT_FINISHED
    ret     z ; wtf? - reset
    cp      a,GAME_RESULT_MANUAL
    jr      z,.main_menu
    cp      a,GAME_RESULT_LIMIT
    jr      z,.high_scores_modify
    cp      a,GAME_RESULT_WIN
    jr      z,.main_menu
    cp      a,GAME_RESULT_LOSE
    jr      z,.main_menu
    ret ; Shouldn't happen - reset

.high_scores_modify:
    ld      a,1 ; Enable write
    call    HighScoresScreenMainLoop
    jr      .main_menu
.high_scores_dont_modify:
    ld      a,0
    call    HighScoresScreenMainLoop
    jr      .main_menu

.credits:
    call    CreditsScreenMainLoop
    jr      .main_menu

;--------------------------------------------------------------------------

SetPalettesAllBlack::

    ld      a,$FF
    ldh     [rBGP],a
    ld      a,[EnabledGBC]
    and     a,a
    ret     z

    di

    ld      b,144
    call    wait_ly

    ld      a,$80 ; auto increment
    ldh     [rBCPS],a
    ldh     [rOCPS],a

    ld      hl,rBCPD
    ld      c,rOCPD&$FF
    xor     a,a
    ld      b,8
.loop:
    REPT    4
    ld      [hl],a
    ld      [hl],a

    ldh     [$FF00+c],a
    ldh     [$FF00+c],a
    ENDR
    dec     b
    jr      nz,.loop

    ei

    ret
