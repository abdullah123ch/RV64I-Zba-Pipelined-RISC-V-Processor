# RISC-V Processor Architecture

This document provides a comprehensive overview of the 5-stage pipelined RISC-V processor design, including the pipeline stages, key components, instruction set support, and design considerations.

## Pipeline Overview

The processor implements a classic 5-stage pipeline architecture for improved throughput:

```
Fetch → Decode → Execute → Memory → Writeback
  ↓        ↓        ↓         ↓        ↓
 [PC]    [Regs]   [ALU]     [Mem]    [Regs]
```

Each stage operates on a different instruction in parallel, enabling one instruction to complete per cycle at steady state.

## Pipeline Stages

### 1. Fetch Stage (`fetch.sv`)

**Purpose**: Retrieve the next instruction from program memory.

**Functionality**:
- Maintains the Program Counter (PC) to track the current instruction address
- Fetches the instruction at the current PC from instruction memory
- Handles PC updates based on branch outcomes and jumps from previous stages
- Manages PC increment (+4) for sequential instructions

**Outputs to FD Pipeline Register**:
- `instruction`: 32-bit RISC-V instruction
- `pc`: Current instruction address
- `next_pc`: PC incremented by 4

### 2. Decode Stage (`decode.sv`)

**Purpose**: Decode the instruction and fetch operands from the register file.

**Functionality**:
- Decodes the instruction format and extracts fields (opcode, rd, rs1, rs2, immediate)
- Reads two source operands from the 64-bit register file
- Generates immediate values using the immediate generator
- Produces control signals for subsequent stages
- Detects data hazards and stalls if necessary

**Key Operations**:
- Instruction field extraction (via `instruction.sv`)
- Register file read (via `register.sv`)
- Immediate sign extension (via `immediate.sv`)
- Hazard detection (via `hazard_unit.sv`)

**Outputs to DE Pipeline Register**:
- `rs1_data`, `rs2_data`: Register operands
- `immediate`: Extended immediate value
- `rd`: Destination register address
- Control signals for ALU and memory operations

### 3. Execute Stage (`execute.sv`)

**Purpose**: Perform arithmetic, logical, and comparison operations.

**Functionality**:
- Performs ALU operations on operands (with forwarding from later stages)
- Executes shifts, arithmetic, logical, and bit manipulation instructions
- Computes branch target addresses and determines branch outcomes
- Handles Zba extension instructions (SH1ADD, SH2ADD, SH3ADD)
- Forwards results to Decode stage to resolve data dependencies

**Key Operations**:
- ALU computation (via `alu.sv`)
- Branch condition evaluation
- Address calculation for memory operations
- Data forwarding to earlier stages

**Outputs to EM Pipeline Register**:
- `alu_result`: Computation result
 - `branch_taken`: Branch outcome
- `branch_target`: Target address if branch taken
- Memory operation flags (read/write)

### 4. Memory Stage (`memory.sv`)

**Purpose**: Perform load and store operations.

**Functionality**:
- Executes load instructions (LD) to read from data memory
- Executes store instructions (SD) to write to data memory
- Manages memory address calculation and alignment
- Handles 64-bit data transfers

**Outputs to MW Pipeline Register**:
- `mem_data`: Data read from memory (for loads)
- `alu_result`: Forwarded result for non-memory instructions
- `rd`: Destination register address

### 5. Writeback Stage (`writeback.sv`)

**Purpose**: Update the register file with computation results.

**Functionality**:
- Writes results back to the destination register (rd)
- Updates register file for arithmetic, logical, load, and jump instructions
- Provides forwarding data to Execute stage

**Sources of writeback data**:
- ALU results (arithmetic, logical, shifts)
- Memory load data (LD instructions)
- PC + 4 (for JAL/JALR instructions to save return address)

## Key Components

| Component | File | Description |
|-----------|------|-------------|
| **ALU** | `alu.sv` | Arithmetic logic unit supporting ADD, SUB, AND, OR, XOR, shifts, SLT, and Zba instructions |
| **Control Unit** | `control_unit.sv` | Decodes instruction opcodes and generates control signals for all pipeline stages |
| **Register File** | `register.sv` | 32 × 64-bit registers with dual read ports and single write port; includes ABI naming |
| **Program Counter** | `pc.sv` | Manages instruction address; updates based on branches, jumps, and sequential execution |
| **Data Memory** | `data.sv` | System memory for load/store operations; supports 64-bit read/write |
| **Hazard Unit** | `hazard_unit.sv` | Detects data dependencies and control hazards; stalls pipeline when necessary |
| **Immediate Generator** | `immediate.sv` | Extracts and sign-extends immediates from various RISC-V instruction formats |
| **Instruction Decoder** | `instruction.sv` | Parses instruction fields (opcode, rs1, rs2, rd, immediate, funct3, funct7) |

## Pipeline Registers

Pipeline registers hold intermediate data between stages, enabling parallel execution:

- **FD_pipeline.sv**: Fetch-Decode register (instruction, pc, next_pc)
- **DE_pipeline.sv**: Decode-Execute register (operands, immediate, rd, control signals)
- **EM_pipeline.sv**: Execute-Memory register (alu_result, branch info, rd)
- **MW_pipeline.sv**: Memory-Writeback register (writeback data, rd)

