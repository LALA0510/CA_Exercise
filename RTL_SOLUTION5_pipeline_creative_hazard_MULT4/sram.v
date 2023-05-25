//Instruction Memory
//Function: The instruction memory pointed by the PC is retrieved. Taking into account the input address (addr) the data will be put in the read data output (rdata).
//Inputs:
//clk: System clock
//arst_n: Asynchronous Reset
//wen: Write Enable Signal. Since the instruction memory is not written after initialization, this input must be statically deasserted (wen=0).
//Ren: Read Enable Signal. Since the instruction memory must be continuouslly read, this input must be statically asserted (ren=1).
//Outputs:
//rdata: Instruction read taking into account the address pointed.



//Data Memory
//Function: The data memory has 2 main functions. (1) In the case of a LW instruction, read the value pointed by the read address (addr) and put its value into the read data (rdata) (2) In the case of a SW instruction, store a word into the address pointed by the write address (addr)
//Taking into account the input address (addr) the data will be put in the read data output (rdata).
//Inputs:
//clk: System clock
//arst_n: Asynchronous Reset
//wen: Write Enable Signal. Since the instruction memory is not written after initialization, this input must be statically deasserted (wen=0).
//Ren: Read Enable Signal. Since the instruction memory must be continuouslly read, this input must be statically asserted (ren=1).
//Outputs:
//rdata: Instruction read taking into account the address pointed.



module sram_BW32#(
   parameter integer ADDR_W      = 9
) (
		input wire			       clk,
		input wire	      [63:0] addr,
		input wire	      [63:0] addr_ext,
      input wire               wen,
      input wire               wen_ext,
      input wire               ren,
      input wire               ren_ext,
		input wire 	      [31:0] wdata,
		input wire 	      [31:0] wdata_ext,
		output reg	      [31:0] rdata,
		output reg	      [31:0] rdata_ext

   );
parameter integer SEL_W       = (ADDR_W>9) ? ADDR_W-9 : 0;
parameter integer MACRO_DEPTH = 128;
parameter integer N_MEMS      = 2**(ADDR_W - 2)/MACRO_DEPTH;


reg  [      6:0] addr_i, addr_ext_i;
reg  [  SEL_W:0] mem_sel;
reg  [  SEL_W:0] mem_sel_ext;
wire [     31:0] data_i     [0:(2**SEL_W)-1];
wire [     31:0] data_ext_i [0:(2**SEL_W)-1];
reg              cs_i       [0:(2**SEL_W)-1];
reg              cs_ext_i   [0:(2**SEL_W)-1];
 
reg web0, web1, csb0, csb1;

always@(*)begin
   rdata     = data_i    [mem_sel][31:0];
   // print each read for debug
   // $display($time, " sram_BW32 rdata = %h", rdata);

   rdata_ext = data_ext_i[mem_sel_ext][31:0]; 
end 


always@(*)begin
   addr_i      = addr    [8:2];
   addr_ext_i  = addr_ext[8:2];
   web0        = (~wen) | ren ;
   csb0        = wen ~^ ren;
   web1        = (~wen_ext) | ren_ext; 
   csb1        = wen_ext ~^ ren_ext;
   mem_sel     = (SEL_W == 0) ? 1'b0 : addr[SEL_W +: 9];
   mem_sel_ext = (SEL_W == 0) ? 1'b0 : addr_ext[SEL_W +: 9];
end

genvar index_depth;
generate
   for (index_depth = 0; index_depth < N_MEMS; index_depth = index_depth+1) begin: process_for_mem
         always@(*)begin
            cs_i[index_depth] = (mem_sel == index_depth) ? 1'b0 : 1'b1;
            cs_ext_i[index_depth] = (mem_sel == index_depth) ? 1'b0 : 1'b1;
         end
         sky130_sram_2rw_32x128_32  dram_inst(
            .clk0         ( ~clk                         ),
            .csb0         ( csb0 | cs_i[index_depth]     ),
            .web0         ( web0                         ),
            .addr0        ( addr_i                       ),
            .din0         ( wdata                        ),
            .dout0        ( data_i[index_depth]          ),
            .clk1         ( ~clk                         ),
            .csb1         ( csb1 | cs_ext_i[index_depth] ),
            .web1         ( web1                         ),
            .addr1        ( addr_ext_i                   ),
            .din1         ( wdata_ext                    ),
            .dout1        ( data_ext_i[index_depth]      )
         );

   end
endgenerate
	
endmodule


module sram_BW64#(
   parameter integer ADDR_W      = 10
) (
		input wire			       clk,
		input wire	      [63:0] addr,
		input wire	      [63:0] addr_ext,
      input wire               wen,
      input wire               wen_ext,
      input wire               ren,
      input wire               ren_ext,
		input wire 	      [63:0] wdata,
		input wire 	      [63:0] wdata_ext,
		output reg	      [63:0] rdata,
		output reg	      [63:0] rdata_ext

   );
parameter integer SEL_W       = (ADDR_W>10) ? ADDR_W-10 : 0;
parameter integer MACRO_DEPTH = 128;
parameter integer N_MEMS      = 2**(ADDR_W - 3)/MACRO_DEPTH;


reg  [      6:0] addr_i, addr_ext_i;
reg  [  SEL_W:0] mem_sel;
reg  [  SEL_W:0] mem_sel_ext;
wire [     63:0] data_i     [0:(2**SEL_W)-1];
wire [     63:0] data_ext_i [0:(2**SEL_W)-1];
reg              cs_i       [0:(2**SEL_W)-1];
reg              cs_ext_i   [0:(2**SEL_W)-1];
 
reg web0, web1, csb0, csb1;


always@(*)begin
   rdata     = data_i    [mem_sel][63:0];
   // print each read for debug
   // $display($time, " sram_BW64 rdata = %h", rdata);
   
   rdata_ext = data_ext_i[mem_sel_ext][63:0]; 
end 

always@(*)begin
   addr_i      = addr    [9:3];
   addr_ext_i  = addr_ext[9:3];
   web0        = (~wen) | ren ;
   csb0        = wen ~^ ren;
   web1        = (~wen_ext) | ren_ext; 
   csb1        = wen_ext ~^ ren_ext;
   mem_sel     = (SEL_W == 0) ? 1'b0 : addr[SEL_W +: 10];
   mem_sel_ext = (SEL_W == 0) ? 1'b0 : addr_ext[SEL_W +: 10];
end

genvar index_depth;
generate
   for (index_depth = 0; index_depth < N_MEMS; index_depth = index_depth+1) begin: process_for_mem
         always@(*)begin
            cs_i[index_depth] = (mem_sel == index_depth) ? 1'b0 : 1'b1;
            cs_ext_i[index_depth] = (mem_sel == index_depth) ? 1'b0 : 1'b1;
         end

         sky130_sram_2rw_64x128_64  spad_inst( 
            .clk0         ( ~clk                         ),
            .csb0         ( csb0 | cs_i[index_depth]     ),
            .web0         ( web0                         ),
            .addr0        ( addr_i                       ),
            .din0         ( wdata                        ),
            .dout0        ( data_i[index_depth]          ),
            .clk1         ( ~clk                         ),
            .csb1         ( csb1 | cs_ext_i[index_depth] ),
            .web1         ( web1                         ),
            .addr1        ( addr_ext_i                   ),
            .din1         ( wdata_ext                    ),
            .dout1        ( data_ext_i[index_depth]      )
         );
      
   end
endgenerate
	
endmodule
