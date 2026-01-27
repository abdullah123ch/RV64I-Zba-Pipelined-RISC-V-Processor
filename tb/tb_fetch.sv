`timescale 1ns/1ps

module tb_fetch();
    // Signal definitions
    logic        clk;
    logic        rst;
    logic [63:0] PCTarget;
    logic        PCWrite_F;
    logic [63:0] PC;
    logic [31:0] Instr;

    // Instantiate the Fetch Stage
    fetch dut (
        .clk(clk),
        .rst(rst),
        .PCTarget(PCTarget),
        .PCWrite_F(PCWrite_F),
        .PC(PC),
        .Instr(Instr)
    );

    // Clock generation (100MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize memory with dummy instructions
        // 0x00000013 is NOP (addi x0, x0, 0)
        // 0x00500093 is addi x1, x0, 5
        dut.imem.rom[0] = 32'h00000013; 
        dut.imem.rom[1] = 32'h00500093;
        dut.imem.rom[2] = 32'h00000013;
        dut.imem.rom[10] = 32'hDEADBEEF; // Test target address

        // Initialize signals
        clk = 0;
        rst = 1;
        PCWrite_F = 0;
        PCTarget = 64'b0;

        // Reset Sequence
        #15 rst = 0;
        
        // Test 1: Sequential Fetch
        $display("Time=%0t | PC=%h | Instr=%h (Expected: PC=0, Instr=00000013)", $time, PC, Instr);
        #10;
        $display("Time=%0t | PC=%h | Instr=%h (Expected: PC=4, Instr=00500093)", $time, PC, Instr);
        #10;
        $display("Time=%0t | PC=%h | Instr=%h (Expected: PC=8, Instr=00000013)", $time, PC, Instr);

        // Test 2: External PC Update (Branch/Jump Simulation)
        PCWrite_F = 1;
        PCTarget = 64'd40; // Jump to index 10 (40/4 = 10)
        #10;
        PCWrite_F = 0;
        $display("Time=%0t | PC=%h | Instr=%h (Expected: PC=40, Instr=DEADBEEF)", $time, PC, Instr);

        #20;
        $display("Simulation Finished");
        $finish;
    end
endmodule