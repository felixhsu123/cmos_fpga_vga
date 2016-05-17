`include "udp_para.v"

module udp_receive(	r_clk,
					rst_n,
					r_dv,
					fifo_data,
					fifo_en,
					datain,
					arp_req,
					arp,
					dst_ip,
					dst_mac
					);
//
output reg [3:0] fifo_data;
output reg arp;
//output reg [7:0] led; 
output reg [47:0] dst_mac;
output reg [31:0] dst_ip;
output reg arp_req;
output reg fifo_en;
input [3:0] datain;
input r_clk;
input rst_n;
input r_dv;
//½ÓÊÕ×´Ì¬»ú
reg [3:0] r_state;
reg [63:0] buffer;
reg [9:0] index;
//------------------------------------
//assign fifo_data= datain;
//assign led[3:0]=r_state;
reg [47:0] dst_mac_r;
//------------------------------------
always @ (posedge r_clk or negedge rst_n)
begin
	if(~rst_n)
	begin
		r_state <= `R_IDEL ;
		buffer 	<= 0;
		index  	<= 0;
		fifo_en <= 0;
		arp_req <= 0;
		dst_mac <= `M_DST;
		//led <=0;
		//arp <= 0;
	end
	else
	begin
		case(r_state)
		`R_IDEL:begin
					if(r_dv)
					begin
						buffer[63:60] <= datain;
						r_state <= `R_M_PRE;
					end
					else
						r_state <= `R_IDEL;
				end
		`R_M_PRE:begin
					buffer <= { datain, buffer[63:4] };
					if({ datain, buffer[63:4] } == `M_PRE)
					begin
						r_state <= `R_MAC;
						buffer <= {64{1'b0}};
						index  <= 0;
					end
					else if(~r_dv)
						r_state <= `R_IDEL;
					else
						r_state <=r_state;
				end
		`R_MAC:	begin	
					buffer <= { buffer[59:0] , datain };
					index  <= index + 1'b1;
					case (index)
					12	:	begin 
							if(buffer[47:0] == `M_SRC)
							begin
								r_state <= r_state;
							end
							else if(buffer[47:0] == {48{1'b1}})
								r_state <= r_state;
							else
								r_state <= `R_IDEL;
							end
					//24	:	dst_mac <= buffer[47:0];
					27	: 	begin
							if({ buffer[11:0] , datain } == (`M_TYPE<<4 & 16'hf0_f0) | (`M_TYPE>>4 & 16'h0f_0f) )
							begin	
								r_state <= `R_IP;
								index  <= 0;
								buffer <= {64{1'b0}};
								arp <= 0;
							end
							else if({ buffer[11:0] , datain } == (`ARP_TYPE<<4 & 16'hf0_f0) | (`ARP_TYPE>>4 & 16'h0f_0f)) //arp
							begin	
								r_state <= `R_ARP;
								index  <= 0;
								buffer <= {64{1'b0}};
								arp <= 1;
							end
							else
							begin
								r_state <= `R_IDEL;
								arp <= 0;
							end
					
							end
					default:r_state <= r_state;
					endcase
				end
		`R_IP:	begin
				index  <= index + 1'b1;
				buffer <= { buffer[59:0] , datain };
				case(index)	
				1:	begin 
					if(datain == `I_VER)
					begin
						r_state <= r_state;
					end
					else
						r_state <= `R_IDEL;
					end
				13:	begin
					if(datain[3:1] == 3'b000)
					begin
						r_state <= r_state;
					end
					else
						r_state <= `R_IDEL;
					end
				18:begin
					if(datain == 4'h1)
					begin
						r_state <= r_state;
					end
					else
						r_state <= `R_IDEL;
					end
				19:begin
					if(datain == 4'h1)
					begin
						r_state <= r_state;
					end
					else
						r_state <= `R_IDEL;
					end
				39:	begin
					if({ buffer[27:0] , datain } == ((`I_SRC_IP<<4 & 32'hf0_f0_f0_f0) | (`I_SRC_IP>>4 & 32'h0f_0f_0f_0f)))	
					begin
						r_state <= `R_UDP;
						index  <= 0;
						buffer <= {64{1'b0}};
					end
					else
						r_state <= `R_IDEL;
					end
				default:r_state <= r_state;
				endcase
				end
		`R_UDP:	begin
					index  <= index + 1'b1;
					case (index)
					8:	begin
						buffer <= { buffer[59:0] , datain };
						end
					9:	begin
						buffer <= { buffer[59:4] , datain ,buffer[3:0]};
						end
					10:	begin
						buffer <= { buffer[59:0] , datain };
						end
					11:	begin
						buffer <= { buffer[59:4] , datain ,buffer[3:0]};
						end
					15:	begin
							index <= (buffer[15:0]-8)*2-1;
							r_state <= `R_DATA;
						end
					default:r_state <= r_state;
					endcase	
				end
		`R_DATA:begin
					fifo_en <= 1'b1;
					index <= index-1;
					fifo_data  <= datain;
					if(index == 0)
					begin
						r_state <= `R_CRC;
						index <= 0;
					end
					else
					begin
						r_state <= r_state;
					end
				end
		`R_CRC:	begin
					fifo_en <= 1'b0;
					//fifo_data  <= datain;
					index <= index+1;
					if(index == 3)
						r_state <= `R_DONE;
					else
						r_state <= r_state;
				end
		`R_DONE:begin
				if(r_dv)
					r_state <= r_state;
				else
					r_state <= `R_IDEL;	
				end
		`R_ARP:begin
					index  <= index + 1'b1;
					buffer <= { buffer[59:0] , datain};
					case(index)
					28:	dst_mac_r <= buffer[47:0];
					36: dst_ip <= buffer[31:0];
					37:begin
						if(dst_ip==((`I_DST_IP<<4 & 32'hf0_f0_f0_f0) | (`I_DST_IP>>4 & 32'h0f_0f_0f_0f)))
						begin	
							r_state <= r_state;	
							dst_mac <= dst_mac_r;
						end
						else
						begin
							r_state <= `R_IDEL;	
							dst_mac <= dst_mac;//`M_DST;
						end
						end
					55:	begin
							if({ buffer[27:0] , datain } == ((`I_SRC_IP<<4 & 32'hf0_f0_f0_f0) | (`I_SRC_IP>>4 & 32'h0f_0f_0f_0f)))	
							begin		
									arp_req <= 1;
							end
							else
							begin
								    arp_req <= 0;
									r_state <= `R_IDEL;	
							end
						end
					57:	begin
							arp_req <= 0;
							r_state <= `R_IDEL;	
							arp <= 0;
						end
					default:r_state <= r_state;	
					endcase
				
			   end
		endcase
	end
		
end
endmodule