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
O_SPACE			EQU	181
O_BAR			EQU	182
O_COPYRIGHT     EQU 183 ; Mapped to "%"
O_COMMA			EQU	184
O_DOT			EQU	185
O_UNDERSCORE	EQU	186
O_AT    		EQU	187
O_TWO_DOTS      EQU 188
O_ARROW         EQU 189 ; Mapped to "#"
O_APOSTROPHE	EQU	190
O_EXCLAMATION	EQU	192
O_QUESTION		EQU	191
O_ZERO			EQU	194
O_A_UPPERCASE	EQU	204
O_A_LOWERCASE	EQU	230
O_NTILDE		EQU	193 ; La eñe, leches XD - Mapped to "~"
O_NONE			EQU	O_QUESTION

;----------------------------------------------------------------------------

BCD2Tile : MACRO ; a = number from 0 to 9. Returns tile number in a
    add     a,O_ZERO
ENDM

;----------------------------------------------------------------------------

    ENDC ;TEXT_INC
