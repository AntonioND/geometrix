
;--------------------------------------------------------------------------

    INCLUDE "hardware.inc"
    INCLUDE "engine.inc"

    INCLUDE "room_game.inc"

;--------------------------------------------------------------------------

    SECTION "Room Menu Variables",WRAM0

;--------------------------------------------------------------------------

MenuSelection:  DS  1 ; selected option

FlashAnimationCountdown:    DS  1
FlashAnimationSelected: DS  1
FlashAnimIndex: DS  1

FLASH_DELAY_CREATE_ANIMATION        EQU 16
FLASH_DELAY_CREATE_ANIMATION_RANGE  EQU 32 ; power of 2

FLASH_DELAY_ANIMATION_FRAMES    EQU 4

FLASH_ANIMATION_DISABLED    EQU -1

;--------------------------------------------------------------------------

    SECTION "Room Game Code Data",ROMX

;--------------------------------------------------------------------------

MenuBGTilesData:
    INCBIN	"data/menu_bg_tiles.bin"
MenuBGTilesNumber  EQU 33-0+1
MenuBGTilesDataDMG:
    INCBIN	"data/menu_bg_tiles_dmg.bin"

MenuBGMapData: ; tilemap first, attr map second
    INCBIN	"data/menu_bg_map.bin"
MENU_BG_MAP_WIDTH   EQU 20
MENU_BG_MAP_HEIGHT  EQU 18

MENU_SPACE_TILE    EQU 181
MENU_SELECT_TILE   EQU 189 ; ARROW

FlashTilesData:
    INCBIN	"data/flash_tiles.bin"
FlashTilesNumber  EQU 5*4 ; 5 tiles

;--------------------------------------------------------------------------

MenuPalettesBG:
    DW (31<<10)|(31<<5)|31, (20<<10)|(20<<5)|20, (10<<10)|(10<<5)|10, (0<<10)|(0<<5)|0
    DW 31, 20, 10, 0
    DW (31<<5), (20<<5), (10<<5), (0<<5)
    DW (31<<10), (20<<10), (10<<10), (0<<10)
    DW (31<<5)|31, (20<<5)|20, (10<<5)|10, (0<<5)|0
    DW (31<<10)|31, (20<<10)|20, (10<<10)|10, (0<<10)|0
    DW (31<<10)|(31<<5), (20<<10)|(20<<5), (10<<10)|(10<<5), (0<<10)|(0<<5)
    DW (31<<10)|(31<<5)|31, (20<<10)|(20<<5)|20, (10<<10)|(10<<5)|10, (0<<10)|(0<<5)|0

MenuPalettesSPR:
    DW 0, (31<<10)|(31<<5)|31, (15<<10)|(31<<5)|31, (31<<5)|31

;--------------------------------------------------------------------------

MenuHandlerVBL:

    call    refresh_OAM

    call    RefreshCursor

;    call    rom_bank_push
    call    gbt_update
;    call    rom_bank_pop

    ret

;--------------------------------------------------------------------------

LoadMenuTiles::

    ld      a,[EnabledGBC]
    and     a,a
    jr      z,.not_gbc
    ld      hl,MenuBGTilesData
    jr      .end_check_color
.not_gbc:
    ld      hl,MenuBGTilesDataDMG
.end_check_color:
    ld      de,256 ; Bank at 8800h
    ld      bc,MenuBGTilesNumber
    call    vram_copy_tiles

    ld      bc,FlashTilesNumber
    ld      de,0 ; Bank at 8000h
    ld      hl,FlashTilesData
    call    vram_copy_tiles

    ret

LoadMenuPalettes::

    ld      a,%00011011
    ld      [rBGP],a
    ld      a,%11100100
    ld      [rOBP0],a
    ld      [rOBP1],a

    ld      hl,MenuPalettesBG
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

    ld      hl,MenuPalettesSPR
    ld      a,0
    call    spr_set_palette

    ret

LoadMenuScreen:

    ; Black screen
    call    SetPalettesAllBlack

    ; Disable interrupts
    di

    ; Load BG
    call    LoadMenuTiles

    xor     a,a
    ld      [rVBK],a
    ld      de,$9800
    ld      hl,MenuBGMapData
    ld      a,MENU_BG_MAP_HEIGHT
