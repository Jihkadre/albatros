ifeq 		($(TARGET_MCU_FAMILY), STM32F1)
ARCH_FLAGS  = -mcpu=cortex-m3 -mthumb -msoft-float
LIBS		= -lopencm3_stm32f1
else ifeq 	($(TARGET_MCU_FAMILY), STM32F4)
ARCH_FLAGS  = -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard
LIBS		= -lopencm3_stm32f4
else
$(error "Target MCU Family unsupported!")
endif
