# --- Toolchain Definitions ---
CROSS_COMPILE = riscv64-unknown-elf-
CC      = $(CROSS_COMPILE)gcc
LD      = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
VLOG    = iverilog
VSIM    = vvp
FLAGS   = -g2012

# --- File Paths ---
SW_DIR  = sw
RTL_DIR = rtl
DV_DIR  = tb
FETCH_TB_SRC = $(DV_DIR)/tb_fetch.sv
FETCH_SIM    = fetch_sim

# --- Software Files ---
C_SRC   = $(SW_DIR)/test.c
LINKER  = $(SW_DIR)/link.ld
HEX     = $(SW_DIR)/test.hex
ELF     = $(SW_DIR)/test.elf

# --- Hardware Files ---
# Automatically find all .sv files in rtl and the main testbench
RTL_SRC = $(wildcard $(RTL_DIR)/*.sv)
TB_SRC  = $(DV_DIR)/tb_processor.sv
SIM_EXE = core_sim
VCD     = core_sim.vcd

# --- Default Target ---
all: sw sim

# --- 1. Software Compilation (C to Hex) ---
sw: $(HEX)

$(HEX): $(C_SRC) $(LINKER)
	@echo "Compiling Software..."
	$(CC) -march=rv64i_zba -mabi=lp64 -ffreestanding -nostdlib -T $(LINKER) $(C_SRC) -o $(ELF)
	$(OBJCOPY) -O verilog --verilog-data-width=4 $(ELF) $(HEX)
	@echo "Software build complete: $(HEX)"

# --- 2. Hardware Compilation (RTL to Simulation) ---
compile: $(RTL_SRC) $(TB_SRC)
	@echo "Compiling Hardware..."
	$(VLOG) $(FLAGS) -o $(SIM_EXE) $(RTL_SRC) $(TB_SRC)

# --- 3. Run Simulation ---
sim: sw compile
	@echo "Running Simulation..."
	$(VSIM) $(SIM_EXE)
	@echo "Simulation complete. Waves saved to $(VCD)"

# --- 4. Open Waveforms ---
waves:
	gtkwave $(VCD) &

# --- 5. Fetch Unit Test ---
fetch: sw
	@echo "Compiling Fetch Unit Test..."
	$(VLOG) $(FLAGS) -o $(FETCH_SIM) $(RTL_SRC) $(FETCH_TB_SRC)
	@echo "Running Fetch Unit Test..."
	$(VSIM) $(FETCH_SIM)
	@echo "Fetch Test complete." 
	gtkwave fetch_pipeline.vcd &


# --- 9. Cleanup ---
clean:
	rm -f $(SIM_EXE) $(FETCH_SIM) $(VCD) fetch_pipeline.vcd $(HEX) $(SW_DIR)/*.elf $(SW_DIR)/*.o
	@echo "Cleanup complete."

.PHONY: all sw compile sim waves clean