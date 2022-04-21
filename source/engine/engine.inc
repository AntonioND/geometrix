;###############################################################################
;
;    Geometrix - A simple puzzle game for Game Boy and Game Boy Color.
;
;    Copyright (c) 2015, 2018 Antonio Niño Díaz (AntonioND/SkyLyrac)
;
;    SPDX-License-Identifier: GPL-3.0-or-later
;
;###############################################################################

    IF !DEF(HEADER_INC)
HEADER_INC = 1

;+-----------------------------------------------------------------------------+
;| +-------------------------------------------------------------------------+ |
;| |                                MACROS                                   | |
;| +-------------------------------------------------------------------------+ |
;+-----------------------------------------------------------------------------+

DMA_COPY : MACRO   ;   src, dst, size, is_hdma
    ld      a, ( \1 >> 8 )& $FF
    ld      [rHDMA1],a
    ld      a, \1 & $F0 ; Lower 4 bits ignored
    ld      [rHDMA2],a

    ld      a, ( \2 >> 8 )& $1F ; Upper 3 bits ignored
    ld      [rHDMA3],a
    ld      a, \2 & $F0 ; Lower 4 bits ignored
    ld      [rHDMA4],a

    ld      a, ( ( ( \3 >> 4 ) - 1 ) | ( \4 << 7 ) ) ; ( Size / $10 ) - 1
    ld      [rHDMA5],a
ENDM

LONG_CALL : MACRO  ;  function
    ld      b,BANK(\1)
    ld      hl,\1
    call    ___long_call
ENDM

LONG_CALL_ARGS : MACRO  ;  function
    ld      a,BANK(\1)
    ld      hl,\1
    call    ___long_call_args ; a bit slower, but it can use bc and de for arguments
ENDM

CALL_HL : MACRO
    rst     $08
ENDM

;+-----------------------------------------------------------------------------+
;| +-------------------------------------------------------------------------+ |
;| |                                 LUTS.ASM                                | |
;| +-------------------------------------------------------------------------+ |
;+-----------------------------------------------------------------------------+

Sine    EQU $3E00 ; \ Aligned to $100 to improve speed when
Cosine  EQU $3F00 ; / reading from them. :)

;--------------------------------------------------------------------------
;- GetRandom()    a = returned value    hl is destroyed                   -
;- SetRandomSeed()    a = new seed                                        -
;--------------------------------------------------------------------------

    EXPORT  GetRandom
    EXPORT  SetRandomSeed

;+-----------------------------------------------------------------------------+
;| +-------------------------------------------------------------------------+ |
;| |                                 INIT.ASM                                | |
;| +-------------------------------------------------------------------------+ |
;+-----------------------------------------------------------------------------+

;--------------------------------------------------------------------------
;- irq_set_VBL()    bc = function pointer                                 -
;- irq_set_LCD()    bc = function pointer                                 -
;- irq_set_TIM()    bc = function pointer                                 -
;- irq_set_SIO()    bc = function pointer                                 -
;- irq_set_JOY()    bc = function pointer                                 -
;--------------------------------------------------------------------------

    EXPORT  irq_set_VBL
    EXPORT  irq_set_LCD
    EXPORT  irq_set_TIM
    EXPORT  irq_set_SIO
    EXPORT  irq_set_JOY

;--------------------------------------------------------------------------
;- CPU_fast()                                                             -
;- CPU_slow()                                                             -
;--------------------------------------------------------------------------

    EXPORT  CPU_fast
    EXPORT  CPU_slow

;--------------------------------------------------------------------------
;- wait_vbl()                                                             -
;--------------------------------------------------------------------------

    EXPORT  wait_vbl

;--------------------------------------------------------------------------
;- Reset()                                                                -
;--------------------------------------------------------------------------

    EXPORT  Reset

;--------------------------------------------------------------------------
;-                                Variables                               -
;--------------------------------------------------------------------------

    EXPORT  Init_Reg_A
    EXPORT  Init_Reg_B

    EXPORT  VBL_handler
    EXPORT  LCD_handler
    EXPORT  TIM_handler
    EXPORT  SIO_handler
    EXPORT  JOY_handler

;+-----------------------------------------------------------------------------+
;| +-------------------------------------------------------------------------+ |
;| |                                 MAIN.ASM                                | |
;| +-------------------------------------------------------------------------+ |
;+-----------------------------------------------------------------------------+

;--------------------------------------------------------------------------
;- Main()                                                                 -
;--------------------------------------------------------------------------

    EXPORT  Main

;+-----------------------------------------------------------------------------+
;| +-------------------------------------------------------------------------+ |
;| |                            UTILITIES.ASM                                | |
;| +-------------------------------------------------------------------------+ |
;+-----------------------------------------------------------------------------+

