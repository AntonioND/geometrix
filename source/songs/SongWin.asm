
; File created by mod2gbt

    SECTION "SongWin_0",ROMX
SongWin_0:
    DB  $9D,$1F, $91,$2F, $20, $4A,$04
    DB  $9D,$92,$02, $42,$02, $00, $20
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $98,$1F, $91,$2F, $00, $00
    DB  $98,$92,$02, $91,$A2,$02, $00, $00
    DB  $9D,$1F, $91,$2F, $00, $00
    DB  $9D,$92,$02, $91,$A2,$02, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $A1,$1F, $91,$2F, $00, $00
    DB  $A1,$92,$02, $91,$A2,$02, $00, $00
    DB  $A4,$1F, $8C,$2F, $00, $00
    DB  $A4,$92,$02, $8C,$A2,$02, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $9C,$1F, $90,$2F, $00, $00
    DB  $9C,$92,$02, $90,$A2,$02, $00, $00
    DB  $9C,$1F, $90,$2F, $00, $00
    DB  $9C,$92,$02, $90,$A2,$02, $00, $00
    DB  $9C,$1F, $90,$2F, $00, $00
    DB  $9C,$92,$02, $90,$A2,$02, $00, $00
    DB  $9D,$1F, $91,$2F, $00, $00
    DB  $9D,$92,$02, $91,$A2,$02, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $91,$1F, $85,$2F, $00, $00
    DB  $91,$92,$02, $85,$A2,$02, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00
    DB  $00, $00, $00, $00

  SECTION "SongWin_data",ROMX
SongWin_data::
  DB  BANK(SongWin_0)
  DW  SongWin_0
  DB  $00
  DW  $0000
