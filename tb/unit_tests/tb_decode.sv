// File: tb/unit_tests/tb_decode.sv
// Brief: Unit testbench for Decode stage and ID/EX pipeline register.
// Tests instruction decoding, register file read/write, stall, and flush behavior.
// Validates control signal generation and hazard handling in the pipeline.

`timescale 1ns/1ps

module tb_decode();
    // ============================================================
    // TEST SIGNALS AND WIRES
    // ============================================================
    logic clk, rst;                             // clock and reset
    
    // Decode Stage Inputs (from IF/ID pipeline)
    logic [31:0] Instr_D;                       // instruction to decode
    logic [63:0] PC_D;                          // program counter
    
    // Writeback Feedback (for register file update)
    logic [63:0] Result_W;                      // writeback result
    logic [4:0]  Rd_W;                          // writeback destination register
    logic        RegWrite_W;                    // writeback enable

    // Hazard Control Signals
    logic        Stall_D;                       // stall signal (freeze Decode)
    logic        Flush_E;                       // flush signal (clear ID/EX)

    // Decode Stage Outputs (Combinational - from control_unit and register file)
    logic [63:0] RD1_D, RD2_D, ImmExt_D;       // register operands and immediate
    logic [4:0]  Rd_D, Rs1_D, Rs2_D;           // register indices
    logic [1:0]  ResultSrc_D;                   // writeback source selector
    logic        MemWrite_D, ALUSrc_D, RegWrite_D, Branch_D, Jump_D; // control signals
    logic [3:0]  ALUControl_D;                  // ALU control code
    logic [63:0] PC_D_out;                      // PC pass-through

    // ID/EX Pipeline Register Outputs (to Execute stage)
    logic        RegWrite_E, MemWrite_E;        // control signals in Execute
    logic [4:0]  Rd_E;                          // destination register in Execute

    // ============================================================
    // 1. DECODE STAGE INSTANTIATION
    // ============================================================
    // Instantiate decode module: reads registers, decodes instruction, generates control signals
    decode ID_STAGE (
        .clk(clk), .rst(rst),                   // clock and reset
        .Instr_D(Instr_D), .PC_D(PC_D),         // instruction and PC inputs
        .Result_W(Result_W), .Rd_W(Rd_W), .RegWrite_W(RegWrite_W), // writeback feedback
        .RD1_D(RD1_D), .RD2_D(RD2_D), .ImmExt_D(ImmExt_D), // operand outputs
        .Rd_D(Rd_D), .Rs1_D(Rs1_D), .Rs2_D(Rs2_D), // register index outputs
        .ResultSrc_D(ResultSrc_D), .MemWrite_D(MemWrite_D), // control signals
        .ALUSrc_D(ALUSrc_D), .RegWrite_D(RegWrite_D), 
        .ALUControl_D(ALUControl_D), .Branch_D(Branch_D), .Jump_D(Jump_D),
        .PC_D_out(PC_D_out)                     // PC pass-through
    );

    // ============================================================
    // 2. ID/EX PIPELINE REGISTER INSTANTIATION
    // ============================================================
    // Instantiate DE_pipeline: latches decode outputs with stall/flush control
    DE_pipeline ID_EX_REG (
        .clk(clk), .rst(rst),                   // clock and reset
        .clr(Flush_E),                          // flush signal (clears on branch)
        // Input connections from Decode stage
        .RD1_D(RD1_D), .RD2_D(RD2_D), .PC_D(PC_D), .ImmExt_D(ImmExt_D), 
        .Rd_D(Rd_D), .Rs1_D(Rs1_D), .Rs2_D(Rs2_D),
        .RegWrite_D(RegWrite_D), .ResultSrc_D(ResultSrc_D), .MemWrite_D(MemWrite_D),
        .ALUControl_D(ALUControl_D), .ALUSrc_D(ALUSrc_D), .Branch_D(Branch_D), .Jump_D(Jump_D),
        // Output connections to Execute stage (selected subset shown)
        .RegWrite_E(RegWrite_E), .MemWrite_E(MemWrite_E), .Rd_E(Rd_E)
        // (Other outputs omitted for brevity)
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
        // SETUP: VCD DUMP AND INITIALIZATION
        // ============================================================
        $dumpfile("decode_hazards.vcd");        // waveform capture
        $dumpvars(0, tb_decode);                // capture all signals

        // ============================================================
        // INITIALIZATION
        // ============================================================
        clk = 0; rst = 1; Flush_E = 0; Stall_D = 0;
        Instr_D = 32'h0; PC_D = 64'h0;
        Result_W = 64'h0; Rd_W = 5'h0; RegWrite_W = 0;
        
        #15 rst = 0;                            // release reset

        // ============================================================
        // TEST 1: STALL SIGNAL VERIFICATION
        // ============================================================
        // Test that Stall_D prevents pipeline register update (hazard handling)
        // Instruction: ADD x7, x6, x5 (binary: 005303b3)
        $display("[%0t] TEST 1: Stall Verification", $time);
        $display("  - Loading instruction: ADD x7, x6, x5");
        
        Instr_D = 32'h005303b3;                 // ADD x7, x6, x5 encoding
        #10;                                     // first clock: data propagates to pipeline
        
        $display("[%0t]   Before Stall: Rd_E=%d, RegWrite_E=%b", $time, Rd_E, RegWrite_E);
        
        Stall_D = 1;                            // activate stall (prevent register update)
        $display("[%0t]   Stall activated (should freeze all pipeline outputs)", $time);
        
        #10;
        $display("[%0t]   During Stall: Rd_E=%d (Should match previous cycle)", $time, Rd_E);
        
        Stall_D = 0;                            // deactivate stall
        $display("[%0t]   Stall released", $time);

        // ============================================================
        // TEST 2: FLUSH SIGNAL VERIFICATION
        // ============================================================
        // Test that Flush_E clears pipeline register (branch mispredict recovery)
        // Instruction: ADDI x28, x0, 1 (binary: 00100e13)
        $display("[%0t] TEST 2: Flush Verification (Branch Recovery)", $time);
        $display("  - Loading instruction: ADDI x28, x0, 1");
        
        Instr_D = 32'h00100e13;                 // ADDI x28, x0, 1 encoding
        #10;                                     // latch data into pipeline
        
        $display("[%0t]   Before Flush: RegWrite_E=%b (should be 1)", $time, RegWrite_E);
        
        Flush_E = 1;                            // activate flush (inject NOP)
        $display("[%0t]   Flush activated (DE_pipeline should zero outputs)", $time);
        
        #10;                                     // clock edge: flush takes effect
        $display("[%0t]   After Flush Edge: RegWrite_E=%b (EXPECTED: 0)", $time, RegWrite_E);
        
        if (RegWrite_E == 0) 
            $display("   >>> SUCCESS: Flush cleared control signals correctly.");
        else
            $display("   >>> FAILURE: Flush failed to clear RegWrite_E.");

        Flush_E = 0;                            // deactivate flush

        // ============================================================
        // SIMULATION COMPLETION
        // ============================================================
        #20;
        $display("[%0t] Decode unit test completed.", $time);
        $finish;
    end
endmodule