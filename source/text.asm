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

    INCLUDE "text.inc"

;----------------------------------------------------------------------------

    SECTION "Text",ROM0

;----------------------------------------------------------------------------


TextTilesData:
    INCBIN	"data/text_tiles.bin"
TEXT_BASE_TILE  EQU 180
TEXT_MAX_TILE   EQU 255
TextTilesNumber EQU TEXT_MAX_TILE-TEXT_BASE_TILE+1


;----------------------------------------------------------------------------

LoadText::

    xor     a,a
    ld      [rVBK],a

    ld      bc,TextTilesNumber
    ld      de,TEXT_BASE_TILE ; Bank at 8800h
    ld      hl,TextTilesData
    call    vram_copy_tiles

    ret

;----------------------------------------------------------------------------

credits_ascii_to_tiles_table:

	;   .--Space is here!
	;   v
	; ##  ! " # $ % & ' ( ) * + , - . / 0 1 2 3 4 5 6 7 8 9 : ; < = > ?##
	; ##@ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z [ \ ] ^ _##
	; ##` a b c d e f g h i j k l m n o p q r s t u v w x y z { | } ~  ##

	;   ' '     !             "      #       $      %           &      '            (      )
	DB	O_SPACE,O_EXCLAMATION,O_NONE,O_ARROW,O_NONE,O_COPYRIGHT,O_NONE,O_APOSTROPHE,O_NONE,O_NONE
	;   *      +      ,       -      .     /
	DB	O_NONE,O_NONE,O_COMMA,O_NONE,O_DOT,O_BAR
	;   0 1 2 3 4 5 6 7 8 9
CHARACTER	SET	0
	REPT	10
	DB	O_ZERO+CHARACTER
CHARACTER	SET	CHARACTER+1
	ENDR
	;   :          ;      <      =      >      ?          @
	DB	O_TWO_DOTS,O_NONE,O_NONE,O_NONE,O_NONE,O_QUESTION,O_AT
	;   A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
CHARACTER	SET	0
	REPT	26
	DB	O_A_UPPERCASE+CHARACTER
CHARACTER	SET	CHARACTER+1
	ENDR
	;   [      \      ]      ^      _            `
	DB	O_NONE,O_NONE,O_NONE,O_NONE,O_UNDERSCORE,O_NONE
	; a b c d e f g h i j k l m n o p q r s t u v w x y z
CHARACTER	SET	0
	REPT	26
	DB	O_A_LOWERCASE+CHARACTER
CHARACTER	SET	CHARACTER+1
	ENDR
	;   {      |      }      ~
	DB	O_NONE,O_NONE,O_NONE,O_NTILDE

;----------------------------------------------------------------------------

ASCII2Tile:: ; a = ascii code. Returns tile number in a. Destroys de and hl

    sub     a,32 ; Non-printing characters
    ld      hl,credits_ascii_to_tiles_table
    ld      d,0
    ld      e,a
    add     hl,de
    ld      a,[hl]

    ret
