// 64-bit Program Counter 
module pc (
    input  logic        clk,
    input  logic        rst,
    input  logic [63:0] PCNext, // Address calculated by Fetch Stage logic
    output logic [63:0] PC      // Current PC value for the Fetch stage
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            PC <= 64'b0; 
        end else begin
            PC <= PCNext;
        end
    end

endmodule