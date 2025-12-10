// --------------------------------------------------------
// YARP: Top
//
// Designing the top module for the YARP core. This would
// instantiate and connect all the sub-modules together
// completing the entire processor.
// --------------------------------------------------------

// --------------------------------------------------------
// Yet Another RISC-V Processor - Top
// --------------------------------------------------------

module yarp_top import yarp_pkg::*; #(
  parameter RESET_PC = 32'h1000
)(
  input   logic          clk,
  input   logic          reset_n,

  // Instruction memory interface
  output  logic          instr_mem_req_o,
  output  logic [31:0]   instr_mem_addr_o,
  input   logic [31:0]   instr_mem_rd_data_i,

  // Data memory interface
  output  logic          data_mem_req_o,
  output  logic [31:0]   data_mem_addr_o,
  output  logic [1:0]    data_mem_byte_en_o,
  output  logic          data_mem_wr_o,
  output  logic [31:0]   data_mem_wr_data_o,
  input   logic [31:0]   data_mem_rd_data_i

);
  // instr and pc signals
  logic [31:0] instr;
  logic [31:0] cur_pc;
  logic [31:0] nxt_pc_mux;
  logic [31:0] pc_inc_by_4;
  
  // YARP Control Signals:
  logic       pc_sel;
  logic       opr1_sel;
  logic       opr2_sel;
  logic       mem_data_req;
  logic       mem_data_wr;
  logic [1:0] mem_data_byte_size;
  logic       mem_data_zero_extend;
  logic       rf_wr_en;
  logic [1:0] rf_wr_data_sel;
  logic [3:0] alu_func;
  
  // Yarp Decode signals:
  logic [4:0] rs1_addr;        
  logic [4:0] rs2_addr;     
  logic [4:0] rd_addr;          
  logic [6:0] instr_opcode;          
  logic [2:0] func3;      
  logic [6:0] func7;      
  logic r_type_instr;
  logic i_type_instr;
  logic s_type_instr;
  logic b_type_instr;
  logic u_type_instr;
  logic j_type_instr;
  logic [31:0] imm;
  
  // Reg file signals:
  logic [31:0] rs1_data;
  logic [31:0] rs2_data;
  logic [31:0] rf_input_data_mux;
  
  // Yarp execute:
  logic [31:0] alu_res;
  logic [31:0] opr_a;
  logic [31:0] opr_b;
  
  // Data mem
  logic [31:0] data_fetched_from_data_mem;
  
  // Branch control
  logic take_branch;
  
  // generate PC reg:
  logic reset_seen_q; // this is needed to align pc to simul.
  always_ff @(posedge clk or negedge reset_n) begin
    if (~reset_n) cur_pc <= RESET_PC;
    else if (reset_seen_q) cur_pc <= nxt_pc_mux;
  end
  
  always_ff @ (posedge clk or negedge reset_n) begin
    if (!reset_n) reset_seen_q <= 1'b0;
     else reset_seen_q <= 1'b1;
  end
  
  assign pc_inc_by_4  = cur_pc + 32'h4;
  assign nxt_pc_mux   = (take_branch | pc_sel) ? {alu_res[31:1], 1'b0} : pc_inc_by_4;
  

  // --------------------------------------------------------
  // Instruction Memory
  // --------------------------------------------------------
  yarp_instr_mem u_yarp_instr_mem (
    .clk                      (clk),
    .reset_n                  (reset_n),
    .instr_mem_pc_i           (cur_pc),
    .instr_mem_req_o          (instr_mem_req_o),
    .instr_mem_addr_o         (instr_mem_addr_o),
    .mem_rd_data_i            (instr_mem_rd_data_i),
    .instr_mem_instr_o        (instr)
  );

  // --------------------------------------------------------
  // Instruction Decode
  // --------------------------------------------------------
  yarp_decode u_yarp_decode (
    .instr_i                  (instr),
    .rs1_o                    (rs1_addr),
    .rs2_o                    (rs2_addr),
    .rd_o                     (rd_addr),
    .op_o                     (instr_opcode),
    .funct3_o                 (func3),
    .funct7_o                 (func7),
    .r_type_instr_o           (r_type_instr),
    .i_type_instr_o           (i_type_instr),
    .s_type_instr_o           (s_type_instr),
    .b_type_instr_o           (b_type_instr),
    .u_type_instr_o           (u_type_instr),
    .j_type_instr_o           (j_type_instr),
    .instr_imm_o              (imm)
  );
  
  always_comb begin
    case (rf_wr_data_sel_typed)
      NXT_PC_ADDR:  rf_input_data_mux = pc_inc_by_4;
      DATA_MEM:     rf_input_data_mux = data_fetched_from_data_mem;
      ALU_RES:      rf_input_data_mux = alu_res;
      IMMIDIET:     rf_input_data_mux = imm;
    endcase
  end
  
  // --------------------------------------------------------
  // Register File
  // --------------------------------------------------------
  yarp_regfile u_yarp_regfile (
    .clk                      (clk),
    .reset_n                  (reset_n),
    .rs1_addr_i               (rs1_addr),
    .rs2_addr_i               (rs2_addr),
    .rd_addr_i                (rd_addr),
    .wr_en_i                  (rf_wr_en),
    .wr_data_i                (rf_input_data_mux),
    .rs1_data_o               (rs1_data),
    .rs2_data_o               (rs2_data)
  );
  
  rf_mux_t rf_wr_data_sel_typed;
  assign rf_wr_data_sel_typed = rf_mux_t'(rf_wr_data_sel);
  // --------------------------------------------------------
  // Control Unit
  // --------------------------------------------------------
  yarp_control u_yarp_control (
    .instr_funct3_i           (func3),
    .instr_funct7_bit5_i      (func7[5]),
    .instr_opcode_i           (instr_opcode),
    .is_r_type_i              (r_type_instr),
    .is_i_type_i              (i_type_instr),
    .is_s_type_i              (s_type_instr),
    .is_b_type_i              (b_type_instr),
    .is_u_type_i              (u_type_instr),
    .is_j_type_i              (j_type_instr),
    
    .pc_sel_o                 (pc_sel),
    .op1sel_o                 (opr1_sel),
    .op2sel_o                 (opr2_sel),
    .data_req_o               (mem_data_req),
    .data_wr_o                (mem_data_wr),
    .data_byte_o              (mem_data_byte_size),
    .zero_extnd_o             (mem_data_zero_extend),
    .rf_wr_en_o               (rf_wr_en),
    .rf_wr_data_o             (rf_wr_data_sel),
    .alu_func_o               (alu_func)
  );

  // --------------------------------------------------------
  // Branch Control
  // --------------------------------------------------------
  yarp_branch_control u_yarp_branch_control (
    .opr_a_i                  (rs1_data),
    .opr_b_i                  (rs2_data),
    .is_b_type_ctl_i          (b_type_instr),
    .instr_func3_ctl_i        (func3),
    .branch_taken_o           (take_branch)
  );

  
  assign opr_a = opr1_sel ? cur_pc : rs1_data;
  assign opr_b = opr2_sel ? imm : rs2_data;
  // --------------------------------------------------------
  // Execute Unit
  // --------------------------------------------------------
  yarp_execute u_yarp_execute (
    .opr_a_i                  (opr_a),
    .opr_b_i                  (opr_b),
    .op_sel_i                 (alu_func),
    .alu_res_o                (alu_res)
  );

  // --------------------------------------------------------
  // Data Memory
  // --------------------------------------------------------
  yarp_data_mem u_yarp_data_mem (
    .clk                      (clk),
    .reset_n                  (reset_n),
    .data_req_i               (mem_data_req),
    .data_addr_i              (alu_res),  // addr to write calculated at ALU as rs1 + imm.
    .data_byte_en_i           (mem_data_byte_size),
    .data_wr_i                (mem_data_wr),
    .data_wr_data_i           (rs2_data),  // data to write is from rs2.
    .data_zero_extnd_i        (mem_data_zero_extend),
    
    .data_mem_req_o           (data_mem_req_o),
    .data_mem_addr_o          (data_mem_addr_o),
    .data_mem_byte_en_o       (data_mem_byte_en_o),
    .data_mem_wr_o            (data_mem_wr_o),
    .data_mem_wr_data_o       (data_mem_wr_data_o),
    .mem_rd_data_i            (data_mem_rd_data_i),
    .data_mem_rd_data_o       (data_fetched_from_data_mem)
  );

  logic _unused_ok1;
  logic _unused_ok2;
  assign _unused_ok1 = &func7[6];
  assign _unused_ok2 = &func7[4:0];
  // This just takes care of lint error that not all bits are used
endmodule
