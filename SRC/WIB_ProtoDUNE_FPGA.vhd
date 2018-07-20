--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: ProtoDUNE_FPGA.VHD         
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 09/25/2016 
--////  Description:  TOP LEVEL ProtoDUNE WIB FPGA FIRMWARE  
--////					 PIN planning					
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2015 Brookhaven National Laboratory
--////
--////
--////	V111 = Fixed TIME STAMP SYNC AND 
--////			 Added  filter control to power monitor
--////			 Fixed  Link monitor for FEMB boards 1-3
--////
--////	V112 = Board responds to subnet broudcast on 192.168.121.255
--////			 Board IP address selection now has multiple options  -- uses on board EEPROM
--////				 -- When Jumper J2 is shorted board will have IP address of 192.168.121.1
--////				 -- When EEPROM bit 0 of regisistor 0 is set to 1 board uses IP from EEPROM registor 1 and mac 
--////					   form  register 2 and 3
--////				 -- When EEPROM bit 0 of regisistor 0 is set to 0 board uses IP from Slot + Crate locations
--////			 Front pannel LED indicators now show  link + comunication status
--////			 5V bias control added for new REV A version of protoDUNE
--////			 Crate address + slot address added to verion ID register
--////	V113 = Bromberg mode fifo incresed to 32K allowing for 512uS worth of data
--////			 
--////	V114 = Added PING to Ethernet link , CERN IP ADDRESS MAP ADDED	 
--////		
--////	V115 = Added Pulse generator -- uses si5344 for now next version will use 100Mhz clk
--////
--/////////////////////////////////////////////////////////////////////


library ieee;
--library WIB_PLL_SYS; modified by junbinzhang 06062018 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.SbndPkg.all;

