// --------------------------------------------------------
// YARP: Data Memory
//
// Designing the data memory unit for the YARP core which
// implements the interface to the data memory used for
// reading and writing data
// --------------------------------------------------------

// --------------------------------------------------------
// Data Memory
// --------------------------------------------------------

module yarp_data_mem import yarp_pkg::*; (
  input   logic           clk,
  input   logic           reset_n,

  // Data request from current instruction
  input   logic           data_req_i,
  input   logic [31:0]    data_addr_i,
  input   logic [1:0]     data_byte_en_i,
  input   logic           data_wr_i,
  input   logic [31:0]    data_wr_data_i,

  input   logic           data_zero_extnd_i,//

  // Read/Write request to memory
  output  logic           data_mem_req_o,
  output  logic  [31:0]   data_mem_addr_o,
  output  logic  [1:0]    data_mem_byte_en_o,
  output  logic           data_mem_wr_o,
  output  logic  [31:0]	  data_mem_wr_data_o,
  // Read data from memory
  input   logic [31:0]    mem_rd_data_i,//

  // Data output
  output  logic [31:0]    data_mem_rd_data_o//
);
  
  access_byte_t data_byte_size;
  assign data_byte_size = access_byte_t'(data_byte_en_i);

	assign data_mem_req_o			 = data_req_i;
	assign data_mem_addr_o		 = data_addr_i;
  assign data_mem_byte_en_o	 = data_byte_size;
  assign data_mem_wr_o 		 	 = data_wr_i;
  assign data_mem_wr_data_o	 = data_wr_data_i;
  
  // In case of read (load) req (data_wr_i=0) we need to correctly pad the read data.
  logic [31:0] mem_rd_data;
  assign mem_rd_data = mem_rd_data_i;
  always_comb begin
    unique case (data_byte_size)
      BYTE_ACCESS: begin
        data_mem_rd_data_o = data_zero_extnd_i ? {24'h0, mem_rd_data[7:0]} : {{24{mem_rd_data[7]}}, mem_rd_data[7:0]};
      end
      
      HALF_WORD_ACCESS: begin
        data_mem_rd_data_o = data_zero_extnd_i ? {16'h0, mem_rd_data[15:0]} : {{16{mem_rd_data[15]}}, mem_rd_data[15:0]};
      end
      
      WORD_ACCESS: begin
        data_mem_rd_data_o = mem_rd_data;
      end
      default: data_mem_rd_data_o = mem_rd_data;
    endcase
  end
        
      
  
  

  
  
  
endmodule

