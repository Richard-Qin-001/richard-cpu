MODULE ?= alu
HW_DIR  = $(abspath hardware/src)
HW_SRC = $(abspath hardware/src/$(MODULE).v)
TB_SRC = $(abspath sim/$(MODULE)_tb.cpp)
INC_DIR = $(abspath hardware/include)

BUILD_DIR = build/$(MODULE)_build
OBJ_DIR   = $(BUILD_DIR)/obj_dir
BIN       = $(abspath $(BUILD_DIR)/V$(MODULE))
WAVE_FILE = $(abspath waves/$(MODULE).vcd)

VERILATOR = verilator
VFLAGS += -Wall --trace --cc --exe -y $(HW_DIR)

all: $(BIN)

verilate:
	@mkdir -p $(BUILD_DIR)
	@echo "### [1/3] Verilating $(MODULE) ###"
	$(VERILATOR) $(VFLAGS) \
		--Mdir $(OBJ_DIR) \
		-I$(INC_DIR) \
		$(HW_SRC) $(TB_SRC)

$(BIN): verilate
	@echo "### [2/3] Building Binary ###"
	$(MAKE) -C $(OBJ_DIR) -f V$(MODULE).mk \
		OPT_FAST="" \
		CXXFLAGS="-g -O0" \
		LDFLAGS="-g"
	@cp $(OBJ_DIR)/V$(MODULE) $(BIN)

run: $(BIN)	
	@mkdir -p waves
	@echo "### [3/3] Running Simulation ###"
	$(BIN)

gdb: $(BIN)
	gdb $(BIN)

wave: run
	gtkwave $(WAVE_FILE)

clean:
	rm -rf build wave

.PHONY: all verilate run gdb wave clean