entity WIB_ProtoDUNE_FPGA is
	port 
	(

	-- FPGA CLOCKS	
	CLK_IN_50MHz		: IN STD_LOGIC;					--	2.5V, default 50MHz
	
	refclk_R0			: IN STD_LOGIC;					--	LVDS	, default 128MHz  FEMB GXB CLOCK, PIN_AA8, 128M
	refclk_L1			: IN STD_LOGIC;					--	LVDS	, default 128MHz  FEMB GXB CLOCK, PIN_W26, 128M

	refclk_L0			: IN STD_LOGIC;					--	LVDS	, default SI5342  recoverd clock, PIN_AA27, 120M, felix eventbuilder	
	refclk_L3			: IN STD_LOGIC;					--	LVDS	, default 125MHz	PIN_R26,SFP CLOCK 
	ProtoDUNE_CLK		: IN STD_LOGIC;					--	2.5V, default 16MHz PIN_K18, normal 100MHz EXTRA SYSTEM CLOCK Si5344,
-- used clock resources-------	
--	refclk_R1			: IN STD_LOGIC;					--	LVDS	, default 128MHz	crystal Xx
--	refclk_R2			: IN STD_LOGIC;					--	LVDS	, default 128MHz
--	refclk_R3			: IN STD_LOGIC;					--	LVDS	, default 128MHz	
--	refclk_L2			: IN STD_LOGIC;					--	LVDS	, default 125MHz	spare crystal 
--	CORE_CLK_0			: IN STD_LOGIC;					--	LVDS
--	CORE_CLK_1			: IN STD_LOGIC;					--	LVDS
--	CORE_CLK_2			: IN STD_LOGIC;					--	LVDS
--	CORE_CLK_3			: IN STD_LOGIC;					--	LVDS
--	CORE_CLK_4			: IN STD_LOGIC;					--	LVDS
--	CORE_CLK_5			: IN STD_LOGIC;					--	LVDS	
	
	-- ProtoDUNE TIMING 

	TX_TIMING			: OUT		STD_LOGIC;					-- LVDS		
	TX_TIMING_DISABLE	: OUT		STD_LOGIC;					--	2.5V, default
	
	FEMB_CMD_SEL		:	OUT	STD_LOGIC;				--	2.5V, default
	FEMB_CLK_SEL		:	OUT	STD_LOGIC;				--	2.5V, default	
		
	ADN2814_LOL			: IN 		STD_LOGIC;				--	2.5V, default 16MHz  EXTRA SYSTEM CLOCK
	ADN2814_LOS			: IN 		STD_LOGIC;				--	2.5V, default 16MHz  EXTRA SYSTEM CLOCK
	ADN2814_SDA			: INOUT 	STD_LOGIC;				--	2.5V, default 16MHz  EXTRA SYSTEM CLOCK
	ADN2814_SCK			: IN 		STD_LOGIC;				--	2.5V, default 16MHz  EXTRA SYSTEM CLOCK		
	BP_CMD				: IN	STD_LOGIC;					--	LVDS ,	

	
	
	
	--	SI5344 clock control, should get it worked
		
	SI5344_SCL			: OUT		STD_LOGIC;				--	2.5V, default
	SI5344_SDA			: INOUT	STD_LOGIC;				--	2.5V, default
	SI5344_INTR			: INOUT	STD_LOGIC;				--	2.5V, default
	SI5344_SEL0			: OUT		STD_LOGIC;				--	2.5V, default
	SI5344_SEL1			: OUT		STD_LOGIC;				--	2.5V, default
	SI5344_RST			: OUT		STD_LOGIC;				--	2.5V, default
	SI5344_OE			: OUT		STD_LOGIC;				--	2.5V, default	
	SI5344_lol			: IN		STD_LOGIC;				--	2.5V, default	
	SI5344_LOSXAXB		: IN		STD_LOGIC;				--	2.5V, default	
	
	--	SI5342 clock control, should get it worked
		
	SI5342_SCL			: OUT		STD_LOGIC;				--	2.5V, default
	SI5342_SDA			: INOUT	STD_LOGIC;				--	2.5V, default
	SI5342_INTR			: INOUT	STD_LOGIC;				--	2.5V, default
	SI5342_SEL0			: OUT		STD_LOGIC;				--	2.5V, default
	SI5342_SEL1			: OUT		STD_LOGIC;				--	2.5V, default	
	SI5342_RST			: OUT		STD_LOGIC;				--	2.5V, default		
	SI5342_OE			: OUT		STD_LOGIC;				--	2.5V, default	
	SI5342_lol			: IN		STD_LOGIC;				--	2.5V, default	
	SI5342_LOSXAXB		: IN		STD_LOGIC;				--	2.5V, default	
	SI5342_LOS1			: IN		STD_LOGIC;				--	2.5V, default	
	SI5342_LOS2			: IN		STD_LOGIC;				--	2.5V, default	
	SI5342_LOS3			: IN		STD_LOGIC;				--	2.5V, default		
	RECOV_CLK			: OUT		STD_LOGIC;
	
	--	HIGH SPEED  GIG-E LINK

	SFP_rx 				: IN  STD_LOGIC;					--	1.5-V PCML, GIG-E  RX
	SFP_tx	 			: OUT STD_LOGIC;					--	1.5-V PCML, GIG-E  TX
	
	--	FELIX QSFP module control, should get it worked
	QSFP_TX			: OUT std_logic_vector(1 downto 0);		--	1.5-V PCML, DAQ Transmit Data
	--QSFP_TX			: OUT std_logic_vector(3 downto 0);		--	1.5-V PCML, DAQ Transmit Data
--	QSFP_RX			: IN std_logic_vector(3 downto 0);		--	1.5-V PCML, DAQ Transmit Data
	QSFP_MODE		: OUT	STD_LOGIC;					--	2.5V, default
	QSFP_SEL			: OUT	STD_LOGIC;					--	2.5V, default		
	QSFP_RST			: OUT	STD_LOGIC;					--	2.5V, default
	QSFP_SCL			: OUT	STD_LOGIC;					--	2.5V, default	
	QSFP_SDA			: INOUT	STD_LOGIC;				--	2.5V, default
	QSFP_INTn		: INOUT	STD_LOGIC;				--	2.5V, default
	QSFP_PRSN		: INOUT	STD_LOGIC;				--	2.5V, default	
		--	HIGH SPEED  FEMB LINK

	FEMB_GXB_RX				: IN 	std_logic_vector(15 downto 0);	--	1.5-V PCML, Cold electronics board reciver

		
	--  WIB-FEMB CMD , CLOCK & CONTROL INTERFACE
	
	SYS_CMD_FPGA_OUT			: OUT	STD_LOGIC;					--	LVDS ,  
	ProtoDUNE_CLK_FPGA_OUT	: OUT	STD_LOGIC;					--	LVDS ,  
		
	FEMB_SCL_BRD0			:	OUT	STD_LOGIC;				--	LVDS ,	FEMB DIFF I2C  CLOCK
	FEMB_SDA_BRD0_P		:	INOUT STD_LOGIC;				-- DIFF 2.5V SSTL CLASS I , FEMB	DIFF I2C  DATA
	FEMB_SDA_BRD0_N		:	INOUT STD_LOGIC;				-- DIFF 2.5V SSTL CLASS I , FEMB	DIFF I2C  DATA
	FEMB_SDO_BRD0			:	OUT	STD_LOGIC;				--	LVDS ,	FEMB DIFF I2C  CLOCK

	FEMB_SCL_BRD1			:	OUT	STD_LOGIC;				--	LVDS ,	FEMB DIFF I2C  CLOCK
	FEMB_SDA_BRD1_P		:	INOUT STD_LOGIC;				-- DIFF 2.5V SSTL CLASS I , FEMB	DIFF I2C  DATA
	FEMB_SDA_BRD1_N		:	INOUT STD_LOGIC;				-- DIFF 2.5V SSTL CLASS I , FEMB	DIFF I2C  DATA	
	FEMB_SDO_BRD1			:	OUT	STD_LOGIC;				--	LVDS ,	FEMB DIFF I2C  CLOCK
	
	FEMB_SCL_BRD2			:	OUT	STD_LOGIC;				--	LVDS ,	FEMB DIFF I2C  CLOCK
	FEMB_SDA_BRD2_P		:	INOUT STD_LOGIC;				-- DIFF 2.5V SSTL CLASS I , FEMB	DIFF I2C  DATA
	FEMB_SDA_BRD2_N		:	INOUT STD_LOGIC;				-- DIFF 2.5V SSTL CLASS I , FEMB	DIFF I2C  DATA	
	FEMB_SDO_BRD2			:	OUT	STD_LOGIC;				--	LVDS ,	FEMB DIFF I2C  CLOCK
	
	FEMB_SCL_BRD3			:	OUT	STD_LOGIC;				--	LVDS ,	FEMB DIFF I2C  CLOCK
	FEMB_SDA_BRD3_P		:	INOUT STD_LOGIC;				-- DIFF 2.5V SSTL CLASS I , FEMB	DIFF I2C  DATA
	FEMB_SDA_BRD3_N		:	INOUT STD_LOGIC;				-- DIFF 2.5V SSTL CLASS I , FEMB	DIFF I2C  DATA
	FEMB_SDO_BRD3			:	OUT	STD_LOGIC;				--	LVDS ,	FEMB DIFF I2C  CLOCK
	


	
	--  WIB-FEMB JTAG INTERFACE
		
	JTAG_TDO_FMB	:	IN		STD_LOGIC_VECTOR(3 downto 0);				--	2.5V, default
	JTAG_TMS_FMB	:	OUT	STD_LOGIC_VECTOR(3 downto 0);				--	2.5V, default
	JTAG_TCK_FMB	:	OUT	STD_LOGIC_VECTOR(3 downto 0);				--	2.5V, default
	JTAG_TDI_FMB	:	OUT	STD_LOGIC_VECTOR(3 downto 0);				--	2.5V, default
	

	
	--		WIB ProtoDUNE BACK PLANE SYSTEM CLOCK AND COMMAND
	

	BP_CLOCK_X1			: IN	STD_LOGIC;					--	LVDS ,   	16MHZ
	BP_CLOCK_X10		: IN	STD_LOGIC;					--	LVDS ,   	160MHZ
	BP_CRATE_ADDR		: IN 	STD_LOGIC_VECTOR(3 downto 0);		--	2.5V, default
	BP_SLOT_ADDR		: IN 	STD_LOGIC_VECTOR(3 downto 0);		--	2.5V, default	
	FBEN					: OUT		STD_LOGIC_VECTOR(5 downto 0);				--	2.5V, default
	SPARE_1				: INOUT	STD_LOGIC;		--	2.5V, default
	SPARE_0				: INOUT	STD_LOGIC;		--	2.5V, default
	
	-- WIB FEMB POWER CONTROL 
	PWR_CLK_IN			: OUT	STD_LOGIC_VECTOR(5 downto 0);		--	2.5V, NOT USED
	PWR_CLK_OUT			: IN	STD_LOGIC_VECTOR(5 downto 0);		--	2.5V, NOt USED
	
--	PWR_CLK_OUT			: OUT	STD_LOGIC_VECTOR(4 downto 4);		-- 5V BIAS  DC to DC enable
	
	PWR_EN_3_6V_BRD0	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 3.6V
	PWR_EN_2_8V_BRD0	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 2.8V
	PWR_EN_2_5V_BRD0	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 2.5V	
	PWR_EN_1_5V_BRD0	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 1.5V	
	PWR_EN_BIAS_BRD0	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 4.9V		
	
	PWR_EN_3_6V_BRD1	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 3.6V
	PWR_EN_2_8V_BRD1	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 2.8V
	PWR_EN_2_5V_BRD1	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 2.5V	
	PWR_EN_1_5V_BRD1	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 1.5V	
	PWR_EN_BIAS_BRD1	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 4.9V			
	
	PWR_EN_3_6V_BRD2	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 3.6V
	PWR_EN_2_8V_BRD2	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 2.8V
	PWR_EN_2_5V_BRD2	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 2.5V	
	PWR_EN_1_5V_BRD2	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 1.5V	
	PWR_EN_BIAS_BRD2	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 4.9V		

	PWR_EN_3_6V_BRD3	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 3.6V
	PWR_EN_2_8V_BRD3	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 2.8V
	PWR_EN_2_5V_BRD3	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 2.5V	
	PWR_EN_1_5V_BRD3	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 1.5V	
	PWR_EN_BIAS_BRD3	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 4.9V	
	
	-- WIB FEMB POWER MONITOR 	
	
	
	PWR_SCL_BRD0		: OUT		STD_LOGIC;			--	2.5V, LTC2991 clk control
	PWR_SDA_BRD0		: INOUT	STD_LOGIC;			--	2.5V, LTC2991 SDA control
	
	PWR_SCL_BRD1		: OUT		STD_LOGIC;			--	2.5V, LTC2991 clk control
	PWR_SDA_BRD1		: INOUT	STD_LOGIC;			--	2.5V, LTC2991 SDA control

	PWR_SCL_BRD2		: OUT		STD_LOGIC;			--	2.5V, LTC2991 clk control
	PWR_SDA_BRD2		: INOUT	STD_LOGIC;			--	2.5V, LTC2991 SDA control

	PWR_SCL_BRD3		: OUT		STD_LOGIC;			--	2.5V, LTC2991 clk control
	PWR_SDA_BRD3		: INOUT	STD_LOGIC;			--	2.5V, LTC2991 SDA control

	PWR_SCL_BIAS		: OUT		STD_LOGIC;			--	2.5V, LTC2991 clk control
	PWR_SDA_BIAS		: INOUT	STD_LOGIC;			--	2.5V, LTC2991 SDA control
	
	

	PWR_SCL_WIB			: OUT	STD_LOGIC;				--	2.5V, LTC2991 clk control
	PWR_SDA_WIB			: INOUT	STD_LOGIC;			--	2.5V, LTC2991 SDA control


	EQ_LOS_BRD0_RX		:	IN	STD_LOGIC_VECTOR(3 downto 0);						--	2.5V, default
	EQ_LOS_BRD1_RX		:	IN	STD_LOGIC_VECTOR(3 downto 0);						--	2.5V, default
	EQ_LOS_BRD2_RX		:	IN	STD_LOGIC_VECTOR(3 downto 0);						--	2.5V, default
	EQ_LOS_BRD3_RX		:	IN	STD_LOGIC_VECTOR(3 downto 0);						--	2.5V, default
	
		
	-- WIB CALIBRATRION CONTROL
	
	
	CAL_PUL_GEN			: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 3.6V
		
	CAL_DAC_SYNC		: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 3.6V
	CAL_DAC_SCLK		: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 3.6V
	CAL_DAC_DIN			: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 3.6V

	
	CAL_SRC_SEL_BRD0	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 3.6V
	CAL_SRC_SEL_BRD1	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 3.6V
	CAL_SRC_SEL_BRD2	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 3.6V
	CAL_SRC_SEL_BRD3	: OUT	STD_LOGIC;				--	2.5V, DC TO DC PWR ENABLE FOR 3.6V
	
	-- WIB MISC_IO
		
	RESET_EXT			: IN		STD_LOGIC;				--	2.5V,  MAX811	
	LEMO_IN1				: INOUT	STD_LOGIC;				--	2.5V,  LEMO_FRNT PANNEL	
	LEMO_IN2				: INOUT	STD_LOGIC;				--	2.5V,  LEMO_FRNT PANNEL	

 	
	--MISC_IO				: INOUT	STD_LOGIC_VECTOR(15 downto 0);				--	2.5V,
	MISC_IO				: OUT	STD_LOGIC_VECTOR(15 downto 0);				--	2.5V, modified by junbin	
	DIP_SW				: IN	STD_LOGIC;				--	2.5V, 			-- USED FOR IP HARD CODE
	FLASH_SCL			: OUT	STD_LOGIC;				--	2.5V,  24lc64
	FLASH_SDA			: INOUT	STD_LOGIC;			--	2.5V,  24lc64
	WIB_LED				: OUT	STD_LOGIC_VECTOR(7 downto 0);				--	2.5V, 
	WIB_TEMP_CS			: OUT	STD_LOGIC;				--	2.5V,  MAX31855K
	WIB_TEMP_SCK		: OUT	STD_LOGIC;				--	2.5V,  MAX31855K
	WIB_TEMP_SO			: INOUT	STD_LOGIC			--	2.5V,  MAX31855K
	);
