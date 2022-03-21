#
# Template GNU Makefile for example FPGA design host programs that use the
# ADXDMA API (Linux)
#
# (C) Copyright 2018 Alpha Data
#
# Available targets:
# ------------------
#
#   all           - Builds executable
#   clean         - Removes executable and object files
#
# MAKE variables or environment variables recognized by this Makefile:
#
#   NAME          - (Required) The name of the executable built by this Makefile.
#   BIARCH        - If value is yes, builds for bi-archtecture 64-bit system
#                   (i.e. both 32-bit and 64-bit binaries are created).
#   SYSROOT       - If specified, is the root of the target filesystem;
#                   typically used when cross-building.
#   CROSS_COMPILE - Prefix before tools, e.g. arm-linux-; typically used when
#                   cross-building. If cross-building, the target platform'script
#                   toolchain must be in the PATH.
#

TARGET=$(NAME)
TARGET32=$(NAME)32

CXXFLAGS = -g -Wall -O6 -I$(SDK_LOCATION)/host/adxdma-$(ADXDMA_VER)/include -I$(SDK_LOCATION)/host/app_framework-$(APP_FRAMEWORK_VER)/include
LIBDEPS = -ladxdma -lc -lrt -lpthread

ifdef SYSROOT
CXXFLAGS += --sysroot $(SYSROOT)
LDFLAGS += --sysroot $(SYSROOT)
endif

SRCS = $(wildcard ../../../src/$(NAME)/*.c) $(wildcard ../../../src/$(NAME)/*.cpp)

OBJDIR = obj
OBJ = $(patsubst %,$(OBJDIR)/%.o,$(basename $(notdir $(SRCS))))
OBJ32DIR = obj32
OBJ32 = $(patsubst %,$(OBJ32DIR)/%.o,$(basename $(notdir $(SRCS))))

TARGETS = $(TARGET)
ifeq ($(BIARCH),yes)
TARGETS += $(TARGET32)
endif

.PHONY: all clean install tidy

all: $(TARGETS)

clean:
	rm -f $(TARGETS) $(OBJDIR)/* $(OBJ32DIR)/*

# Nothing to install
install: ;

ifneq ($(BIARCH),yes)

#
# Build native
#

DEPDIR := $(OBJDIR)
$(shell mkdir -p $(DEPDIR) >/dev/null)
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.Td

$(TARGET): $(OBJ)
	$(CROSS_COMPILE)$(CXX) $(LDFLAGS) -o $@ $(OBJ) $(LIBDEPS)

$(OBJDIR)/%.o : ../../../src/$(NAME)/%.c
$(OBJDIR)/%.o : ../../../src/$(NAME)/%.c $(DEPDIR)/%.d
	$(CXX) $(DEPFLAGS) $(CXXFLAGS) -c -o $@ $<
	@mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d && touch $@

$(OBJDIR)/%.o : ../../../src/$(NAME)/%.cpp
$(OBJDIR)/%.o : ../../../src/$(NAME)/%.cpp $(DEPDIR)/%.d
	$(CXX) $(DEPFLAGS) $(CXXFLAGS) -c -o $@ $<
	@mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d && touch $@

$(DEPDIR)/%.d: ;
.PRECIOUS: $(DEPDIR)/%.d

include $(wildcard $(patsubst %,$(DEPDIR)/%.d,$(basename $(SRCS))))

#
# Install native library
#

else

#
# Build 64-bit
#

DEPDIR := $(OBJDIR)
$(shell mkdir -p $(DEPDIR) >/dev/null)
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.Td

$(TARGET): $(OBJ)
	$(CROSS_COMPILE)$(CXX) $(LDFLAGS) -m64 -o $@ $(OBJ) $(LIBDEPS)

$(OBJDIR)/%.o : ../../../src/$(NAME)/%.c
$(OBJDIR)/%.o : ../../../src/$(NAME)/%.c $(DEPDIR)/%.d
	$(CXX) $(DEPFLAGS) $(CXXFLAGS) -c -m64 -o $@ $<
	@mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d && touch $@

$(OBJDIR)/%.o : ../../../src/$(NAME)/%.cpp
$(OBJDIR)/%.o : ../../../src/$(NAME)/%.cpp $(DEPDIR)/%.d
	$(CXX) $(DEPFLAGS) $(CXXFLAGS) -c -m64 -o $@ $<
	@mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d && touch $@

$(DEPDIR)/%.d: ;
.PRECIOUS: $(DEPDIR)/%.d

include $(wildcard $(patsubst %,$(DEPDIR)/%.d,$(basename $(SRCS))))

#
# Build 32-bit
#

DEP32DIR := $(OBJ32DIR)
$(shell mkdir -p $(DEP32DIR) >/dev/null)
DEP32FLAGS = -MT $@ -MMD -MP -MF $(DEP32DIR)/$*.Td

$(TARGET32): $(OBJ32)
	$(CROSS_COMPILE)$(CXX) $(LDFLAGS) -m32 -o $@ $(OBJ32) $(LIBDEPS)

$(OBJ32DIR)/%.o : ../../../src/$(NAME)/%.c
$(OBJ32DIR)/%.o : ../../../src/$(NAME)/%.c $(DEP32DIR)/%.d
	$(CXX) $(DEP32FLAGS) $(CXXFLAGS) -c -m32 -o $@ $<
	@mv -f $(DEP32DIR)/$*.Td $(DEP32DIR)/$*.d && touch $@

$(OBJ32DIR)/%.o : ../../../src/$(NAME)/%.cpp
$(OBJ32DIR)/%.o : ../../../src/$(NAME)/%.cpp $(DEP32DIR)/%.d
	$(CXX) $(DEP32FLAGS) $(CXXFLAGS) -c -m32 -o $@ $<
	@mv -f $(DEP32DIR)/$*.Td $(DEP32DIR)/$*.d && touch $@

$(DEP32DIR)/%.d: ;
.PRECIOUS: $(DEP32DIR)/%.d

include $(wildcard $(patsubst %,$(DEP32DIR)/%.d,$(basename $(SRCS))))

endif