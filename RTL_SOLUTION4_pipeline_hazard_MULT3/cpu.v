//Module: CPU
//Function: CPU is the top design of the RISC-V processor

//Inputs:
//	clk: main clock
//	arst_n: reset
// enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory

// Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[63:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[63:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [63:0]  wdata_ext_2,

		output wire	[31:0]  rdata_ext,
		output wire	[63:0]  rdata_ext_2

   );

wire              zero_flag;
wire [      63:0] branch_pc,updated_pc,current_pc,jump_pc;
wire [      31:0] instruction;
wire [       1:0] alu_op;
wire [       3:0] alu_control;
wire              reg_dst,branch,mem_read,mem_2_reg,
                  mem_write,alu_src, reg_write, jump;
wire [       4:0] regfile_waddr;
wire [      63:0] regfile_wdata,mem_data,alu_out,
                  regfile_rdata_1,regfile_rdata_2,
                  alu_operand_2, wire_jal;

wire signed [63:0] immediate_extended;

// Register WIREs
wire zero_flag_EX_MEM;
wire [ 1:0] forward1, forward2;
wire [ 2:0] cntrEX_ID_EX, cntrM_ID_EX, cntrWB_ID_EX, cntrM_EX_MEM, cntrWB_EX_MEM, cntrWB_MEM_WB;
wire [ 4:0] instructionALU_ID_EX, instructionWB_ID_EX, instructionWB_EX_MEM, instructionWB_MEM_WB, rs1_ID_EX, rs2_ID_EX;
wire [31:0] instruction_IF_ID;
wire [63:0] current_pc_IF_ID, current_pc_ID_EX, updated_pc_IF_ID, reg1_ID_EX, 
            reg2_ID_EX, immediate_extended_ID_EX, updated_pc_ID_EX, alu_out_EX_MEM, 
            reg2_EX_MEM, updated_pc_EX_MEM, mem_data_MEM_WB, alu_out_MEM_WB, updated_pc_MEM_WB, alu_forward_operand_1, alu_forward_operand_2;

// IF STAGE BEGIN    //////////////////////////////////////
pc #(
   .DATA_W(64)
) program_counter (
   .clk       (clk               ),
   .arst_n    (arst_n            ),
   .branch_pc (branch_pc_EX_MEM  ),
   .jump_pc   (jump_pc_EX_MEM    ),
   .zero_flag (zero_flag_EX_MEM  ),
   .branch    (cntrM_EX_MEM[2:2] ),// branch
   .jump      (cntrWB_EX_MEM[0:0]),// jump 
   .current_pc(current_pc        ),
   .enable    (enable            ),
   .updated_pc(updated_pc        )
);

sram_BW32 #(// The instruction memory.
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ),
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);
// IF STAGE END      //////////////////////////////////////

// IF_ID REG BEGIN   //////////////////////////////////////
reg_arstn_en #(
   .DATA_W(32) // width of the forwarded signal
)REG_instruction_IF_ID(
   .clk        (clk                 ),
   .arst_n     (arst_n              ),
   .en         (enable              ),
   .din        (instruction         ),
   .dout       (instruction_IF_ID   )
);

reg_arstn_en #(
   .DATA_W(64) // width of the forwarded signal
)PC_IF_ID(
   .clk        (clk                 ),
   .arst_n     (arst_n              ),
   .en         (enable              ),
   .din        (current_pc          ),
   .dout       (current_pc_IF_ID    )
);

reg_arstn_en #(
   .DATA_W(64)
)REG_updated_pc_IF_ID(
   .clk        (clk                 ),
   .arst_n     (arst_n              ),
   .en         (enable              ),
   .din        (updated_pc          ),
   .dout       (updated_pc_IF_ID    )
);
// IF_ID REG END     //////////////////////////////////////



// ID STAGE BEGIN    //////////////////////////////////////
control_unit control_unit(
   .opcode   (instruction_IF_ID[6:0]),
   .alu_op   (alu_op          ),
   .reg_dst  (reg_dst         ),
   .branch   (branch          ),
   .mem_read (mem_read        ),
   .mem_2_reg(mem_2_reg       ),
   .mem_write(mem_write       ),
   .alu_src  (alu_src         ),
   .reg_write(reg_write       ),
   .jump     (jump            )
);

register_file #(
   .DATA_W(64)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(cntrWB_MEM_WB[2:2]),// reg_write
   .raddr_1  (instruction_IF_ID[19:15]),
   .raddr_2  (instruction_IF_ID[24:20]),
   .waddr    (instructionWB_MEM_WB ),// instruction_MEM_WB[11:7]
   .wdata    (regfile_wdata     ),
   .rdata_1  (regfile_rdata_1   ),
   .rdata_2  (regfile_rdata_2   )
);