.loop_vbk0:
    push    af
    ld      bc,MENU_BG_MAP_WIDTH
    call    vram_copy
    push    hl
    ld      hl,32-MENU_BG_MAP_WIDTH
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
    ld      [rVBK],a
    ld      de,$9800
    ld      hl,MenuBGMapData+MENU_BG_MAP_WIDTH*MENU_BG_MAP_HEIGHT
    ld      a,MENU_BG_MAP_HEIGHT
.loop_vbk1:
    push    af
    ld      bc,MENU_BG_MAP_WIDTH
    call    vram_copy
    push    hl
    ld      hl,32-MENU_BG_MAP_WIDTH
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    pop     af
    dec     a
    jr      nz,.loop_vbk1

.skip_attr:

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    ; Load text tiles
    call    LoadText

    ld      a,FLASH_DELAY_CREATE_ANIMATION
    ld      [FlashAnimationCountdown],a

    ld      a,FLASH_ANIMATION_DISABLED
    ld      [FlashAnimationSelected],a
    ld      [FlashAnimIndex],a

    ; Load palettes
    ld      b,144
    call    wait_ly

    call    LoadMenuPalettes

    ; Set cursor to first option (we are in VBL, after palettes)
    ld      a,0
    ld      [MenuSelection],a

    call    RefreshCursor

    ; Enable interrupts
    ld      a,IEF_VBLANK
    ld      [rIE],a

    ld      bc,MenuHandlerVBL
    call    irq_set_VBL

    ei

    ; Screen configuration
    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_ON|LCDCF_OBJ16
    ld      [rLCDC],a

    ld      a,[EnabledGBC]
    and     a,a
    ret     nz ; this config is enough for GBC, but not DMG

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_ON|LCDCF_OBJ16|LCDCF_BGON
    ld      [rLCDC],a

    ; Done
    ret

;--------------------------------------------------------------------------

FlashAnimations: ; 4 animations - Metatiles
    DB  1,2,1,2
    DB  3,4,3,4
    DB  1,3,4,3
    DB  3,1,2,1

FlashCoordinates: ; 8 coordinates
    DB  16,48
    DB  32,32
    DB  48,48
    DB  66,32
    DB  90,56
    DB  98,24
    DB  120,40
    DB  144,24

;--------------------------------------------------------------------------

FlashDelete:

    ld      l,0
    call    sprite_get_base_pointer ; bc is preserved
    xor     a,a
    ld      [hl+],a
    ld      [hl+],a
    inc     hl
    inc     hl

    ld      [hl+],a
    ld      [hl+],a

    ret

;--------------------------------

FlashesHandle:

    ld      a,[FlashAnimationCountdown]
    dec     a
    ld      [FlashAnimationCountdown],a
    ret     nz

    ld      a,[FlashAnimationSelected]
    cp      a,FLASH_ANIMATION_DISABLED
    jr      nz,.animate

    ; Create
    ; ------

    call    GetRandom
    and     a,3
    ld      [FlashAnimationSelected],a
    xor     a,a
    ld      [FlashAnimIndex],a

    ld      hl,FlashAnimations
    ld      a,[FlashAnimationSelected]
    ld      c,a
    ld      b,0
    add     hl,bc
    add     hl,bc
    ld      a,[FlashAnimIndex]
    ld      c,a
    ld      b,0
    add     hl,bc
    ld      a,[hl] ; a = metatile
    sla     a
    sla     a
    ld      b,a ; b = base tile

    push    bc

    call    GetRandom
    and     a,7
    ld      hl,FlashCoordinates
    ld      c,a
    ld      b,0
    add     hl,bc
    add     hl,bc

    ld      a,[hl+]
    ld      e,[hl] ; Y
    ld      d,a ; X

    push    de
    ld      l,0
    call    sprite_get_base_pointer
    pop     de
    pop     bc

    ld      a,e
    ld      [hl+],a ; Y
    ld      a,d
    ld      [hl+],a ; X
    ld      a,b
    ld      [hl+],a ; Tile
    xor     a,a
    ld      [hl+],a ; Attr

    ld      a,e
    ld      [hl+],a ; Y
    ld      a,d
    add     a,8
    ld      [hl+],a ; X
    ld      a,b
    add     a,2
    ld      [hl+],a ; Tile
    xor     a,a
    ld      [hl+],a ; Attr

    ld      a,FLASH_DELAY_ANIMATION_FRAMES
    ld      [FlashAnimationCountdown],a
    ret
