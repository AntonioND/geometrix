;###############################################################################
;
;    Geometrix - A simple puzzle game for Game Boy and Game Boy Color.
;
;    Copyright (c) 2015, 2018 Antonio Niño Díaz (AntonioND/SkyLyrac)
;
;    SPDX-License-Identifier: GPL-3.0-or-later
;
;###############################################################################

    IF !DEF(ROOM_MENU_INC)
    DEF ROOM_MENU_INC = 1

;--------------------------------

; From room_game.inc:
;    DEF GAME_MODE_REMOVE_ALL    EQU 0 ; remove all blocks from the screen
;    DEF GAME_MODE_SWAP_LIMIT    EQU 1 ; earn as much points as possible in X movements
;    DEF GAME_MODE_TIME_LIMIT    EQU 2 ; earn as much points as possible in X seconds

    DEF ROOM_GAME_REMOVE_ALL    EQU 0
    DEF ROOM_GAME_SWAP_LIMIT    EQU 1
    DEF ROOM_GAME_TIME_LIMIT    EQU 2
    DEF ROOM_HIGH_SCORES        EQU 3
    DEF ROOM_CREDITS            EQU 4

;--------------------------------

    ENDC ;ROOM_MENU_INC
