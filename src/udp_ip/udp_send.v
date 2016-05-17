`include "udp_para.v"

module udp_send(s_clk,
				rst_n,
				s_en,
				fifo_data,
				fifo_en,
				dataout,
				go,
				dst_mac,
				dst_ip,
				arp
				);
input arp;
input [31:0] dst_ip;
input [47:0] dst_mac;
output reg [3:0] dataout;
input rst_n;
output reg fifo_en;
output reg s_en;//allow phy send
input s_clk;//phy输入的发送时�input rst_n;
input [3:0] fifo_data;//buffer data in;
input go;//控制开始发�----------------------------
//parameter 
//--------------------------------------
//--------------------------------------
//mac crc 校验
wire [31:0] crc,crc_next;
reg crc_rst_n;
reg crc_en;
crc crc1(	.clk(s_clk), 
			.rst_n(crc_rst_n), 
			.data(dataout), 
			.en(crc_en), 
			.crc(crc),
			.crc_next(crc_next));
//发送状态机
//-----------------------
reg [3:0] s_state;//工作状态控�//reg [5:0] d_num;//每个阶段需要发送的4bit的个�
reg [9:0] index;//当前发送的位置索引
reg [15:0] i_id;//IP头中的标�
wire [15:0] i_chk_sum;//ip check_sum
//reg [3:0] tmp;
reg [47:0] buffer;
always@(posedge s_clk or negedge rst_n)
begin
	if(~rst_n)
	begin
		s_state <= `S_IDEL;
		index <= 0;
		dataout <= 0;
		i_id <= 0;
		crc_rst_n <= 0;
		crc_en <= 0;
		s_en <= 1'b0;
	end
	else begin
		case(s_state)
		`S_IDEL:begin
					if(go)
						begin
							s_state <= `S_M_PRE;
							crc_rst_n <= 0;
							crc_en <= 0;
							index <= 0;
							dataout <=4'h5;
							//s_en <= 1'b1;
						end
					else if(arp)
					begin
						buffer[15:0] <= `ARP_TYPE;
						s_state <= `S_IDEL;
					end
					else
					begin
							s_state <= `S_IDEL;
							buffer[15:0] <= `M_TYPE;
					end
				end
		`S_M_PRE:begin
						
						s_en <= 1'b1;
						dataout <= `M_PRE>>(index*4);
						if(index==`S_M_PRE_LTH-1)
						begin
							s_state <= `S_MAC;
							index <= `S_M_LTH-1;
						end
						else 	
						begin
							index <= index+1'b1;		
						end
					end
		`S_MAC:	begin
						index <= index-1'b1;
						crc_en <= 1;
						crc_rst_n <= 1;
						if(index>`S_M_LTH-1-12)
						begin
							//dataout <= (`M_DST>>((index-16)*4));
							dataout <= (dst_mac>>((index-16)*4));
						end
						else if(index>`S_M_LTH-1-24)
						begin
							dataout <= (`M_SRC>>((index-4)*4));
						end
						else if(index==`S_M_LTH-1-24)
						begin
							dataout <= buffer[11:8];
						end
						else if(index==`S_M_LTH-1-25)
						begin
							dataout <= buffer[15:12];	
						end
						else if(index==`S_M_LTH-1-26)
						begin
							dataout <= buffer[3:0];
						end
						else if(index==`S_M_LTH-1-27)
						begin
							dataout <= buffer[7:4];
							s_state <=(buffer[15:0] == `ARP_TYPE)?`S_ARP:`S_IP;//!!!
							//s_state <= `S_IP;
							index <= 0;
							i_id <= i_id+1;
						end
						else
							dataout <= dataout;
					end
		`S_IP:	begin
						index <= index+1'b1;
						case(index)
						0:	begin dataout <= `I_H_LENGHT; end
						1:	begin dataout <= `I_VER; end
						2:	begin dataout <= `I_SER_TYPE; end
						3:	begin dataout <= `I_SER_TYPE>>4; end
						4:	begin dataout <= `I_LENGTH>>8; end//头总长�+28byte固定
						5:	begin dataout <= `I_LENGTH>>12;end//头总长�			
						6:	begin dataout <= `I_LENGTH; end//头总长�			
						7:	begin dataout <= `I_LENGTH>>4; end//头总长�			
						8:	begin dataout <= (i_id/256); end
						9:	begin dataout <= (i_id/4096); end
						10:	begin dataout <= (i_id%256); end
						11:	begin dataout <= (i_id%256)>>4; end
						12:	begin dataout <= `I_B_SHIFT>>8; end//
						13:	begin dataout <= {`I_FLAG,1'b0}|(`I_B_SHIFT>>12); end
						14:	begin dataout <= `I_B_SHIFT; end
						15:	begin dataout <= `I_B_SHIFT>>4; end
						16:	begin dataout <= `I_TTL; end
						17:	begin dataout <= `I_TTL>>4; end
						18:	begin dataout <= `I_PROTO; end
						19:	begin dataout <= `I_PROTO>>4; end
						20:	begin dataout <= i_chk_sum>>8; end
						21:	begin dataout <= i_chk_sum>>12; end
						22:	begin dataout <= i_chk_sum; end
						23:	begin dataout <= i_chk_sum>>4; end
						24:	begin dataout <= `I_SRC_IP>>24; end
						25:	begin dataout <= `I_SRC_IP>>28; end
						26:	begin dataout <= `I_SRC_IP>>16; end
						27:	begin dataout <= `I_SRC_IP>>20; end
						28:	begin dataout <= `I_SRC_IP>>8; end
						29:	begin dataout <= `I_SRC_IP>>12; end
						30:	begin dataout <= `I_SRC_IP; end
						31:	begin dataout <= `I_SRC_IP>>4; end
						32:	begin dataout <= `I_DST_IP>>24; end
						33:	begin dataout <= `I_DST_IP>>28; end
						34:	begin dataout <= `I_DST_IP>>16; end
						35:	begin dataout <= `I_DST_IP>>20; end
						36:	begin dataout <= `I_DST_IP>>8; end
						37:	begin dataout <= `I_DST_IP>>12; end
						38:	begin dataout <= `I_DST_IP; end
						39:	begin
								dataout <= `I_DST_IP>>4;
								s_state <= `S_UDP;
								index <= 0;
							end
						default:dataout <= dataout;
						endcase	
					end
		`S_UDP:	begin
						index <= index+1'b1;
						case(index)
						0:begin	dataout <= `U_SRC_P>>8;end
						1:begin dataout <= `U_SRC_P>>12;end
						2:begin dataout <= `U_SRC_P;end
						3:begin dataout <= `U_SRC_P>>4;end
						4:begin dataout <= `U_DST_P>>8;end
						5:begin dataout <= `U_DST_P>>12;end
						6:begin dataout <= `U_DST_P;end
						7:begin dataout <= `U_DST_P>>4;end//
						8:begin dataout <= `U_LENGTH>>8;end
						9:begin dataout <= `U_LENGTH>>12;end
						10:begin dataout <= `U_LENGTH;end
						11:begin dataout <= `U_LENGTH>>4;end//
						12:begin dataout <= 4'd0;end
						13:begin dataout <= 4'd0;end
						14:begin dataout <= 4'd0;fifo_en <= 1;end
						15:	begin 
								index <= (`U_D_LTH*2-1 <35)?35:`U_D_LTH*2-1;
								s_state <=(`U_D_LTH*2-1 <35)?`S_DATA_S:`S_DATA_L;
								dataout <= 4'd0;
							end
						default:dataout <= dataout;
						endcase
					end
		`S_DATA_S:	begin
						dataout <=(index>(35-(`U_D_LTH*2-1)-1))?fifo_data:0;
						index <= index-1'b1;
						case(index)
						0:	begin
								s_state <= `S_CRC;
								index <= 0;
							end
						//35-(`U_D_LTH*2-1)-1:crc_en <= 0;	
						35-(`U_D_LTH*2-1)+1:fifo_en <= 0;	 
						default: s_state <= s_state;
						endcase
					end
		`S_DATA_L:	begin
						dataout <= fifo_data;
						index <= index-1'b1;
						case(index)
						0:	begin
								s_state <= `S_CRC;
								index <= 0;
							end
						1:	fifo_en <= 0;
						default: s_state <= s_state;
						endcase
					end
			
		 `S_CRC:	begin
					index <= index+1'b1;
					case(index)	
					0:	begin 
							crc_en <= 0;
							dataout <={~crc_next[28], ~crc_next[29], ~crc_next[30], ~crc_next[31]};
						end
					1:begin dataout <= {~crc[24], ~crc[25], ~crc[26], ~crc[27]};end
					2:begin dataout <= {~crc[20], ~crc[21], ~crc[22], ~crc[23]} ;end
					3:begin dataout <= {~crc[16], ~crc[17], ~crc[18], ~crc[19]};end
					4:begin dataout <= {~crc[12], ~crc[13], ~crc[14], ~crc[15]};end
					5:begin dataout <= {~crc[8], ~crc[9], ~crc[10], ~crc[11]} ;end
					6:begin dataout <= {~crc[4], ~crc[5], ~crc[6], ~crc[7]} ;end
					7:	begin 
							dataout <= {~crc[0], ~crc[1], ~crc[2], ~crc[3]};
							s_state <= `S_DONE;
							index <= `S_W_CLK-2;//��������֮֡������ڼ���						
						end
					default:dataout <= dataout;
					endcase
				end
		`S_DONE:	begin 
						dataout <=  4'd0;
						s_en <= 0;
						index <= index-1;
						if(index==0) //��̫����һ֡�ĳ�������128clk;
							s_state <= `S_IDEL;
						else
							s_state <= s_state;
					end
		`S_ARP:	begin
					index <= index+1'b1;
					case(index)
					0:dataout <= 4'h0;
					1:dataout <= 4'h0;
					2:dataout <= 4'h1;
					3:dataout <= 4'h0;
					4:dataout <= 4'h8;
					5:dataout <= 4'h0;
					6:dataout <= 4'h0;
					7:dataout <= 4'h0;
					8:dataout <= 4'h6;
					9:dataout <= 4'h0;
					10:dataout <= 4'h4;
					11:dataout <= 4'h0;
					12:dataout <= 4'h0;
					13:dataout <= 4'h0;
					14:dataout <= 4'h2;
					15:begin 
						dataout <= 4'h0;
						buffer <= `M_SRC;
						end
					16:dataout <= buffer[47:44];
					17:dataout <= buffer[43:40];
					18:dataout <= buffer[39:36];
					19:dataout <= buffer[35:32];
					20:dataout <= buffer[31:28];
					21:dataout <= buffer[27:24];
					22:dataout <= buffer[23:20];
					23:dataout <= buffer[19:16];
					24:dataout <= buffer[15:12];
					25:dataout <= buffer[11:8];
					26:dataout <= buffer[7:4];
					27:begin 
						dataout <= buffer[3:0];
						buffer[31:0] <= `I_SRC_IP;
						end
					28:dataout <= buffer[27:24];
					29:dataout <= buffer[31:28];
					30:dataout <= buffer[19:16];
					31:dataout <= buffer[23:20];
					32:dataout <= buffer[11:8];
					33:dataout <= buffer[15:12];
					34:dataout <= buffer[3:0];
					35:begin 
						dataout <= buffer[7:4];
						buffer <= dst_mac;//
						end
					36:dataout <= buffer[47:44];
					37:dataout <= buffer[43:40];
					38:dataout <= buffer[39:36];
					39:dataout <= buffer[35:32];
					40:dataout <= buffer[31:28];
					41:dataout <= buffer[27:24];
					42:dataout <= buffer[23:20];
					43:dataout <= buffer[19:16];
					44:dataout <= buffer[15:12];
					45:dataout <= buffer[11:8];
					46:dataout <= buffer[7:4];
					47:begin 
						dataout <= buffer[3:0];
						buffer[31:0] <= dst_ip;//
						end
					48:dataout <= buffer[31:28];
					49:dataout <= buffer[27:24];
					50:dataout <= buffer[23:20];
					51:dataout <= buffer[19:16];
					52:dataout <= buffer[15:12];
					53:dataout <= buffer[11:8];
					54:dataout <= buffer[7:4] ;
					55:dataout <= buffer[3:0];
					56:dataout <= 4'h0;
					91:begin 
						s_state <= `S_CRC;
						index <= 0;
						end
					default:s_state <= s_state;
					endcase
				end
		default:s_state <= s_state;
		endcase
	end
		
end
//----------------------------------------
//i_check_sum 生成
checksum checksum1(	.i_sum(i_chk_sum),
							.i_id(i_id)
					);
endmodule
