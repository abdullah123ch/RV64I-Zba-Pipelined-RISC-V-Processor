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
