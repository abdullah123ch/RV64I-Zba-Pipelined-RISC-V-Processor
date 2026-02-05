// File: rtl/mem/data.sv
// Brief: Synchronous data RAM for load/store operations. Supports 64-bit word access.
// Performs synchronous writes on rising clock edge and asynchronous reads (combinational).
// Includes debug dump task for memory contents inspection.

module data (
    input  logic        clk,                     // system clock (for synchronous writes)
    input  logic        WE,                      // write enable: 1=write, 0=read-only
    input  logic [63:0] A,                       // memory address (64-bit, byte-addressable)
    input  logic [63:0] WD,                      // write data (64-bit value to store)
    output logic [63:0] RD                       // read data (64-bit value from load)
);

    // ============================================================
    // DATA MEMORY STORAGE
    // ============================================================
    // 1024 entries of 64-bit words (8 KB total)
    // Supports both load and store operations
    logic [63:0] ram [1023:0];

    // ============================================================
    // ASYNCHRONOUS READ (Combinational)
    // ============================================================
    // Provides immediate read access (no clock dependency)
    // Uses bits [12:3] of address for 8-byte (word) alignment indexing
    // Bits [2:0] would normally select within a 64-bit word; here they're ignored
    
    assign RD = ram[A[12:3]];                   // asynchronous read from address A

    // ============================================================
    // SYNCHRONOUS WRITE (on rising clock edge)
    // ============================================================
    // Commits write operation on rising clock when WE=1
    // Ensures data stability for pipelined architecture
    
    always_ff @(posedge clk) begin
        if (WE) begin
            // Write enable: store WD into memory location A
            ram[A[12:3]] <= WD;                 // write WD to address A[12:3]
        end
        // If WE=0, no write occurs (read-only cycle)
    end

    // ============================================================
    // DEBUG TASK: MEMORY DUMP
    // ============================================================
    // Displays contents of first 32 memory locations for debugging
    
    task dump_mem;
        integer k;
        begin
            $display("\n========================= DATA MEMORY DUMP =========================");
            $display(" Address    | Value (Hex)            | Decimal");
            $display("--------------------------------------------------------------------");
            for (k = 0; k < 32; k = k + 1) begin
                // Display memory address (8-byte aligned) and contents
                $display(" 0x%08h | %h | %d", k*8, ram[k], ram[k]);
            end
            $display("====================================================================\n");
        end
    endtask
    
endmodule