immediate_extend_unit immediate_extend_u(
    .instruction         (instruction_IF_ID),
    .immediate_extended  (immediate_extended)
);
// ID STAGE END      //////////////////////////////////////

// ID_EX REG BEGIN   //////////////////////////////////////

// cntrWB_ID_EX
reg_arstn_en #(
   .DATA_W(3)
)REG_cntrEX_ID_EX(
   .clk        (clk                 ),
   .arst_n     (arst_n              ),
   .en         (enable              ),
   .din        ({alu_op, alu_src}   ),
   .dout       (cntrEX_ID_EX        )
);
// cntrM_ID_EX
reg_arstn_en #(
   .DATA_W(3)
)REG_cntrM_ID_EX(
   .clk        (clk                             ),
   .arst_n     (arst_n                          ),
   .en         (enable                          ),
   .din        ({branch, mem_read, mem_write}   ),
   .dout       (cntrM_ID_EX                     )
);
// cntrEX_ID_EX
reg_arstn_en #(
   .DATA_W(3)
)REG_cntrWB_ID_EX(
   .clk        (clk                          ),
   .arst_n     (arst_n                       ),
   .en         (enable                       ),
   .din        ({reg_write, mem_2_reg, jump} ),
   .dout       (cntrWB_ID_EX                 )
);

reg_arstn_en #(
   .DATA_W(64)
)PC_ID_EX(
   .clk        (clk                 ),
   .arst_n     (arst_n              ),
   .en         (enable              ),
   .din        (current_pc_IF_ID    ),
   .dout       (current_pc_ID_EX    )
);

reg_arstn_en #(// reg1_ID_EX
   .DATA_W(64)
)REG_reg1_ID_EX(
   .clk        (clk                       ),
   .arst_n     (arst_n                    ),
   .en         (enable                    ),
   .din        (regfile_rdata_1           ),
   .dout       (reg1_ID_EX                )
);

reg_arstn_en #(// reg2_ID_EX
   .DATA_W(64)
)REG_reg2_ID_EX(
   .clk        (clk                       ),
   .arst_n     (arst_n                    ),
   .en         (enable                    ),
   .din        (regfile_rdata_2           ),
   .dout       (reg2_ID_EX                )
);

reg_arstn_en #(
   .DATA_W(64)
)immExt_ID_EX(
   .clk        (clk                       ),
   .arst_n     (arst_n                    ),
   .en         (enable                    ),
   .din        (immediate_extended        ),
   .dout       (immediate_extended_ID_EX  )
);

reg_arstn_en #(
   .DATA_W(5)
)instrALU_ID_EX(
   .clk        (clk                                               ),
   .arst_n     (arst_n                                            ),
   .en         (enable                                            ),
   .din        ({instruction_IF_ID[30], instruction_IF_ID[25], instruction_IF_ID[14:12]} ),
   .dout       (instructionALU_ID_EX                              )
);

reg_arstn_en #(
   .DATA_W(5)
)REG_instructionWB_ID_EX(
   .clk        (clk                       ),
   .en         (enable                    ),
   .arst_n     (arst_n                    ),
   .din        (instruction_IF_ID[11:7]   ),
   .dout       (instructionWB_ID_EX       )
);

reg_arstn_en #(
   .DATA_W(5)
)REG_rs1_ID_EX(
   .clk        (clk                       ),
   .en         (enable                    ),
   .arst_n     (arst_n                    ),
   .din        (instruction_IF_ID[19:15]  ),
   .dout       (rs1_ID_EX                 )
);

reg_arstn_en #(
   .DATA_W(5)
)REG_rs2_ID_EX(
   .clk        (clk                       ),
   .en         (enable                    ),
   .arst_n     (arst_n                    ),
   .din        (instruction_IF_ID[24:20]  ),
   .dout       (rs2_ID_EX                 )
);

reg_arstn_en #(
   .DATA_W(64)
)REG_updated_pc_ID_EX(
   .clk        (clk                 ),
   .arst_n     (arst_n              ),
   .en         (enable              ),
   .din        (updated_pc_IF_ID    ),
   .dout       (updated_pc_ID_EX    )
);
// ID_EX REG END     //////////////////////////////////////

// EX STAGE BEGIN    //////////////////////////////////////

