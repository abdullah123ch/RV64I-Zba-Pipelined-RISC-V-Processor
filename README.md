# RISC-V Processor

A 5-stage pipelined RISC-V processor implementation in SystemVerilog.

## Overview

This project implements a 5-stage pipelined RISC-V processor with support for the RV64I base integer instruction set and the Zba bit manipulation extension. The processor follows a classic pipeline architecture consisting of Fetch, Decode, Execute, Memory, and Writeback stages.

## Architecture

The processor architecture includes:

- **Fetch Stage** (`fetch.sv`): Instruction fetching from program memory
- **Decode Stage** (`decode.sv`): Instruction decoding and register file access
- **Execute Stage** (`execute.sv`): Arithmetic and logical operations via ALU
- **Memory Stage** (`memory.sv`): Load/store operations
- **Writeback Stage** (`writeback.sv`): Register file updates

### Key Components

| Component | File | Description |
|-----------|------|-------------|
| ALU | `alu.sv` | Arithmetic logic unit for computations |
| Control Unit | `control_unit.sv` | Instruction decoding and control signals |
| Register File | `register.sv` | 64-bit general purpose registers |
| Program Counter | `pc.sv` | Instruction address management |
| Data Memory | `data.sv` | Load/store memory interface |
| Hazard Unit | `hazard_unit.sv` | Data and control hazard detection |
| Immediate Generator | `immediate.sv` | Immediate value extraction and sign extension |
| Instruction Decoder | `instruction.sv` | Instruction field parsing |

### Pipeline Stages

- **FD_pipeline.sv**: Fetch-Decode pipeline register
- **DE_pipeline.sv**: Decode-Execute pipeline register
- **EM_pipeline.sv**: Execute-Memory pipeline register
- **MW_pipeline.sv**: Memory-Writeback pipeline register

### Extensions

- **Zba (Address Generation)**: Bit manipulation instructions for efficient address calculations
  - `SH1ADD`: Shift left by 1 and add (multiply by 2 and add)
  - `SH2ADD`: Shift left by 2 and add (multiply by 4 and add)
  - `SH3ADD`: Shift left by 3 and add (multiply by 8 and add)

## Directory Structure

```
riscv-processor/
├── rtl/                 # RTL design files
├── tb/                  # Testbenches
├── sw/                  # Software and build files
├── docs/                # Documentation
├── Makefile            # Build configuration
└── README.md           # This file
```

## Building and Simulation

### Prerequisites

- SystemVerilog simulator (e.g., ModelSim, VCS, or Verilator)
- GNU Make
- GCC (for software compilation)

### Build

To compile the design and run the testbench:

```bash
make
```

To run a specific testbench:

```bash
make tb_fetch
make tb_decode
make tb_execute
make tb_memory
make tb_writeback
make tb_processor
```

### Debugging

The simulation provides a real-time cycle log and a final Register File dump including RISC-V ABI names (e.g., `RA`, `SP`, `A0`) for easier verification of software execution.

## Supported Instructions

The processor supports the following RISC-V instructions:

### Base Integer (RV64I)

- Arithmetic: `ADD`, `ADDI`, `SUB`, `ADDW`, `ADDIW`, `SUBW`
- Logical: `AND`, `ANDI`, `OR`, `ORI`, `XOR`, `XORI`
- Shift: `SLL`, `SLLI`, `SRL`, `SRLI`, `SRA`, `SRAI`, `SLLW`, `SLLIW`, `SRLW`, `SRLIW`, `SRAW`, `SRAIW`
- Compare: `SLT`, `SLTI`, `SLTU`, `SLTIU`
- Memory: `LD`, `SD` (64-bit load/store)
- Branch: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
- Jump: `JAL`, `JALR`

### Bit Manipulation (Zba)

- `SH1ADD`: Shift left by 1 and add
- `SH2ADD`: Shift left by 2 and add
- `SH3ADD`: Shift left by 3 and add

## Pipeline Features

- **5-stage pipeline**: Improved throughput with concurrent execution
- **Hazard detection**: Data and control hazard detection and resolution
- **Forwarding**: Register forwarding to minimize stalls
- **Branch prediction**: Basic branch resolution

## Software

Example test programs are located in the `sw/` directory:

- `test.c`: Example program to validate processor execution
- `link.ld`: Linker script for software builds

## Documentation

Detailed architecture documentation is available in `docs/architecture.drawio`.

## Contributing

When modifying the processor:

1. Update relevant RTL files in `rtl/`
2. Add or update testbenches in `tb/`
3. Update this README with any new features or changes

## License


## Contact

For questions or issues, please refer to the project documentation or reach out to the project maintainers.
