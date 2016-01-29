
;--------------------------------------------------------------------------

    INCLUDE "hardware.inc"
    INCLUDE "engine.inc"

    INCLUDE "room_game.inc"
    INCLUDE "text.inc"

;--------------------------------------------------------------------------

    SECTION "Room Game Variables",WRAM0

BoardStatus:    DS  BOARD_SIZE ; Number of form in each position

BoardFrame:     DS  BOARD_SIZE ; Frame of each position
BoardCountDown: DS  BOARD_SIZE ; Ticks to animate (0 = update)
BOARD_ANIMATION_TICKS   EQU 64 ; Ticks to update. Should be a power of 2.

BoardMetatile:  DS  BOARD_SIZE ; Metatile of each position

BoardChecking:  DS  BOARD_SIZE ; Set to 1 o 0 when checking for lines

;--------------------------------

; Logic variables
LastCheckLines: DS  1 ; Number of complete lines detected last time
GravityHasUpdated:  DS  1 ; Temp var for BoardGravityHandle

CurrentCombo:   DS  1 ; Current multiplier
ComboBubbleCountdown:   DS  1 ; Frames to disappear

; 0 = Regular, 1 = removing completed lines, 2 = gravity after removal
GameLogicStatus:    DS  1 ; state 2 can go back to 1 if new completed lines (combo)
STATUS_REGULAR      EQU 0
STATUS_REMOVE_LINES EQU 1
STATUS_GRAVITY      EQU 2

DeleteCountdown:    DS  1 ; countdown for delete blocks animation
DELETE_COUNTDOWN_TICKS  EQU 30

GameFillScreenMode:  DS  1 ; 1 if screen should be filled

GameMode::  DS  1 ; Constants are in game_screen.inc

GamePaused: DS  1 ; 1 if paused, 0 if not
GamePauseCursor:    DS  1 ; Selection of continue or exit
GamePausedBaseSCY:  DS  1  ; SCY for the sign
GamePausedHeight:   DS  1  ; Size of the sign

; In remove all blocks mode, after removing lines, every block is checked. If there are 1 or 2
; of at least one type, this flag is set to 1. The next iteration of the main loop it will set
; GameEnd to 1.
GameRemoveAllFlagEnd:   DS  1

GameEnd:    DS  1 ; Set to 1 if game has ended
GameResult: DS  1 ; Game result. List of values is in game_screen.inc

; LSB FIRST!!!!
ScoreCounter::  DS  3 ; 20 bit should be more than enough (5 BCD)
SwapCounter:    DS  2 ; Number of movements performed
TimeCounter:    DS  2 ; Frames (1 second = aprox 60 frames)
TimeCounterFrameDivider:    DS  1 ; Divide between 60 to get seconds from frames

;--------------------------------

    SECTION "Main Screen VRAM Buffers",WRAM0[$C0A0] ; Align

; 32 columns (complete map) x 18 rows (the visible ones)
BoardVRAM:      DS  32*(18+2) ; This is modified instead of VRAM to speed up the drawing
BoardVRAM_GBC:  DS  32*(18+2)

BoardVRAM_Mutex:    DS 1 ; if 1, VBL won't update the screen

;--------------------------------------------------------------------------

    SECTION "Room Game Code Data",ROM0

;--------------------------------------------------------------------------

GeoTilesData:
    INCBIN	"data/geo_tiles.bin"
NUMBER_OF_FORMS EQU 6+1
GeoTilesNumber  EQU 4*2*NUMBER_OF_FORMS ; Tiles per frame * frames per form * number of forms

GeoTilesDMGData:
    INCBIN	"data/geo_tiles_dmg.bin"

GameBGTilesData:
    INCBIN	"data/game_bg_tiles.bin"
GameBGTilesNumber  EQU 76-56+1

GameBGMapData: ; tilemap first, attr map second
    INCBIN	"data/game_bg_map.bin"
GAME_BG_MAP_WIDTH   EQU 20
GAME_BG_MAP_HEIGHT  EQU 18

PauseBGMapData: ; tilemap first, attr map second
    INCBIN	"data/pause_bg_map.bin"
PAUSE_BG_MAP_WIDTH  EQU 20
PAUSE_BG_MAP_HEIGHT EQU 23

PAUSE_SCREEN_BASE_Y         EQU 32
PAUSE_SCREEN_BASE_Y_END     EQU 40
PAUSE_SCREEN_BASE_Y_LIMIT   EQU PAUSE_SCREEN_BASE_Y_END+(-8*8)
PAUSE_SCREEN_BASE_Y_WON     EQU PAUSE_SCREEN_BASE_Y_END+(-13*8)
PAUSE_SCREEN_BASE_Y_LOST    EQU PAUSE_SCREEN_BASE_Y_END+(-18*8)

PAUSE_SPACE_TILE    EQU 181
PAUSE_SELECT_TILE   EQU 189 ; ARROW

ComboBubbleTilesData:
    INCBIN  "data/combo_tiles.bin"
ComboBubblesTilesNumber  EQU 2*(9+1)

;--------------------------------------------------------------------------

GamePalettesBG:
    DW (0<<10)|(0<<5)|0, (20<<10)|(20<<5)|20, (10<<10)|(10<<5)|10, (0<<10)|(0<<5)|0
    DW (0<<10)|(0<<5)|0, 31, 20, 10
    DW (0<<10)|(0<<5)|0, (31<<10), (20<<10), (10<<10)
    DW (0<<10)|(0<<5)|0, (31<<5), (20<<5), (10<<5)
    DW (0<<10)|(0<<5)|0, (31<<10)|(31<<5), (20<<10)|(20<<5), (10<<10)|(10<<5)
    DW (0<<10)|(0<<5)|0, (31<<5)|31, (20<<5)|20, (10<<5)|10
    DW (0<<10)|(0<<5)|0, (31<<10)|31, (20<<10)|20, 10
    DW (31<<10)|(31<<5)|31, (20<<10)|(20<<5)|20, (10<<10)|(10<<5)|10, (0<<10)|(0<<5)|0

GamePalettesSPR:
    DW 0, (31<<10)|(31<<5)|31, (15<<10)|(15<<5)|15, (0<<10)|(0<<5)|0 ; combo 2-3
    DW 0, (31<<5), (15<<5), (0<<5) ; combo 4-5
    DW 0, (31<<5)|31, (15<<5)|15, (0<<5)|0 ; combo 6-7
    DW 0, 31, 15, 0 ; combo 8-9

;--------------------------------------------------------------------------

GameHandlerVBL:

    call    refresh_OAM

    ; Update graphics
    ld      a,[GamePaused]
    ld      hl,GameEnd
    or      a,[hl]
    and     a,a
    jr      nz,.paused_dont_update_vram
    call    Board_CopyVRAM ; not paused, update vram
    jr      .end_update_graphics
.paused_dont_update_vram
    call    PauseRefreshCursor ; update pause cursor
.end_update_graphics

    ; Update board animation
    ld      a,[GameLogicStatus]
    cp      a,STATUS_REGULAR
    jr      nz,.dont_update
    ld      a,[GamePaused]
    and     a,a
    jr      nz,.dont_update
    call    BoardUpdateAnim ; update if regular status and not paused
    call    ComboBubblesHandle
.dont_update:

;    call    rom_bank_push
    call    gbt_update
;    call    rom_bank_pop

    ret

;--------------------------------------------------------------------------

LoadMainGameScreen:: ; a = game mode

    ld      [GameMode],a ; save game mode

    ; Black screen
    call    SetPalettesAllBlack

    ; Disable interrupts
    di

    ; Clear buffers

    ld      bc,BOARD_SIZE
    ld      d,0
    ld      hl,BoardStatus
    call    memset

    ld      bc,BOARD_SIZE
    ld      d,0
    ld      hl,BoardMetatile
    call    memset

    ld      bc,32*18
    ld      d,0
    ld      hl,BoardVRAM
    call    memset

    ld      bc,32*18
    ld      d,0
    ld      hl,BoardVRAM_GBC
    call    memset

    ; Cleanup

    ld      bc,256+128
    ld      d,0
    ld      hl,$8000
    call    vram_memset

    ; Load

    ld      a,0
    ld      [BoardVRAM_Mutex],a

    ld      a,0
    ld      [GameLogicStatus],a

    ;ld      a,-(BOARD_X_OFFSET_TILES*16)
    ld      a,0
    ld      [rSCX],a
    ld      a,-(BOARD_Y_OFFSET_TILES*16)
    ld      [rSCY],a

    ld      a,[EnabledGBC]
    and     a,a
    jr      z,.load_dmg_tiles
    ; Load GBC tiles
    ld      hl,GeoTilesData
    jr      .end_load_tiles