end entity;

architecture WIB_ProtoDUNE_FPGA_ARCH of WIB_ProtoDUNE_FPGA is

	-----------------------------------------------------
	--components--
	-----------------------------------------------------

	component FEMB_CLK_MUX is
		port (
			inclk2x   : in  std_logic                    := 'X';             -- inclk2x
			inclk1x   : in  std_logic                    := 'X';             -- inclk1x
			inclk0x   : in  std_logic                    := 'X';             -- inclk0x
			clkselect : in  std_logic_vector(1 downto 0) := (others => 'X'); -- clkselect
			outclk    : out std_logic                                        -- outclk
		);
	end component FEMB_CLK_MUX;


	COMPONENT sys_rst
		PORT(
				clk 			: IN STD_LOGIC;
				reset_in 	: IN STD_LOGIC;
				start 		: OUT STD_LOGIC;
				RST_OUT 		: OUT STD_LOGIC
		);
	END COMPONENT;

	component PLL_DC_DC is
		port (
			refclk   : in  std_logic := 'X'; -- clk
			rst      : in  std_logic := 'X'; -- reset
			outclk_0 : out std_logic;        -- clk
			outclk_1 : out std_logic;        -- clk
			outclk_2 : out std_logic;        -- clk
			outclk_3 : out std_logic;        -- clk
			outclk_4 : out std_logic;        -- clk
			outclk_5 : out std_logic         -- clk
		);
	end component PLL_DC_DC;


	component SYS_PLL_WIB is
	port (
		refclk : in std_logic;
		rst    : in std_logic;
		outclk_0 : out std_logic;
		outclk_1 : out std_logic;
		outclk_2 : out std_logic;
		locked   : out std_logic
	);
	end component SYS_PLL_WIB;
	--------------------------------------------------------
	
	SIGNAL	clk_125Mhz 		: STD_LOGIC;
	SIGNAL	clk_100Mhz 		: STD_LOGIC;
	SIGNAL	clk_50Mhz		: STD_LOGIC;
	SIGNAL	clk_40Mhz		: STD_LOGIC;
	SIGNAL	GTX_100_CLK		: STD_LOGIC;
	SIGNAL	FEMB_CLK			: STD_LOGIC;
	SIGNAL	ProtoDUNE_ADC_CLK	: STD_LOGIC;
	SIGNAL	FEMB_CONV_CLK	: STD_LOGIC;
	SIGNAL 	GLB_i_RESET		: STD_LOGIC;
	SIGNAL 	GLB_RESET		: STD_LOGIC;
	SIGNAL 	REG_RESET		: STD_LOGIC;
	SIGNAL 	UDP_RESET		: STD_LOGIC;
	SIGNAL 	ALG_RESET		: STD_LOGIC;
	SIGNAL	start_udp_mac	:  STD_LOGIC;

	SIGNAL	FEMB_INT_CLK_SEL :  STD_LOGIC_VECTOR(1 downto 0);

	SIGNAL	UDP_FRAME_SIZE				: STD_LOGIC_VECTOR(11 downto 0);
	SIGNAL	UDP_TIME_OUT_wait 		: STD_LOGIC_VECTOR(31 downto 0);	
	SIGNAL	UDP_header_user_info		: STD_LOGIC_VECTOR(31 downto 0);

	SIGNAL	RD_WR_ADDR_SEL	:  STD_LOGIC;
	SIGNAL	rd_strb 			:  STD_LOGIC;
	SIGNAL	wr_strb 			:  STD_LOGIC;
	SIGNAL	WR_address		:  STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL	RD_address		:  STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL	data 				:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	rdout 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg0_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg1_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg2_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg3_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg4_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg5_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg6_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg7_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg8_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg9_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg10_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg11_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg12_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg13_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg14_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg15_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg16_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg17_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg18_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg19_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg20_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg21_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg22_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg23_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg24_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg25_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg26_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg27_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg28_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg29_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg30_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg31_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg40_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	reg41_p 			:  STD_LOGIC_VECTOR(31 DOWNTO 0);
   signal   reg50_p        :  std_logic_vector(31 downto 0); --added 0622
	signal   LINK_DISABLE   :  std_logic_vector(15 downto 0); --added 0622
	SIGNAL	DP_WFM_CLK_A	:  STD_LOGIC;		
	SIGNAL	DP_WFM_ADDR_A	:  STD_LOGIC_VECTOR(7 downto 0);		
	SIGNAL	DP_WFM_DATA_A 	:  STD_LOGIC_VECTOR(23 downto 0);		

	SIGNAL	DP_WFM_CLK_B	:  STD_LOGIC;		
	SIGNAL	DP_WFM_ADDR_B	:  STD_LOGIC_VECTOR(7 downto 0);		
	SIGNAL	DP_WFM_DATA_B 	:  STD_LOGIC_VECTOR(23 downto 0);	
		
	SIGNAL	TST_WFM_GEN_MODE : STD_LOGIC_VECTOR(3 downto 0);		
		
	-- GXB


	SIGNAL	tx_pll_refclk           :  std_logic;
	SIGNAL	rx_analogreset          :  std_logic_vector(15 downto 0);
	SIGNAL	rx_digitalreset         :  std_logic_vector(15 downto 0);
	SIGNAL	rx_cdr_refclk           :  std_logic;	
	SIGNAL	tx_std_coreclkin        :  std_logic;
	SIGNAL	rx_std_coreclkin        :  std_logic;   --   := (others => 'X'); -- rx_std_coreclkin	
	SIGNAL	pll_locked              :  std_logic;   --;                      -- pll_locked
	SIGNAL	rx_pma_clkout           :  std_logic;   --;                      -- rx_pma_clkout
	SIGNAL	rx_is_lockedtoref       :  std_logic;   --;                      -- rx_is_lockedtoref
	SIGNAL	rx_is_lockedtodata      :  std_logic;   --;                      -- rx_is_lockedtodata
	SIGNAL	rx_std_clkout           :  std_logic_vector(15 downto 0) ;   --;                      -- rx_std_clkout
	SIGNAL	tx_cal_busy             :  std_logic;   --;                      -- tx_cal_busy
	SIGNAL	rx_cal_busy             :  std_logic;   --;                      -- rx_cal_busy
	SIGNAL	unused_tx_parallel_data :  std_logic_vector(25 downto 0);--  := (others => 'X'); -- unused_tx_parallel_data
	SIGNAL	rx_parallel_data        :  std_logic_vector(255 downto 0);                     -- rx_parallel_data

	 
	SIGNAL	TMP_IO  						: std_logic_vector(31 downto 0);    

	SIGNAL	udp_data						: std_logic_vector(15 downto 0);    
	SIGNAL	UDP_LATCH_L					: STD_LOGIC;


		
	SIGNAL	HEADER_ERROR				: STD_LOGIC_VECTOR(15 downto 0);	
	SIGNAL	ADC_ERROR					: STD_LOGIC_VECTOR(15 downto 0);	
	SIGNAL	LINK_SYNC_STATUS			: std_logic_vector(31 downto 0); 
	SIGNAL	TIME_STAMP					: STD_LOGIC_VECTOR(15 downto 0);	
	SIGNAL	CHKSUM_ERROR				: STD_LOGIC_VECTOR(15 downto 0);	
	SIGNAL	FRAME_ERROR					: STD_LOGIC_VECTOR(15 downto 0);	
	SIGNAL   TS_ERROR                : STD_LOGIC_VECTOR(15 downto 0);
	
	SIGNAL	link_stat_sel				: std_logic_vector(3 downto 0); 
	SIGNAL	TS_latch						: std_logic; 
	SIGNAL	ERR_CNT_RST					: std_logic; 

	SIGNAL	BRD_SEL						: std_logic_vector(3 downto 0); 
	SIGNAL	BRD_SEL2						: std_logic_vector(3 downto 0); 
	SIGNAL	CHIP_SEL						: std_logic_vector(3 downto 0); 
	SIGNAL	CHN_SEL						: std_logic_vector(3 downto 0); 
	SIGNAL	UDP_DATA_OUT				: SL_ARRAY_15_TO_0(0 to 2);
		


	SIGNAL	FEMB_BRD						: std_logic_vector(3 downto 0);		
	SIGNAL	FEMB_RD_strb				: STD_LOGIC;
	SIGNAL	FEMB_WR_strb				: STD_LOGIC;	
	SIGNAL	FEMB_RDBK_strb				: STD_LOGIC;
	SIGNAL	FEMB_RDBK_DATA				: STD_LOGIC_VECTOR(31 DOWNTO 0);


	--	FLASH  MEMORY INTERFACE
		
	SIGNAL	EEPROM_RD			: STD_LOGIC;		
	SIGNAL	EEPROM_WR			: STD_LOGIC;		
	SIGNAL	EEPROM_ADDR			: STD_LOGIC_VECTOR(15 downto 0);	
	SIGNAL	EEPROM_WR_DATA		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL	EEPROM_RD_DATA		: STD_LOGIC_VECTOR(31 downto 0);
		
	SIGNAL	LOAD_EE_DATA		: STD_LOGIC;		
	SIGNAL	EEPROM_DATA0		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL	EEPROM_DATA1		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL	EEPROM_DATA2		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL	EEPROM_DATA3		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL	EEPROM_DATA4		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL	EEPROM_DATA5		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL	EEPROM_DATA6		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL	EEPROM_DATA7		: STD_LOGIC_VECTOR(31 downto 0);
		

	SIGNAL I2C_WR_STRB_S1		: STD_LOGIC;
	SIGNAL I2C_RD_STRB_S1		: STD_LOGIC;
	
	SIGNAL I2C_WR_STRB_S2		: STD_LOGIC;
	SIGNAL I2C_RD_STRB_S2		: STD_LOGIC;

	SIGNAL I2C_DEV_ADDR		: STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL I2C_NUM_BYTES		: STD_LOGIC_VECTOR(3 downto 0);
	SIGNAL I2C_ADDRESS		: STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL I2C_DOUT_S1		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL I2C_DOUT_S2		: STD_LOGIC_VECTOR(31 downto 0);	
	SIGNAL I2C_DIN				: STD_LOGIC_VECTOR(7 downto 0);

	
	SIGNAL FEMB_DATA			: SL_ARRAY_15_TO_0(0 to 15);
	SIGNAL RX_FF_EMPTY		: std_logic_vector(15 downto 0);
	SIGNAL RX_FF_RDREQ		: std_logic_vector(15 downto 0);	
	SIGNAL RX_FF_CLK			: STD_LOGIC_vector(15 downto 0);	
	SIGNAL RX_FF_RST			: std_logic_vector(15 downto 0);	
	
	SIGNAL TIME_STAMP_ev    : SL_ARRAY_15_TO_0(0 to 15);
	SIGNAL CAPTURE_ERROR_ev : SL_ARRAY_15_TO_0(0 to 15);
	SIGNAL CD_ERROR_ev      : SL_ARRAY_15_TO_0(0 to 15);
	
	
	
	SIGNAL FEMB_DATA_VALID	: std_logic_vector(15 downto 0);
	SIGNAL FEMB_DATA_CLK		: std_logic_vector(15 downto 0);
	SIGNAL FEMB_EOF			: std_logic_vector(15 downto 0);	
	
	
	
	SIGNAL FILTER_EN					: STD_LOGIC;
	SIGNAL PWR_MES_RDY				: STD_LOGIC;	
	SIGNAL PWR_MES_OUT				: std_logic_vector(31 downto 0);	
	SIGNAL PWR_MES_SEL				: std_logic_vector(7 downto 0);	
	SIGNAL PWR_MES_start				: STD_LOGIC;	
		
	SIGNAL GXB_analogreset			: STD_LOGIC;	
	SIGNAL GXB_digitalreset			: STD_LOGIC;	
	SIGNAL UDP_EN_WR_RDBK			: STD_LOGIC;	

	SIGNAL TX_PACK_FF_RST			: STD_LOGIC;
	SIGNAL TX_PACK_Stream_EN		: STD_LOGIC;
	SIGNAL tx_analogreset_EN 		: STD_LOGIC;
	SIGNAL tx_digitalreset_EN		: STD_LOGIC;
	SIGNAL pll_powerdown_EN			: STD_LOGIC;
	SIGNAL K_CODE_comma_sym			: std_logic_vector(15 downto 0);	
	SIGNAL K_CODE_is_k				: std_logic_vector(1 downto 0);	
	SIGNAL HSD_RESET					: STD_LOGIC;
	SIGNAL UDP_DISABLE				: STD_LOGIC;

	SIGNAL UDP_fifo_full				: STD_LOGIC;
	SIGNAL UDP_BURST_MODE			: std_logic_vector(3 downto 0);	
	SIGNAL UDP_SAMP_TO_SAVE			: std_logic_vector(15 downto 0);	
	SIGNAL UDP_BURST_EN				: STD_LOGIC;

	SIGNAL SILABS_RST					: STD_LOGIC;
	
	
	SIGNAL IP_SEL						: STD_LOGIC;     						 -- 0 from BRD ID  1= from eeprom
	SIGNAL IP_IN_EEPROM				: STD_LOGIC_VECTOR(31 downto 0);  -- FROM EEPROM
	SIGNAL MAC_IN_EEPROM				: STD_LOGIC_VECTOR(47 downto 0);  	-- FROM EEPROM
	SIGNAL IP_OUT						: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL MAC_OUT						: STD_LOGIC_VECTOR(47 downto 0);

		


	SIGNAL DPM_WREN			: STD_LOGIC;		
	SIGNAL DPM_ADDR			: STD_LOGIC_VECTOR(7 downto 0);		
	SIGNAL DPM_D	  	 		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL DPM_Q				: STD_LOGIC_VECTOR(31 downto 0);		

	SIGNAL F_FLASH_S_OP		: STD_LOGIC;
	SIGNAL FPGA_F_OP_CODE	: STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL FPGA_F_ADDR		: STD_LOGIC_VECTOR(23 downto 0);
	SIGNAL FPGA_F_status		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL JTAG_EEPROM		: STD_LOGIC;			

	SIGNAL UDP_DATA_BRD_o   : SL_ARRAY_15_TO_0(15 downto 0);	
	SIGNAL UDP_LATCH_L_o		: std_logic_vector(15 downto 0);		
	
	
	SIGNAL PULSE_src_SELECT	: std_logic_vector(3 downto 0);	
	SIGNAL Pulse_Period		: std_logic_vector(31 downto 0);	
	SIGNAL Pulse_out			: std_logic;	
	--------------------probe------------------------------
	signal probe            : std_logic_vector(63 downto 0);
