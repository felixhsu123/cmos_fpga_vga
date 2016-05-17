module crc (clk, rst_n, data, en, crc,crc_next);

input clk;
input rst_n;
input [0:3] data;
input en;

output reg [31:0] crc;
output [31:0] crc_next;
//wire [31:0] crc_next;
//output reg [31:0] crc_next1;
assign crc_next[0] = en & (data[0] ^ crc[28]); 
assign crc_next[1] = en & (data[1] ^ data[0] ^ crc[28] ^ crc[29]); 
assign crc_next[2] = en & (data[2] ^ data[1] ^ data[0] ^ crc[28] ^ crc[29] ^ crc[30]); 
assign crc_next[3] = en & (data[3] ^ data[2] ^ data[1] ^ crc[29] ^ crc[30] ^ crc[31]); 
assign crc_next[4] = (en & (data[3] ^ data[2] ^ data[0] ^ crc[28] ^ crc[30] ^ crc[31])) ^ crc[0]; 
assign crc_next[5] = (en & (data[3] ^ data[1] ^ data[0] ^ crc[28] ^ crc[29] ^ crc[31])) ^ crc[1]; 
assign crc_next[6] = (en & (data[2] ^ data[1] ^ crc[29] ^ crc[30])) ^ crc[ 2]; 
assign crc_next[7] = (en & (data[3] ^ data[2] ^ data[0] ^ crc[28] ^ crc[30] ^ crc[31])) ^ crc[3]; 
assign crc_next[8] = (en & (data[3] ^ data[1] ^ data[0] ^ crc[28] ^ crc[29] ^ crc[31])) ^ crc[4]; 
assign crc_next[9] = (en & (data[2] ^ data[1] ^ crc[29] ^ crc[30])) ^ crc[5]; 
assign crc_next[10] = (en & (data[3] ^ data[2] ^ data[0] ^ crc[28] ^ crc[30] ^ crc[31])) ^ crc[6]; 
assign crc_next[11] = (en & (data[3] ^ data[1] ^ data[0] ^ crc[28] ^ crc[29] ^ crc[31])) ^ crc[7]; 
assign crc_next[12] = (en & (data[2] ^ data[1] ^ data[0] ^ crc[28] ^ crc[29] ^ crc[30])) ^ crc[8]; 
assign crc_next[13] = (en & (data[3] ^ data[2] ^ data[1] ^ crc[29] ^ crc[30] ^ crc[31])) ^ crc[9]; 
assign crc_next[14] = (en & (data[3] ^ data[2] ^ crc[30] ^ crc[31])) ^ crc[10]; 
assign crc_next[15] = (en & (data[3] ^ crc[31])) ^ crc[11]; 
assign crc_next[16] = (en & (data[0] ^ crc[28])) ^ crc[12]; 
assign crc_next[17] = (en & (data[1] ^ crc[29])) ^ crc[13]; 
assign crc_next[18] = (en & (data[2] ^ crc[30])) ^ crc[14]; 
assign crc_next[19] = (en & (data[3] ^ crc[31])) ^ crc[15]; 
assign crc_next[20] = crc[16]; 
assign crc_next[21] = crc[17]; 
assign crc_next[22] = (en & (data[0] ^ crc[28])) ^ crc[18]; 
assign crc_next[23] = (en & (data[1] ^ data[0] ^ crc[29] ^ crc[28])) ^ crc[19]; 
assign crc_next[24] = (en & (data[2] ^ data[1] ^ crc[30] ^ crc[29])) ^ crc[20]; 
assign crc_next[25] = (en & (data[3] ^ data[2] ^ crc[31] ^ crc[30])) ^ crc[21]; 
assign crc_next[26] = (en & (data[3] ^ data[0] ^ crc[31] ^ crc[28])) ^ crc[22]; 
assign crc_next[27] = (en & (data[1] ^ crc[29])) ^ crc[23]; 
assign crc_next[28] = (en & (data[2] ^ crc[30])) ^ crc[24]; 
assign crc_next[29] = (en & (data[3] ^ crc[31])) ^ crc[25]; 
assign crc_next[30] = crc[26]; 
assign crc_next[31] = crc[27]; 

//------------------------------
wire n_clk=~clk;
always @ (posedge clk or negedge rst_n)
begin
	if (~rst_n)
		crc <={32{1'b1}};
	else 	
	begin
		crc <=en?crc_next:crc;
		//crc_next1<=crc_next;
	end
end

/* always @ (negedge clk)
begin
	if (en)
		crc_next1<=crc_next;
	else
		crc_next1<=crc_next1;
end */

endmodule
