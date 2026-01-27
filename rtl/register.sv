// Implements 32 64-bit registers with x0 hardwired to 0

module register (
    input  logic        clk,
    input  logic        rst,
    input  logic [4:0]  A1,  // Read Address 1 (rs1)
    input  logic [4:0]  A2,  // Read Address 2 (rs2)
    input  logic [4:0]  A3,  // Write Address (rd)
    input  logic [63:0] WD3, // Write Data
    input  logic        WE3, // Write Enable
    output logic [63:0] RD1, // Read Data 1
    output logic [63:0] RD2  // Read Data 2
);

    // 32 registers of 64 bits each
    logic [63:0] rf [31:1]; // x0 is omitted as it's hardwired to 0

    // Synchronous Write Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all registers to 0
            for (int i = 1; i < 32; i++) begin
                rf[i] <= 64'b0;
            end
        end else if (WE3 && (A3 != 5'b0)) begin
            // Write data to register A3 if not x0
            rf[A3] <= WD3;
        end
    end

    // Asynchronous Read Logic (with x0 check)
    assign RD1 = (A1 == 5'b0) ? 64'b0 : rf[A1];
    assign RD2 = (A2 == 5'b0) ? 64'b0 : rf[A2];

endmodule