begin


	QSFP_MODE		<= '0';
	QSFP_SEL			<= '1';
	QSFP_RST			<= '1';


	GLB_i_RESET				<= reg0_P(0);
	REG_RESET				<= GLB_RESET or reg0_P(1);
	UDP_RESET				<= GLB_RESET or reg0_P(2);
	ALG_RESET				<= GLB_RESET or reg0_P(3);
	HSD_RESET				<= GLB_RESET or reg0_P(4);
	
	WIB_LED(3 downto 0)	<=	reg2_P(3 downto 0);

	
	FEMB_CMD_SEL			<= not reg4_p(1);
	FEMB_CLK_SEL			<= not reg4_p(0);
	FEMB_INT_CLK_SEL		<= reg4_p(3 downto 2);
	
	PWR_MES_SEL				<=	reg5_P(7 downto 0);
	PWR_MES_start			<=	reg5_P(16);
	FILTER_EN				<= reg5_P(17);
	reg6_P					<= PWR_MES_OUT;
		

	
	BRD_SEL					<= reg7_p(19 DOWNTO 16);
--	BRD_SEL2					<= reg7_p(19 DOWNTO 16);
	CHIP_SEL					<= reg7_p(11 DOWNTO 8);
	CHN_SEL					<= reg7_p(3 DOWNTO 0);
	UDP_DISABLE				<= reg7_p(31);

	PWR_EN_3_6V_BRD0		<= reg8_p(0);
	PWR_EN_2_8V_BRD0		<=	reg8_p(1);
	PWR_EN_2_5V_BRD0		<= reg8_p(2);
	PWR_EN_1_5V_BRD0		<= reg8_p(3);
	PWR_EN_BIAS_BRD0		<= reg8_p(16);

	PWR_EN_3_6V_BRD1		<= reg8_p(4);
	PWR_EN_2_8V_BRD1		<= reg8_p(5);
	PWR_EN_2_5V_BRD1		<= reg8_p(6);
	PWR_EN_1_5V_BRD1		<= reg8_p(7);
	PWR_EN_BIAS_BRD1		<= reg8_p(17);
	
	PWR_EN_3_6V_BRD2		<= reg8_p(8);
	PWR_EN_2_8V_BRD2		<= reg8_p(9);
	PWR_EN_2_5V_BRD2		<= reg8_p(10);
	PWR_EN_1_5V_BRD2		<= reg8_p(11);
	PWR_EN_BIAS_BRD2		<= reg8_p(18);

	PWR_EN_3_6V_BRD3		<= reg8_p(12);
	PWR_EN_2_8V_BRD3		<= reg8_p(13);
	PWR_EN_2_5V_BRD3		<= reg8_p(14);
	PWR_EN_1_5V_BRD3		<= reg8_p(15);
	PWR_EN_BIAS_BRD3		<= reg8_p(19);
	
	PWR_CLK_IN(1)			<= reg8_p(20);  -- 5V BIAS DC/DC ENABLE
	
	
