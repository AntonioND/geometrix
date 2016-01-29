
;--------------------------------------------------------------------------

    INCLUDE "hardware.inc"
    INCLUDE "engine.inc"

    INCLUDE "gbt_player.inc"

;--------------------------------------------------------------------------

    SECTION "SFX Variables",WRAM0

;--------------------------------------------------------------------------

SFX_Countdown:  DS  1
TIMER_COUNTDOWN         EQU     3 ; 4kHz, TIMA = 0, TMA = 0
TIMER_COUNTDOWN_MENU    EQU     2 ; 4kHz, TIMA = 0, TMA = 0

;--------------------------------------------------------------------------

    SECTION "SFX Code",ROM0

;--------------------------------------------------------------------------

SFX_TimerHandler:

    ld      a,[SFX_Countdown]
    dec     a
    ld      [SFX_Countdown],a
    ret     nz

    ld      a,[rIE]
    and     a,(~IEF_TIMER)&$FF
    ld      [rIE],a

    xor     a,a
    ld      [rNR12],a ; volume 0
    xor     a,a
    ld      [rNR14],a ; disable

    ld      a,8|4|2|1 ; enable all channels
    call    gbt_enable_channels

    ret

;--------------------------------------------------------------------------

ComboFrequencies:; C5 onwards
    DW  1546, 1575, 1602, 1627, 1650, 1673, 1694, 1714, 1732 ;, 1750, 1767, 1783

SFX_DeleteLine:: ; a = combo

    push    af ; (*

    ld      bc,SFX_TimerHandler
    call    irq_set_TIM

    ld      a,8|4|2 ; disable channel 1
    call    gbt_enable_channels

    xor     a,a
    ld      [rTMA],a
    ld      a,TACF_START|TACF_4KHZ
    ld      [rTAC],a
    xor     a,a
    ld      [rTIMA],a
    ld      a,TIMER_COUNTDOWN
    ld      [SFX_Countdown],a

    ld      a,$80
    ld      [rNR52],a ; sound on
    ld      a,$77
    ld      [rNR50],a ; volume max for both speakers
    ld      a,$FF
    ld      [rNR51],a ; enable all channels in both speakers

    ld      a,(1<<4) | (0<<3) | 7
    ld      [rNR10],a ; sweep : time, subtract, 7 sweeps
    ld      a,(1<<6)
    ld      [rNR11],a ; duty, lenght (unused)

    ld      a,(15<<4) ; 100% volume, no envelope
    ld      [rNR12],a

    pop     af ;*)
    ; a = combo
    dec     a ; combo = 0 doesn't exist, the lowest value is 1.
    ; adjust to array index 0

        ld      c,a
        ld      b,0
        ld      hl,ComboFrequencies
        add     hl,bc
        add     hl,bc
        ld      c,[hl]
        inc     hl
        ld      b,[hl]

    ld      a,c
    ld      [rNR13],a ; freq low
    ld      a,b
    or      a,$80 ; enable
    ld      [rNR14],a ; freq high, enable, don't use length

    ; Enable interrupt
    ld      a,[rIE]
    or      a,IEF_TIMER
    ld      [rIE],a

    ret

;--------------------------------------------------------------------------

IF  0

SFX_ChangeOption:: ; For menues
    ld      bc,SFX_TimerHandler
    call    irq_set_TIM

    ld      a,8|4|2 ; disable channel 1
    call    gbt_enable_channels

    xor     a,a
    ld      [rTMA],a
    ld      a,TACF_START|TACF_4KHZ
    ld      [rTAC],a
    xor     a,a
    ld      [rTIMA],a
    ld      a,TIMER_COUNTDOWN_MENU
    ld      [SFX_Countdown],a

    ld      a,$80
    ld      [rNR52],a ; sound on
    ld      a,$77
    ld      [rNR50],a ; volume max for both speakers
    ld      a,$FF
    ld      [rNR51],a ; enable all channels in both speakers

    ld      a,0
    ld      [rNR10],a ; disable sweep
    ld      a,(1<<6)
    ld      [rNR11],a ; duty, lenght (unused)
    ld      a,(15<<4) ; 100% volume, no envelope
    ld      [rNR12],a

    ld      bc,1546 ; C6
    ld      a,c
    ld      [rNR13],a ; freq low
    ld      a,b
    or      a,$80 ; enable
    ld      [rNR14],a ; freq high, enable, don't use length

    ; Enable interrupt
    ld      a,[rIE]
    or      a,IEF_TIMER
    ld      [rIE],a

    ret

ENDC

;--------------------------------------------------------------------------


