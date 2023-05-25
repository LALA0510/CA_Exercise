module hazard_unit(
      input  wire [       4:0] raddr_1,
      input  wire [       4:0] raddr_2,
      input  wire [       4:0] raddr_rd,
      input  wire  mem_read,
      output reg   hazard_enable,
      output reg  hazard_mux
   );

   always @(*) begin
   
        if (mem_read && ((raddr_rd == raddr_1) || (raddr_rd == raddr_2))) begin
            hazard_enable <= 1'b1;
            hazard_mux <= 1'b1;
        end
        else begin
            hazard_enable <= 1'b0;
            hazard_mux <= 1'b0;
        end
   end

   endmodule