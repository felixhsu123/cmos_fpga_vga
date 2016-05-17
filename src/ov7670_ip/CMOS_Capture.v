`timescale 1ns/1ns
module CMOS_Capture
(
	//Global Clock
	input				iCLK,			//25MHz
	input				iRST_N,

	//I2C Initilize Done
	input				Config_Done,	//Configure Done
	
	//Sensor Interface
	output				CMOS_XCLK,		//25MHz
	input				CMOS_PCLK,		//25MHz
	input	[7:0]		CMOS_iDATA,		//CMOS Data
	input				CMOS_VSYNC,		//L: Vaild
	input				CMOS_HREF,		//H: Vaild
	
	//Ouput Sensor Data
	output	reg			CMOS_oCLK,		//1/2 PCLK
	output	reg	[15:0]	CMOS_oDATA,		//16Bits RGB		
	output	reg			CMOS_VALID		//Data Enable
);

assign	CMOS_XCLK = iCLK;				//25MHz XCLK


//-----------------------------------------------------
//同步输入//Sensor HS & VS Vaild Capture
/**************************************************
________							       ________
VS		|_________________________________|
HS			  _______	 	   _______
_____________|       |__...___|       |____________
**************************************************/
reg			mCMOS_VSYNC;
reg			mCMOS_HREF;
reg	[7:0]	mCMOS_iDATA;
reg			pos_CMOS_VSYNC;		//VSYNC上升沿
reg			neg_CMOS_HREF;	  	//HREF下降沿
always@(negedge CMOS_PCLK or negedge iRST_N)
begin
	if(!iRST_N)
		begin
		mCMOS_VSYNC <= 1;
		mCMOS_HREF <= 0;
		mCMOS_iDATA <= 0;
		pos_CMOS_VSYNC <= 0;
		neg_CMOS_HREF <= 0;
		end
	else
		begin
		mCMOS_VSYNC <= CMOS_VSYNC;		//场同步：低电平有效
		mCMOS_HREF <= CMOS_HREF;		//行同步：高电平有效
		mCMOS_iDATA <= CMOS_iDATA;		//CMOS数据同步
		pos_CMOS_VSYNC <= ({mCMOS_VSYNC,CMOS_VSYNC} == 2'b01) ? 1'b1 : 1'b0;	//VSYNC上升沿结束
		neg_CMOS_HREF <= ({mCMOS_HREF,CMOS_HREF} == 2'b10) ? 1'b1 : 1'b0;		//HREF 下降沿结束
		end
end

//--------------------------------------------
//Counter the HS & VS Pixel
localparam		H_DISP	=	12'd640;
localparam		V_DISP	=	12'd480;
reg		[11:0]	X_Cont;	//640
reg		[11:0]	Y_Cont;	//480
//-----------------------------------------------------
//X_Cont 行有效信号计数
reg	byte_cnt;	//byte count
always@(posedge CMOS_PCLK or negedge iRST_N)
begin
	if(!iRST_N)
		begin
		byte_cnt <= 0;
		X_Cont <= 0;
		end
	else if(mCMOS_VSYNC == 1'b0)			//场信号有效
		begin
		if(mCMOS_HREF)
			begin
			byte_cnt <= byte_cnt + 1'b1;	//（RGB565 = {first_byte, second_byte}）
			X_Cont <= (byte_cnt == 1'b1) ?  X_Cont + 1'b1 : X_Cont;
			end
		else
			begin
			byte_cnt <= 0;
			X_Cont <= 0;
			end
		end
	else
		begin
		byte_cnt <= 0;
		X_Cont <= 0;
		end
end

//-----------------------------------------------------
//Y_Cont场有效信号计数
always@(posedge CMOS_PCLK or negedge iRST_N)
begin
	if(!iRST_N)
		Y_Cont <= 0;
	else if(mCMOS_VSYNC == 1'b0)
		begin
		if(neg_CMOS_HREF == 1'b1)		//HREF下降沿 一行结束
			Y_Cont <= Y_Cont + 1'b1;
		else
			Y_Cont <= Y_Cont;
		end
	else
		Y_Cont <= 0;
end

//-----------------------------------------------------
//Change the sensor data from 8 bits to 16 bits.
reg  data_change_state;
reg [7:0]  Pre_CMOS_iDATA;
always@(posedge CMOS_PCLK or negedge iRST_N)
begin
	if(!iRST_N)
		begin
		CMOS_oDATA <= 16'd0;
		data_change_state <= 1'b0;
		end
	else
		begin
		if(~mCMOS_VSYNC & mCMOS_HREF)		//行场有效，{first_byte, second_byte} 
			case(data_change_state)
			1'b0 : 
				begin
				Pre_CMOS_iDATA[7:0] <= mCMOS_iDATA;
				data_change_state <= 1'b1;
				end
			1'b1 : 
				begin
				CMOS_oDATA <= {Pre_CMOS_iDATA[7:0], mCMOS_iDATA};
				data_change_state <= 1'b0;
				end
			default : 
				begin
				CMOS_oDATA <= CMOS_oDATA;
				data_change_state <= 1'b0;
				end
			endcase
		else
			begin
			CMOS_oDATA <= CMOS_oDATA;
			data_change_state <= 1'b0;
			end
		end
end


//--------------------------------------------
//Wait for Sensor output Data valid， 10 Franme
reg	[3:0] 	Frame_Cont;
reg 		data_valid;
always@(posedge CMOS_PCLK or negedge iRST_N)
begin
	if(!iRST_N)
		begin
		Frame_Cont <= 0;
		data_valid <= 0;
		end
	else if(Config_Done)				//CMOS I2C初始化完毕
		begin
		if(pos_CMOS_VSYNC == 1'b1)		//VS上升沿，1帧写入完毕
			begin
			if(Frame_Cont < 10)
				begin
				Frame_Cont	<=	Frame_Cont + 1'b1;
				data_valid <= 1'b0;
				end
			else
				begin
				Frame_Cont	<=	Frame_Cont;
				data_valid <= 1'b1;		//数据输出有效
				end
			end
		end
end

//-----------------------------------------------------
//CMOS_DATA数据同步输出使能时钟
always@(posedge CMOS_PCLK or negedge iRST_N)
begin
	if(!iRST_N)
		CMOS_oCLK <= 0;
	else if(data_valid == 1'b1 && (X_Cont >= 12'd1 && X_Cont <= H_DISP))
		CMOS_oCLK <= ~CMOS_oCLK;
	else
		CMOS_oCLK <= 0;
end

//----------------------------------------------------
//数据输出有效CMOS_VALID
always@(posedge CMOS_PCLK or negedge iRST_N)
begin
	if(!iRST_N)
		CMOS_VALID <= 0;
	else if(data_valid == 1'b1)
		CMOS_VALID <= ~mCMOS_VSYNC;
	else
		CMOS_VALID <= 0;
end

endmodule



