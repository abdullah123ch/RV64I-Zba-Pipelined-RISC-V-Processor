`timescale 1ns/1ps

module tb_decode();
    // Clock and Reset
    logic clk, rst;
    
    // Decode Inputs (Simulating IF/ID output)
    logic [31:0] Instr_D;
    logic [63:0] PC_D;
    
    // Writeback Inputs (Feedback)
    logic [63:0] Result_W;
    logic [4:0]  Rd_W;
    logic        RegWrite_W;

    // Hazard Control Signals
    logic        Stall_D; // Logic for this test: freeze the pipeline
    logic        Flush_E; // Logic for this test: clear the ID/EX register

    // Decode Stage Outputs (Combinational)
    logic [63:0] RD1_D, RD2_D, ImmExt_D;
    logic [4:0]  Rd_D, Rs1_D, Rs2_D;
    logic [1:0]  ResultSrc_D;
    logic        MemWrite_D, ALUSrc_D, RegWrite_D, Branch_D, Jump_D;
    logic [3:0]  ALUControl_D;
    logic [63:0] PC_D_out;

    // Pipeline Stage Outputs (Registered)
    logic        RegWrite_E, MemWrite_E;
    logic [4:0]  Rd_E;

    // 1. Instantiate Decode Module
    decode ID_STAGE (
        .clk(clk), .rst(rst),
        .Instr_D(Instr_D), .PC_D(PC_D),
        .Result_W(Result_W), .Rd_W(Rd_W), .RegWrite_W(RegWrite_W),
        .RD1_D(RD1_D), .RD2_D(RD2_D), .ImmExt_D(ImmExt_D), 
        .Rd_D(Rd_D), .Rs1_D(Rs1_D), .Rs2_D(Rs2_D),
        .ResultSrc_D(ResultSrc_D), .MemWrite_D(MemWrite_D), 
        .ALUSrc_D(ALUSrc_D), .RegWrite_D(RegWrite_D), 
        .ALUControl_D(ALUControl_D), .Branch_D(Branch_D), .Jump_D(Jump_D),
        .PC_D_out(PC_D_out)
    );

    // 2. Instantiate DE_pipeline (Where the Hazard Logic applies)
    DE_pipeline ID_EX_REG (
        .clk(clk), .rst(rst),
        .clr(Flush_E), // Flush signal from Hazard Unit
        .RD1_D(RD1_D), .RD2_D(RD2_D), .PC_D(PC_D), .ImmExt_D(ImmExt_D), 
        .Rd_D(Rd_D), .Rs1_D(Rs1_D), .Rs2_D(Rs2_D),
        .RegWrite_D(RegWrite_D), .ResultSrc_D(ResultSrc_D), .MemWrite_D(MemWrite_D),
        .ALUControl_D(ALUControl_D), .ALUSrc_D(ALUSrc_D), .Branch_D(Branch_D), .Jump_D(Jump_D),
        // Outputs to Execute
        .RegWrite_E(RegWrite_E), .MemWrite_E(MemWrite_E), .Rd_E(Rd_E)
        // (Other ports omitted for brevity, use .* if naming matches)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("decode_hazards.vcd");
        $dumpvars(0, tb_decode);

        // --- Initialization ---
        clk = 0; rst = 1; Flush_E = 0; Stall_D = 0;
        Instr_D = 32'h0; PC_D = 64'h0;
        Result_W = 64'h0; Rd_W = 5'h0; RegWrite_W = 0;
        #15 rst = 0;

        // --- TEST 1: Stall Verification ---
        // add x7, x6, x5
        $display("[%0t] T1: Setting up Stall...", $time);
        Instr_D = 32'h005303b3; 
        #10; // First clock edge: data moves to DE_pipeline output
        $display("[%0t] Before Stall: Rd_E=%d, RegWrite_E=%b", $time, Rd_E, RegWrite_E);
        
        Stall_D = 1; // In a real core, this would disable the IF/ID register
        #10;
        $display("[%0t] During Stall: Rd_E=%d (Should be same as before)", $time, Rd_E);
        Stall_D = 0;

        // --- TEST 2: Flush Verification (The previous failure point) ---
        // addi x28, x0, 1 (Op: 013, rd: 28, rs1: 0, imm: 1) -> 00100e13
        $display("[%0t] T2: Setting up Flush...", $time);
        Instr_D = 32'h00100e13; 
        #10; // Data is now at the input of DE_pipeline
        
        Flush_E = 1; // Trigger Flush
        #10; // Clock edge: DE_pipeline should clear
        $display("[%0t] After Flush Edge: RegWrite_E=%b (EXPECTED: 0)", $time, RegWrite_E);
        
        if (RegWrite_E == 0) $display(">>> SUCCESS: Flush logic verified.");
        else                $display(">>> FAILURE: Flush logic failed to clear RegWrite_E.");

        Flush_E = 0;
        #20;
        $finish;
    end
endmodule