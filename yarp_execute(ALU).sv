// --------------------------------------------------------
// RISC-V: Arithmetic Logical Unit
//
// Designing the ALU for the YARP Core supporting RV32I.
// The ALU should be able to perform all the arithmetic
// operations necessary to execute the RV32I subset of the
// instructions.
// --------------------------------------------------------

// --------------------------------------------------------
// Arithmetic Logical Unit (ALU)
// --------------------------------------------------------

module yarp_execute import yarp_pkg::*; (
  // Source operands
  input   logic [31:0] opr_a_i,
  input   logic [31:0] opr_b_i,

  // ALU Operation
  input   logic [3:0]  op_sel_i,

  // ALU output
  output  logic [31:0] alu_res_o
);
    
  logic [4:0] shamt;
  assign shamt = opr_b_i[4:0];  // shift amount
 // logic [31:0] twos_compl_a;
 // logic [31:0] twos_compl_b;
  
 // assign twos_compl_a = opr_a_i[31] ? ~opr_a_i + 31'h1 : opr_a_i;
 // assign twos_compl_b = opr_b_i[31] ? ~opr_b_i + 31'h1 : opr_b_i;
  
  always_comb begin
    unique case (op_sel_i)
    	ADD: alu_res_o = opr_a_i + opr_b_i;
      SUB: alu_res_o = opr_a_i - opr_b_i;
      SLL: alu_res_o = opr_a_i << shamt;
      SRL: alu_res_o = opr_a_i >> shamt;
      
      SRA: alu_res_o = opr_a_i >> shamt | 
        ({32{opr_a_i[31]}} & ~(32'hFFFFFFFF >> shamt));
      // SRA calculates: (SRL) OR (sign ? upper_ones : 0)
      
      OR: alu_res_o = opr_a_i | opr_b_i;
      AND: alu_res_o = opr_a_i & opr_b_i;
      XOR: alu_res_o = opr_a_i ^ opr_b_i;
      SLTU: alu_res_o = {31'h0, (opr_a_i < opr_b_i)};
      SLT: alu_res_o = ((opr_a_i[30:0] < opr_b_i[30:0]) || (opr_a_i[31] && !opr_b_i[31])) ? 32'b1 : 32'b0;
      // Here it is assumed that opr_a_i and opr_b_i are two's complement.
      default: alu_res_o = '0;
      endcase
  end

  

endmodule
