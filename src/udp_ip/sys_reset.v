`include "udp_para.v"
module sys_reset(	clk,
					rst_n,
					sys_rst_n
				);
//-------------------------------------
input clk;
input rst_n;
output reg sys_rst_n; 
//-------------------------------------
reg sys_rst_nr;
//现将异步复位信号用同步时钟打一�
`ifdef altera
always@(posedge clk)
		if(~rst_n)
		begin
			sys_rst_n  <= 0;
			sys_rst_nr <= 0;
		end
		else
		begin
			sys_rst_nr <= rst_n;   
			sys_rst_n  <= sys_rst_nr;
		end
`else
always@(posedge clk)
		if(rst_n)
		begin
			sys_rst_n  <= 0;
			sys_rst_nr <= 0;
		end
		else
		begin
			sys_rst_nr <= ~rst_n;   
			sys_rst_n  <= sys_rst_nr;
		end
`endif		
endmodule