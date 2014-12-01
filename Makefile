# All the files will be generated with this name (main.elf, main.bin, main.hex, etc)
PROJECT_NAME = main

MAIN_SRC = src
FREERTOS_SRC = FreeRTOS
STM32_SRC = STM32F3DISCOVERY

# Startup file
STARTUP = $(STM32_SRC)/startup_stm32f30x.s

# All source files
SRCS = $(STARTUP)

SRCS += $(MAIN_SRC)/main.c
SRCS += $(MAIN_SRC)/errno.c
SRCS += $(MAIN_SRC)/stm32f30x_it.c
SRCS += $(MAIN_SRC)/stm32f3_discovery.c
SRCS += $(MAIN_SRC)/system_stm32f30x.c

SRCS += $(FREERTOS_SRC)/croutine.c
SRCS += $(FREERTOS_SRC)/event_groups.c
SRCS += $(FREERTOS_SRC)/list.c
SRCS += $(FREERTOS_SRC)/queue.c
SRCS += $(FREERTOS_SRC)/tasks.c
SRCS += $(FREERTOS_SRC)/timers.c
#SRCS += $(wildcard $(FREERTOS_SRC)/Common/Minimal/*.c)
SRCS += $(FREERTOS_SRC)/portable/GCC/ARM_CM4F/port.c
SRCS += $(FREERTOS_SRC)/portable/MemMang/heap_2.c

# Location of the Libraries
STM32_LIB = $(STM32_SRC)/Libraries
FREERTOS_LIB = $(FREERTOS_SRC)/include
#FREERTOS_COMMON_LIB = $(FREERTOS_SRC)/Common/include

# Location of the linker scripts
LDSCRIPTS = $(STM32_SRC)/ldscripts

# Location of OpenOCD Board .cfg files (only used with 'make program')
OPENOCD_BOARD_DIR = /usr/share/openocd/scripts/board

# Configuration (cfg) file containing programming directives for OpenOCD
OPENOCD_PROC_FILE = $(STM32_SRC)/stm32f3-openocd.cfg

###################################################

CC = arm-none-eabi-gcc
LD = arm-none-eabi-ld
GDB = arm-none-eabi-gdb
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump
SIZE = arm-none-eabi-size

# CPU Architecture
CFLAGS = -mcpu=cortex-m4 -march=armv7e-m -mtune=cortex-m4 -mthumb -mlittle-endian
CFLAGS += -mfpu=fpv4-sp-d16 -mfloat-abi=hard

CFLAGS + = -Wall -g -std=c99 -O3 -v 
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -fno-common

# STM32_StdPeriph_Driver
CFLAGS += -DSTM32F30X
CFLAGS += -DUSE_STDPERIPH_DRIVER
CFLAGS += -D"assert_param(expr)=((void)0)"

define get_library_path
    $(shell dirname $(shell $(CC) $(CFLAGS) -print-file-name=$(1)))
endef
LDFLAGS += -L $(call get_library_path,libc.a)
LDFLAGS += -L $(call get_library_path,libgcc.a)

LDFLAGS += --gc-sections -Map=$(PROJECT_NAME).map --verbose

###################################################

vpath %.a $(STM32_LIB) $(FREERTOS_LIB)

CFLAGS += -I $(MAIN_SRC)
CFLAGS += -I $(FREERTOS_LIB)
#CFLAGS += -I $(FREERTOS_COMMON_LIB)
CFLAGS += -I $(FREERTOS_SRC)/portable/GCC/ARM_CM4F
CFLAGS += -I $(STM32_SRC)
CFLAGS += -I $(STM32_LIB)
CFLAGS += -I $(STM32_LIB)/CMSIS/Device/ST/STM32F30x/Include
CFLAGS += -I $(STM32_LIB)/CMSIS/Include
CFLAGS += -I $(STM32_LIB)/STM32F30x_StdPeriph_Driver/inc
CFLAGS += -I $(STM32_LIB)/STM32_USB-FS-Device_Driver/inc

OBJS = $(addprefix objs/,$(addsuffix .o,$(basename $(SRCS))))

###################################################

.PHONY: all image program debug clean

all: image

image: $(PROJECT_NAME).elf

objs/%.o: %.c
	mkdir -p $(dir $@)
	@echo "    CC    "$(notdir $@)
	$(CC) $(CFLAGS) -c $< -o $@
    
objs/%.o: %.s
	mkdir -p $(dir $@)
	@echo "    CC      "$(notdir $@)
	@$(CC) $(CFLAGS) -c $< -o $@    
    
$(PROJECT_NAME).elf: $(OBJS)
	@echo "    LD      "$(notdir $@)
	@$(LD) -o $@ $(OBJS) \
		--start-group $(LIBS) --end-group \
		$(LDFLAGS) \
        -L$(STM32_LIB) -lstm32f3 -L$(LDSCRIPTS) -Tstm32f3.ld
        
	#$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@ $(STARTUP) -L$(STM32_LIB) -lstm32f3 -L$(LDSCRIPTS) -Tstm32f3.ld
	$(OBJCOPY) -O ihex $(PROJECT_NAME).elf $(PROJECT_NAME).hex
	$(OBJCOPY) -O binary $(PROJECT_NAME).elf $(PROJECT_NAME).bin
	$(OBJDUMP) -St $(PROJECT_NAME).elf >$(PROJECT_NAME).lst
	$(SIZE) $(PROJECT_NAME).elf

program: all
	openocd -f $(OPENOCD_BOARD_DIR)/stm32f3discovery.cfg -f $(OPENOCD_PROC_FILE) -c "stm_flash `pwd`/$(PROJECT_NAME).bin" -c shutdown

debug: program
	$(GDB) -x extra/gdb_cmds $(PROJECT_NAME).elf

clean:
	rm -r -f objs
	rm -f $(PROJECT_NAME).elf
	rm -f $(PROJECT_NAME).hex
	rm -f $(PROJECT_NAME).bin
	rm -f $(PROJECT_NAME).map
	rm -f $(PROJECT_NAME).lst
