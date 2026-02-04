# RISC-V Processor

A 5-stage pipelined RISC-V processor implementation in SystemVerilog.

## Overview

This project implements a 5-stage pipelined RISC-V processor with support for the RV64I base integer instruction set and the Zba bit manipulation extension. The processor follows a classic pipeline architecture consisting of Fetch, Decode, Execute, Memory, and Writeback stages.


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

- SystemVerilog simulator ( i have used iVerilator)
- GNU Make
- GCC (for software compilation)

### Build

To compile the design and run the testbench:

```bash
make
```

To run a specific testbench:

```bash
make fetch
make decode
make execute
make memory
make writeback
```

### Debugging

The simulation provides a real-time cycle log and a final Register File dump including RISC-V ABI names (e.g., `RA`, `SP`, `A0`) for easier verification of software execution.

## Software

Software files are organized in the `sw/` directory:

- `programs/`: Source code directory
  - `main.c`: Example program to validate processor execution
  - `main.s`: Generated assembly code
- `build/`: Build output directory
  - `main.elf`: Compiled executable
  - `main.hex`: Machine code in Verilog hex format
- `common/`: Common files
  - `link.ld`: Linker script for software builds
  - `start.s`: Startup/initialization code

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
