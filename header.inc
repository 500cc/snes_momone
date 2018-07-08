;LoROM
.MEMORYMAP
  SLOTSIZE $8000
  DEFAULTSLOT 0
  SLOT 0 $8000
.ENDME

.ROMBANKSIZE $8000
.ROMBANKS 8

.SNESHEADER
  ID "SNES"

  NAME "snes momone          "

  SLOWROM
  LOROM

  CARTRIDGETYPE $00
  ROMSIZE $08
  SRAMSIZE $00
  COUNTRY $00
  LICENSEECODE $00
  VERSION $00
.ENDSNES

.SNESNATIVEVECTOR
  COP empty_handler
  BRK empty_handler
  ABORT empty_handler
  NMI v_blank
  IRQ empty_handler
.ENDNATIVEVECTOR

.SNESEMUVECTOR
  COP empty_handler
  ABORT empty_handler
  NMI empty_handler
  RESET start
  IRQBRK empty_handler
.ENDEMUVECTOR

.BANK 0 SLOT 0
.ORG 0
.SECTION "empty_vectors" SEMIFREE

empty_handler:
        rti
.ENDS

.EMPTYFILL $00