module forwarding_unit
  #(
   parameter integer DATA_W = 16
   )(
      input  wire [DATA_W-1:0] rs1_ID_EX,
      input  wire [DATA_W-1:0] rs2_ID_EX,
      input  wire [DATA_W-1:0] rd_EX_MEM,
      input  wire [DATA_W-1:0] rd_MEM_WB,
      input  wire [       2:0] wb_EX_MEM,
      input  wire [       2:0] wb_MEM_WB,
      output reg  [       1:0] forward1,
      output reg  [       1:0] forward2
   );

   //forward1 = (stat) ? 2'b01 : (sata) ? 2'b10 : 2'b00;

   always @(*) begin

   if(wb_MEM_WB[2:2] && (rd_MEM_WB != 0) && (!(wb_EX_MEM[2:2] && (rd_EX_MEM != 0) && (rd_EX_MEM == rs1_ID_EX))) && (rd_MEM_WB == rs1_ID_EX))begin
         forward1 = 2'b01;
      end
      else if(wb_EX_MEM[2:2] && (rd_EX_MEM != 0) && (rd_EX_MEM == rs1_ID_EX))begin
         forward1 = 2'b10;
      end
      else begin
         forward1 = 2'b00;
      end

      if(wb_MEM_WB[2:2] && (rd_MEM_WB != 0) && (!(wb_EX_MEM[2:2] && (rd_EX_MEM != 0) && (rd_EX_MEM == rs2_ID_EX))) && (rd_MEM_WB == rs2_ID_EX))begin
         forward2 = 2'b01;
      end
      else if(wb_EX_MEM[2:2] && (rd_EX_MEM != 0) && (rd_EX_MEM == rs2_ID_EX))begin
         forward2 = 2'b10;
      end
      else begin
         forward2 = 2'b00;
      end

   end



   endmodule
