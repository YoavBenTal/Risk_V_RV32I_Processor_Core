// --------------------------------------------------------
// YARP: Branch Control
//
// Designing the branch control unit for YARP core
//
// The unit should be able to decide if the branch is taken
// or not based on the branch instruction
// --------------------------------------------------------

module yarp_branch_control import yarp_pkg::*; (
  // Source operands
  input  logic [31:0] opr_a_i,
  input  logic [31:0] opr_b_i,

  // Branch Type
  input  logic        is_b_type_ctl_i,
  input  logic [2:0]  instr_func3_ctl_i,

  // Branch outcome
  output logic        branch_taken_o
);
  
  logic [31:0] opr_a;
  logic [31:0] opr_b;
  branch_func3_t func3;

  assign opr_a	= opr_a_i; 
  assign opr_b	= opr_b_i; 
  assign func3	= branch_func3_t'(instr_func3_ctl_i);
  
  logic [32:0] sub_res; // 1 extra bit for burrow.
  logic sign_sub;

  logic take_branch;
  logic be;
  logic bltu;
  logic lt_signed;
  logic sign_a;
  logic sign_b;
  assign sign_a = opr_a[31];
  assign sign_b = opr_b[31];

  always_comb begin
    sub_res 		= {1'b0, opr_a} + {1'b0, ~opr_b + 32'h1};
    sign_sub 		= sub_res[31];  // This is the sign without the carry-out for signed comparisons.
    be 					= (sub_res == 33'h0);
    bltu					= ~sub_res[32];  // This is the carry-out, in case of unsigned comparison, carryout=0 -> A-B<0 -> A<B.
    lt_signed 	= (sign_a & ~sign_b) | (~(sign_a ^ sign_b) & sign_sub);
    case (func3)
      BEQ: 			take_branch = be;
      BNE: 			take_branch = ~be;
      BLT: 			take_branch = lt_signed;
      BGE: 			take_branch = ~lt_signed;
      BLTU: 		take_branch = bltu;
      BGEU: 		take_branch = ~bltu;
      default: 	take_branch = 1'b0;
    endcase
    
  end
  
  assign branch_taken_o = (is_b_type_ctl_i & take_branch);
endmodule