--	P_POD_RST				<=	not reg9_P(0);	
	TST_WFM_GEN_MODE		<= reg9_P(7 downto 4); 
	
	I2C_WR_STRB_s1				<=  reg10_p(0);
	I2C_RD_STRB_s1				<=	 reg10_p(1);
	I2C_WR_STRB_s2				<=  reg10_p(2);
	I2C_RD_STRB_s2				<=	 reg10_p(3);
	
	
	SILABS_RST					<= reg10_p(8);
	
	I2C_NUM_BYTES			<=	reg11_p(3 downto 0);--   : STD_LOGIC_VECTOR(3 downto 0);
	I2C_ADDRESS				<= reg12_p(7 downto 0);--	: STD_LOGIC_VECTOR(7 downto 0);
	reg14_p 					<=	I2C_DOUT_S1; --			: STD_LOGIC_VECTOR(31 downto 0);
	reg19_p					<=	I2C_DOUT_S2; --			: STD_LOGIC_VECTOR(31 downto 0);
	I2C_DIN					<= reg13_p(7 downto 0);--	: STD_LOGIC_VECTOR(7 downto 0);

	
	UDP_BURST_MODE			<= reg15_p(3 downto 0); --  0 = normal op  1= collect data 2= readout mode  3 = clear fifo
	UDP_BURST_EN			<= reg15_p(4);	
	UDP_SAMP_TO_SAVE		<= reg16_p(15 downto 0);
	
	GXB_analogreset		<= reg17_p(0);
	GXB_digitalreset		<= reg17_p(1);

	
	link_stat_sel			<= reg18_p(3 downto 0);
	TS_latch					<= reg18_p(8);	
	ERR_CNT_RST				<= reg18_p(15);		

--	reg19_p					<= I2C_DOUT_S2; --	 x"0000" & EQ_LOS_RX_BRD3 &  EQ_LOS_RX_BRD2 & EQ_LOS_RX_BRD1 & EQ_LOS_RX_BRD0;
	
	
	TX_PACK_Stream_EN		<= not reg20_p(0);
	TX_PACK_FF_RST			<= reg20_p(1);
	tx_analogreset_EN 	<= reg20_p(2);
	tx_digitalreset_EN	<= reg20_p(3);
	pll_powerdown_EN		<= reg20_p(4);
	K_CODE_comma_sym		<= reg21_p(15 downto 0); 
	K_CODE_is_k				<= reg21_p(17 downto 16); 
	EEPROM_ADDR				<= reg23_p(15 downto 0);	
	EEPROM_RD				<=	reg23_p(16);		
	EEPROM_WR				<= reg23_p(17);
	LOAD_EE_DATA			<= reg23_p(31);
	EEPROM_WR_DATA			<= reg24_p;
	reg25_p					<=	EEPROM_RD_DATA	 ;	 		
	
	
	

	
	FPGA_F_OP_CODE	<= reg26_p(7 downto 0);	
	F_FLASH_S_OP	<= reg26_p(8);	
	JTAG_EEPROM	   <= reg28_p(0);
	FPGA_F_ADDR		<= reg27_p(23 downto 0);	
	
	
	
	
	UDP_EN_WR_RDBK			<= reg30_p(0);	
	UDP_FRAME_SIZE			<= reg31_p(11 downto 0);
		

		
	PULSE_src_SELECT		<= reg40_p(3 downto 0);
	Pulse_Period			<= reg41_p;

	
	TX_TIMING			<= clk_100Mhz;
	TX_TIMING_DISABLE	<= reg4_p(4);
	
		
		
	LINK_DISABLE <= reg50_p(15 downto 0);
--WIB_PLL_SYS_inst : entity  WIB_PLL_SYS.WIB_PLL_SYS --description file doesn't change.
--PORT MAP(	
--			refclk   	=> CLK_IN_50MHz,
--			rst      	=> '0',
--			outclk_0 	=> clk_100Mhz,  --used as system clock
--			outclk_1 	=>	clk_50Mhz,   --used in udp_io
--			outclk_2 	=> clk_40Mhz    --used for i2c control and monitoring
--			--outclk_3		=> clk_50Mhz,
--			--outclk_4		=> clk_40Mhz   
--	);

SYS_PLL_WIB_inst : SYS_PLL_WIB
		port map
		(
			refclk => CLK_IN_50MHz,
			rst    => '0',
			outclk_0 => clk_100Mhz,
			outclk_1 => clk_50Mhz,
			outclk_2 => clk_40Mhz,
			locked => open
		);
FEMB_CLK_MUX_inst2 : FEMB_CLK_MUX
		port map(
			inclk0x   => ProtoDUNE_CLK,
			inclk1x   => ProtoDUNE_CLK,
			inclk2x   => clk_100Mhz,
			clkselect => FEMB_INT_CLK_SEL,
			outclk    => FEMB_CLK
		);

--	
--PLL_DC_DC_inst : PLL_DC_DC
--		port map (
--			refclk    => FEMB_CLK,
--			rst       => not reg8_p(31),
--			outclk_0  => PWR_CLK_IN(0),
--			outclk_1  => open,
--			outclk_2  => PWR_CLK_IN(2),
--			outclk_3  => PWR_CLK_IN(3),
--			outclk_4  => PWR_CLK_IN(4),
--			outclk_5  => PWR_CLK_IN(5)
--		);
	