forwarding_unit#(
   .DATA_W(5)
   )forwarding_unit(
      .rs1_ID_EX(rs1_ID_EX),
      .rs2_ID_EX(rs2_ID_EX),
      .rd_EX_MEM(instructionWB_EX_MEM),
      .rd_MEM_WB(instructionWB_MEM_WB),
      .wb_EX_MEM(cntrWB_EX_MEM),
      .wb_MEM_WB(cntrWB_MEM_WB),
      .forward1(forward1),
      .forward2(forward2)
   );

branch_unit#(
   .DATA_W(64)
)branch_unit(
   .updated_pc         (updated_pc_ID_EX        ),// updated_pc
   .immediate_extended (immediate_extended_ID_EX),// immediate_extended
   .branch_pc          (branch_pc               ),
   .jump_pc            (jump_pc                 )
);

alu_control alu_ctrl(
   .func7_5        (instructionALU_ID_EX[4:4]   ),
   .MULT           (instructionALU_ID_EX[3:3]   ),
   .func3          (instructionALU_ID_EX[2:0]   ),
   .alu_op         (cntrEX_ID_EX[2:1]           ),// alu_op
   .alu_control    (alu_control                 )
);

mux_3 #(
   .DATA_W(64)
) alu_forward_mux1 (
   .input_a (reg1_ID_EX        ),// immExt_ID_EX
   .input_b (regfile_wdata                      ),
   .input_c (alu_out_EX_MEM                      ),
   .select_a(forward1               ),// alu_src
   .mux_out (alu_forward_operand_1                   )
);

mux_3 #(
   .DATA_W(64)
) alu_forward_mux2 (
   .input_a (reg2_ID_EX        ),// immExt_ID_EX
   .input_b (regfile_wdata                      ),
   .input_c (alu_out_EX_MEM                      ),
   .select_a(forward2               ),// alu_src
   .mux_out (alu_forward_operand_2                   )
);

mux_2 #(
   .DATA_W(64)
) alu_operand_mux (
   .input_a (immediate_extended_ID_EX        ),// immExt_ID_EX
   .input_b (alu_forward_operand_2                      ),
   .select_a(cntrEX_ID_EX[0:0]               ),// alu_src
   .mux_out (alu_operand_2                   )
);

alu#(
   .DATA_W(64)
) alu(
   .alu_in_0 (alu_forward_operand_1      ),// regfile_rdata_1
   .alu_in_1 (alu_operand_2   ),
   .alu_ctrl (alu_control     ),
   .alu_out  (alu_out         ),
   .zero_flag(zero_flag       ),
   .overflow (                )
);
// EX STAGE END      //////////////////////////////////////


// EX_MEM REG BEGIN  //////////////////////////////////////
reg_arstn_en #(// cntrM_EX_MEM
   .DATA_W(3)
)REG_cntrM_EX_MEM(
   .clk        (clk           ),
   .arst_n     (arst_n        ),
   .en         (enable        ),
   .din        (cntrM_ID_EX   ),
   .dout       (cntrM_EX_MEM  )
);

reg_arstn_en #(// cntrWB_EX_MEM
   .DATA_W(3)
)REG_cntrWB_EX_MEM(
   .clk        (clk           ),
   .arst_n     (arst_n        ),
   .en         (enable        ),
   .din        (cntrWB_ID_EX  ),
   .dout       (cntrWB_EX_MEM )
);

reg_arstn_en #(// branch_pc_EX_MEM
   .DATA_W(64)
)REG_branch_pc_EX_MEM(
   .clk        (clk              ),
   .arst_n     (arst_n           ),
   .en         (enable           ),
   .din        (branch_pc          ),
   .dout       (branch_pc_EX_MEM   )
);

reg_arstn_en #(// jump_pc_EX_MEM
   .DATA_W(64)
)REG_jump_pc_EX_MEM(
   .clk        (clk              ),
   .arst_n     (arst_n           ),
   .en         (enable           ),
   .din        (jump_pc          ),
   .dout       (jump_pc_EX_MEM   )
);

reg_arstn_en #(// zero_flag_EX_MEM
   .DATA_W(1)
)REG_zero_flag_EX_MEM(
   .clk        (clk              ),
   .arst_n     (arst_n           ),
   .en         (enable           ),
   .din        (zero_flag        ),
   .dout       (zero_flag_EX_MEM )
);

reg_arstn_en #(// alu_out_EX_MEM
   .DATA_W(64)
)REG_alu_out_EX_MEM(
   .clk        (clk              ),
   .arst_n     (arst_n           ),
   .en         (enable           ),
   .din        (alu_out          ),
   .dout       (alu_out_EX_MEM   )
);

