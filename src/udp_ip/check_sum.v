`include "udp_para.v"

module checksum(
					i_sum,
					i_id
				);

output [15:0] i_sum;
input [15:0] i_id;

//---------------------------------------------
//i_check_sum一个周期算不出来，需要两个时钟周�
wire [15:0] I_SRC_IP0=`I_SRC_IP>>16;
wire [15:0] I_SRC_IP1=`I_SRC_IP;
wire [15:0] I_DST_IP0=`I_DST_IP>>16;
wire [15:0] I_DST_IP1=`I_DST_IP;
wire [31:0] i_sum1={`I_VER,`I_H_LENGHT,`I_SER_TYPE}+`I_LENGTH+
							i_id	+	{`I_FLAG,`I_B_SHIFT}+
							{`I_TTL,`I_PROTO}+16'd00+
							I_SRC_IP0+I_SRC_IP1+
							I_DST_IP0+I_DST_IP1;
assign i_sum=~(i_sum1[31:16]+i_sum1[15:0]);
//------------------------------------------
//i_check_sum

endmodule