SBND_PWM_CLK_ENCODER_INST : ENTITY WORK.SBND_PWM_CLK_ENCODER
	PORT map
	(	
			RESET				=> ALG_RESET,
			CLK_100MHz		=> FEMB_CLK,	 --100MHz   from si5338
			SAMPLE_RATE		=> X"0",		
			EXT_CMD1			=> Pulse_out,	
			EXT_CMD2			=> '0',
			EXT_CMD3			=> '0',
			EXT_CMD4			=> '0',	
			SW_CMD1			=> reg1_p(0), --LALIB
			SW_CMD2			=> reg1_p(1), --TIMESTAMP RESET
			SW_CMD3			=> reg1_p(2), --START
			SW_CMD4			=> reg1_p(3), --STOP
			DIS_CMD1			=> reg2_p(0), 
			DIS_CMD2			=> '0',
			DIS_CMD3			=> '0',
			DIS_CMD4			=> '0',			
			SBND_SYNC_CMD	=> FEMB_CONV_CLK,
			SBND_ADC_CLK	=> ProtoDUNE_ADC_CLK				
	);

	
	
	

	ProtoDUNE_CLK_FPGA_OUT	 	<= FEMB_CLK;
	SYS_CMD_FPGA_OUT		<= FEMB_CONV_CLK;
--	LEMO_IN1					<= FEMB_CONV_CLK when  (reg4_p(1) = '0') else BP_CMD;
	
ProtoDUNE_TST_PULSE_GEN_inst : entity work.ProtoDUNE_TST_PULSE_GEN 
	PORT MAP
	(
	
			RESET					=> ALG_RESET,	
			CLK_100MHz			=> clk_100Mhz,
			src_SELECT			=>	Pulse_src_SELECT,			--: IN STD_LOGIC_vector(3 downto 0);  
			Period				=>	Pulse_Period,		--: IN STD_LOGIC_vector(31 downto 0);
			SW_Pulse_cntl		=> '0',
			External_Pulse		=> LEMO_IN2,
			Pulse_out			=> Pulse_out,
			Pulse_out_lemo		=> LEMO_IN1	
							
	);



	
-----------don't need this-------------	
--SBND_PWM_CLK_DECODER_inst : entity work.SBND_PWM_CLK_DECODER
--	PORT MAP
--	(		RESET				=> ALG_RESET,
--			CLK_100MHz		=> ProtoDUNE_CLK,
--			SBND_SYNC_CMD	=> BP_CMD, --doesn't find the scource.
--			CMD1				=> open,
--			CMD2				=> open,
--			CMD3				=> open,
--			CMD4				=> open											
--	);



				

	
SYS_RST_inst : sys_rst
PORT MAP(	clk 		=> CLK_IN_50MHz,
				reset_in => GLB_i_RESET,
				start 	=> start_udp_mac,
				RST_OUT 	=> GLB_RESET);
				



io_registers_inst : entity work.io_registers
PORT MAP(	rst 			=> REG_RESET,
				Ver_ID		=> BP_CRATE_ADDR & BP_SLOT_ADDR & x"000116",
				clk 			=> clk_100Mhz,
				WR 			=> wr_strb,
				WR_address 	=> WR_address,
				RD_address 	=> RD_address,
				RD_WR_ADDR_SEL => RD_WR_ADDR_SEL,
				data 			=> data,
				data_out => rdout,
				
				DP_WFM_CLK_A	=> DP_WFM_CLK_A,
				DP_WFM_ADDR_A	=> DP_WFM_ADDR_A,
				DP_WFM_DATA_A 	=> DP_WFM_DATA_A,
	
				DP_WFM_CLK_B	=> DP_WFM_CLK_B,
				DP_WFM_ADDR_B	=> DP_WFM_ADDR_B,
				DP_WFM_DATA_B 	=> DP_WFM_DATA_B,
				
				DP_FPGA_ADDR	=> DPM_ADDR,
				DP_FPGA_D		=> DPM_D,
				DP_FPGA_WREN	=> DPM_WREN,
				DP_FPGA_Q		=> DPM_Q,
				
				reg0_i 	=> reg0_p,
				reg1_i	=> reg1_p,		 
				reg2_i 	=> reg2_p,		 
				reg3_i 	=> reg3_p,
				reg4_i 	=> reg4_p,
				reg5_i 	=> reg5_p,
				reg6_i 	=> reg6_p,
				reg7_i 	=> reg7_p,
				reg8_i 	=> reg8_p,
				reg9_i 	=> reg9_p,
				reg10_i 	=> reg10_p,
				reg11_i 	=> reg11_p,
				reg12_i 	=> reg12_p,
				reg13_i 	=> reg13_p,
				reg14_i 	=> reg14_p,
				reg15_i 	=> reg15_p,
				reg16_i 	=> reg16_p,				
				reg17_i 	=> reg17_p,
				reg18_i 	=> reg18_p,
				reg19_i 	=> reg19_p,
				reg20_i 	=> reg20_p,
				reg21_i 	=> reg21_p,
				reg22_i 	=> reg22_p,
				reg23_i 	=> reg23_p,
				reg24_i 	=> reg24_p,
				reg25_i 	=> reg25_p,
				reg26_i 	=> reg26_p,
				reg27_i 	=> reg27_p,
				reg28_i 	=> FPGA_F_status,
				reg29_i 	=> reg29_p,
				reg30_i 	=> reg30_p,
				reg31_i 	=> reg31_p,
				reg32_i 	=> ADC_ERROR  & HEADER_ERROR,		
				reg33_i 	=> LINK_SYNC_STATUS,
				reg34_i 	=> TIME_STAMP   & CHKSUM_ERROR,
				--reg35_i 	=> x"0000"  & FRAME_ERROR,
				reg35_i 	=> TS_ERROR  & FRAME_ERROR,
				reg36_i 	=> x"0000"  & EQ_LOS_BRD3_RX & EQ_LOS_BRD2_RX & EQ_LOS_BRD1_RX & EQ_LOS_BRD0_RX,
				reg37_i 	=> x"00000000",			
				reg38_i 	=> x"00000000",	
				reg39_i 	=> x"00000000",
				reg40_i 	=> reg40_p,
				reg41_i 	=> reg41_p,	
				reg42_i 	=> x"00000000",
				reg43_i 	=> x"00000000",
				reg50_i  => reg50_p, --added 0622
				----------output-----------
				reg0_o => reg0_p,
				reg1_o => reg1_p,				
				reg2_o => reg2_p,		
				reg3_o => reg3_p,		
				reg4_o => reg4_p,
				reg5_o => reg5_p,
				reg6_o => open,
				reg7_o => reg7_p,
				reg8_o => reg8_p,
				reg9_o => reg9_p,		
				reg10_o => reg10_p,
				reg11_o => reg11_p,
				reg12_o => reg12_p,
				reg13_o => reg13_p,
				reg14_o => open,
				reg15_o => reg15_p,
				reg16_o => reg16_p,				
				reg17_o => reg17_p,
				reg18_o => reg18_p,
				reg19_o => open,
				reg20_o => reg20_p,
				reg21_o => reg21_p,
				reg22_o => reg22_p,
				reg23_o => reg23_p,
				reg24_o => reg24_p,
				reg25_o => open,
				reg26_o => reg26_p,
				reg27_o => reg27_p,
				reg28_o => reg28_p,
				reg29_o => reg29_p,
				reg30_o => reg30_p,
				reg31_o => reg31_p,
				reg40_o => reg40_p,
				reg41_o => reg41_p,	
				reg50_o => reg50_p
				);
			




  ProtoDUNE_FEMB_HSRX_inst :  entity work.ProtoDUNE_FEMB_HSRX
	PORT MAP
	(
			RESET						=> HSD_RESET,
			SYS_CLK					=> clk_100Mhz,
			FEMB_GXB_RX				=> FEMB_GXB_RX,
			GXB_refclk_L			=> refclk_L1,			
			GXB_refclk_R			=> refclk_R0,				
			
			GXB_analogreset		=> GXB_analogreset,	
			GXB_digitalreset		=> GXB_digitalreset,

			UDP_DISABLE				=> UDP_DISABLE,			
			UDP_DATA_OUT			=>	udp_data,				
			UDP_LATCH				=> UDP_LATCH_L,	
			UDP_fifo_full			=> UDP_fifo_full,	
			
			BRD_SEL					=>	BRD_SEL,					
			CHIP_SEL					=> CHIP_SEL,		
	
			UDP_DATA_BRD_o  		=> UDP_DATA_BRD_o,
			UDP_LATCH_L_o			=> UDP_LATCH_L_o,		
	
			UDP_BURST_MODE			=> UDP_BURST_MODE,
			UDP_SAMP_TO_SAVE		=> UDP_SAMP_TO_SAVE,
			UDP_BURST_EN			=> UDP_BURST_EN,
	
			FEMB_EOF					=>	FEMB_EOF,
			RX_FF_DATA				=>	FEMB_DATA,
			RX_FF_EMPTY				=> RX_FF_EMPTY,
			RX_FF_RDREQ				=> RX_FF_RDREQ,	
			RX_FF_RST				=> RX_FF_RST,	
			RX_FF_CLK				=> RX_FF_CLK,
			----add messages-----------------
			TIME_STAMP_ev        => TIME_STAMP_ev,
			CAPTURE_ERROR_ev     => CAPTURE_ERROR_ev,
			CD_ERROR_ev          => CD_ERROR_ev,
			-------------------------------------
			----------------probe--------------
			probe                => probe,
			------------------------------------
			
			LINK_DISABLE   		=> LINK_DISABLE, --changed 0622		
			

			
			DP_WFM_CLK_A				=> DP_WFM_CLK_A,
			DP_WFM_ADDR_A				=> DP_WFM_ADDR_A,
			DP_WFM_DATA_A 				=> DP_WFM_DATA_A,
			
			DP_WFM_CLK_B				=> DP_WFM_CLK_B,
			DP_WFM_ADDR_B				=> DP_WFM_ADDR_B,
			DP_WFM_DATA_B 				=> DP_WFM_DATA_B,
			
			
    		ProtoDUNE_ADC_CLK		=> ProtoDUNE_ADC_CLK,
			TST_WFM_GEN_MODE		=> TST_WFM_GEN_MODE,
			
			ERR_CNT_RST				=> ERR_CNT_RST,			

			TS_latch					=> TS_latch,
			
			link_stat_sel			=> link_stat_sel,			
			LINK_SYNC_STATUS		=>	LINK_SYNC_STATUS, 							 
			TIME_STAMP				=> TIME_STAMP,
			CHKSUM_ERROR			=> CHKSUM_ERROR,
			FRAME_ERROR				=>	FRAME_ERROR,
			HEADER_ERROR			=>	HEADER_ERROR,
			ADC_ERROR				=> ADC_ERROR,		
			TS_ERROR             => TS_ERROR
	);