;--------------------------------------------------------------------------
;- mul_u8u8u16()    hl = returned value    a,c = initial values           -
;- div_u8u8u8()     c = a / b     a = a % b                               -
;- div_s8s8s8()     a / b -> c     a % b -> a     destroys e              -
;--------------------------------------------------------------------------

    EXPORT  mul_u8u8u16
    EXPORT  div_u8u8u8
    EXPORT  div_s8s8s8

;--------------------------------------------------------------------------
;- memset()    d = value    hl = start address    bc = size               -
;- memset_rand()    hl = start address    bc = size                       -
;- memcopy()    bc = size    hl = source address    de = dest address     -
;- memcopy_inc()    b = size    c = increase    hl = source    de = dest  -
;--------------------------------------------------------------------------

    EXPORT  memset
    EXPORT  memset_rand
    EXPORT  memcopy
    EXPORT  memcopy_inc

;--------------------------------------------------------------------------
;- scan_keys()                                                            -
;--------------------------------------------------------------------------

    EXPORT  scan_keys

;--------------------------------------------------------------------------
;-                               Variables                                -
;--------------------------------------------------------------------------

    EXPORT  joy_held ; Holds current held keys
    EXPORT  joy_pressed ; Holds keys that have been pressed this frame

;--------------------------------------------------------------------------
;-                              Definitions                               -
;--------------------------------------------------------------------------

PAD_START   EQU $80
PAD_SELECT  EQU $40
PAD_B       EQU $20
PAD_A       EQU $10
PAD_DOWN    EQU $08
PAD_UP      EQU $04
PAD_LEFT    EQU $02
PAD_RIGHT   EQU $01

;--------------------------------------------------------------------------
;- rom_handler_init()                                                     -
;- rom_bank_pop()                                                         -
;- rom_bank_push()                                                        -
;- rom_bank_set()    b = bank to change to                                -
;- rom_bank_push_set()    b = bank to change to                           -
;-                                                                        -
;- ___long_call()    hl = function    b = bank where it is located        -
;--------------------------------------------------------------------------

    EXPORT  rom_handler_init
    EXPORT  rom_bank_pop
    EXPORT  rom_bank_push
    EXPORT  rom_bank_set
    EXPORT  rom_bank_push_set
    EXPORT  ___long_call

;+-----------------------------------------------------------------------------+
;| +-------------------------------------------------------------------------+ |
;| |                              VIDEO.ASM                                  | |
;| +-------------------------------------------------------------------------+ |
;+-----------------------------------------------------------------------------+

;--------------------------------------------------------------------------
;- wait_ly()    b = ly to wait for                                        -
;- wait_frames()    e = frames to wait                                    -
;- wait_screen_blank()                                                    -
;- screen_off()                                                           -
;--------------------------------------------------------------------------

    EXPORT  wait_ly
    EXPORT  wait_frames
    EXPORT  wait_screen_blank
    EXPORT  screen_off

;--------------------------------------------------------------------------
;- vram_copy()    bc = size    hl = source address    de = dest address   -
;- vram_memset()    bc = size    d = value    hl = dest address           -
;- vram_copy_tiles()    bc = tiles    de = start index    hl = source     -
;--------------------------------------------------------------------------

    EXPORT  vram_copy
    EXPORT  vram_memset
    EXPORT  vram_copy_tiles

;--------------------------------------------------------------------------
;- init_OAM()                                                             -
;- refresh_OAM()                                                          -
;- refresh_custom_OAM()    a = (oam copy >> 8), aligned to 100h           -
;-                                                                        -
;- sprite_get_base_pointer()    l = sprite    return = hl    destroys de  -
;-                                                                        -
;- sprite_set_xy()    b = x    c = y    l = sprite number                 -
;- sprite_set_tile()    a = tile    l = sprite number                     -
;- sprite_set_params()    a = params    l = sprite number                 -
;-                                                                        -
;- spr_set_palette()    a = palette number    hl = pointer to data        -
;--------------------------------------------------------------------------

    EXPORT  init_OAM
    EXPORT  refresh_OAM
    EXPORT  refresh_custom_OAM
    EXPORT  sprite_get_base_pointer
    EXPORT  sprite_set_xy
    EXPORT  sprite_set_tile
    EXPORT  sprite_set_params
    EXPORT  spr_set_palette

;--------------------------------------------------------------------------
;-                               Variables                                -
;--------------------------------------------------------------------------

    EXPORT  OAM_Copy ; Pointer to the copy in RAM of the OAM

;--------------------------------------------------------------------------
;- bg_set_tile()    b = x    c = y    a = tile index                      -
;- bg_set_tile_wrap()    b = x    c = y    a = tile index                 -
;-                                                                        -
;- bg_set_palette()    a = palette number    hl = pointer to data         -
;--------------------------------------------------------------------------

    EXPORT  bg_set_tile
    EXPORT  bg_set_tile_wrap
    EXPORT  bg_set_palette

;-------------------------------------------------------------------------------

    ENDC ;HEADER_INC
