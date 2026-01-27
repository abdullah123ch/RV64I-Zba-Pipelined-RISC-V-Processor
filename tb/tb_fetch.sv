`timescale 1ns/1ps

module tb_fetch();
    // Testbench signals
    logic        clk;
    logic        rst;
    logic [63:0] PCTarget_E;
    logic        PCSrc_E;
    logic [63:0] PC_D;
    logic [31:0] Instr_D;

    // Instantiate the "Clean" Fetch Stage (without hazard signals)
    fetch dut (
        .clk(clk),
        .rst(rst),
        .PCTarget_E(PCTarget_E),
        .PCSrc_E(PCSrc_E),
        .PC_D(PC_D),
        .Instr_D(Instr_D)
    );

    // Clock generation: 100MHz (10ns period)
    always #5 clk = ~clk;

    initial begin
        $dumpfile("fetch_pipeline.vcd"); // Name of the waveform file
        $dumpvars(0, tb_fetch);
        // Manually initialize instruction memory with test machine code
        // Indices represent [Address/4]
        dut.imem.rom[0] = 32'h00100093; // addi x1, x0, 1
        dut.imem.rom[1] = 32'h00200113; // addi x2, x0, 2
        dut.imem.rom[2] = 32'h00300193; // addi x3, x0, 3
        dut.imem.rom[20] = 32'h64646464; // Jump Target data

        // Signal initialization
        clk = 0;
        rst = 1;
        PCSrc_E = 0;
        PCTarget_E = 64'b0;

        // Reset Sequence
        #15 rst = 0;
        
        // Test 1: Sequential Fetching (PC + 4)
        $display("Time=%0t | PC_D=%h | Instr_D=%h", $time, PC_D, Instr_D);
        #10; // Clock edge 1
        $display("Time=%0t | PC_D=%h | Instr_D=%h", $time, PC_D, Instr_D);
        #10; // Clock edge 2
        $display("Time=%0t | PC_D=%h | Instr_D=%h", $time, PC_D, Instr_D);

        // Test 2: Jump/Branch Simulation
        // Force an external update to address 80 (index 20)
        PCTarget_E = 64'd80; 
        PCSrc_E = 1;
        #10;
        PCSrc_E = 0;
        $display("Time=%0t | PC_D=%h | Instr_D=%h (Jump Result)", $time, PC_D, Instr_D);

        #20;
        $display("Fetch Stage Test Complete.");
        $finish;
    end
endmodule