------------FELIX eventbuilder ----------------junbin added 060518----
---------p2 connector------
--MISC_IO(0) <= FEMB_EOF(0);
--MISC_IO(1) <= RX_FF_EMPTY(0);
--MISC_IO(2) <= RX_FF_CLK(0);
--MISC_IO(3) <= RX_FF_RDREQ(0);
--
--MISC_IO(4) <= FEMB_EOF(8);
--MISC_IO(5) <= RX_FF_EMPTY(8);
--MISC_IO(6) <= RX_FF_CLK(8);
--MISC_IO(7) <= RX_FF_RDREQ(8);

MISC_IO(0) <= probe(0); --wr
MISC_IO(1) <= probe(1); --full
MISC_IO(2) <= probe(2); --rd
MISC_IO(3) <= probe(3); --empty

MISC_IO(4) <= probe(4);
MISC_IO(5) <= probe(5);
MISC_IO(6) <= probe(6);
MISC_IO(7) <= probe(7);
---------p1 connector-----
MISC_IO(8)  <= probe(32);
MISC_IO(9)  <= probe(33);
MISC_IO(10) <= probe(34);
MISC_IO(11) <= probe(35);

MISC_IO(12) <= probe(36);
MISC_IO(13) <= probe(37);
MISC_IO(14) <= probe(38);
MISC_IO(15) <= probe(39);

FELIX_EventBuilder_inst : entity work.FELIX_EventBuilder
	PORT MAP
	(
	
			RESET						=> (ALG_RESET or TX_PACK_FF_RST),	--reg20 bit1
			Stream_EN 				=> TX_PACK_Stream_EN,               --reg20 bit0 
			LINK_DISABLE			=>	LINK_DISABLE,                    --added 0622

			tx_serial_data       => QSFP_TX(1 downto 0), --remapped
			tx_pll_refclk        => refclk_L0,          --si5342 recoved clock
			pll_locked           => open,
			tx_analogreset_EN    => tx_analogreset_EN,  --reg20 bit2
			tx_digitalreset_EN   => tx_digitalreset_EN, --reg20 bit3
			pll_powerdown_EN		=> pll_powerdown_EN, --reg20 bit4
				
			FEMB_EOF					=> FEMB_EOF,			
			RX_FF_DATA				=> FEMB_DATA,
			RX_FF_EMPTY				=> RX_FF_EMPTY,			
			RX_FF_RDREQ				=> RX_FF_RDREQ,
			RX_FF_RST				=> RX_FF_RST,
			RX_FF_CLK				=> RX_FF_CLK,
			-----------probe-------------------
			probe                => open, --0621
			-----------------------------------
			TIME_STAMP_ev        => TIME_STAMP_ev,     -- sync to RX_FF_CLK
			CAPTURE_ERROR_ev     => CAPTURE_ERROR_ev,      -- sync to RX_FF_CLK
			CD_ERROR_ev          => CD_ERROR_ev     -- sync to RX_FF_CLK

	);
----------------------------------------------------------------------
WIB_LED_STATUS_inst : entity work.WIB_LED_STATUS
	port MAP
	(

		SYS_CLK	   		=> clk_100Mhz,
		RESET   	   		=> ALG_RESET,
		FEMB_BRD				=> FEMB_BRD,
		FEMB_RDBK_strb		=> FEMB_RDBK_strb,
		FEMB_LINK_STATUS	=> LINK_SYNC_STATUS,
		LED_OUT				=> WIB_LED(7 downto 4)	
	);


		
		
IP_ADDR_SELECT_inst : entity work.IP_ADDR_SELECT
PORT MAP (
		CLK						=> clk_50Mhz,
		IP_JUMP_SEL				=> DIP_SW,
		IP_SEL					=> IP_SEL,
		BP_CRATE_ADDR			=> BP_CRATE_ADDR,
		BP_SLOT_ADDR			=> BP_SLOT_ADDR,
		IP_IN_EEPROM			=> IP_IN_EEPROM,
		MAC_IN_EEPROM			=> MAC_IN_EEPROM,
		IP_OUT					=> IP_OUT,
		MAC_OUT					=> MAC_OUT
);


