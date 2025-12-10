// --------------------------------------------------------
// YARP: Package File
//
// The should contain all of the enums, structs or any other
// common functions used while designing the YARP core
// --------------------------------------------------------
// --------------------------------------------------------
// YARP Package
// --------------------------------------------------------

package yarp_pkg;
  
  typedef enum logic[6:0] {
    R_TYPE    = 7'h33,
    I_TYPE0   = 7'h03,
    I_TYPE1   = 7'h13,
    I_TYPE2   = 7'h67,
    S_TYPE    = 7'h23,
    B_TYPE    = 7'h63,
    U_TYPE0   = 7'h37,
    U_TYPE1   = 7'h17,
    J_TYPE    = 7'h6F
  } opcode_t;
  
  typedef enum logic [5:0] {
    IS_R_TYPE = 6'b100000,
    IS_I_TYPE = 6'b010000,
    IS_S_TYPE = 6'b001000,
    IS_B_TYPE = 6'b000100,
    IS_U_TYPE = 6'b000010,
    IS_J_TYPE = 6'b000001
    
  } instr_type_t;
  

  typedef enum logic[3:0] {
    ADD = 4'b0000,
    SUB = 4'b0001,
    SLL = 4'b0010,
    SRL = 4'b1010,
    SRA = 4'b1011,
    OR  = 4'b1100,
    AND = 4'b1110,
    XOR = 4'b1000,
    SLTU= 4'b0110,
    SLT = 4'b0100
  } alu_op_t;
  
  
  typedef enum logic[1:0] {
    BYTE_ACCESS,
    HALF_WORD_ACCESS,
    RESERVED,
    WORD_ACCESS
  } access_byte_t;

  
  typedef enum logic [1:0] {
    NXT_PC_ADDR,
    DATA_MEM,
    ALU_RES,
    IMMIDIET
  } rf_mux_t;
  
  
  typedef enum logic [2:0] {
    BEQ   = 3'b000,
    BNE   = 3'b001,
    BLT   = 3'b100,
    BGE   = 3'b101,
    BLTU  = 3'b110,
    BGEU  = 3'b111
  } branch_func3_t;
  
endpackage
