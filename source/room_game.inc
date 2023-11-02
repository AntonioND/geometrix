;###############################################################################
;
;    Geometrix - A simple puzzle game for Game Boy and Game Boy Color.
;
;    Copyright (c) 2015, 2018 Antonio Niño Díaz (AntonioND/SkyLyrac)
;
;    SPDX-License-Identifier: GPL-3.0-or-later
;
;###############################################################################

    IF !DEF(ROOM_GAME_INC)
    DEF ROOM_GAME_INC = 1

;--------------------------------

    ; Don't modify any constant of this group!

    DEF BOARD_ROWS      EQU 9 ; 1 is hidden
    DEF BOARD_COLUMNS   EQU 8
    DEF BOARD_SIZE      EQU BOARD_ROWS*BOARD_COLUMNS
    DEF BOARD_ROWS_MINUS_2      EQU 7
    DEF BOARD_COLUMNS_MINUS_2   EQU 6
    DEF BOARD_COLUMNS_MINUS_1   EQU 7

    DEF BOARD_X_OFFSET_TILES    EQU 1 ; Metatiles of space top of the screen
    DEF BOARD_Y_OFFSET_TILES    EQU -1 ; Metatiles of space left of the screen

    ;--------------------------------

    DEF GAME_MODE_REMOVE_ALL    EQU 0 ; remove all blocks from the screen
    DEF GAME_MODE_SWAP_LIMIT    EQU 1 ; earn as much points as possible in X movements
    DEF GAME_MODE_TIME_LIMIT    EQU 2 ; earn as much points as possible in X seconds

    DEF GAME_RESULT_NOT_FINISHED    EQU 0 ; Game still running.
    DEF GAME_RESULT_MANUAL          EQU 1 ; For manual exit.
    DEF GAME_RESULT_LIMIT           EQU 2 ; For time or swap limit.
    DEF GAME_RESULT_WIN             EQU 3 ; For "remove all" if all are eliminated.
    DEF GAME_RESULT_LOSE            EQU 4 ; For "remove all" if not all are eliminated.

    ; BCD numbers!
    DEF GAME_TIME_LIMIT_SECONDS EQU $0300 ; 300 seconds
    DEF GAME_SWAP_LIMIT_SWAPS   EQU $0300 ; 300 swaps

;--------------------------------

    ENDC ;ROOM_GAME_INC
