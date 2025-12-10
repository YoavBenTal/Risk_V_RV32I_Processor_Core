// --------------------------------------------------------
// YARP: Control Unit
//
// Designing the instruction control unit for YARP core
//
// The control signals should be generated for every
// supported instruction
// --------------------------------------------------------

module yarp_control import yarp_pkg::*; (
  // Instruction type
  input   logic         is_r_type_i,
  input   logic         is_i_type_i,
  input   logic         is_s_type_i,
  input   logic         is_b_type_i,
  input   logic         is_u_type_i,
  input   logic         is_j_type_i,

  // Instruction opcode/funct fields
  input   logic [2:0]   instr_funct3_i,
  input   logic         instr_funct7_bit5_i,
  input   logic [6:0]   instr_opcode_i,

  // Control signals
  output  logic         pc_sel_o,
  output  logic         op1sel_o,
  output  logic         op2sel_o,
  output  logic [3:0]   alu_func_o,
  output  logic [1:0]   rf_wr_data_o,
  output  logic         data_req_o,
  output  logic [1:0]   data_byte_o,
  output  logic         data_wr_o,
  output  logic         zero_extnd_o,
  output  logic         rf_wr_en_o
);
 
  rf_mux_t rf_wr_data;
  assign rf_wr_data_o = rf_wr_data;
  
  alu_op_t alu_func;
  assign alu_func_o = alu_func;
  
  logic arthm_imm_select;  // Selects between arithmatic operations on imm (1) and load operationc(0) in I type instructions.
  assign arthm_imm_select = instr_opcode_i[4];
  
  logic jalr_select;  // selects I-type commands - JALR.
  assign jalr_select = instr_opcode_i[6];
  
  logic lui_select;  // Selects between U - type commands: LUI and AUIPC.
  assign lui_select = instr_opcode_i[5];
  
  
  instr_type_t instr_type;
  assign instr_type = instr_type_t'({is_r_type_i, is_i_type_i, is_s_type_i, is_b_type_i, is_u_type_i, is_j_type_i});
  always_comb begin
    // operands select
    pc_sel_o      = 1'b0; // 0 - next PC value, 1 - branch/jump
    op1sel_o      = 1'b0; // 0 - choose rs1, 1 - choose PC addr
    op2sel_o      = 1'b0; // 0 - choose rs2, 1 - choose imm
    alu_func    = alu_op_t'(0);
    
    // Register file interface
    rf_wr_en_o    = 1'b0; // 1 - Enable write to register file.
    rf_wr_data    = rf_mux_t'(0); // rf mux selector - NXT_PC_ADDR, DATA_MEM, ALU_RES, IMMIDIET
    
    // Data mem interface:
    data_req_o    = 1'b0;
    data_byte_o   = 2'b0;
    data_wr_o     = 1'b0;
    zero_extnd_o  = 1'b0;
    
    case (instr_type)
      IS_R_TYPE: begin    
        rf_wr_en_o    = 1'b1;
        rf_wr_data    = ALU_RES;
        alu_func    = alu_op_t'({instr_funct3_i, instr_funct7_bit5_i});
      end
      
      IS_I_TYPE: begin  // instr_opcode_i[4] = 1 is load, otherwise its arithmatic.
        // if arithmetic on imm:
        pc_sel_o      = jalr_select ? 1'b1 : 1'b0;
        op2sel_o      = 1'b1;
        alu_func      = alu_op_t'(arthm_imm_select ? {instr_funct3_i, 1'b0} : ADD);
        // rs1 + imm is the memory addr for the load instr.
        rf_wr_en_o    = 1'b1;
        rf_wr_data    = rf_mux_t'(arthm_imm_select ? ALU_RES :
                                  jalr_select      ? NXT_PC_ADDR : DATA_MEM);
        data_req_o    = (arthm_imm_select | jalr_select) ? 1'b0 : 1'b1;
        data_byte_o   = {instr_funct3_i[1], (instr_funct3_i[0] | instr_funct3_i[1])};
        // This is the func3 field of the load instr   
        // 00 -> 00 LB/LBU
        // 01 -> 01 LH/LHU
        // 10 -> 11 LW
        // And signed or unsigned is decided by bit 3:
        zero_extnd_o = instr_funct3_i[2];
      end
      
      IS_S_TYPE: begin 
        // store instr
        // rs1 + imm is the address to store.
        // rs2 holds the data to store. this will be connected at top. TODO!!
        op2sel_o      = 1'b1;
        alu_func      = ADD;

        data_req_o    = 1'b1;
        data_byte_o   = {instr_funct3_i[1], (instr_funct3_i[0] | instr_funct3_i[1])};
        data_wr_o     = 1'b1;
      end
      
      IS_B_TYPE: begin
        // Branch addr is calculated as PC_addr + imm:
        // Branch condition is calculated at branch_logic module. TODO!!
        op1sel_o      = 1'b1;
        op2sel_o      = 1'b1;
        alu_func      = ADD;
        // Issue here, we have an output pc_sel_o, we cant seem to calculate both addr and branch condition
        //in the same cycle using only the ALU, 
        //i assumed the condition be calculated in the branch control unit 
        //but then here we wounldnt have the pc_sel_o signal.

        
      end
      
      IS_U_TYPE: begin // Load upper imm (LUI) or add upper imm to PC (AUIPC)
        op1sel_o      = 1'b1;
        op2sel_o      = 1'b1;
        alu_func      = ADD;
        
        rf_wr_en_o    = 1'b1;
        rf_wr_data    = rf_mux_t'(lui_select ? IMMIDIET : ALU_RES);
      end
      
      IS_J_TYPE: begin // Uncoditional jump instr to addr = current_pc + imm. current_pc + 4 is stored to rd.
        pc_sel_o      = 1'b1;
        op1sel_o      = 1'b1;
        op2sel_o      = 1'b1;
        alu_func      = ADD;
        
        rf_wr_en_o    = 1'b1;
        rf_wr_data    = NXT_PC_ADDR;
      end
      default:;
    endcase
  end
  
  logic _unused_ok;
  assign _unused_ok = &instr_opcode_i[3:0];
  // This just takes care of lint error that not all bits are used
endmodule