.animate:

    ; Animate
    ; -------

    ld      a,[FlashAnimIndex]
    inc     a
    ld      [FlashAnimIndex],a

    cp      a,4
    jr      nz,.not_end

    ; End of animation
    ld      a,FLASH_ANIMATION_DISABLED
    ld      [FlashAnimationSelected],a

    call    GetRandom
    and     a,FLASH_DELAY_CREATE_ANIMATION_RANGE-1
    add     a,FLASH_DELAY_CREATE_ANIMATION
    ld      [FlashAnimationCountdown],a

    call    FlashDelete


    ret

.not_end:

    ; Refresh

    ld      a,FLASH_DELAY_ANIMATION_FRAMES
    ld      [FlashAnimationCountdown],a

    ld      hl,FlashAnimations
    ld      a,[FlashAnimationSelected]
    ld      c,a
    ld      b,0
    add     hl,bc
    add     hl,bc
    ld      a,[FlashAnimIndex]
    ld      c,a
    ld      b,0
    add     hl,bc
    ld      a,[hl] ; a = metatile
    sla     a
    sla     a
    ld      b,a ; b = base tile

    ld      l,0
    call    sprite_get_base_pointer ; bc is preserved
    inc     hl
    inc     hl
    ld      a,b
    ld      [hl+],a ; Tile
    inc     hl

    inc     hl
    inc     hl
    ld      a,b
    add     a,2
    ld      [hl+],a ; Tile
    inc     hl

    ret

;--------------------------------------------------------------------------

CursorOffsetAray:
    DB  32*0,32*1,32*2, 32*4, 32*6

RefreshCursor:

    ; Clear possible positions

    ld      a,MENU_SPACE_TILE
    ld      hl,$9800 + 32*9 + 3
    ld      de,32
    ld      [hl],a
    add     hl,de
    ld      [hl],a
    add     hl,de
    ld      [hl],a
    add     hl,de
    add     hl,de
    ld      [hl],a
    add     hl,de
    add     hl,de
    ld      [hl],a

    ; Draw cursor

    ld      a,[MenuSelection]
    ld      c,a
    ld      b,0
    ld      hl,CursorOffsetAray
    add     hl,bc
    ld      c,[hl] ; read from array
    ld      hl,$9800 + 32*9 + 3
    add     hl,bc

    ld      a,MENU_SELECT_TILE
    ld      [hl],a

    ret

;--------------------------------------------------------------------------

CursorHandle:

    ld      a,[joy_pressed]
    and     a,PAD_UP
    jr      z,.not_pad_up ; not pressed
    ld      a,[MenuSelection]
    and     a,a
    jr      z,.not_pad_up ; limit reached
    dec     a
    ld      [MenuSelection],a
;    call    SFX_ChangeOption
.not_pad_up:

    ld      a,[joy_pressed]
    and     a,PAD_DOWN
    jr      z,.not_pad_down ; not pressed
    ld      a,[MenuSelection]
    cp      a,4
    jr      z,.not_pad_down ; limit reached
    inc     a
    ld      [MenuSelection],a
;    call    SFX_ChangeOption
.not_pad_down:

    ret

;--------------------------------------------------------------------------

MenuHandle:

    call    CursorHandle

    call    FlashesHandle

    ret

;--------------------------------------------------------------------------

MenuScreenMainLoop:: ; returns the room to switch to

    call    LoadMenuScreen

    ld      de,SongMenu_data
    ld      a,6
    ld      bc,BANK(SongMenu_data)
    call    gbt_play

    ; Game loop
.loop:
    call    wait_vbl
    call    scan_keys
    call    KeyAutorepeatHandle

    call    GetRandom ; randomize, for emulators that don't have random initial values of RAM

    call    MenuHandle

    ld      a,[joy_pressed]
    and     a,PAD_A|PAD_START
    jr      z,.loop ; if A or START are pressed, exit

    ; End
    call    gbt_stop

    ; Disable interrupts
    di

    ; Remove sprites
    call    FlashDelete

    ; Load next room to register A
    ld      a,[MenuSelection]
    ret

;--------------------------------------------------------------------------