.load_dmg_tiles:
    ; Load DMG tiles
    ld      hl,GeoTilesDMGData
.end_load_tiles:
    ld      de,256 ; Bank at 8800h
    ld      bc,GeoTilesNumber
    call    vram_copy_tiles

    ld      bc,GameBGTilesNumber
    ld      de,256+56 ; Bank at 8800h
    ld      hl,GameBGTilesData
    call    vram_copy_tiles

    ; Load game BG
    xor     a,a
    ld      [rVBK],a
    ld      de,BoardVRAM+32*2 ; copy to temporal buffer
    ld      hl,GameBGMapData
    ld      a,GAME_BG_MAP_HEIGHT
.loop_vbk0:
    push    af
    ld      bc,GAME_BG_MAP_WIDTH
    call    memcopy
    push    hl
    ld      hl,32-GAME_BG_MAP_WIDTH
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    pop     af
    dec     a
    jr      nz,.loop_vbk0

    ld      de,$9C00+32*2
    ld      hl,GameBGMapData ; Copy to VRAM (for DMG)
    ld      a,GAME_BG_MAP_HEIGHT
.loop_dmg:
    push    af
    ld      bc,GAME_BG_MAP_WIDTH
    call    vram_copy
    push    hl
    ld      hl,32-GAME_BG_MAP_WIDTH
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    pop     af
    dec     a
    jr      nz,.loop_dmg

    ; Attr map
    ld      a,[EnabledGBC]
    and     a,a
    jr      z,.skip_attr_1

    ld      a,1
    ld      [rVBK],a
    ld      de,BoardVRAM_GBC+32*2
    ld      hl,GameBGMapData+GAME_BG_MAP_WIDTH*GAME_BG_MAP_HEIGHT
    ld      a,GAME_BG_MAP_HEIGHT
.loop_vbk1:
    push    af
    ld      bc,GAME_BG_MAP_WIDTH
    call    memcopy
    push    hl
    ld      hl,32-GAME_BG_MAP_WIDTH
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    pop     af
    dec     a
    jr      nz,.loop_vbk1

.skip_attr_1:

    ; Load pause BG
    xor     a,a
    ld      [rVBK],a
    ld      de,$9800
    ld      hl,PauseBGMapData
    ld      a,PAUSE_BG_MAP_HEIGHT
.loop_vbk0_2:
    push    af
    ld      bc,PAUSE_BG_MAP_WIDTH
    call    vram_copy
    push    hl
    ld      hl,32-PAUSE_BG_MAP_WIDTH
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    pop     af
    dec     a
    jr      nz,.loop_vbk0_2

    ld      a,[EnabledGBC]
    and     a,a
    jr      z,.skip_attr_2

    ld      a,1
    ld      [rVBK],a
    ld      de,$9800
    ld      hl,PauseBGMapData+PAUSE_BG_MAP_WIDTH*PAUSE_BG_MAP_HEIGHT
    ld      a,PAUSE_BG_MAP_HEIGHT
.loop_vbk1_2:
    push    af
    ld      bc,PAUSE_BG_MAP_WIDTH
    call    vram_copy
    push    hl
    ld      hl,32-PAUSE_BG_MAP_WIDTH
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    pop     af
    dec     a
    jr      nz,.loop_vbk1_2

.skip_attr_2:

    ; Load text tiles
    call    LoadText

    ; Load sprites for combo bubbles
    call    ComboBubblesLoad

    ; Load cursor
    call    CursorLoad

    ; Load board
    call    BoardInit

    call    ResetScoreCounters ; This group of functions should be called after BoardInit
    call    RefreshSwapCounter
    call    RefreshTimeCounter
    call    RefreshScoreCounter
    call    ResetComboCounter

    xor     a,a
    ld      [GameEnd],a ; Game begin!
    ld      [GameRemoveAllFlagEnd],a
    ld      [GamePaused],a ; not paused

    ; Load palettes
    ld      b,144
    call    wait_ly

    ld      hl,GamePalettesBG
    ld      a,0
    call    bg_set_palette
    ld      a,1
    call    bg_set_palette
    ld      a,2
    call    bg_set_palette
    ld      a,3
    call    bg_set_palette
    ld      a,4
    call    bg_set_palette
    ld      a,5
    call    bg_set_palette
    ld      a,6
    call    bg_set_palette
    ld      a,7
    call    bg_set_palette

    ld      hl,GamePalettesSPR
    ld      a,0
    call    spr_set_palette
    ld      a,1
    call    spr_set_palette
    ld      a,2
    call    spr_set_palette
    ld      a,3
    call    spr_set_palette

    ld      a,%00011011
    ld      [rBGP],a
    ld      a,%11100000
    ld      [rOBP0],a
    ld      [rOBP1],a

    ; Enable interrupts
    ld      a,IEF_LCDC|IEF_VBLANK
    ld      [rIE],a

    xor     a,a
    ld      [rSTAT],a ; disable STAT interrupt for now, only used when in pause mode

    ld      bc,GameHandlerVBL
    call    irq_set_VBL
    ld      bc,$0000
    call    irq_set_LCD

    xor     a,a
    ld      [rIF],a ; clear interrupt flags

    ei

    ; Screen configuration
    ld      a,[LCDCF_GBC_MODE]
    or      a,LCDCF_BG9C00|LCDCF_WIN9800|LCDCF_OBJON|LCDCF_ON|LCDCF_OBJ8
    ld      [rLCDC],a

    ; Done
    ret

;--------------------------------------------------------------------------

COMBO_BUBBLE_SPR_TILE_BASE      EQU 64 ; bank in $8000
COMBO_BUBBLE_SPR_OAM_BASE       EQU 20 ; sprite number 20-...
COMBO_BUBBLES_FRAMES_DURATION   EQU 60 ; frames before disappearing

COMBO_BUBBLES_RAND_RANGE_X      EQU 64
COMBO_BUBBLES_RAND_RANGE_Y      EQU 32
COMBO_BUBBLES_RAND_BASE_X       EQU 8 + ((160-64-16)/2)
COMBO_BUBBLES_RAND_BASE_Y       EQU 16 + ((144-32-16)/2) - 16 ; move a bit to the top

ComboBubblesLoad:

    ld      bc,ComboBubblesTilesNumber
    ld      de,COMBO_BUBBLE_SPR_TILE_BASE ; Bank at 8000h
    ld      hl,ComboBubbleTilesData
    call    vram_copy_tiles

    xor     a,a
    ld      [ComboBubbleCountdown],a

    ret

; ------------------------

ComboBubblesCreate:

    ld      a,[CurrentCombo]
    call    SFX_DeleteLine

    ld      a,[CurrentCombo]
    cp      a,1
    jr      nz,.show ; if 1, don't show!
    call    ComboBubblesDelete
    ret
