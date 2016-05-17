`timescale 1ns / 1ps
module cmos_fpga_vga
(
	//global
	input			clk_50,			//global clock 50MHz
	input			rst_n,			//global reset
	
	//sdram control
	output			sdram_clk,		//sdram clock
	output			sdram_cke,		//sdram clock enable
	output			sdram_cs_n,		//sdram chip select
	output			sdram_we_n,		//sdram write enable
	output			sdram_cas_n,	//sdram column address strobe
	output			sdram_ras_n,	//sdram row address strobe
	output			sdram_udqm,		//sdram data enable (H:8)
	output			sdram_ldqm,		//sdram data enable (L:8)
	output	[1:0]	sdram_ba,		//sdram bank address
	output	[11:0]	sdram_addr,		//sdram address
	inout	[15:0]	sdram_data,		//sdram data
	
	//lcd port
	output			lcd_dclk,		//lcd pixel clock			
	output			lcd_hs,			//lcd horizontal sync 
	output			lcd_vs,			//lcd vertical sync
	output			lcd_sync,		//lcd sync
	output			lcd_blank,		//lcd blank(L:blank)
	output	[9:0]	lcd_red,		//lcd red data
	output	[9:0]	lcd_green,		//lcd green data
	output	[9:0]	lcd_blue,		//lcd blue data
	
	//cmos interface
	output			i2c_sclk,		//cmos i2c clock
	inout			i2c_sdat,		//cmos i2c data
	input			cmos_vsync,		//cmos vsync
	input			cmos_href,		//cmos hsync refrence
	input			cmos_pclk,		//cmos pxiel clock
	output			cmos_xclk,		//cmos externl clock
	input	[7:0]	cmos_data,		//cmos data
	output			cmos_rst_n,		//cmos reset
	output			cmos_pwdn,		//cmos pwer down	
	//led
	output [7:0] led_data,
	//
	input rx_dv,
	input phy_clk_rx,
	input phy_clk_tx,
	input key1,
	input [3:0] rx_data,
	output [3:0] tx_data,
	output tx_en,
	output phy_rst_n
);
//---------------------------------------------
assign	led_data = {8{Config_Done}};
//assign	led_data = I2C_RDATA;
//---------------------------------------------
wire	clk_vga;
wire	clk_ref;
wire	clk_refout;
wire	sys_rst_n;
system_ctrl	u_system_ctrl
(
	.clk				(clk_50),
	.rst_n				(rst_n),
	
	.sys_rst_n			(sys_rst_n),
	.clk_c0				(clk_vga),		//25MHz
	.clk_c1				(clk_ref),		//125MHz	-3ns
	.clk_c2				(clk_refout)	//125MHz
);

//----------------------------------------------
wire			wr_load;			//sdram write address reset
wire			rd_load;			//sdram read address reset
wire			sys_we;				//fifo write enable
wire	[15:0]	sys_data_in;   		//fifo data input
wire			sys_rd;        		//fifo read enable
wire	[15:0]	sys_data_out;  		//fifo data output
wire			lcd_framesync;		//lcd frame sync
wire			sdram_init_done;	//sdram init done
wire			frame_write_done;	//sdram write frame done
wire			frame_read_done;	//sdram read frame done
wire	[1:0]	wr_bank;			//sdram write bank
wire	[1:0]	rd_bank;			//sdram read bank
sdram_2fifo_top	u_sdram_2fifo_top
(
	//global clock
	.clk_ref			(clk_ref),			//sdram	reference clock
	.clk_refout			(clk_refout),		//sdram clk	input 
	.clk_write			(clk_vga),			//fifo data write clock
	.clk_read			(clk_vga),			//fifo data read clock
	.rst_n				(sys_rst_n),		//global reset
	
	//sdram interface
	.sdram_clk			(sdram_clk),		//sdram clock	
	.sdram_cke			(sdram_cke),		//sdram clock enable	
	.sdram_cs_n			(sdram_cs_n),		//sdram chip select	
	.sdram_we_n			(sdram_we_n),		//sdram write enable	
	.sdram_ras_n		(sdram_ras_n),		//sdram column address strobe	
	.sdram_cas_n		(sdram_cas_n),		//sdram row address strobe	
	.sdram_ba			(sdram_ba),			//sdram data enable (H:8)    
	.sdram_addr			(sdram_addr),		//sdram data enable (L:8)	
	.sdram_data			(sdram_data),		//sdram bank address	
	.sdram_udqm			(sdram_udqm),		//sdram address	
	.sdram_ldqm			(sdram_ldqm),		//sdram data
	
	//user interface
	//burst and addr
	.wr_length			(9'd256),			//sdram write burst length
	.rd_length			(9'd256),			//sdram read burst length
	.wr_addr			({wr_bank,22'd0}),			//sdram start write address
	.wr_max_addr		({wr_bank,22'd307200}),		//sdram max write address
	.wr_load			(wr_load),			//sdram write address reset
	.rd_addr			({rd_bank,22'd0}),			//sdram start read address
	.rd_max_addr		({rd_bank,22'd307200}),		//sdram max read address
	.rd_load			(rd_load),			//sdram read address reset
	
	//dcfifo interface
	.sdram_init_done	(sdram_init_done),	//sdram init done
	.frame_write_done	(frame_write_done),	//sdram write one frame
	.frame_read_done	(frame_read_done),	//sdram read one frame
	.sys_we				(sys_we),			//fifo write enable
	.sys_data_in		(sys_data_in),		//fifo data input sys_data_in
	.sys_rd				(sys_rd),			//fifo read enable
	.sys_data_out		(sys_data_out),		//fifo data output
	.data_valid			(lcd_framesync)		//system data output enable
);


sdbank_switch	u_sdbank_switch
(
	//global
	.clk				(clk_vga),
	.rst_n				(sys_rst_n),
	
	.bank_valid			(cmos_valid),
	.frame_write_done	(frame_write_done),
	.frame_read_done	(frame_read_done),
	
	.wr_bank			(wr_bank),
	.rd_bank			(rd_bank),
	.wr_load			(wr_load),
	.rd_load			(rd_load)
);

//-----------------------------
assign	cmos_rst_n = 1'b1;		//cmos work state (50us delay)
assign	cmos_pwdn = 1'b0;		//cmos power on
//assign	cmos_xclk = clk_vga;	//25MHz
wire	[7:0]	I2C_RDATA;
wire	[7:0]	LUT_INDEX;
wire			Config_Done;			
I2C_AV_Config	u_I2C_AV_Config 
(
	//Global clock
	.iCLK		(clk_vga),		//25MHz
	.iRST_N		(sys_rst_n & sdram_init_done),	//Global Reset
	
	//I2C Side
	.I2C_SCLK	(i2c_sclk),		//I2C CLOCK
	.I2C_SDAT	(i2c_sdat),		//I2C DATA
	
	//CMOS Signal
	.Config_Done(Config_Done),
	.I2C_RDATA	(I2C_RDATA),	//CMOS ID
	.LUT_INDEX	(LUT_INDEX)
);

wire	cmos_valid;		//data valid, or address restart
CMOS_Capture	u_CMOS_Capture
(
	//Global Clock
	.iCLK				(clk_vga),			//25MHz
	.iRST_N				(sys_rst_n),
	
	//I2C Initilize Done
	.Config_Done		(Config_Done),	//Configure Done
	
	//Sensor Interface
	.CMOS_XCLK			(cmos_xclk),	//25MHz
	.CMOS_PCLK			(cmos_pclk),	//25MHz
	.CMOS_iDATA			(cmos_data),    //CMOS Data
	.CMOS_VSYNC			(cmos_vsync),   //L: Vaild
	.CMOS_HREF			(cmos_href), 	//H: Vaild
	                                    
	//Ouput Sensor Data                 
	.CMOS_oCLK			(sys_we),		//Data PCLK
	.CMOS_oDATA			(sys_data_in),  //16Bits RGB
	.CMOS_VALID			(cmos_valid)	//Data Enable
);

					
//-----------------------------
wire	[15:0]	lcd_data;
// wire	[10:0]	lcd_xpos;
// wire	[10:0]	lcd_ypos;
lcd_top	u_lcd_top
(
	//global clock
	.clk			(clk_vga),	
	.rst_n			(sys_rst_n),	

	//lcd interface
	.lcd_blank		(lcd_blank),
	.lcd_sync		(lcd_sync),
	.lcd_dclk		(lcd_dclk),
	.lcd_hs			(lcd_hs),		
	.lcd_vs			(lcd_vs),	
	.lcd_en			(),	
	.lcd_rgb		({lcd_red[9:5], lcd_green[9:4] ,lcd_blue[9:5]}),

	//user interface
	.lcd_request	(sys_rd),
	.lcd_framesync	(lcd_framesync),
	.lcd_data		(sys_data_out),
	.lcd_xpos		(),
	.lcd_ypos		()
);
assign	lcd_red[4:0] = 5'd0;
assign	lcd_green[3:0] = 4'd0;
assign	lcd_blue[4:0] = 5'd0;
wire sys_en;
wire [15:0] sys_data;
/* udp udp(	.rst_n(rst_n),
			.phy_rst_n(phy_rst_n),
			.phy_clk_tx(phy_clk_tx),
			.phy_clk_rx(phy_clk_rx),
			.rx_dv(rx_dv),
			.tx_data(tx_data),
			.tx_en(tx_en),
			.rx_data(rx_data),
			.key1(key1),
			.led(),
			.rx_er(),
			.sys_data(sys_data),
			.sys_en(sys_en)
			); */
endmodule
