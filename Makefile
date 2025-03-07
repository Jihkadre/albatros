# ----------------------------------------------
# Target

TARGET ?= demo

OPTIONS ?=

TARGET_MCU_FAMILY ?= STM32F4

DEBUG = -g3

OPT = -O0

# ----------------------------------------------
# Folder structure

ROOT         := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
BUILD_DIR    := $(ROOT)/build
DOC_DIR      := $(ROOT)/doc
MODULE_DIR   := $(ROOT)/modules
SRC_DIR      := $(ROOT)/src
MAKE_DIR	 := $(ROOT)/mk

# ----------------------------------------------
# Cross Compiler or Native Build
# Folder structure

TOOLCHAIN_ROOT ?=
PREFIX  := $(TOOLCHAIN_ROOT)arm-none-eabi-
CC      := $(PREFIX)gcc
AS 		:= $(PREFIX)as
CXX     := $(PREFIX)g++
OBJCOPY := $(PREFIX)objcopy
OBJDUMP := $(PREFIX)objdump
SIZE    := $(PREFIX)size
GDB 	:= $(PREFIX)gdb

# ----------------------------------------------
# Sources, Includes

SRCS = main.c

INC_DIRS = $(SRC_DIR) \
		$(MODULE_DIR)/libopencm3/include

VPATH = $(SRC_DIR)

LDSCRIPT = $(SRC_DIR)/linkerscript.ld

# ----------------------------------------------
# Includes

include $(MAKE_DIR)/utils.mk
include $(MAKE_DIR)/family.mk

# ----------------------------------------------
# Compiler, Assembler and linker flags

CFLAGS = $(ARCH_FLAGS) \
		$(addprefix -D,$(OPTIONS)) \
		$(addprefix -I,$(INC_DIRS)) \
		-D$(TARGET_MCU_FAMILY) \
		-Wall -Wextra -Werror \
		-fdata-sections \
		-ffunction-sections \
		$(DEBUG) \
		$(OPT)

ASFLAGS = $(ARCH_FLAGS) \
		$(addprefix -I,$(INC_DIRS)) \
		-Wall -Wextra -Werror \
		-fdata-sections \
		-ffunction-sections

LIBDIR		= -L$(MODULE_DIR)/libopencm3/lib

LDFLAGS		= --static \
			-nostartfiles \
			-T$(LDSCRIPT) \
			$(LIBDIR) $(LIBS) \
			$(ARCH_FLAGS) $(DEBUG) \
			-Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref \
 			-Wl,--gc-sections \
			-Wl,--print-memory-usage

$(info $(LDFLAGS))
$(info $(CFLAGS))
$(info $(ASFLAGS))

# ----------------------------------------------
# OpenOCD Flags

OCDINTER  = -f interface/stlink-v2.cfg
OCDTARGET = -f target/stm32f4x.cfg

OCDFLAGS	= $(OCDINTER) $(OCDTARGET)

# ----------------------------------------------
# Object and Dependecies

OBJS		= $(addprefix $(BUILD_DIR)/objs/, $(SRCS:.c=.o))
OBJS	   += $(addprefix $(BUILD_DIR)/objs/, $(STARTUP_FILE:.s=.o))
DEPS		= $(addprefix $(BUILD_DIR)/objs/, $(SRCS:.c=.d))
DEPS	   += $(addprefix $(BUILD_DIR)/objs/, $(STARTUP_FILE:.s=.d))

# ----------------------------------------------
# Target ("Ordular, ilk hedefiniz Akdeniz'dir, ileri!")

.PHONY: all dirs 

all: $(BUILD_DIR)/$(TARGET).bin

dirs: $(BUILD_DIR)/objs

$(BUILD_DIR)/objs:
	@echo "\e[34m[MKDIR] Creating directory $@\e[0m"
	@mkdir -p $@

$(BUILD_DIR)/objs/%.o: %.c | dirs
	@echo "\e[33m[CC] Compiling $(notdir $<)\e[0m"
	@$(CC) -c $(CFLAGS) $< -o $@ || (echo "\e[31m[ERROR] Compilation failed: $(notdir $<)\e[0m"; exit 1)

$(BUILD_DIR)/objs/%.o: %.s | dirs
	@echo "\e[35m[AS] Assembling $(notdir $<)\e[0m"
	@$(CC) -c $(ASFLAGS) $< -o $@ || (echo "\e[31m[ERROR] Assembly failed: $(notdir $<)\e[0m"; exit 1)

$(BUILD_DIR)/$(TARGET).elf: $(OBJS)
	@echo "\e[32m[LD] Linking $@\e[0m"
	@$(CC) $(OBJS) $(LDFLAGS) -o $@ || (echo "\e[31m[ERROR] Linking failed: $@\e[0m"; exit 1)

$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	@echo "\e[34m[OBJCOPY] Creating binary $@\e[0m"
	@$(OBJCOPY) -O binary $< $@ || (echo "\e[31m[ERROR] Binary creation failed: $@\e[0m"; exit 1)
	@echo "\e[36m[SIZE] Firmware size:\e[0m"
	@$(SIZE) -A -x  $<

# ----------------------------------------------
# Make directives

.DEFAULT_GOAL := help

.PHONY: clean help flash debug

clean:
	@echo "Cleaning objects and binary files"
	@rm -rf $(OBJS) $(DEPS) $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).bin

help:
	@echo "Albatros"

flash:
	openocd $(OCDFLAGS) -c "program build/demo.bin 0x08000000 reset exit"

debug:
	openocd $(OCDFLAGS)

# ----------------------------------------------
# Documentation

.PHONY: doxygen

doxygen:
	@mkdir -p $(BUILD_DIR)
	@cd $(DOC_DIR) && doxygen Doxyfile