## Supported Instructions

### Base Integer (RV64I)

The processor supports a comprehensive subset of the RISC-V RV64I instruction set:

#### Arithmetic Instructions
- `ADD`: Add registers (rd = rs1 + rs2)
- `ADDI`: Add immediate (rd = rs1 + imm)
- `SUB`: Subtract registers (rd = rs1 - rs2)

#### Logical Instructions
- `AND`, `ANDI`: Bitwise AND
- `OR`, `ORI`: Bitwise OR
- `XOR`, `XORI`: Bitwise XOR

#### Shift Instructions
- `SLL`, `SLLI`: Shift left logical
- `SRL`, `SRLI`: Shift right logical
- `SRA`, `SRAI`: Shift right arithmetic

#### Comparison Instructions
- `SLT`, `SLTI`: Set less than (signed)
- `SLTU`, `SLTIU`: Set less than (unsigned)

#### Memory Instructions
- `LD`: Load doubleword (64-bit from memory)
- `SD`: Store doubleword (64-bit to memory)

#### Branch Instructions
- `BEQ`: Branch if equal
- `BNE`: Branch if not equal
- `BLT`: Branch if less than (signed)
- `BGE`: Branch if greater than or equal (signed)
- `BLTU`: Branch if less than (unsigned)
- `BGEU`: Branch if greater than or equal (unsigned)

#### Jump Instructions
- `JAL`: Jump and link (saves return address in rd)
- `JALR`: Jump and link register (jumps to address in rs1 + imm)

### Bit Manipulation (Zba Extension)

The Zba extension provides efficient address calculation instructions:

- **SH1ADD**: `rd = (rs1 << 1) + rs2` — Useful for byte array indexing
- **SH2ADD**: `rd = (rs1 << 2) + rs2` — Useful for 4-byte element arrays
- **SH3ADD**: `rd = (rs1 << 3) + rs2` — Useful for 8-byte element arrays

These instructions replace a shift-add sequence with a single operation, improving code density and reducing execution time.

## Hazard Handling

The processor implements sophisticated hazard detection and resolution:

### Data Hazards

**Types**:
1. **Read-after-Write (RAW)**: Most common; occurs when an instruction reads a register before a previous instruction writes to it
2. **Write-after-Write (WAW)**: Multiple instructions write to the same register
3. **Write-after-Read (WAR)**: In-order processors don't typically exhibit this hazard

**Resolution**:
- **Forwarding**: Forward results from Execute and Memory stages directly to Execute inputs
- **Stalling**: Insert pipeline bubbles when forwarding cannot resolve the hazard

### Control Hazards

**Types**:
- Branch conditions determined in Execute stage may invalidate Fetch/Decode stages

**Branch Prediction Strategy**:
- The processor implements a **Predict-Not-Taken** strategy
- Default assumption: All branches are assumed to not be taken
- The fetch stage continues fetching sequential instructions (PC + 4)
- When the Execute stage determines a branch is actually taken, the pipeline flushes and restarts at the branch target address

**Resolution**:
- Flush Fetch and Decode stages when a branch is taken
- **Penalty: Exactly 2 cycles** (instructions in Fetch and Decode stages must be cleared)
- No penalty if branch is not taken (prediction was correct)

## Data Flow and Forwarding

### Forwarding Paths

The Execute stage can receive operands from multiple sources:

1. **Direct from Decode**: Current cycle's decoded values
2. **From Execute output**: Previous instruction's result (1-cycle-old)
3. **From Memory output**: 2-cycle-old result
4. **From Writeback**: 3-cycle-old result

### Example: Dependent Instructions

```
ADD x1, x2, x3     # x1 = x2 + x3 (Cycle 1)
ADDI x4, x1, 10    # x4 = x1 + 10 (Cycle 2, depends on x1)
```

In Cycle 2 when ADDI executes:
- ADD result is available directly from Execute output
- Forwarding logic selects this result instead of register file value
- No stall required

## Performance Characteristics

### Best Case (No Hazards)
- **CPI**: 1.0 (one instruction per cycle)
- **Throughput**: One instruction completes every cycle

### With Data Hazards (Forwarding)
- **CPI**: 1.0 (hazards resolved via forwarding)
- **Throughput**: Still one instruction per cycle

### With Control Hazards (Branch Taken)
- **Penalty**: 2 cycles (Fetch and Decode stages flushed)
- **Impact**: Depends on branch frequency in the program

## Design Decisions

1. **64-bit Data Width**: Supports RV64I instruction set
2. **5-stage Pipeline**: Balances throughput improvement with complexity
3. **Separate Instruction and Data Memory**: Avoids memory port conflicts (Harvard architecture)
4. **Forwarding Network**: Reduces stall penalties for data dependencies
5. **Zba Extension**: Provides efficient address calculation without additional cycles

## Testing and Verification

Each component has dedicated testbenches:

- `tb_fetch.sv`: Program counter and instruction fetch
- `tb_decode.sv`: Instruction decoding and register file operations
- `tb_execute.sv`: ALU operations and forwarding
- `tb_memory.sv`: Load/store operations
- `tb_writeback.sv`: Register file updates
- `tb_processor.sv`: Full processor integration and complex instruction sequences