.show:

    ld      b,a ; b = multiplier

    ld      l,COMBO_BUBBLE_SPR_OAM_BASE
    call    sprite_get_base_pointer ; bc is preserved

    push    bc
    push    hl

    call    GetRandom
    and     a,COMBO_BUBBLES_RAND_RANGE_X-1
    add     a,COMBO_BUBBLES_RAND_BASE_X
    ld      d,a
    call    GetRandom
    and     a,COMBO_BUBBLES_RAND_RANGE_Y-1
    add     a,COMBO_BUBBLES_RAND_BASE_Y
    ld      e,a

    ; d = x, e = y
    pop     hl ; hl = OAM base
    pop     bc ; b = multiplier

    ; Left part

    ld      a,e
    ld      [hl+],a ; Y
    ld      a,d
    ld      [hl+],a ; X
    ld      a,COMBO_BUBBLE_SPR_TILE_BASE
    ld      [hl+],a ; Tile
    ld      a,b
    srl     a
    dec     a
    ld      [hl+],a ; Attr

    ld      a,e
    add     a,8
    ld      [hl+],a ; Y
    ld      a,d
    ld      [hl+],a ; X
    ld      a,COMBO_BUBBLE_SPR_TILE_BASE+1
    ld      [hl+],a ; Tile
    ld      a,b
    srl     a
    dec     a
    ld      [hl+],a ; Attr

    ; Right part

    ld      a,COMBO_BUBBLE_SPR_TILE_BASE
    add     a,b
    add     a,b
    ld      c,a

    ld      a,e
    ld      [hl+],a ; Y
    ld      a,d
    add     a,8+1
    ld      [hl+],a ; X
    ld      a,c
    ld      [hl+],a ; Tile
    ld      a,b
    srl     a
    dec     a
    ld      [hl+],a ; Attr

    ld      a,e
    add     a,8
    ld      [hl+],a ; Y
    ld      a,d
    add     a,8+1
    ld      [hl+],a ; X
    ld      a,c
    inc     a
    ld      [hl+],a ; Tile
    ld      a,b
    srl     a
    dec     a
    ld      [hl+],a ; Attr

    ld      a,COMBO_BUBBLES_FRAMES_DURATION
    ld      [ComboBubbleCountdown],a

    ret

; ------------------------

ComboBubblesHandle:

    ld      a,[ComboBubbleCountdown]
    and     a,a
    ret     z ; if zero, nothing to do

    dec     a
    ld      [ComboBubbleCountdown],a

    and     a,a
    ret     nz ; if not zero, don't delete

    ; Delete
    call    ComboBubblesDelete

    ret

; ------------------------

ComboBubblesDelete:

    ld      l,COMBO_BUBBLE_SPR_OAM_BASE
    call    sprite_get_base_pointer ; bc is preserved

    ; Left part

    xor     a,a
    ld      [hl+],a ; Y
    ld      [hl+],a ; X
    ld      [hl+],a ; Tile
    ld      [hl+],a ; Attr

    ld      [hl+],a ; Y
    ld      [hl+],a ; X
    ld      [hl+],a ; Tile
    ld      [hl+],a ; Attr

    ; Right part

    ld      [hl+],a ; Y
    ld      [hl+],a ; X
    ld      [hl+],a ; Tile
    ld      [hl+],a ; Attr

    ld      [hl+],a ; Y
    ld      [hl+],a ; X
    ld      [hl+],a ; Tile
    ld      [hl+],a ; Attr

    ret

;--------------------------------------------------------------------------

GameHandlerLCD_Pause:

    ld      a,[rLY]
    cp      a,PAUSE_SCREEN_BASE_Y-1
    jr      nz,.bottom_of_sign

    call    wait_screen_blank
    ld      a,[LCDCF_GBC_MODE]
    or      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_ON
    ld      [rLCDC],a
    ld      a,[GamePausedBaseSCY]
    ld      [rSCY],a

    ld      a,[GamePausedHeight]
    add     a,PAUSE_SCREEN_BASE_Y -1
    ld      [rLYC],a

    ret

.bottom_of_sign:

    call    wait_screen_blank
    ld      a,[LCDCF_GBC_MODE]
    or      a,LCDCF_BG9C00|LCDCF_OBJON|LCDCF_ON
    ld      [rLCDC],a
    ld      a,-(BOARD_Y_OFFSET_TILES*16)
    ld      [rSCY],a

    ld      a,PAUSE_SCREEN_BASE_Y -1
    ld      [rLYC],a

    ret

;--------------------------------------------------------------------------

GameHandlerLCD_End:

    ld      a,[rLY]
    cp      a,PAUSE_SCREEN_BASE_Y_END-1
    jr      nz,.bottom_of_sign

    call    wait_screen_blank
    ld      a,[LCDCF_GBC_MODE]
    or      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_ON
    ld      [rLCDC],a
    ld      a,[GamePausedBaseSCY]
    ld      [rSCY],a

    ld      a,[GamePausedHeight]
    add     a,PAUSE_SCREEN_BASE_Y_END -1
    ld      [rLYC],a

    ret

.bottom_of_sign:

    call    wait_screen_blank
    ld      a,[LCDCF_GBC_MODE]
    or      a,LCDCF_BG9C00|LCDCF_OBJON|LCDCF_ON
    ld      [rLCDC],a
    ld      a,-(BOARD_Y_OFFSET_TILES*16)
    ld      [rSCY],a

    ld      a,PAUSE_SCREEN_BASE_Y_END -1
    ld      [rLYC],a

    ret

;--------------------------------------------------------------------------

BoardInitFill:

    ; Init coarse

    ld  bc,BOARD_SIZE
    ld  hl,BoardStatus
.memset_rand:
    push    hl
    call    GetRandom
    and     a,7
    pop     hl
    cp      a,NUMBER_OF_FORMS
    jr      nc,.memset_rand
    ld      [hl+],a
    dec     bc
    ld      a,b
    or      a,c
    jr      nz,.memset_rand

    ; Fill
.fill:

    call    BoardInitHiddenRow
    call    BoardGravitySetFinalPosition
    call    BoardCheckLines
    call    BoardDeleteCompleteLines
    call    BoardIsFull
    and     a,a
    jr      z,.fill

    ; Clear hidden row to avoid bugs like not breaking combo chains when reloading.
    call    BoardClearHiddenRow

    ld      a,[GameMode]
    cp      a,GAME_MODE_REMOVE_ALL
    ret     nz ; if not mode remove all, exit

    ; if mode remove all, check if less than 3 of any form. if so, repeat all process!
    xor     a,a
    ld      [GameRemoveAllFlagEnd],a
    call    GameRemoveAllCountBlocks
    ld      a,[GameRemoveAllFlagEnd]
    and     a,a
    ret     z ; return if everything ok

    jr      BoardInitFill ; try again

;--------------------------------------------------------------------------

PrintSwapString:

    ld      hl,BoardVRAM + 32*(18+2-1) + 12 ; Pointer to start of word in VRAM buffer
    ld      a,"S"
    push    hl
    call    ASCII2Tile
    pop     hl
    ld      [hl+],a
    ld      a,"w"
    push    hl
    call    ASCII2Tile
    pop     hl
    ld      [hl+],a
    ld      a,"a"
    push    hl
    call    ASCII2Tile
    pop     hl
    ld      [hl+],a
    ld      a,"p"
    push    hl
    call    ASCII2Tile
    pop     hl
    ld      [hl+],a

    ret

PrintTimeString:

    ld      hl,BoardVRAM + 32*(18+2-1) + 12 ; Pointer to start of word in VRAM buffer
    ld      a,"T"
    push    hl
    call    ASCII2Tile
    pop     hl
    ld      [hl+],a
    ld      a,"i"
    push    hl
    call    ASCII2Tile
    pop     hl
    ld      [hl+],a
    ld      a,"m"
    push    hl
    call    ASCII2Tile
    pop     hl
    ld      [hl+],a
    ld      a,"e"
    push    hl
    call    ASCII2Tile
    pop     hl
    ld      [hl+],a

    ret

;--------------------------------------------------------------------------

BoardInit:

    call    BoardAnimInit ; Init animation

    call    BoardInitFill ; Load data

    ; Check game mode and configure

    ld      a,[GameMode]
    cp      a,GAME_MODE_REMOVE_ALL
    jr      nz,.not_remove_all

    ; Remove all
    ; ----------

    ld      a,0
    ld      [GameFillScreenMode],a ; Finite mode

    call    PrintTimeString

    ret

.not_remove_all:
    cp      a,GAME_MODE_SWAP_LIMIT
    jr      nz,.not_swap_limit

    ; Swap limit
    ; ----------

    ld      a,1
    ld      [GameFillScreenMode],a ; Infinite mode

    call    PrintSwapString

    ret

.not_swap_limit:
    ; Time limit
    ; ----------

    ld      a,1
    ld      [GameFillScreenMode],a ; Infinite mode

    call    PrintTimeString

    ret

;--------------------------------------------------------------------------

