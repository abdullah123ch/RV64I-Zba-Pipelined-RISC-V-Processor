// File: tb/unit_tests/tb_fetch.sv
// Brief: Unit testbench for Fetch stage and IF/ID pipeline register.
// Tests PC increment, branch target switching, stall, and flush control signals.
// Validates correct instruction fetching behavior under hazard conditions.

`timescale 1ns/1ps

module tb_fetch();
    // ============================================================
    // TEST SIGNALS AND WIRES
    // ============================================================
    logic clk, rst;                             // clock and reset
    
    // Hazard unit control outputs
    logic Stall_F, Stall_D, Flush_D;            // stall and flush signals
    
    // Branch/Jump signals from Execute stage
    logic [63:0] PCTarget_E;                    // target address for branch/jump
    logic        PCSrc_E;                       // PC source selector: branch taken
    
    // Fetch stage outputs and pipeline signals
    logic [63:0] PC_F_wire, PC_D;               // program counters (Fetch and Decode)
    logic [31:0] Instr_F_wire, Instr_D;         // instructions (Fetch and Decode)

    // ============================================================
    // 1. FETCH STAGE INSTANTIATION
    // ============================================================
    // Instantiate fetch module with stall control from hazard unit
    fetch dut (
        .clk(clk), .rst(rst),                   // clock and reset
        .Stall_F(Stall_F),                      // stall signal (hold PC)
        .PCTarget_E(PCTarget_E),                // branch target from Execute
        .PCSrc_E(PCSrc_E),                      // branch taken indicator
        .PC_F(PC_F_wire),                       // current PC output
        .Instr_F(Instr_F_wire)                  // instruction from ROM
    );

    // ============================================================
    // 2. IF/ID PIPELINE REGISTER INSTANTIATION
    // ============================================================
    // Instantiate IF/ID pipeline register with enable and clear controls
    FD_pipeline IF_ID_REG (
        .clk(clk), .rst(rst),                   // clock and reset
        .en(~Stall_D),                          // enable (active low stall): 0=hold, 1=latch
        .clr(Flush_D),                          // clear (flush): 1=zero outputs, 0=normal
        .PC_F(PC_F_wire), .Instr_F(Instr_F_wire), // inputs from Fetch
        .PC_D(PC_D), .Instr_D(Instr_D)          // outputs to Decode
    );

    // ============================================================
    // CLOCK GENERATION (100MHz)
    // ============================================================
    always #5 clk = ~clk;

    // ============================================================
    // TEST SEQUENCE
    // ============================================================
    initial begin
        // ============================================================
        // SETUP: VCD DUMP AND TEST DATA
        // ============================================================
        $dumpfile("fetch_hazards.vcd");         // waveform capture file
        $dumpvars(0, tb_fetch);                 // capture all signals

        // Initialize instruction ROM with test program
        // Test sequence: ADDI x1, x0, 10 → LD x2, 0(x1) → ADD x3, x2, x1 → BEQ (loop)
        dut.imem.rom[0] = 32'h00a00093;         // ADDI x1, x0, 10    (load 10 into x1)
        dut.imem.rom[1] = 32'h0000b103;         // LD x2, 0(x1)       (load from memory[x1])
        dut.imem.rom[2] = 32'h001101b3;         // ADD x3, x2, x1     (add x1 and x2)
        dut.imem.rom[3] = 32'h00000463;         // BEQ x0, x0, 8      (branch to self: infinite loop)

        // ============================================================
        // INITIALIZATION
        // ============================================================
        clk = 0; rst = 1;                       // reset active
        Stall_F = 0; Stall_D = 0; Flush_D = 0;  // no stall or flush
        PCSrc_E = 0; PCTarget_E = 0;            // no branch taken

        #15 rst = 0;                            // release reset after 15ns

        // ============================================================
        // TEST 1: LOAD-USE STALL SIMULATION
        // ============================================================
        // Simulate hazard unit stalling Fetch and Decode on load-use dependency
        #20;                                     // let pipeline fill for a few cycles
        $display("TEST 1: Stalling Fetch at Time %0t (Load-Use Hazard)", $time);
        Stall_F = 1; Stall_D = 1;               // activate stall signals
        
        #10;                                     // hold stall for one cycle
        $display("  - PC should hold steady during stall");
        $display("  - Instr_D should hold previous value");
        
        Stall_F = 0; Stall_D = 0;               // release stall
        $display("TEST 1: Resuming Fetch at Time %0t", $time);

        // ============================================================
        // TEST 2: BRANCH FLUSH SIMULATION
        // ============================================================
        // Simulate branch taken, causing Decode stage flush (NOP injection)
        #10;
        $display("TEST 2: Flushing Decode (Branch Taken) at Time %0t", $time);
        PCSrc_E = 1;                            // indicate branch taken
        PCTarget_E = 64'd100;                   // set branch target address
        Flush_D = 1;                            // flush Decode stage
        
        #10;
        $display("  - PC should jump to target %d (0x%h)", PCTarget_E, PCTarget_E);
        $display("  - Instr_D should become zero (NOP) due to flush");
        
        PCSrc_E = 0; Flush_D = 0;               // deassert branch and flush

        // ============================================================
        // SIMULATION COMPLETION
        // ============================================================
        #40;                                     // run a few more cycles
        $display("TEST COMPLETE: Fetch unit test finished at time %0t", $time);
        $finish;                                // end simulation
    end
endmodule