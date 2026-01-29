module data (
    input  logic        clk,
    input  logic        WE,      // Write Enable 
    input  logic [63:0] A,       // Address 
    input  logic [63:0] WD,      // Write Data 
    output logic [63:0] RD       // Read Data
);

    // Memory array: 1024 x 64-bit (8 KB total)
    logic [63:0] ram [1023:0]; 

    // Synchronous Write Logic
    always_ff @(posedge clk) begin
        if (WE) begin
            // Use bit [12:3] for 64-bit (8-byte) word alignment
            ram[A[12:3]] <= WD;
        end
    end

    // Asynchronous Read Logic
    // In a 64-bit system, we shift by 3 bits (divide by 8) for word indexing
    assign RD = ram[A[12:3]];

    task dump_mem;
        input integer words_to_dump; 
        begin
            $display("\n========================= DATA MEMORY DUMP =========================");
            $display(" Address    | Value (Hex)            | Decimal");
            $display("--------------------------------------------------------------------");
            for (integer k = 0; k < words_to_dump; k++) begin
                // Displaying address as index * 8 (since it's a 64-bit/8-byte word)
                $display(" 0x%08h | %h | %d", k*8, mem[k], mem[k]);
            end
            $display("====================================================================\n");
        end
    endtask

endmodule