ResetScoreCounters:

    xor     a,a

    ld      hl,ScoreCounter
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a

    ld      hl,SwapCounter ; Load swaps
    ld      a,(GAME_SWAP_LIMIT_SWAPS)&$FF
    ld      [hl+],a
    ld      a,(GAME_SWAP_LIMIT_SWAPS>>8)&$FF
    ld      [hl+],a

    ld      a,60
    ld      [TimeCounterFrameDivider],a

    xor     a,a
    ld      hl,TimeCounter
    ld      [hl+],a
    ld      [hl+],a

    ld      a,[GameMode]
    cp      a,GAME_MODE_TIME_LIMIT
    ret     nz ; if not mode time limit, exit, else set counter to 100

    ld      hl,TimeCounter ; 300 seconds
    ld      a,(GAME_TIME_LIMIT_SECONDS)&$FF
    ld      [hl+],a
    ld      a,(GAME_TIME_LIMIT_SECONDS>>8)&$FF
    ld      [hl+],a

    ret

;--------------------------------------------------------------------------

RefreshSwapCounter:

    ld      a,[GameMode]
    cp      a,GAME_MODE_SWAP_LIMIT
    ret     nz ; if not mode swap limit, exit

    ; Update screen - print 3 numbers

    ld      hl,SwapCounter+1 ; LSB first
    ld      a,[hl-]

    ; hl now points to the LSB
    ; a holds MSB

    and     a,$0F
    BCD2Tile ; a = MSB
    ld      b,[hl] ; b = LSBs

    ld      hl,BoardVRAM + 32*(18+2-1) + 17 ; Pointer to start of word in VRAM buffer
    ld      [hl+],a

    ld      a,b
    swap    a
    and     a,$0F
    BCD2Tile
    ld      [hl+],a

    ld      a,b
    and     a,$0F
    BCD2Tile
    ld      [hl],a

    ret

IncreaseSwapCounter:

    ld      a,[GameMode]
    cp      a,GAME_MODE_SWAP_LIMIT
    ret     nz ; if not mode swap limit, exit

    ld      hl,SwapCounter ; LSB first
    ld      a,[hl]
    sub     a,1
    daa ; OMFG!!!
    ld      [hl+],a
    ld      a,[hl]
    sbc     a,0
    daa ; OMFG!!!
    ld      [hl],a

    call    RefreshSwapCounter

    ret

;--------------------------------------------------------------------------

RefreshTimeCounter:

    ld      a,[GameMode]
    cp      a,GAME_MODE_SWAP_LIMIT
    ret     z ; if mode swap limit, exit

    ; Update screen - print 3 numbers

    ld      hl,TimeCounter+1 ; LSB first
    ld      a,[hl-]

    ; hl now points to the LSB
    ; a holds MSB

    and     a,$0F
    BCD2Tile ; a = MSB
    ld      b,[hl] ; b = LSBs

    ld      hl,BoardVRAM + 32*(18+2-1) + 17 ; Pointer to start of word in VRAM buffer
    ld      [hl+],a

    ld      a,b
    swap    a
    and     a,$0F
    BCD2Tile
    ld      [hl+],a

    ld      a,b
    and     a,$0F
    BCD2Tile
    ld      [hl],a

    ret

IncreaseTimeCounter: ; inc/dec time counter. Called every frame (Divides between 60 internally)

    ld      a,[GameMode]
    cp      a,GAME_MODE_SWAP_LIMIT
    ret     z ; if mode swap limit, exit

    ld      hl,TimeCounterFrameDivider
    dec     [hl]
    ret     nz
    ld      [hl],60

    ld      a,[GameMode]
    cp      a,GAME_MODE_TIME_LIMIT
    jr      z,.time_limit_decrease

    ; Not time limit -> increase

    ld      hl,TimeCounter ; LSB first
    ld      a,$99
    sub     a,[hl]
    ld      b,a
    inc     hl
    ld      a,$09
    sub     a,[hl]
    or      a,b ; check if 999 reached
    ret     z

    ld      hl,TimeCounter ; LSB first
    ld      a,[hl]
    add     a,1
    daa ; OMFG!!!
    ld      [hl+],a
    ld      a,[hl]
    adc     a,0
    daa ; OMFG!!!
    ld      [hl],a

    call    RefreshTimeCounter

    ret

.time_limit_decrease:
    ld      hl,TimeCounter
    ld      a,[hl+]
    or      a,[hl]
    ret     z ; if it was 0 before, don't decrease

    ld      hl,TimeCounter ; LSB first
    ld      a,[hl]
    sub     a,1
    daa ; OMFG!!!
    ld      [hl+],a
    ld      a,[hl]
    sbc     a,0
    daa ; OMFG!!!
    ld      [hl],a

    call    RefreshTimeCounter

    ret

;--------------------------------------------------------------------------

RefreshScoreCounter:

    ; Update screen - print 5 numbers

    ld      hl,ScoreCounter ; LSB first
    ld      a,[hl+]
    ld      b,a ; b = LSBs
    ld      a,[hl+]
    ld      c,a ; c = CSBs
    ld      d,[hl] ; d = MSBs

    ld      hl,BoardVRAM + 32*(18+2-1) + 6 ; Pointer to start of word in VRAM buffer

    ld      a,$0F
    and     a,d
    BCD2Tile
    ld      [hl+],a

    ld      a,$F0
    and     a,c
    swap    a
    BCD2Tile
    ld      [hl+],a
    ld      a,$0F
    and     a,c
    BCD2Tile
    ld      [hl+],a

    ld      a,$F0
    and     a,b
    swap    a
    BCD2Tile
    ld      [hl+],a
    ld      a,$0F
    and     a,b
    BCD2Tile
    ld      [hl],a

    ret

AddScoreCounter: ; a = score to add

    ld      b,a ; b = score to add

    ld      a,[CurrentCombo]
    ld      c,a ; c = combo
.loop:
    ld      hl,ScoreCounter ; LSB first
    ld      a,[hl]
    add     a,b
    daa ; OMFG!!!
    ld      [hl+],a
    ld      a,[hl]
    adc     a,0
    daa ; OMFG!!!
    ld      [hl+],a
    ld      a,[hl]
    adc     a,0
    daa ; OMFG!!!
    ld      [hl+],a

    dec     c
    jr      nz,.loop

    ; Check if more than $099999

    ld      hl,ScoreCounter+2 ; MSB
    ld      a,$F0
    and     a,[hl]
    jr      z,.not_reached_limit
    ld      a,$09
    ld      [hl-],a
    ld      a,$99
    ld      [hl-],a
    ld      [hl],a

.not_reached_limit:
    call    RefreshScoreCounter

    ret

;--------------------------------------------------------------------------

ResetComboCounter:
    ld      a,1
    ld      [CurrentCombo],a

    ret

