# ----------------------------------------------
# Utils

UNAME = $(shell uname)

# https://stackoverflow.com/a/51149133
# Linux
ifeq ($(UNAME), Linux)
	NPROCS = $(shell grep -c 'processor' /proc/cpuinfo)
	MAKEFLAGS += -j$(NPROCS)
# macOSX
else ifeq ($(UNAME), Darwin)
	NPROCS = $(shell sysctl hw.ncpu  | grep -o '[0-9]\+')
	MAKEFLAGS += -j$(NPROCS)
endif