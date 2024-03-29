## Name your project
NAME = paneltest
FILES = $(NAME).c
HEADERS = 

## Point this to the directory where you did
##   git clone git://github.com/esmil/oniudra-headers.git arduino
ARDUINO_HEADERS = .

## Change this according to your code to make the tty and cat targets work
#BAUD     = 9600
BAUD     = 115200
#BAUD     = 230400
#BAUD     = 2400
MODE     = $(MODE_RAW) $(MODE_8) $(MODE_N) $(MODE_1)# 8n1

## Uncomment your arduino version below

# Duemilanove
MCU       = atmega328p
F_CPU     = 16000000UL
PORT      = /dev/ttyUSB0
PROG      = arduino
PROG_BAUD = 57600

## Uno
#MCU       = atmega328p
#F_CPU     = 16000000UL
#PORT      = /dev/ttyACM0
#PROG      = arduino
#PROG_BAUD = 115200

CC      = avr-gcc
OBJCOPY = avr-objcopy
OBJDUMP = avr-objdump
NM      = avr-nm
AVRDUDE = avrdude
STTY    = stty
SED     = sed
CAT     = cat

MODE_RAW = raw -echo -hup
MODE_7   = cs7
MODE_8   = cs8
MODE_N   = -parenb
MODE_E   = parenb -parodd
MODE_O   = parenb parodd
MODE_1   = -cstopb
MODE_2   = cstopb

PROG_arduino = -D -P$(PORT) -b$(PROG_BAUD)
PROG_avrispmkII = -Pusb

OPT        = 3
CFLAGS     = -O$(OPT) -pipe -gdwarf-2
CFLAGS    += -mmcu=$(MCU) -DF_CPU=$(F_CPU) -I$(ARDUINO_HEADERS)
CFLAGS    += -fstrict-aliasing
CFLAGS    += -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums
## Uncomment to create listing file
#CFLAGS    += -Wa,-adhlns=$(<:.c=.lst)
CFLAGS    += -Wall -Wextra -Wno-unused -Wno-variadic-macros -pedantic

LDFLAGS    = -Wl,--relax
## Uncomment to create a map file
#LDFLAGS   += -Wl,-Map=$(NAME).map,--cref
## Uncomment for minimal printf suport
#LDFLAGS   += -Wl,-u,vfprintf -lprintf_min
## Uncomment for printf support with floating point (needs -lm below)
#LDFLAGS   += -Wl,-u,vfprintf -lprintf_flt
## Uncomment for minimal scanf support
#LDFLAGS   += -Wl,-u,vfscanf -lscanf_min
## Uncomment for scanf support with floating point (needs -lm below)
#LDFLAGS   += -Wl,-u,vfscanf -lscanf_flt
## Uncomment for trigonometry and other floating point functions
LDFLAGS   += -lm

.PHONY: all list tty cat
.PRECIOUS: %.elf

all: $(NAME).hex

$(NAME).elf: $(FILES) $(HEADERS)
	@echo '  CC $@'
	@$(CC) $(CFLAGS) $(FILES) -o $@ $(LDFLAGS)

%.hex: %.elf
	@echo '  OBJCOPY $@'
	@$(OBJCOPY) -O ihex -R .eeprom -S $< $@
	@echo "  $$((0x$$($(OBJDUMP) -h $@ | $(SED) -n '6{s/^  0 \.sec1         //;s/ .*//;p}'))) bytes"

%.bin: %.elf
	@echo '  OBJCOPY $@'
	@$(OBJCOPY) -O binary -R .eeprom -S $< $@

# Create extended listing file from ELF output file.
%.lss: %.elf
	@echo '  OBJDUMP > $@'
	@$(OBJDUMP) -h -S $< > $@

# Create a symbol table from ELF output file.
%.sym: %.elf
	@echo '  NM $@'
	@$(NM) -n $< > $@

upload: $(NAME).hex
	$(AVRDUDE) -v -p$(MCU) -c$(PROG) $(PROG_$(PROG)) -Uflash:w:$<:i

upload5: $(NAME)5.hex
	$(AVRDUDE) -v -p$(MCU) -c$(PROG) $(PROG_$(PROG)) -Uflash:w:$<:i

list: $(NAME).lss

tty: $(PORT)
	@echo '  STTY -F$(PORT) $(MODE) $(BAUD)'
	@$(STTY) -F$(PORT) $(MODE) $(BAUD)

cat: $(PORT)
	@$(CAT) $(PORT)

clean:
	rm -f *.elf *.hex *.bin *.map *.lst *.lss *.sym