IncreaseComboCounter:
    ld      a,[CurrentCombo]
    inc     a
    cp      a,10
    jr      nz,.dont_clamp ; if 10, clamp to 9. Sorry :(
    ld      a,9
.dont_clamp:
    ld      [CurrentCombo],a

    ret

;--------------------------------------------------------------------------

BoardIsFull: ; returns 1 if filled, 0 if not
    ld  bc,BOARD_SIZE-BOARD_COLUMNS
    ld  hl,BoardStatus+BOARD_COLUMNS ; first row is ignored
.loop:
    ld      a,[hl+]
    and     a,a
    ret     z ; if there is a hole, return 0
    dec     bc
    ld      a,b
    or      a,c
    jr      nz,.loop

    ld      a,1
    ret

;--------------------------------------------------------------------------

BoardInitHiddenRow:

    ld      hl,BoardStatus
    ld      b,BOARD_COLUMNS
.loop:
    push    hl
.is_zero:
    call    GetRandom
    and     a,7
    and     a,a
    jr      z,.is_zero
    pop     hl
    cp      a,NUMBER_OF_FORMS
    jr      nc,.loop
    ld      [hl+],a
    dec     b
    jr      nz,.loop

    ret
;--------------------------------------------------------------------------

BoardClearHiddenRow:

    ld      hl,BoardStatus
    ld      b,BOARD_COLUMNS
    xor     a,a
.loop:
    ld      [hl+],a
    dec     b
    jr      nz,.loop

    ret
;--------------------------------------------------------------------------

BoardAnimInit: ; Inits animation to a pattern

    ; Reset buffers

    ld      bc,BOARD_SIZE
    ld      d,0
    ld      hl,BoardCountDown
    call    memset

    ld      bc,BOARD_SIZE
    ld      d,0
    ld      hl,BoardFrame
    call    memset

    ; Create pattern

    call    GetRandom
    and     a,1

    jr      nz,.second_animation

    ; First animation

    ld      hl,BoardCountDown

    ld      c,0 ; rows
.columns_loop_1:

    ld      b,0 ; columns
.rows_loop_1:

    ld      a,b
    add     a,c
    sla     a
    sla     a
    sla     a
    and     a,BOARD_ANIMATION_TICKS-1
    ld      [hl+],a

    inc     b
    ld      a,b
    cp      a,BOARD_COLUMNS
    jr      nz,.rows_loop_1

    inc     c
    ld      a,c
    cp      a,BOARD_ROWS
    jr      nz,.columns_loop_1

    ret

    ; Second animation

.second_animation:

    ld      hl,BoardCountDown

    ld      c,0 ; rows
.columns_loop_2:

    ld      b,0 ; columns
.rows_loop_2:

    ld      a,BOARD_COLUMNS
    sub     a,b
    add     a,c
    sla     a
    sla     a
    sla     a
    and     a,BOARD_ANIMATION_TICKS-1
    ld      [hl+],a

    inc     b
    ld      a,b
    cp      a,BOARD_COLUMNS
    jr      nz,.rows_loop_2

    inc     c
    ld      a,c
    cp      a,BOARD_ROWS
    jr      nz,.columns_loop_2

    ret

;--------------------------------------------------------------------------

Draw_Metatile_Board: ; Status + Frame -> Metatile

    ld      bc,BoardMetatile ; Destination

    ld      de,BoardStatus
    ld      hl,BoardFrame

    ld      a,BOARD_ROWS
.loop:
    push    af
    REPT    BOARD_COLUMNS
        ld      a,[de] ; get status
        sla     a ; tile = type * 2 + frame (0 or 1)

        add     a,[hl] ; add frame

        ld      [bc],a

        inc     bc
        inc     de
        inc     hl
    ENDR
    pop     af
    dec     a
    jr      nz,.loop

    ret

;--------------------------------------------------------------------------

Draw_VRAM_Board: ; Metatile -> Vram

    ld      a,1
    ld      [BoardVRAM_Mutex],a ; in use

    ; Draw board tiles
    ; ----------------

    ld      bc,BoardMetatile
    ld      hl,BoardVRAM+2 ; displace 2 tiles right

    ld      a,BOARD_ROWS
.loop_draw:
    push    af

    ld      de,32-2 ; Distance to next line, 2 columns before
    REPT    BOARD_COLUMNS
        ld      a,[bc]
        inc     bc
        sla     a
        sla     a ; a = metatile * 4

        ld      [hl+],a
        add     a,2
        ld      [hl+],a
        push    hl ; (*
        add     hl,de
        dec     a
        ld      [hl+],a
        add     a,2
        ld      [hl+],a
        pop     hl ; *)
    ENDR
    ld      de,32-(BOARD_COLUMNS*2)+32 ; extra space (in tiles) right to the board + extra row
    add     hl,de

    pop     af
    dec     a
    jp      nz,.loop_draw

    ld      a,[EnabledGBC]
    and     a,a
    jr      z,.skip_palettes ; don't update palettes in DMG

    ; Setup palettes
    ; --------------
    ld      bc,BoardMetatile
    ld      hl,BoardVRAM_GBC+2 ; displace 2 tiles right

    ld      a,BOARD_ROWS
.loop_pal:
    push    af

    ld      de,32-2 ; Distance to next line, 2 columns before
    REPT    BOARD_COLUMNS
        ld      a,[bc]
        inc     bc
        srl     a ; a = metatile / 2

        ld      [hl+],a
        ld      [hl+],a
        push    hl ; (*
        add     hl,de
        ld      [hl+],a
        ld      [hl+],a
        pop     hl ; *)
    ENDR
    ld      de,32-(BOARD_COLUMNS*2)+32 ; extra space (in tiles) right to the board + extra row
    add     hl,de

    pop     af
    dec     a
    jp      nz,.loop_pal

.skip_palettes:
    xor     a,a
    ld      [BoardVRAM_Mutex],a ; not in use

    ret

;--------------------------------------------------------------------------

BoardUpdateAnim:

    ld      de,BoardFrame
    ld      hl,BoardCountDown

    ld      a,BOARD_ROWS
.loop:
    push    af
    REPT    BOARD_COLUMNS
        ld      a,[hl]
        dec     [hl]
        and     a,a
        jr      nz,.skipanim\@

        ld      [hl],BOARD_ANIMATION_TICKS
        ld      a,[de] ; get status
        xor     a,1
        ld      [de],a
.skipanim\@:
        inc     de
        inc     hl
    ENDR
    pop     af
    dec     a
    jp      nz,.loop

    ret

;--------------------------------------------------------------------------

BoardUpdateAnimDeleting:

    ld      de,BoardFrame
    ld      hl,BoardChecking

    ld      a,BOARD_ROWS
.loop:
    push    af
    REPT    BOARD_COLUMNS
        ld      a,[hl+]
        and     a,a
        jr      z,.skipanim\@

        ld      a,[DeleteCountdown]
        srl     a
        srl     a
        and     a,1
        ld      [de],a

.skipanim\@:
        inc     de
    ENDR
    pop     af
    dec     a
    jp      nz,.loop

    ret

;--------------------------------------------------------------------------

BoardStatusGetPointer: ; b = x, c = y

    push    bc
    ld      a,BOARD_COLUMNS
    call    mul_u8u8u16 ; hl = y * BOARD_COLUMNS
    pop     bc ; b = x
    ld      c,b
    ld      b,0
    add     hl,bc ; hl = y * BOARD_COLUMNS + x
    ld      bc,BoardStatus
    add     hl,bc ; hl = BoardStatus + y * BOARD_COLUMNS + x

    ret

;--------------------------------------------------------------------------

SwapCursorBoard:

    ld      a,[CursorTileX]
    ld      b,a
    ld      a,[CursorTileY]
    ld      c,a
    call    BoardStatusGetPointer
    ld      d,h
    ld      e,l ; de = hl = base pointer

    ld      a,[CursorHorizontal]
    and     a,a
    jr      z,.vertical

    ; Horizontal
    inc     hl

    jr      .swapforms
.vertical:

    ; Vertical
    ld      bc,BOARD_COLUMNS
    add     hl,bc

.swapforms:

    ; de = left/top | hl = right/bottom

    ld      a,[de]
    ld      b,a
    ld      c,[hl]

    ld      [hl],b
    ld      a,c
    ld      [de],a

    ret

;--------------------------------------------------------------------------

BoardCheckLines: ; Returns number of lines

    ld      bc,BOARD_SIZE
    ld      d,0
    ld      hl,BoardChecking
    call    memset

    xor     a,a
    ld      [LastCheckLines],a

    ; Check rows
    ; ----------

    ld      de,BoardChecking+BOARD_COLUMNS ; FIRST ROW IS HIDDEN, DON'T CHECK
    ld      hl,BoardStatus+BOARD_COLUMNS ; FIRST ROW IS HIDDEN, DON'T CHECK

    ld      a,BOARD_ROWS-1 ; FIRST ROW IS HIDDEN, DON'T CHECK
.loop_1:
    push    af

    REPT    BOARD_COLUMNS_MINUS_2 ; there can't be any row of 3 when only 2 tiles left
        ld      a,[hl+]
        and     a,a ; if 0, exit
        jr      z,.end_check_row_0\@
        ld      b,a
        ld      a,[hl+]
        and     a,a ; if 0, exit
        jr      z,.end_check_row_1\@
        ld      c,a
        ld      a,[hl-]
        and     a,a ; if 0, exit
        jr      z,.end_check_row_0\@

        ; Check if a = b = c

        cp      a,b
        jr      nz,.end_check_row_0\@
        cp      a,c
        jr      nz,.end_check_row_0\@

        ; a = b = c, flag as equal

        ld      a,[LastCheckLines]
        inc     a
        ld      [LastCheckLines],a

        ld      a,1
        ld      [de],a
        inc     de
        ld      [de],a
        inc     de
        ld      [de],a
        dec     de
        jr      .end_check_row\@

.end_check_row_1\@:
        dec     hl
.end_check_row_0\@:
        inc     de
.end_check_row\@:
    ENDR

    inc     hl ; advance pointers to next row
    inc     hl
    inc     de
    inc     de

    pop     af
    dec     a
    jp      nz,.loop_1

    ; Check columns
    ; -------------

    ld      de,BoardChecking+BOARD_COLUMNS ; FIRST ROW IS HIDDEN, DON'T CHECK
    ld      hl,BoardStatus+BOARD_COLUMNS ; FIRST ROW IS HIDDEN, DON'T CHECK

    ld      bc,BOARD_COLUMNS ; to add to hl

    ld      a,BOARD_ROWS_MINUS_2-1 ; one of them is hidden, and 2 less because there can't be
    ; any columns of 3 if there are only 2 rows left
.loop_2:
    push    af

    REPT    BOARD_COLUMNS
        push    hl
        push    de

        ld      a,[hl]
        and     a,a
        jr      z,.end_check_col\@
        ld      d,a

        add     hl,bc
        ld      a,[hl]
        and     a,a
        jr      z,.end_check_col\@
        ld      e,a

        add     hl,bc
        ld      a,[hl]
        and     a,a
        jr      z,.end_check_col\@

        ; Check if a = d = e

        cp      a,d
        jr      nz,.end_check_col\@
        cp      a,e
        jr      nz,.end_check_col\@

        ; a = d = e, flag as equal

        ld      a,[LastCheckLines]
        inc     a
        ld      [LastCheckLines],a

        pop     hl ; hl = BoardChecking (previously in de)
        add     sp,-2 ; "push hl"

        ld      a,1
        ld      [hl],a
        add     hl,bc
        ld      [hl],a
        add     hl,bc
        ld      [hl],a

.end_check_col\@:
        pop     de ; next position
        inc     de
        pop     hl
        inc     hl
    ENDR

    pop     af
    dec     a
    jp      nz,.loop_2

    ; Return number of lines
    ld      a,[LastCheckLines]
    ret

;--------------------------------------------------------------------------

BoardDeleteCompleteLines:

    ld      hl,BoardChecking
    ld      de,BoardStatus

    ld      a,BOARD_ROWS*BOARD_COLUMNS
.loop_draw:
    push    af

    ld      a,[hl+]
    and     a,a
    jr      z,.dont_delete
    xor     a,a
    ld      [de],a ; delete
.dont_delete:
    inc     de

    pop     af
    dec     a
    jp      nz,.loop_draw

    ret

;--------------------------------------------------------------------------

BoardGravitySetFinalPosition: ; update logic buffer

    xor     a,a
    ld      [GravityHasUpdated],a

    ld      hl,BoardStatus + ( BOARD_ROWS -1 ) * BOARD_COLUMNS ; last map row
    ld      de,-BOARD_COLUMNS ; to subtract from hl

    ld      b,BOARD_ROWS
.loop_outer:

    push    hl

    ld      c,BOARD_COLUMNS

.loop_inner:
        ld      a,[hl] ; a = tile
        and     a,a

        jr      nz,.place_not_free

        ; if b == 1 special check (first row, load a 0 always)
        ld      a,1
        cp      a,b
        jr      z,.first_row
        push    hl
        add     hl,de
        ld      a,[hl]
        ld      [hl],0
        pop     hl
        jr      .end_row_check
.first_row:
        xor     a,a ; load a 0
.end_row_check:

        ld      [hl],a

        push    hl
        ld      hl,GravityHasUpdated
        or      a,[hl]
        ld      [hl],a ; if not the first tile, result != 0
        pop     hl
.place_not_free:

        inc     hl ; next tile

        dec     c
        jr      nz,.loop_inner

    pop     hl
    add     hl,de ; go to previous row

    dec     b
    jr      nz,.loop_outer

    ld      a,[GravityHasUpdated]
    and     a,a
    jr      nz,BoardGravitySetFinalPosition ; repeat until finished

    ret

;--------------------------------------------------------------------------

; animate VRAM buffer (no effect in game logic)
BoardGravityHandle: ; returns 1 if something has changed, 0 if not

    xor     a,a
    ld      [GravityHasUpdated],a

    ; last map row , first 2 columns are a border
    ld      hl,BoardVRAM + ( BOARD_ROWS*2 -1 ) * 32 + BOARD_X_OFFSET_TILES*2

    ld      de,-32 ; to subtract from hl

    ld      b,BOARD_ROWS*2+2 ; first 2 columns are a border
.loop_outer:

    push    hl

    ld      c,BOARD_COLUMNS*2

.loop_inner:
        ld      a,[hl]
        srl     a
        srl     a
        srl     a ; a = tile / 8 (first 2 metatiles)
        and     a,a

        jr      nz,.place_not_free

        ; if b == 1 special check (first row, load a 0 always)
        ld      a,1
        cp      a,b
        jr      z,.first_row
        push    hl
        add     hl,de
        ld      a,[hl]
        ld      [hl],0
        pop     hl
        jr      .end_row_check
.first_row:
        xor     a,a ; load a 0
.end_row_check:

        ld      [hl],a

        srl     a
        srl     a
        srl     a ; a = tile / 8 (first 2 metatiles)

        push    hl
        ld      hl,GravityHasUpdated
        or      a,[hl]
        ld      [hl],a ; if not the first 2 metatiles, result != 0
        pop     hl
.place_not_free:

        inc     hl ; next tile

        dec     c
        jr      nz,.loop_inner

    pop     hl
    add     hl,de ; go to previous row

    dec     b
    jr      nz,.loop_outer

    ; Now, update palettes
    ; --------------------

    ; last map row , first 2 columns are a border
    ld      hl,BoardVRAM_GBC + ( BOARD_ROWS*2 -1 ) * 32 + BOARD_X_OFFSET_TILES*2

    ld      de,-32 ; to subtract from hl

    ld      b,BOARD_ROWS*2
.loop_outer_pal:

    push    hl

    ld      c,BOARD_COLUMNS*2

.loop_inner_pal:
        ld      a,[hl]
        and     a,a ; a = pal

        jr      nz,.place_not_free_pal

        ; if b == 1 special check (first row, load a 0 always)
        ld      a,1
        cp      a,b
        jr      z,.first_row_pal
        push    hl
        add     hl,de
        ld      a,[hl]
        ld      [hl],0
        pop     hl
        jr      .end_row_check_pal
.first_row_pal:
        xor     a,a ; load a 0
.end_row_check_pal:

        ld      [hl],a
.place_not_free_pal:

        inc     hl ; next tile

        dec     c
        jr      nz,.loop_inner_pal

    pop     hl
    add     hl,de ; go to previous row

    dec     b
    jr      nz,.loop_outer_pal


    ld      a,[GravityHasUpdated]
    ret

;--------------------------------------------------------------------------

GameRemoveAllCountBlocks: ; Count all blocks for "remove all" mode game end conditions

    add     sp,-NUMBER_OF_FORMS ; one byte per form should be enough
    ld      hl,sp+0
    xor     a,a
    REPT    NUMBER_OF_FORMS
    ld      [hl+],a
    ENDR

    ld      de,BoardStatus+BOARD_COLUMNS ; First row should be empty, don't check

    ; Count blocks

    ld      b,0
    ld      a,BOARD_ROWS - 1 ; Don't check first row
.loop:
    push    af
    REPT    BOARD_COLUMNS
        ld      a,[de] ; get number
        inc     de

        ld      c,a
        ;ld      b,0
        ld      hl,sp+2 ; +2 because of the push af
        add     hl,bc
        inc     [hl]
    ENDR
    pop     af
    dec     a
    jr      nz,.loop

    ; Check counters
    ld      hl,sp+1
    ld      b,NUMBER_OF_FORMS-1 ; don't check index 0
.check_loop:
    ld      a,[hl+]
    cp      a,2
    jr      z,.remaining_2_or_1
    cp      a,1
    jr      z,.remaining_2_or_1
    dec     b
    jr      nz,.check_loop
    jr      .end_first_check

.remaining_2_or_1:
    ld      a,1
    ld      [GameRemoveAllFlagEnd],a
    ld      a,GAME_RESULT_LOSE
    ld      [GameResult],a

    ld      de,SongLose_data
    ld      a,3
    ld      bc,BANK(SongLose_data)
    call    gbt_play


    jr      .end
.end_first_check:


    ; Check counters to see if finished
    ld      c,0 ; if this is 0 at the end, game finished (and won)
    ld      hl,sp+1
    ld      b,NUMBER_OF_FORMS-1 ; don't check index 0
.check_loop_2:
    ld      a,[hl+]
    or      a,c
    ld      c,a
    dec     b
    jr      nz,.check_loop_2

    ld      a,c
    and     a,a
    jr      nz,.end_check_loop_2 ; if not 0, not won
    ld      a,1
    ld      [GameRemoveAllFlagEnd],a
    ld      a,GAME_RESULT_WIN
    ld      [GameResult],a

    ld      de,SongWin_data
    ld      a,4
    ld      bc,BANK(SongWin_data)
    call    gbt_play

.end_check_loop_2:


.end:

    add     sp,+NUMBER_OF_FORMS

    ret

;--------------------------------------------------------------------------

GameCheckEnd: ; returns 0 if not ended, != 0 if ended

    ld      a,[GameEnd]
    and     a,a
    ret     nz

    ld      a,[GameLogicStatus]
    cp      a,STATUS_REGULAR
    jr      z,.mode_regular
    xor     a,a
    ret
.mode_regular: ; game can only end if state machine in regular mode

    ; Check conditions for each game mode

    ld      a,[GameMode]
    cp      a,GAME_MODE_REMOVE_ALL
    jr      nz,.not_remove_all

        ; Remove all

        ld      a,[GameEnd]
        ld      b,a
        ld      a,[GameRemoveAllFlagEnd]
        xor     a,b
        call    nz,SetEndingSign ; if changed from 0 to 1

        ld      a,[GameRemoveAllFlagEnd]
        ld      [GameEnd],a

        ret

.not_remove_all:
    cp      a,GAME_MODE_SWAP_LIMIT
    jr      nz,.not_swap_limit

        ; Mode swap limit

        ld      hl,SwapCounter
        ld      a,[hl+]
        or      a,[hl]
        jr      z,.swap_end
        xor     a,a
        ret
.swap_end:

        ld      a,1
        ld      [GameEnd],a
        ld      a,GAME_RESULT_LIMIT
        ld      [GameResult],a
        call    SetEndingSign

        ld      de,SongWin_data
        ld      a,3
        ld      bc,BANK(SongWin_data)
        call    gbt_play

        ret

.not_swap_limit:

        ; Mode time limit

        ld      hl,TimeCounter
        ld      a,[hl+]
        or      a,[hl]
        jr      z,.time_end
        xor     a,a
        ret
.time_end:

        ld      a,1
        ld      [GameEnd],a
        ld      a,GAME_RESULT_LIMIT
        ld      [GameResult],a
        call    SetEndingSign

        ld      de,SongWin_data
        ld      a,3
        ld      bc,BANK(SongWin_data)
        call    gbt_play

        ret

;--------------------------------------------------------------------------

SetEndingSign: ; Reads GameResult and puts the corresponding sign

    call    CursorHide
    call    ComboBubblesDelete

    ld      a,PAUSE_SCREEN_BASE_Y -1
    ld      [rLYC],a
    ld      a,STATF_LYC
    ld      [rSTAT],a

    ld      bc,GameHandlerLCD_End
    call    irq_set_LCD

    ld      a,[GameResult]
    cp      a,GAME_RESULT_LIMIT
    jr      nz,.not_limit

        ; Limit

        ld      a,-PAUSE_SCREEN_BASE_Y_LIMIT
        ld      [GamePausedBaseSCY],a

        ld      a,5*8
        ld      [GamePausedHeight],a

        ret

.not_limit:
    cp      a,GAME_RESULT_WIN
    jr      nz,.not_win

        ; Win

        ld      a,(-PAUSE_SCREEN_BASE_Y_WON)&$FF
        ld      [GamePausedBaseSCY],a

        ld      a,5*8
        ld      [GamePausedHeight],a

        ret

.not_win:

        ; Lose

        ld      a,(-PAUSE_SCREEN_BASE_Y_LOST)&$FF
        ld      [GamePausedBaseSCY],a

        ld      a,5*8
        ld      [GamePausedHeight],a

        ret

;--------------------------------------------------------------------------

PauseSet:

    ld      a,1
    ld      [GamePaused],a

    call    CursorHide
    call    ComboBubblesDelete

    ld      a,PAUSE_SCREEN_BASE_Y -1
    ld      [rLYC],a
    ld      a,STATF_LYC
    ld      [rSTAT],a

    ld      a,0
    ld      [GamePauseCursor],a

    ld      a,-PAUSE_SCREEN_BASE_Y
    ld      [GamePausedBaseSCY],a

    ld      a,8*8
    ld      [GamePausedHeight],a

    ld      bc,GameHandlerLCD_Pause
    call    irq_set_LCD

    ret

PauseUnset:

    ld      a,0
    ld      [GamePaused],a

    call    CursorShow

    xor     a,a
    ld      [rSTAT],a

    ld      bc,$0000
    call    irq_set_LCD

    ret

PauseRefreshCursor:

    ld      a,[GamePauseCursor]
    and     a,a
    jr      z,.continue
        ; Exit
        ;call    wait_screen_blank ; even if HBL it's ending, there should be enough time in mode 2

        ld      a,PAUSE_SPACE_TILE
        ld      [$9800 + 4*32 + 3],a
        ld      a,PAUSE_SELECT_TILE
        ld      [$9800 + 5*32 + 3],a

        ret
.continue:
        ; Continue
        ;call    wait_screen_blank ; even if HBL it's ending, there should be enough time in mode 2

        ld      a,PAUSE_SELECT_TILE
        ld      [$9800 + 4*32 + 3],a
        ld      a,PAUSE_SPACE_TILE
        ld      [$9800 + 5*32 + 3],a

        ret

;--------------------------------------------------------------------------

PauseHandle:

    ld      a,[GamePaused]
    and     a,a
    jr      nz,.paused

    ; Not paused
    ; ----------

        ld      a,[joy_pressed]
        and     a,PAD_START
        jr      z,.pause_handle_end ; start not pressed, exit

        ; Start pressed, pause and load pause menu

        call    PauseSet

        jr      z,.pause_handle_end

.paused:

    ; Paused
    ; ------

        ld      a,[joy_pressed]
        and     a,PAD_START
        jr      z,.start_not_pressed ; start not pressed, continue

        ; Start pressed, unpause and unload pause menu

        call    PauseUnset

        ld      a,1
        ret ; return 1 to prevent the main loop from running this frame

        jr      .pause_handle_end
.start_not_pressed:

        ; Start not pressed, check other buttons

        ld      a,[joy_pressed]
        and     a,PAD_UP|PAD_DOWN
        jr      z,.up_down_not_pressed

        ; Up or down pressed

        ld      a,1 ; swap cursor position
        ld      hl,GamePauseCursor
        xor     a,[hl]
        ld      [hl],a


        jr      z,.pause_handle_end
.up_down_not_pressed:

        ; Up or down not pressed, check other buttons

        ld      a,[joy_pressed]
        and     a,PAD_A
        jr      z,.pause_handle_end ; if A is not pressed, exit

        ; A is pressed, check position and unpause or exit

        ld      a,[GamePauseCursor]
        and     a,1
        jr      nz,.selected_exit

            ; Selected continue
            call    PauseUnset

            ld      a,1
            ret ; return 1 to prevent the main loop from running this frame

            jr      z,.pause_handle_end

.selected_exit:

            ; Selected exit
            call    PauseUnset

            ld      a,1
            ld      [GameEnd],a
            ld      a,GAME_RESULT_MANUAL
            ld      [GameResult],a

            ld      a,1
            ret ; return 1 to prevent the main loop from running this frame

            jr      z,.pause_handle_end

    ; End
    ; ---

.pause_handle_end:

    ld      a,[GamePaused]
    ret

;--------------------------------------------------------------------------

Board_Handle:: ; returns 0 if game continues, 

    ; If game has ended, return game result
    ld      a,[GameEnd]
    and     a,a
    jr      z,.not_end
    ld      a,[GameResult]
    ret
.not_end:

    ; Check PAUSE
    call    PauseHandle ; returns 1 if pause
    and     a,a
    jp      nz,.board_handle_end

    ; Check game end conditions
    call    GameCheckEnd

    ; Switch game status
    ld      a,[GameLogicStatus]
    and     a,a
    jr      nz,.not_zero

    ; Regular status - STATUS_REGULAR - 0
    ; --------------

        ; Increase time counter
        call    IncreaseTimeCounter ; only count time in regular mode!

        ; Update Cursor
        call    CursorHandle
        and     a,a
        jr      z,.not_changed ; if 2 blocks have to be changed, check board

        ; For swap limit game mode
        call    IncreaseSwapCounter

        ; Swap blocks
        call    SwapCursorBoard

        ; Check Board
        call    ResetComboCounter
        call    BoardCheckLines
        and     a,a

        ld      a,STATUS_GRAVITY
        ld      [GameLogicStatus],a

        ; Clear hidden row to avoid bugs like not breaking combo chains when reloading.
        call    BoardClearHiddenRow
.not_changed:

        ; Refresh buffers
        call    Draw_Metatile_Board
        call    Draw_VRAM_Board

        ; Update board animation
        ;call    BoardUpdateAnim - Done in VBL handler

        jr      .board_handle_end

.not_zero:
    cp      a,1
    jr      nz,.not_one

    ; Removing completed lines (animation) - STATUS_REMOVE_LINES - 1
    ; ------------------------------------

        ; Update Cursor
        call    CursorHandle

        ; Update animation
        call    BoardUpdateAnimDeleting

        ld      hl,DeleteCountdown
        dec     [hl]
        jr      nz,.not_finished_state_one
        ; Animation has finished
        call    BoardDeleteCompleteLines

        ; Refresh screen with gravity
        ld      a,STATUS_GRAVITY
        ld      [GameLogicStatus],a

        ; Clear hidden row to avoid bugs like not breaking combo chains when reloading.
        call    BoardClearHiddenRow
.not_finished_state_one:

        ; Refresh buffers
        call    Draw_Metatile_Board
        call    Draw_VRAM_Board

        jr      .board_handle_end

.not_one:

    ; Gravity - STATUS_GRAVITY - 2
    ; -------

        ; Update Cursor
        call    CursorHandle

        call    BoardGravityHandle
        and     a,a
        jr      nz,.not_finished_state_two

        call    BoardGravitySetFinalPosition
        ; Refresh buffers
        call    Draw_Metatile_Board
        call    Draw_VRAM_Board

        call    BoardCheckLines
        and     a,a
        jr      z,.not_changed_state_2
        call    AddScoreCounter ; a = score
        call    ComboBubblesCreate ; bubble shows the combo that has happened
        call    IncreaseComboCounter

        ld      a,STATUS_REMOVE_LINES
        ld      [GameLogicStatus],a
        ld      a,DELETE_COUNTDOWN_TICKS
        ld      [DeleteCountdown],a

        jr      .board_handle_end
.not_changed_state_2:

        ; Finished moving forms. Check if we have to add more forms to screen

        ; If infinite mode, add rows until the screen is full
        ld      a,[GameFillScreenMode]
        and     a,a
        jr      z,.finished_state_two

        call    ResetComboCounter ; reset combo
        call    BoardInitHiddenRow ; add row
        call    Draw_Metatile_Board ; update
        call    Draw_VRAM_Board
        call    BoardIsFull ; until the screen is full, add lines
        and     a,a
        jr      z,.not_finished_state_two

.finished_state_two:
        ld      a,STATUS_REGULAR
        ld      [GameLogicStatus],a

        ; If mode remove all, check game end
        ld      a,[GameMode]
        cp      a,GAME_MODE_REMOVE_ALL
        call    z,GameRemoveAllCountBlocks

.not_finished_state_two:
        jr      .board_handle_end

.board_handle_end:
    ld      a,GAME_RESULT_NOT_FINISHED
    ret

;--------------------------------------------------------------------------

Board_CopyVRAM::

    ld      a,[BoardVRAM_Mutex]
    and     a,a
    ret     nz ; if not 0, this is being used

    ld      a,[EnabledGBC]
    and     a,a
    jr      z,.not_gbc

    xor     a,a
    ld      [rVBK],a
    DMA_COPY    BoardVRAM, $9C00, 32*(18+2), 0

    ld      a,1
    ld      [rVBK],a
    DMA_COPY    BoardVRAM_GBC, $9C00, 32*(18+2), 0
    xor     a,a
    ld      [rVBK],a

    ret

.not_gbc:

    ; OK, not GBC, let's perform a SUPER FAST COPY without DMA!
    ; ---------------------------------------------------------

    ; This works because the GBC has to calculate the palettes for each form
    ; and copy them to the BG attribute map, while the DMG only has to calculate
    ; the tile numbers,

    ; First, let's perform a POP/LD copy... We are in VBL, so interrupts are not a problem.
    ld      hl,sp+0
    ld      b,h
    ld      c,l ; save sp in bc

ITERATION SET 2
    REPT    9 ; lines to be copied without checking (during VBL)
        ld      hl,$9C00+2+32*ITERATION
        ld      sp,BoardVRAM+2+32*ITERATION
        REPT    8
            pop     de
            ld      [hl],e
            inc     hl
            ld      [hl],d
            inc     hl
        ENDR
ITERATION SET ITERATION+1
    ENDR

    ld      h,b
    ld      l,c
    ld      sp,hl ; restore sp from bc

    ; Nitro loop: Force copy to VRAM and read back to check if it was copied ok.
    ; First used by nitro2k01, recommendation by beware :P
;ITERATION SET 11
    REPT    9 ; lines to be copied while checking
    ld      hl,$9C00+2+32*ITERATION
    ld      de,BoardVRAM+2+32*ITERATION
        REPT    16;BOARD_ROWS*2 ; 2 tiles per row
            ld      a,[de]
            inc     de
.repeat\@:
            ld      [hl],a
            cp      a,[hl]
            jr      nz,.repeat\@
            inc     hl
        ENDR
ITERATION SET ITERATION+1
    ENDR

    ; Copy score and time/swaps - Checking
    ld      hl,$9C00+32*19+6
    ld      de,BoardVRAM+32*19+6
    ld      b,14
.loop_s:

    ld      a,[de]
    inc     de
.repeat_s:
    ld      [hl],a
    cp      a,[hl]
    jr      nz,.repeat_s

    inc     hl

    dec     b
    jr      nz,.loop_s

    ; End!
    ret

;--------------------------------------------------------------------------

GameScreenMainLoop:: ; a = game type. Returns game result

    call    LoadMainGameScreen

    ld      de,SongGame_data
    ld      a,4
    ld      bc,BANK(SongGame_data)
    call    gbt_play

    ld      a,1
    call    gbt_loop

    ; Game loop
.loop:
    call    wait_vbl
    call    scan_keys
    call    KeyAutorepeatHandle

    call    Board_Handle
    cp      a,GAME_RESULT_NOT_FINISHED
    jr      z,.loop

    ; Game finished

    call    CursorHide

    ; If game ended manually, exit now. If not, wait one second and wait
    ; until the user presses

    ld      a,[GameResult]
    cp      a,GAME_RESULT_MANUAL
    ret     z ; return with a = GAME_RESULT_MANUAL

    ; Wait one second

    ld      e,60
    call    wait_frames

    ; Wait until the user presses any key

.loop_press:
    call    wait_vbl
    call    scan_keys
    call    KeyAutorepeatHandle

    ld      a,[joy_held]
    and     a,a
    jr      z,.loop_press

    ; End
    call    gbt_stop

    ; Disable interrupts
    di

    ld      a,[GameResult] ; Return with game result
    ret

;--------------------------------------------------------------------------

