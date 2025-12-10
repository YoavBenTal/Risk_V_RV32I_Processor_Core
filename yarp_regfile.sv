// --------------------------------------------------------
// RISC-V: Register File
//
// Designing the register file for YARP core.
// The register file would implement the 32 architectural
// registers, each being XLEN wide. For YARP core each of
// the register would be 32-bit wide i.e. XLEN=32
// --------------------------------------------------------

// --------------------------------------------------------
// Register File
// --------------------------------------------------------

module yarp_regfile (
  input   logic          clk,
  input   logic          reset_n,

  // Source registers
  input   logic [4:0]    rs1_addr_i,
  input   logic [4:0]    rs2_addr_i,

  // Destination register
  input   logic [4:0]    rd_addr_i,
  input   logic          wr_en_i,
  input   logic [31:0]   wr_data_i,

  // Register Data
  output  logic [31:0]   rs1_data_o,
  output  logic [31:0]   rs2_data_o
);

  // --------------------------------------------------------
  // Implement register file as an 2D array
  // Register file should:
  // - Contain the 32 architectural registers
  // - Each register should be 32-bit wide
  // - Register X0 should always return 0
  // --------------------------------------------------------
  logic [31:0] [31:0] regfile;

  always_comb begin
    rs1_data_o = regfile[rs1_addr_i];
    rs2_data_o = regfile[rs2_addr_i];
  end
  
  // Write to regfile
  always_ff @(posedge clk) begin
    if (wr_en_i) begin
      regfile[rd_addr_i] <= wr_data_i;
    end
    regfile[0] <= 32'b0;
  end
    
  // --------------------------------------------------------

  // Write to the register file should use the `rd_addr_i`
  // signal for the register file address and the `wr_en_i`
  // signal as the enable.
  
  // Read data is returned on the same cycle
  // The `rs1_addr_i` and `rs2_addr_i` are the read addresses
  // for the two source registers respectively.

endmodule

