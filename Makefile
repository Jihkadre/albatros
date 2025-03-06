# ----------------------------------------------
# Target

TARGET ?= demo

OPTIONS ?=

TARGET_MCU ?= STM32F446xx

TARGET_MCU_FAMILY ?= STM32F4

DEBUG = -g3

OPT = -O0

OCDFLAGS   = -f board/stm32f4discovery.cfg

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

VPATH = $(SRC_DIR) $(MODULE_DIR)/libopencm3

LDSCRIPT = $(SRC_DIR)/linkerscript.ld

# ----------------------------------------------
# Includes

include $(MAKE_DIR)/utils.mk

# ----------------------------------------------
# Compiler, Assembler and linker flags

CFLAGS = $(DEVICE_FLAGS) \
		$(addprefix -D,$(OPTIONS)) \
		$(addprefix -I,$(INC_DIRS)) \
		-D$(TARGET_MCU) \
		-D$(TARGET_MCU_FAMILY) \
		$(DEBUG) \
		$(OPT) \
		-Wall -Wextra -Werror -Wunsafe-loop-optimizations -Wdouble-promotion \
		-fdata-sections \
		-ffunction-sections \
		-ffreestanding \
		-flto \
		-MMD -MP

ASFLAGS = $(DEVICE_FLAGS) \
		-x assembler-with-cpp \
		$(addprefix -I,$(INC_DIRS)) \
		-MMD -MP

LIBNAME		= opencm3_stm32f1
LDLIBS		+= -l$(LIBNAME)
LDFLAGS		+= -L$(OPENCM3_DIR)/lib

TGT_LDFLAGS		+= --static -nostartfiles
TGT_LDFLAGS		+= -T$(LDSCRIPT)
TGT_LDFLAGS		+= $(ARCH_FLAGS) $(DEBUG)
TGT_LDFLAGS		+= -Wl,-Map=$(*).map -Wl,--cref
TGT_LDFLAGS		+= -Wl,--gc-sections
ifeq ($(V),99)
TGT_LDFLAGS		+= -Wl,--print-gc-sections
endif

LDLIBS		+= -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group

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
	@$(CC) $(TGT_LDFLAGS) $(LDFLAGS) $(OBJS) $(LDLIBS) -o $@ || (echo "\e[31m[ERROR] Linking failed: $@\e[0m"; exit 1)

$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	@echo "\e[34m[OBJCOPY] Creating binary $@\e[0m"
	@$(OBJCOPY) -O binary $< $@ || (echo "\e[31m[ERROR] Binary creation failed: $@\e[0m"; exit 1)
	@echo "\e[36m[SIZE] Firmware size:\e[0m"
	@$(SIZE) -A $< || (echo "\e[31m[ERROR] Size calculation failed: $<\e[0m"; exit 1)

# ----------------------------------------------
# Make directives

.DEFAULT_GOAL := help
.PHONY: clean help

clean:
	@echo "Cleaning objects and binary files"
	@rm -rf $(OBJS) $(DEPS) $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).bin

help:
	@echo "Albatros"

# ----------------------------------------------
# Documentation

.PHONY: doxygen

doxygen:
	@mkdir -p $(BUILD_DIR)
	@cd $(DOC_DIR) && doxygen Doxyfile