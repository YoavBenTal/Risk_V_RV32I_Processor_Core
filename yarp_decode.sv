// --------------------------------------------------------
// YARP: Instruction Decode
//
// Designing the instruction decode unit for YARP core
// capable of decoding all the six types of instructions:
//    - R Type
//    - I Type
//    - S Type
//    - B Type
//    - U Type
//    - J Type
//
// The decode should be able to decode and return needed
// information about the instruction in the same cycle
// --------------------------------------------------------

module yarp_decode import yarp_pkg::*; (
  input   logic [31:0]  instr_i,
  
  output  logic [4:0]   rs1_o,
  output  logic [4:0]   rs2_o,
  output  logic [4:0]   rd_o,
  output  logic [6:0]   op_o,
  output  logic [2:0]   funct3_o,
  output  logic [6:0]   funct7_o,
  output  logic         r_type_instr_o,
  output  logic         i_type_instr_o,
  output  logic         s_type_instr_o,
  output  logic         b_type_instr_o,
  output  logic         u_type_instr_o,
  output  logic         j_type_instr_o,
  output  logic [31:0]  instr_imm_o
);
  
  opcode_t op; 
  logic [5:0] one_hot_opcode;
  
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rd;
  logic [2:0] funct3;
  logic [6:0] funct7;

    // These signals are always in these slots of the instr. If they are not needed they will not be used.
  assign rs1 = instr_i[19:15];
  assign rs2 = instr_i[24:20];
  assign rd = instr_i[11:7];
  assign funct3 = instr_i[14:12];
  assign funct7 = instr_i[31:25];
  
  assign op_o = op;
  assign rs1_o = rs1;
  assign rs2_o = rs2;
  assign rd_o = rd;
  assign funct3_o = funct3;
  assign funct7_o = funct7;
  
  
  always_comb begin
    op = opcode_t'(instr_i[6:0]);  // casting to opcode_t for type checks and safety.
    unique case (op_o)
      R_TYPE: one_hot_opcode = 6'b000001;
      
      I_TYPE0,
      I_TYPE1,
      I_TYPE2:one_hot_opcode = 6'b000010;
      
      S_TYPE: one_hot_opcode = 6'b000100;
      B_TYPE: one_hot_opcode = 6'b001000;
      
      U_TYPE0,
      U_TYPE1: one_hot_opcode = 6'b010000;
      
      J_TYPE: one_hot_opcode = 6'b100000;
      default: one_hot_opcode = 6'b0;
    endcase     
  end
  
  assign r_type_instr_o = one_hot_opcode[0];
  assign i_type_instr_o = one_hot_opcode[1];
  assign s_type_instr_o = one_hot_opcode[2];
  assign b_type_instr_o = one_hot_opcode[3];
  assign u_type_instr_o = one_hot_opcode[4];
  assign j_type_instr_o = one_hot_opcode[5];
  
  
  // The imm structure changes with every opcode so here we decode the correct imm from the instr:
  wire [31:0] i_type_imm;
  wire [31:0] s_type_imm;
  wire [31:0] b_type_imm;
  wire [31:0] u_type_imm;
  wire [31:0] j_type_imm;
  
  assign i_type_imm = {{20{instr_i[31]}}, instr_i[31:20]};
  assign s_type_imm = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
  assign b_type_imm = {{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
  assign u_type_imm = {instr_i[31:12], 12'b0};
  assign j_type_imm = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};

  assign instr_imm_o = r_type_instr_o ? '0 :
  										 i_type_instr_o ? i_type_imm :
  										 s_type_instr_o ? s_type_imm :
  										 b_type_instr_o ? b_type_imm :
  										 u_type_instr_o ? u_type_imm :
      								 									j_type_imm ;
    

endmodule

