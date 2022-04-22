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

BOARD_ROWS      EQU 9 ; 1 is hidden
BOARD_COLUMNS   EQU 8
BOARD_SIZE      EQU BOARD_ROWS*BOARD_COLUMNS
BOARD_ROWS_MINUS_2      EQU 7
BOARD_COLUMNS_MINUS_2   EQU 6
BOARD_COLUMNS_MINUS_1   EQU 7

BOARD_X_OFFSET_TILES    EQU 1 ; Metatiles of space top of the screen
BOARD_Y_OFFSET_TILES    EQU -1 ; Metatiles of space left of the screen

;--------------------------------

GAME_MODE_REMOVE_ALL    EQU 0 ; remove all blocks from the screen
GAME_MODE_SWAP_LIMIT    EQU 1 ; earn as much points as possible in X movements
GAME_MODE_TIME_LIMIT    EQU 2 ; earn as much points as possible in X seconds

GAME_RESULT_NOT_FINISHED    EQU 0 ; Game still running.
GAME_RESULT_MANUAL          EQU 1 ; For manual exit.
GAME_RESULT_LIMIT           EQU 2 ; For time or swap limit.
GAME_RESULT_WIN             EQU 3 ; For "remove all" if all are eliminated.
GAME_RESULT_LOSE            EQU 4 ; For "remove all" if not all are eliminated.

; BCD numbers!
GAME_TIME_LIMIT_SECONDS EQU $0300 ; 300 seconds
GAME_SWAP_LIMIT_SWAPS   EQU $0300 ; 300 swaps

;--------------------------------

    ENDC ;ROOM_GAME_INC