reg_arstn_en #(// reg2_EX_MEM
   .DATA_W(64)
)REG_reg2_EX_MEM(
   .clk        (clk           ),
   .arst_n     (arst_n        ),
   .en         (enable        ),
   .din        (alu_forward_operand_2     ),// reg2_ID_EX
   .dout       (reg2_EX_MEM   )
);

reg_arstn_en #(
   .DATA_W(5)
)REG_instructionWB_EX_MEM(// instructionWB_EX_MEM
   .clk        (clk                 ),
   .en         (enable              ),
   .arst_n     (arst_n              ),
   .din        (instructionWB_ID_EX ),
   .dout       (instructionWB_EX_MEM)
);

reg_arstn_en #(
   .DATA_W(64)
)REG_updated_pc_EX_MEM(
   .clk        (clk                 ),
   .arst_n     (arst_n              ),
   .en         (enable              ),
   .din        (updated_pc_ID_EX    ),
   .dout       (updated_pc_EX_MEM    )
);
// EX_MEM REG END    //////////////////////////////////////    


// MEM STAGE BEGIN   //////////////////////////////////////
sram_BW64 #(// The data memory.
   .ADDR_W(10),
   .DATA_W(64)
) data_memory(
   .clk      (clk            ),
   .addr     (alu_out_EX_MEM     ),// alu_out
   .wen      (cntrM_EX_MEM[0:0]  ),// mem_write 
   .ren      (cntrM_EX_MEM[1:1]       ),// mem_read
   .wdata    (reg2_EX_MEM ),// regfile_rdata_2
   .rdata    (mem_data       ),
   .addr_ext (addr_ext_2     ),
   .wen_ext  (wen_ext_2      ),
   .ren_ext  (ren_ext_2      ),
   .wdata_ext(wdata_ext_2    ),
   .rdata_ext(rdata_ext_2    )
);
// MEM STAGE END     //////////////////////////////////////     


// MEM_WB REG BEGIN  //////////////////////////////////////
// cntrWB_MEM_WB
reg_arstn_en #(// cntrWB_MEM_WB
   .DATA_W(3)
)REG_cntrWB_MEM_WB(
   .clk        (clk           ),
   .arst_n     (arst_n        ),
   .en         (enable        ),
   .din        (cntrWB_EX_MEM    ),
   .dout       (cntrWB_MEM_WB   )
);

// mem_data
reg_arstn_en #(// reg2_EX_MEM
   .DATA_W(64)
)REG_mem_data_MEM_WB(
   .clk        (clk           ),
   .arst_n     (arst_n        ),
   .en         (enable        ),
   .din        (mem_data      ),
   .dout       (mem_data_MEM_WB   )
);
// alu_out_EX_MEM
reg_arstn_en #(// reg2_EX_MEM
   .DATA_W(64)
)REG_alu_out_MEM_WB(
   .clk        (clk           ),
   .arst_n     (arst_n        ),
   .en         (enable        ),
   .din        (alu_out_EX_MEM    ),
   .dout       (alu_out_MEM_WB   )
);

reg_arstn_en #(
   .DATA_W(5)
)REG_instructionWB_MEM_WB(// instructionWB_MEM_WB
   .clk        (clk                 ),
   .en         (enable              ),
   .arst_n     (arst_n              ),
   .din        (instructionWB_EX_MEM ),
   .dout       (instructionWB_MEM_WB)
);

reg_arstn_en #(
   .DATA_W(64)
)REG_updated_pc_MEM_WB(
   .clk        (clk                 ),
   .arst_n     (arst_n              ),
   .en         (enable              ),
   .din        (updated_pc_EX_MEM    ),
   .dout       (updated_pc_MEM_WB    )
);
// MEM_WB REG END    //////////////////////////////////////    


// WB STAGE BEGIN    //////////////////////////////////////

mux_2 #(
   .DATA_W(64)
) regfile_data_mux (
   .input_a  (mem_data_MEM_WB     ),// mem_data
   .input_b  (alu_out_MEM_WB      ),// alu_out
   .select_a (cntrWB_MEM_WB[1:1]    ),// mem_2_reg
   .mux_out  (wire_jal)
);

mux_2 #(
   .DATA_W(64)
) regfile_data_mux_1 (
   .input_a  (updated_pc_MEM_WB     ),
   .input_b  (wire_jal      ),
   .select_a (cntrWB_MEM_WB[1:1] && cntrWB_MEM_WB[0:0]   ),// (mem_2_reg && jump)
   .mux_out  (regfile_wdata)
);

// WB STAGE END      //////////////////////////////////////      


endmodule


