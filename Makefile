#####################################################################
##                           ROM NAME                              ##

NAME = geometrix
EXT	 = gbc

##                                                                 ##
#####################################################################

#####################################################################
##                    PATH TO RGBDS BINARIES                       ##

RGBASM  = ../rgbasm
RGBLINK = ../rgblink
RGBFIX  = ../rgbfix

##                                                                 ##
#####################################################################

#####################################################################
##        Source and include folders - including subfolders        ##

SOURCE = ./source

##                                                                 ##
#####################################################################

BIN	:= $(NAME).$(EXT)

MYSOURCES := $(shell find $(SOURCE) -type d -print)
SOURCES := $(foreach dir,$(MYSOURCES),$(CURDIR)/$(dir))

ASMFILES := $(foreach dir,$(SOURCES),$(wildcard $(dir)/*.asm))

# Make it include all source folders - Add a '/' at the end of the path
INCLUDES := $(foreach dir,$(MYSOURCES),-i$(CURDIR)/$(dir)/)

# Prepare object paths
OBJ = $(ASMFILES:.asm=.obj)

all: $(BIN)

rebuild:
	@make clean
	@make
	@rm -f $(OBJ)

clean:
	@echo rm $(OBJ) $(BIN) $(NAME).sym $(NAME).map
	@rm -f $(OBJ) $(BIN) $(NAME).sym $(NAME).map

# TODO: Remove the -h when RGBASM is updated to remove it
%.obj : %.asm
	@echo rgbasm $@ $<
	@$(RGBASM) $(INCLUDES) -h -o$@ $<

$(BIN): $(OBJ)
	@echo rgblink $(BIN)
	@$(RGBLINK) -o $(BIN) -p 0xFF -m $(NAME).map -n $(NAME).sym $(OBJ)
	@echo rgbfix $(BIN)
	@$(RGBFIX) -p 0xFF -v $(BIN)

#####################################################################