udp_io_inst1 : entity work.udp_io
PORT MAP(
				reset 				=> UDP_RESET,
				CLK_125Mhz 			=> refclk_L3,
				CLK_50MHz 			=> clk_50Mhz,
				CLK_IO 				=> clk_100Mhz,	
				
				SPF_OUT 				=> SFP_rx,
				SFP_IN 				=> SFP_tx,
				
				START 				=> start_udp_mac,			
				BRD_IP				=> IP_OUT,		--x"C0A87901",
				BRD_MAC				=> MAC_OUT,    --x"AABBCCDDEE10",
				EN_WR_RDBK			=> UDP_EN_WR_RDBK,
				TIME_OUT_wait 		=> x"00001000",				
				FRAME_SIZE			=> UDP_FRAME_SIZE,
				
				tx_fifo_clk 		=> clk_100Mhz,	
				tx_fifo_wr 			=> UDP_LATCH_L,
				tx_fifo_in 			=> udp_data,
				tx_fifo_full		=> UDP_fifo_full,
				tx_fifo_used		=> open,
				
				header_user_info 	=> X"00000000" & IP_OUT,		
				system_status 		=> x"0" & BP_CRATE_ADDR & x"0" & BP_SLOT_ADDR & x"0" & BRD_SEL & x"0" & CHIP_SEL,		
				
				data 					=> data,			
				rdout 				=> rdout,
				wr_strb 				=> wr_strb,
				rd_strb 				=> rd_strb,
				WR_address 			=> WR_address,
				RD_address 			=> RD_address,
				RD_WR_ADDR_SEL		=> RD_WR_ADDR_SEL,
				
				FEMB_BRD				=> FEMB_BRD,
				FEMB_RD_strb		=> FEMB_RD_strb,
				FEMB_WR_strb		=> FEMB_WR_strb,
				FEMB_RDBK_strb		=> FEMB_RDBK_strb,
				FEMB_RDBK_DATA		=> FEMB_RDBK_DATA	
	);				
							
				
	WIB_FEMB_COMM_TOP_INST : ENTITY WORK.WIB_FEMB_COMM_TOP
	PORT MAP
	(
		RESET   	   			=> ALG_RESET,
		SYS_CLK	   			=> clk_100Mhz,
						
		FEMB_wr_strb 			=> FEMB_WR_strb,
		FEMB_rd_strb 			=> FEMB_RD_strb,
		FEMB_address 			=> WR_address,
		FEMB_BRD					=> FEMB_BRD,
		FEMB_DATA_TO_FEMB		=> data,
		FEMB_DATA_RDY			=> FEMB_RDBK_strb,
		FEMB_DATA_FRM_FEMB	=> FEMB_RDBK_DATA	,
		
		FEMB_SCL_BRDO			=> FEMB_SCL_BRD0,
		FEMB_SDA_BRD0_P		=> FEMB_SDA_BRD0_P,
		FEMB_SDA_BRD0_N		=> FEMB_SDA_BRD0_N,

		FEMB_SCL_BRD1			=> FEMB_SCL_BRD1,
		FEMB_SDA_BRD1_P		=> FEMB_SDA_BRD1_P,
		FEMB_SDA_BRD1_N		=> FEMB_SDA_BRD1_N,

		FEMB_SCL_BRD2			=> FEMB_SCL_BRD2,
		FEMB_SDA_BRD2_P		=> FEMB_SDA_BRD2_P,
		FEMB_SDA_BRD2_N		=> FEMB_SDA_BRD2_N,
		
		FEMB_SCL_BRD3			=> FEMB_SCL_BRD3,
		FEMB_SDA_BRD3_P		=> FEMB_SDA_BRD3_P,
		FEMB_SDA_BRD3_N		=> FEMB_SDA_BRD3_N

	);	
					
				

IMP_EEPROM_cntl_inst : entity work.IMP_EEPROM_cntl
	PORT MAP
	(
		rst					=>	ALG_RESET,
		clk	   			=> clk_40Mhz,
		SCL         		=> FLASH_SCL,
		SDA         		=> FLASH_SDA,
		EEPROM_RD			=>	EEPROM_RD,		
		EEPROM_WR			=> EEPROM_WR,	
		EEPROM_ADDR			=> EEPROM_ADDR,
		EEPROM_WR_DATA		=> EEPROM_WR_DATA	,
		EEPROM_RD_DATA		=> EEPROM_RD_DATA,
		
		LOAD_EE_DATA		=> LOAD_EE_DATA,
		EEPROM_DATA0		=> EEPROM_DATA0,
		EEPROM_DATA1		=> EEPROM_DATA1,
		EEPROM_DATA2		=> EEPROM_DATA2,
		EEPROM_DATA3		=> EEPROM_DATA3,
		EEPROM_DATA4		=> EEPROM_DATA4,
		EEPROM_DATA5		=> EEPROM_DATA5,
		EEPROM_DATA6		=> EEPROM_DATA6,
		EEPROM_DATA7		=> EEPROM_DATA7
	);
					

-------------	eeprom regmap------

		IP_SEL			<= EEPROM_DATA0(0);
		IP_IN_EEPROM	<=	EEPROM_DATA1;
		MAC_IN_EEPROM	<= EEPROM_DATA3(15 DOWNTO 0) & EEPROM_DATA2;
		
---------------------
		
		
		
WIB_PWR_MON_INST :	entity work.WIB_PWR_MON 
	PORT MAP
	(
		rst					=>	ALG_RESET,
		clk	   			=> clk_40Mhz,
		FILTER_EN  			=> FILTER_EN,
		start_conv			=> PWR_MES_start,
		DATA_VALID			=>	PWR_MES_RDY,
		
		PWR_MES_SEL			=> PWR_MES_SEL,
		PWR_MES_OUT			=> PWR_MES_OUT,
		
		PWR_SCL_BRD0		=> PWR_SCL_BRD0,
		PWR_SDA_BRD0		=> PWR_SDA_BRD0,
		
		PWR_SCL_BRD1		=> PWR_SCL_BRD1,		
		PWR_SDA_BRD1		=> PWR_SDA_BRD1,		
		
		PWR_SCL_BRD2		=> PWR_SCL_BRD2,		
		PWR_SDA_BRD2		=> PWR_SDA_BRD2,		

		PWR_SCL_BRD3		=> PWR_SCL_BRD3,		
		PWR_SDA_BRD3		=> PWR_SDA_BRD3,		

		PWR_SCL_BIAS		=> PWR_SCL_BIAS,
		PWR_SDA_BIAS		=> PWR_SDA_BIAS,
		
		PWR_SCL_WIB			=> PWR_SCL_WIB,
		PWR_SDA_WIB			=> PWR_SDA_WIB	


);




	SI5342_INTR			<= 'Z';
	SI5342_SEL0			<=	'0';
	SI5342_SEL1			<= '0';
	SI5342_RST			<= not SILABS_RST;
	SI5342_OE			<= '0';

	

	SI5344_INTR			<= 'Z';
	SI5344_SEL0			<= '0';
	SI5344_SEL1			<= '0';
	SI5344_RST			<= not SILABS_RST;
	SI5344_OE			<= '0';

	I2C_DEV_ADDR	<= x"6B";
	
	I2c_master_SI5342_inst  : entity work.I2c_master
	PORT MAP
	(
		rst   	   	=> ALG_RESET,				
		sys_clk	   	=> clk_40Mhz,
		SCL_O         	=> SI5342_SCL,
		SDA         	=> SI5342_SDA,					
		I2C_WR_STRB 	=> I2C_WR_STRB_S1,
		I2C_RD_STRB 	=> I2C_RD_STRB_S1,
		I2C_DEV_ADDR	=> I2C_DEV_ADDR(6 downto 0),
		I2C_NUM_BYTES	=> I2C_NUM_BYTES,	
		I2C_ADDRESS		=> I2C_ADDRESS,  -- used only with WR_STRB
		I2C_DOUT			=> I2C_DOUT_S1,
		I2C_DIN			=> x"000000" & I2C_DIN,
		I2C_BUSY       => open,
		I2C_DEV_AVL		=> open
	);
	
	
	I2c_master_SI5344_inst  : entity work.I2c_master
	PORT MAP
	(
		rst   	   	=> ALG_RESET,				
		sys_clk	   	=> clk_40Mhz,
		SCL_O         	=> SI5344_SCL,
		SDA         	=> SI5344_SDA,					
		I2C_WR_STRB 	=> I2C_WR_STRB_S2,
		I2C_RD_STRB 	=> I2C_RD_STRB_S2,
		I2C_DEV_ADDR	=> I2C_DEV_ADDR(6 downto 0),
		I2C_NUM_BYTES	=> I2C_NUM_BYTES,	
		I2C_ADDRESS		=> I2C_ADDRESS,  -- used only with WR_STRB
		I2C_DOUT			=> I2C_DOUT_S2,
		I2C_DIN			=> x"000000" & I2C_DIN,
		I2C_BUSY       => open,
		I2C_DEV_AVL		=> open
	);
			
					
		
AV_sfl_epcq_inst	: entity work.AV_sfl_epcq
	PORT MAP
	(
		rst         => ALG_RESET,	 			
		clk         => clk_40Mhz,
		JTAG_EEPROM	=> JTAG_EEPROM,
		start_op		=> F_FLASH_S_OP,		
		op_code	   => FPGA_F_OP_CODE,		
		address	   => FPGA_F_ADDR, 			
		status		=> FPGA_F_status,		
		DPM_WREN		=> DPM_WREN,
		DPM_ADDR		=> DPM_ADDR,
		DPM_Q	  		=> DPM_Q,
		DPM_D			=>	DPM_D
		
	);
			
	
	
end WIB_ProtoDUNE_FPGA_ARCH;
