`timescale 1ns/1ps

module tb_fetch();
    logic clk, rst;
    // Hazard Unit Outputs
    logic Stall_F, Stall_D, Flush_D;
    // Fetch/Execute Signals
    logic [63:0] PCTarget_E;
    logic        PCSrc_E;
    // Intermediate Wires
    logic [63:0] PC_F_wire, PC_D;
    logic [31:0] Instr_F_wire, Instr_D;

    // 1. Fetch Stage
    // Ensure your fetch module has the Stall_F input!
    fetch dut (
        .clk(clk), .rst(rst),
        .Stall_F(Stall_F),     // NEW: Connect Stall
        .PCTarget_E(PCTarget_E), .PCSrc_E(PCSrc_E),
        .PC_F(PC_F_wire), 
        .Instr_F(Instr_F_wire)
    );

    // 2. IF/ID Pipeline Register
    // Ensure your register has en (enable) and clr (clear) inputs!
    FD_pipeline IF_ID_REG (
        .clk(clk), .rst(rst),
        .en(~Stall_D),         // NEW: Stall keeps old Instr_D
        .clr(Flush_D),         // NEW: Flush makes Instr_D = NOP
        .PC_F(PC_F_wire), .Instr_F(Instr_F_wire),
        .PC_D(PC_D), .Instr_D(Instr_D)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("fetch_hazards.vcd");
        $dumpvars(0, tb_fetch);

        // Initialize Instruction Memory (Binary from the .c file)
        dut.imem.rom[0] = 32'h00a00093; // addi x1, x0, 10
        dut.imem.rom[1] = 32'h0000b103; // ld   x2, 0(x1)
        dut.imem.rom[2] = 32'h001101b3; // add  x3, x2, x1
        dut.imem.rom[3] = 32'h00000463; // beq  x0, x0, 8 (target)

        clk = 0; rst = 1; 
        Stall_F = 0; Stall_D = 0; Flush_D = 0;
        PCSrc_E = 0; PCTarget_E = 0;

        #15 rst = 0;

        // --- TEST 1: Simulate a Load-Use Stall ---
        #20; // Let instructions fill pipeline
        $display("Stalling Fetch at Time %0t", $time);
        Stall_F = 1; Stall_D = 1; 
        #10; // Hold for one cycle
        Stall_F = 0; Stall_D = 0;
        $display("Resuming Fetch at Time %0t", $time);

        // --- TEST 2: Simulate a Branch Flush ---
        #10;
        $display("Flushing Decode (Branch Taken) at Time %0t", $time);
        PCSrc_E = 1; 
        PCTarget_E = 64'd100; // Arbitrary jump target
        Flush_D = 1;
        #10;
        PCSrc_E = 0; Flush_D = 0;

        #40;
        $display("Hazard Fetch Test Complete.");
        $finish;
    end
endmodule