;###############################################################################
;
;    Geometrix - A simple puzzle game for Game Boy and Game Boy Color.
;
;    Copyright (c) 2015, 2018 Antonio Niño Díaz (AntonioND/SkyLyrac)
;
;    SPDX-License-Identifier: GPL-3.0-or-later
;
;###############################################################################

    IF !DEF(TEXT_INC)
    DEF TEXT_INC = 1

;----------------------------------------------------------------------------

; Offsets
    DEF O_SPACE         EQU 181
    DEF O_BAR           EQU 182
    DEF O_COPYRIGHT     EQU 183 ; Mapped to "%"
    DEF O_COMMA         EQU 184
    DEF O_DOT           EQU 185
    DEF O_UNDERSCORE    EQU 186
    DEF O_AT            EQU 187
    DEF O_TWO_DOTS      EQU 188
    DEF O_ARROW         EQU 189 ; Mapped to "#"
    DEF O_APOSTROPHE    EQU 190
    DEF O_EXCLAMATION   EQU 192
    DEF O_QUESTION      EQU 191
    DEF O_ZERO          EQU 194
    DEF O_A_UPPERCASE   EQU 204
    DEF O_A_LOWERCASE   EQU 230
    DEF O_NTILDE        EQU 193 ; La eñe, leches XD - Mapped to "~"
    DEF O_NONE          EQU O_QUESTION

;----------------------------------------------------------------------------

MACRO BCD2Tile ; a = number from 0 to 9. Returns tile number in a
    add     a,O_ZERO
ENDM

;----------------------------------------------------------------------------

    ENDC ;TEXT_INC
