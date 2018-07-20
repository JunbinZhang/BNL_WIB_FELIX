--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: WIB_PWR_MON.VHD   WIB V2  VERSION
--////                                                                                                                                      
--////  Author: Jack Fried                                        
--////          jfried@bnl.gov                
--////  Created:  09/16/2016
--////  Modified: 04/24/2017
--////  Description:  
--////                                  
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2016 Brookhaven National Laboratory
--////
--/////////////////////////////////////////////////////////////////////



library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_unsigned.all;





--  Entity Declaration

ENTITY WIB_PWR_MON IS
	 
	PORT
	(
		rst					: IN 	STD_LOGIC;				
		clk	   			: IN 	STD_LOGIC;			-- 40MHZ ONLY

		FILTER_EN  			: IN 	STD_LOGIC;			-- 40MHZ ONLY		
		start_conv			: IN 	STD_LOGIC;		
		DATA_VALID			: OUT	STD_LOGIC;	
		
		PWR_MES_SEL			: IN 		STD_LOGIC_VECTOR(7 downto 0);		
		PWR_MES_OUT			: OUT 	STD_LOGIC_VECTOR(31 downto 0);		
		
		PWR_SCL_BRD0		: OUT		STD_LOGIC;				--	2.5V, LTC2991 clk control
		PWR_SDA_BRD0		: INOUT	STD_LOGIC;			--	2.5V, LTC2991 SDA control
		
		PWR_SCL_BRD1		: OUT		STD_LOGIC;				--	2.5V, LTC2991 clk control
		PWR_SDA_BRD1		: INOUT	STD_LOGIC;			--	2.5V, LTC2991 SDA control
		
		PWR_SCL_BRD2		: OUT		STD_LOGIC;				--	2.5V, LTC2991 clk control
		PWR_SDA_BRD2		: INOUT	STD_LOGIC;			--	2.5V, LTC2991 SDA control

		PWR_SCL_BRD3		: OUT		STD_LOGIC;				--	2.5V, LTC2991 clk control
		PWR_SDA_BRD3		: INOUT	STD_LOGIC;			--	2.5V, LTC2991 SDA control

		PWR_SCL_BIAS		: OUT		STD_LOGIC;				--	2.5V, LTC2991 clk control
		PWR_SDA_BIAS		: INOUT	STD_LOGIC;			--	2.5V, LTC2991 SDA control		
					
		PWR_SCL_WIB			: OUT		STD_LOGIC;				--	2.5V, LTC2991 clk control
		PWR_SDA_WIB			: INOUT	STD_LOGIC			--	2.5V, LTC2991 SDA control		

	);
	
END WIB_PWR_MON;


ARCHITECTURE behavior OF WIB_PWR_MON IS




	type state_typ is (	s_idle ,s_ltc_setup1, s_ltc_setup2, s_ltc_setup3,s_ltc_setup4,
								s_ltc_SET_ADDR_0C, s_ltc_READ_0C , s_ltc_SET_ADDR_10, s_ltc_READ_10 , 
								s_ltc_SET_ADDR_14, s_ltc_READ_14 , s_ltc_SET_ADDR_18, s_ltc_READ_18 , 
								s_ltc_SET_ADDR_1A, s_ltc_READ_1A , s_ltc_SET_ADDR_1C, s_ltc_READ_1C ,
								s_ltc_SET_ADDR_0A, s_ltc_READ_0A , s_ltc_SET_ADDR_0E, s_ltc_READ_0E , 
								s_ltc_SET_ADDR_12, s_ltc_READ_12 , s_ltc_SET_ADDR_16, s_ltc_READ_16 , s_done );	

	
	SIGNAL STATE : state_typ;

	SIGNAL data_index			: integer range 31 downto 0;
	SIGNAL DLY_CNT 			: integer range 127 downto 0;		
	SIGNAL DLY_CNT2 			: integer range 127 downto 0;			
	SIGNAL I2C_WR_STRB		: STD_LOGIC;
	SIGNAL I2C_RD_STRB		: STD_LOGIC;
	SIGNAL I2C_DEV_ADDR		: STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL I2C_BIAS_ADDR		: STD_LOGIC_VECTOR(7 downto 0);	
	SIGNAL I2C_NUM_BYTES		: STD_LOGIC_VECTOR(3 downto 0);
	SIGNAL I2C_ADDRESS		: STD_LOGIC_VECTOR(7 downto 0);
	
	SIGNAL I2C_DOUT_S1		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL I2C_DOUT_S2		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL I2C_DOUT_S3		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL I2C_DOUT_S4		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL I2C_DOUT_S5		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL I2C_DOUT_S6		: STD_LOGIC_VECTOR(31 downto 0);
	
	SIGNAL I2C_DIN				: STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL I2C_BUSY			: STD_LOGIC;

	
	SIGNAL DOUT_S1				: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL DOUT_S2				: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL DOUT_S3				: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL DOUT_S4				: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL DOUT_S5				: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL DOUT_S6				: STD_LOGIC_VECTOR(15 downto 0);	
	
	SIGNAL BIAS_VCC			:  STD_LOGIC_VECTOR(15 downto 0);	--- VCC = Result + 2.5V  (LSB = 305.18μV)
	SIGNAL BIAS_TEMP			:  STD_LOGIC_VECTOR(15 downto 0);	-- TEMP = LSB = 0.0625 Degrees  	

	SIGNAL BRD1_VCC			:  STD_LOGIC_VECTOR(15 downto 0);	--- VCC = Result + 2.5V  (LSB = 305.18μV)
	SIGNAL BRD1_TEMP			:  STD_LOGIC_VECTOR(15 downto 0);	-- TEMP = LSB = 0.0625 Degrees  
	SIGNAL BRD1_V1				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD1_C1				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD1_V2				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD1_C2				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD1_V3				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD1_C3				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD1_V4				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD1_C4				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD1_V5				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD1_C5				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)

	SIGNAL BRD2_VCC			:  STD_LOGIC_VECTOR(15 downto 0);	--- VCC = Result + 2.5V  (LSB = 305.18μV)
	SIGNAL BRD2_TEMP			:  STD_LOGIC_VECTOR(15 downto 0);	-- TEMP = LSB = 0.0625 Degrees  
	SIGNAL BRD2_V1				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD2_C1				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD2_V2				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD2_C2				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD2_V3				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD2_C3				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD2_V4				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD2_C4				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD2_V5				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD2_C5				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)

	SIGNAL BRD3_VCC			:  STD_LOGIC_VECTOR(15 downto 0);	--- VCC = Result + 2.5V  (LSB = 305.18μV)
	SIGNAL BRD3_TEMP			:  STD_LOGIC_VECTOR(15 downto 0);	-- TEMP = LSB = 0.0625 Degrees  
	SIGNAL BRD3_V1				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD3_C1				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD3_V2				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD3_C2				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD3_V3				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD3_C3				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD3_V4				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD3_C4				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD3_V5				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD3_C5				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
		
	SIGNAL BRD4_VCC			:  STD_LOGIC_VECTOR(15 downto 0);	--- VCC = Result + 2.5V  (LSB = 305.18μV)
	SIGNAL BRD4_TEMP			:  STD_LOGIC_VECTOR(15 downto 0);	-- TEMP = LSB = 0.0625 Degrees  
	SIGNAL BRD4_V1				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD4_C1				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD4_V2				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD4_C2				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD4_V3				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD4_C3				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD4_V4				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD4_C4				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL BRD4_V5				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL BRD4_C5				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)	
	
	
	SIGNAL WIB_VCC			:  STD_LOGIC_VECTOR(15 downto 0);	--- VCC = Result + 2.5V  (LSB = 305.18μV)
	SIGNAL WIB_TEMP			:  STD_LOGIC_VECTOR(15 downto 0);	-- TEMP = LSB = 0.0625 Degrees  
	SIGNAL WIB_V1				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL WIB_C1				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL WIB_V2				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL WIB_C2				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL WIB_V3				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL WIB_C3				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)
	SIGNAL WIB_V4				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13	(13 downto 0)
	SIGNAL WIB_C4				:  STD_LOGIC_VECTOR(15 downto 0);	-- LSB = 305.18μV = 2.5/2^13  (13 downto 0)

	
	
begin
	
	
PWR_MES_OUT <=	BIAS_VCC	& BIAS_TEMP WHEN (PWR_MES_SEL = X"00") ELSE
					BRD1_VCC & BRD1_TEMP WHEN (PWR_MES_SEL = X"01") ELSE
					BRD1_V1  & BRD1_C1 	WHEN (PWR_MES_SEL = X"02") ELSE
					BRD1_V2  & BRD1_C2 	WHEN (PWR_MES_SEL = X"03") ELSE
					BRD1_V3	& BRD1_C3 	WHEN (PWR_MES_SEL = X"04") ELSE
					BRD1_V4	& BRD1_C4 	WHEN (PWR_MES_SEL = X"05") ELSE
					BRD1_V5	& BRD1_C5 	WHEN (PWR_MES_SEL = X"06") ELSE

					BRD2_VCC	& BRD2_TEMP WHEN (PWR_MES_SEL = X"07") ELSE
					BRD2_V1  & BRD2_C1   WHEN (PWR_MES_SEL = X"08") ELSE
					BRD2_V2  & BRD2_C2	WHEN (PWR_MES_SEL = X"09") ELSE
					BRD2_V3	& BRD2_C3	WHEN (PWR_MES_SEL = X"0A") ELSE
					BRD2_V4	& BRD2_C4	WHEN (PWR_MES_SEL = X"0B") ELSE
					BRD2_V5	& BRD2_C5	WHEN (PWR_MES_SEL = X"0C") ELSE

					BRD3_VCC	& BRD3_TEMP	WHEN (PWR_MES_SEL = X"0D") ELSE
					BRD3_V1	& BRD3_C1	WHEN (PWR_MES_SEL = X"0E") ELSE
					BRD3_V2	& BRD3_C2	WHEN (PWR_MES_SEL = X"0F") ELSE
					BRD3_V3	& BRD3_C3	WHEN (PWR_MES_SEL = X"10") ELSE
					BRD3_V4	& BRD3_C4	WHEN (PWR_MES_SEL = X"11") ELSE
					BRD3_V5	& BRD3_C5	WHEN (PWR_MES_SEL = X"12") ELSE
				
					BRD4_VCC	& BRD4_TEMP	WHEN (PWR_MES_SEL = X"13") ELSE
					BRD4_V1	& BRD4_C1	WHEN (PWR_MES_SEL = X"14") ELSE
					BRD4_V2  & BRD4_C2	WHEN (PWR_MES_SEL = X"15") ELSE
					BRD4_V3  & BRD4_C3	WHEN (PWR_MES_SEL = X"16") ELSE
					BRD4_V4  & BRD4_C4	WHEN (PWR_MES_SEL = X"17") ELSE
					BRD4_V5  & BRD4_C5	WHEN (PWR_MES_SEL = X"18") ELSE
					
					WIB_VCC & WIB_TEMP	WHEN (PWR_MES_SEL = X"19") ELSE
					WIB_V1  & WIB_C1		WHEN (PWR_MES_SEL = X"1A") ELSE
					WIB_V2  & WIB_C2		WHEN (PWR_MES_SEL = X"1B") ELSE
					WIB_V3  & WIB_C3		WHEN (PWR_MES_SEL = X"1C") ELSE
					WIB_V4  & WIB_C4		WHEN (PWR_MES_SEL = X"1D") ELSE
					X"DEADBEEF"	;
					
	
	
	
	

	I2c_master_S1_inst  : entity work.I2c_master 
	generic map (  SCL_WIDTH => 20)
	PORT MAP
	(
		rst   	   	=> rst,				
		sys_clk	   	=> clk,		
		SCL_O         	=> PWR_SCL_BRD0,
		SDA         	=> PWR_SDA_BRD0,					
		I2C_WR_STRB 	=> I2C_WR_STRB,
		I2C_RD_STRB 	=> I2C_RD_STRB,
		I2C_DEV_ADDR	=> I2C_DEV_ADDR(7 downto 1),
		I2C_NUM_BYTES	=> I2C_NUM_BYTES,	
		I2C_ADDRESS		=> I2C_ADDRESS,  -- used only with WR_STRB
		I2C_DOUT			=> I2C_DOUT_S1,
		I2C_DIN			=> x"000000" & I2C_DIN,
		I2C_BUSY       => I2C_BUSY,
		I2C_DEV_AVL		=> open
	);
	
	
	I2c_master_S2_inst  : entity work.I2c_master 
	generic map (  SCL_WIDTH => 20)
	PORT MAP
	(
		rst   	   	=> rst,				
		sys_clk	   	=> clk,		
		SCL_O         	=> PWR_SCL_BRD1,
		SDA         	=> PWR_SDA_BRD1,					
		I2C_WR_STRB 	=> I2C_WR_STRB,
		I2C_RD_STRB 	=> I2C_RD_STRB,
		I2C_DEV_ADDR	=> I2C_DEV_ADDR(7 downto 1),
		I2C_NUM_BYTES	=> I2C_NUM_BYTES,	
		I2C_ADDRESS		=> I2C_ADDRESS,  -- used only with WR_STRB
		I2C_DOUT			=> I2C_DOUT_S2,
		I2C_DIN			=> x"000000" & I2C_DIN,
		I2C_BUSY       => open,
		I2C_DEV_AVL		=> open
	);
	
	
	I2c_master_S3_inst  : entity work.I2c_master 
	generic map (  SCL_WIDTH => 20)
	PORT MAP
	(
		rst   	   	=> rst,				
		sys_clk	   	=> clk,		
		SCL_O         	=> PWR_SCL_BRD2,
		SDA         	=> PWR_SDA_BRD2,					
		I2C_WR_STRB 	=> I2C_WR_STRB,
		I2C_RD_STRB 	=> I2C_RD_STRB,
		I2C_DEV_ADDR	=> I2C_DEV_ADDR(7 downto 1),
		I2C_NUM_BYTES	=> I2C_NUM_BYTES,	
		I2C_ADDRESS		=> I2C_ADDRESS,  -- used only with WR_STRB
		I2C_DOUT			=> I2C_DOUT_S3,
		I2C_DIN			=> x"000000" & I2C_DIN,
		I2C_BUSY       => open,
		I2C_DEV_AVL		=> open
	);
	
	
	I2c_master_S4_inst  : entity work.I2c_master 
	generic map (  SCL_WIDTH => 20)
	PORT MAP
	(
		rst   	   	=> rst,				
		sys_clk	   	=> clk,		
		SCL_O         	=> PWR_SCL_BRD3,
		SDA         	=> PWR_SDA_BRD3,					
		I2C_WR_STRB 	=> I2C_WR_STRB,
		I2C_RD_STRB 	=> I2C_RD_STRB,
		I2C_DEV_ADDR	=> I2C_DEV_ADDR(7 downto 1),
		I2C_NUM_BYTES	=> I2C_NUM_BYTES,	
		I2C_ADDRESS		=> I2C_ADDRESS,  -- used only with WR_STRB
		I2C_DOUT			=> I2C_DOUT_S4,
		I2C_DIN			=> x"000000" & I2C_DIN,
		I2C_BUSY       => open,
		I2C_DEV_AVL		=> open
	);
	
	
	I2C_BIAS_ADDR	<= x"98";
	I2c_master_S5_inst  : entity work.I2c_master 
	generic map (  SCL_WIDTH => 20)
	PORT MAP
	(
		rst   	   	=> rst,				
		sys_clk	   	=> clk,		
		SCL_O         	=> PWR_SCL_BIAS,
		SDA         	=> PWR_SDA_BIAS,					
		I2C_WR_STRB 	=> I2C_WR_STRB,
		I2C_RD_STRB 	=> I2C_RD_STRB,
		I2C_DEV_ADDR	=> I2C_DEV_ADDR(7 downto 1),
		I2C_NUM_BYTES	=> I2C_NUM_BYTES,	
		I2C_ADDRESS		=> I2C_ADDRESS,  -- used only with WR_STRB
		I2C_DOUT			=> I2C_DOUT_S5,
		I2C_DIN			=> x"000000" & I2C_DIN,
		I2C_BUSY       => open,
		I2C_DEV_AVL		=> open
	);
		

	
		I2c_master_S6_inst  : entity work.I2c_master 
	generic map (  SCL_WIDTH => 20)
	PORT MAP
	(
		rst   	   	=> rst,				
		sys_clk	   	=> clk,		
		SCL_O         	=> PWR_SCL_WIB,
		SDA         	=> PWR_SDA_WIB,					
		I2C_WR_STRB 	=> I2C_WR_STRB,
		I2C_RD_STRB 	=> I2C_RD_STRB,
		I2C_DEV_ADDR	=> I2C_DEV_ADDR(7 downto 1),
		I2C_NUM_BYTES	=> I2C_NUM_BYTES,	
		I2C_ADDRESS		=> I2C_ADDRESS,  -- used only with WR_STRB
		I2C_DOUT			=> I2C_DOUT_S6,
		I2C_DIN			=> x"000000" & I2C_DIN,
		I2C_BUSY       => open,
		I2C_DEV_AVL		=> open
	);
		
	

		DOUT_S1(7 downto 0)		<= I2C_DOUT_S1(15 downto 8);
		DOUT_S1(15 downto 8)		<= I2C_DOUT_S1(7 downto 0);
		DOUT_S2(7 downto 0)		<= I2C_DOUT_S2(15 downto 8);
		DOUT_S2(15 downto 8)		<= I2C_DOUT_S2(7 downto 0);
		DOUT_S3(7 downto 0)		<= I2C_DOUT_S3(15 downto 8);
		DOUT_S3(15 downto 8)		<= I2C_DOUT_S3(7 downto 0);
		DOUT_S4(7 downto 0)		<= I2C_DOUT_S4(15 downto 8);
		DOUT_S4(15 downto 8)		<= I2C_DOUT_S4(7 downto 0);
		DOUT_S5(7 downto 0)		<= I2C_DOUT_S5(15 downto 8);
		DOUT_S5(15 downto 8)		<= I2C_DOUT_S5(7 downto 0);
		DOUT_S6(7 downto 0)		<= I2C_DOUT_S6(15 downto 8);
		DOUT_S6(15 downto 8)		<= I2C_DOUT_S6(7 downto 0);		

     process( clk , rst )
       begin
         if ( rst = '1' ) then			
				DATA_VALID		<= '0';
				data_index		<= 0;
				DLY_CNT			<= 0;
				DLY_CNT2			<= 0;				
				I2C_WR_STRB		<= '0';
				I2C_RD_STRB		<= '0';
				I2C_DEV_ADDR	<= x"00";
				I2C_NUM_BYTES	<= x"0";
				I2C_ADDRESS		<= x"00";
				I2C_DIN			<= x"00";
			
				BIAS_VCC			<= ( others => '0' );	
				BIAS_TEMP		<= ( others => '0' );	
				
				BRD1_VCC			<= ( others => '0' );	
				BRD1_TEMP		<= ( others => '0' );	
				BRD1_V1			<= ( others => '0' );	
				BRD1_C1			<= ( others => '0' );	
				BRD1_V2			<= ( others => '0' );	
				BRD1_C2			<= ( others => '0' );	
				BRD1_V3			<= ( others => '0' );	
				BRD1_C3			<= ( others => '0' );	
				BRD1_V4			<= ( others => '0' );	
				BRD1_C4			<= ( others => '0' );	
				BRD1_V5			<= ( others => '0' );	
				BRD1_C5			<= ( others => '0' );		
				
				BRD2_VCC			<= ( others => '0' );	
				BRD2_TEMP		<= ( others => '0' );	
				BRD2_V1			<= ( others => '0' );	
				BRD2_C1			<= ( others => '0' );	
				BRD2_V2			<= ( others => '0' );	
				BRD2_C2			<= ( others => '0' );	
				BRD2_V3			<= ( others => '0' );	
				BRD2_C3			<= ( others => '0' );	
				BRD2_V4			<= ( others => '0' );	
				BRD2_C4			<= ( others => '0' );	
				BRD2_V5			<= ( others => '0' );	
				BRD2_C5			<= ( others => '0' );					
				
				BRD3_VCC			<= ( others => '0' );	
				BRD3_TEMP		<= ( others => '0' );	
				BRD3_V1			<= ( others => '0' );	
				BRD3_C1			<= ( others => '0' );	
				BRD3_V2			<= ( others => '0' );	
				BRD3_C2			<= ( others => '0' );	
				BRD3_V3			<= ( others => '0' );	
				BRD3_C3			<= ( others => '0' );	
				BRD3_V4			<= ( others => '0' );	
				BRD3_C4			<= ( others => '0' );	
				BRD3_V5			<= ( others => '0' );	
				BRD3_C5			<= ( others => '0' );					
				
				BRD4_VCC			<= ( others => '0' );	
				BRD4_TEMP		<= ( others => '0' );	
				BRD4_V1			<= ( others => '0' );	
				BRD4_C1			<= ( others => '0' );	
				BRD4_V2			<= ( others => '0' );	
				BRD4_C2			<= ( others => '0' );	
				BRD4_V3			<= ( others => '0' );	
				BRD4_C3			<= ( others => '0' );	
				BRD4_V4			<= ( others => '0' );	
				BRD4_C4			<= ( others => '0' );	
				BRD4_V5			<= ( others => '0' );	
				BRD4_C5			<= ( others => '0' );					

				WIB_VCC			<= ( others => '0' );	
				WIB_TEMP		<= ( others => '0' );	
				WIB_V1			<= ( others => '0' );	
				WIB_C1			<= ( others => '0' );	
				WIB_V2			<= ( others => '0' );	
				WIB_C2			<= ( others => '0' );	
				WIB_V3			<= ( others => '0' );	
				WIB_C3			<= ( others => '0' );	
				WIB_V4			<= ( others => '0' );	
				WIB_C4			<= ( others => '0' );	

				
				STATE 	<= s_idle;
		
         elsif rising_edge( clk ) then
	        case STATE is
            when s_idle =>		
						I2C_WR_STRB		<= '0';
						I2C_RD_STRB		<= '0';
						I2C_DEV_ADDR	<= x"90";
						I2C_NUM_BYTES	<= x"1";
						I2C_ADDRESS		<= x"06";
						I2C_DIN			<= x"99";
						data_index		<= 0;
						DLY_CNT			<= 0;
						DLY_CNT2			<= 0;			
						if (start_conv = '1') then 					
							STATE 			<= s_ltc_setup1; 
							DATA_VALID		<= '0';
						end if;

				when	s_ltc_setup1 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"1";
							I2C_ADDRESS		<= x"06";
							if(FILTER_EN = '1') then
								I2C_DIN			<= x"99"	;		
							else
								I2C_DIN			<= x"11"	;		
							end if;
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= s_ltc_setup2; 
							end if;
						end if;				
						
				when	s_ltc_setup2 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"1";
							I2C_ADDRESS		<= x"07";
							if(FILTER_EN = '1') then
								I2C_DIN			<= x"99"	;		
							else
								I2C_DIN			<= x"11"	;		
							end if;	
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= s_ltc_setup3; 
							end if;
						end if;							
						
						
				when	s_ltc_setup3 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"1";
							I2C_ADDRESS		<= x"01";
							I2C_DIN			<= x"FF";
							DLY_CNT2			<= 0;
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= s_ltc_setup4 ; 
							end if;
						end if;							
						
						
	-----------------------				ADD DELAYS	
						
						
				when	s_ltc_setup4 =>
							DLY_CNT2			<= DLY_CNT2 +1;	
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"0";
							I2C_ADDRESS		<= x"00";
							I2C_DIN			<= x"FF";		
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								if( DLY_CNT2 >= 10) then
									STATE 			<= s_ltc_SET_ADDR_0C ; 
								else
									STATE 			<= s_ltc_setup4 ; 
								end if;
							end if;
						end if;									
	
												
-------------------		ltc2991   v1-v2		reg 0c
				when	s_ltc_SET_ADDR_0C =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"0";
							I2C_ADDRESS		<= x"0C";	
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= s_ltc_READ_0C; 
							end if;
						end if;							
												

				when	s_ltc_READ_0C =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"2";
						if(DLY_CNT = 2) then
							I2C_RD_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_RD_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;								
								BRD1_C1  <= DOUT_S1;
								BRD2_C1  <= DOUT_S2;
								BRD3_C1  <= DOUT_S3;
								BRD4_C1  <= DOUT_S4;								
								BRD1_C5  <= DOUT_S5;
								WIB_C1   <= DOUT_S6;								
								STATE 	<= s_ltc_SET_ADDR_10; 
							end if;
						end if;							
												

-------------------		ltc2991   v3-v4		reg 10						
				when	s_ltc_SET_ADDR_10 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"0";
							I2C_ADDRESS		<= x"10";	
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= s_ltc_READ_10; 
							end if;
						end if;							
												

				when	s_ltc_READ_10 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"2";
						if(DLY_CNT = 2) then
							I2C_RD_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_RD_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;								
								BRD1_C2  <= DOUT_S1;
								BRD2_C2  <= DOUT_S2;
								BRD3_C2  <= DOUT_S3;
								BRD4_C2  <= DOUT_S4;								
								BRD2_C5  <= DOUT_S5;		
								WIB_C2   <= DOUT_S6;		
								STATE 			<= s_ltc_SET_ADDR_14; 
							end if;
						end if;							
												
																							

-------------------		ltc2991   v5-v6		reg 14							
				when	s_ltc_SET_ADDR_14 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"0";
							I2C_ADDRESS		<= x"14";	
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= s_ltc_READ_14; 
							end if;
						end if;							
												

				when	s_ltc_READ_14 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"2";
						if(DLY_CNT = 2) then
							I2C_RD_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_RD_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;								
								BRD1_C3  <= DOUT_S1;
								BRD2_C3  <= DOUT_S2;
								BRD3_C3  <= DOUT_S3;
								BRD4_C3  <= DOUT_S4;								
								BRD3_C5  <= DOUT_S5;	
								WIB_C3   <= DOUT_S6;
								STATE 			<= s_ltc_SET_ADDR_18;  
							end if;
						end if;							

						
-------------------		ltc2991   v7-v8		reg 18							
				when	s_ltc_SET_ADDR_18 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"0";
							I2C_ADDRESS		<= x"18";	
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= s_ltc_READ_18; 
							end if;
						end if;							
												

				when	s_ltc_READ_18 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"2";
						if(DLY_CNT = 2) then
							I2C_RD_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_RD_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;								
								BRD1_C4  <= DOUT_S1;
								BRD2_C4  <= DOUT_S2;
								BRD3_C4  <= DOUT_S3;
								BRD4_C4  <= DOUT_S4;								
								BRD4_C5  <= DOUT_S5;			
								WIB_C4   <= DOUT_S6;						
								STATE 			<= s_ltc_SET_ADDR_1A; 
							end if;
						end if;							
						
						
-------------------		ltc2991   temp		reg 1A							
				when	s_ltc_SET_ADDR_1A =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"0";
							I2C_ADDRESS		<= x"1A";	
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= s_ltc_READ_1A; 
							end if;
						end if;							
												

				when	s_ltc_READ_1A =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"2";
						if(DLY_CNT = 2) then
							I2C_RD_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_RD_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;		
	
								BRD1_TEMP  <= DOUT_S1;
								BRD2_TEMP  <= DOUT_S2;
								BRD3_TEMP  <= DOUT_S3;
								BRD4_TEMP  <= DOUT_S4;								
								BIAS_TEMP  <= DOUT_S5;			
								WIB_TEMP   <= DOUT_S6;								
								STATE 			<= s_ltc_SET_ADDR_1C; 
							end if;
						end if;							

						

-------------------		ltc2991   VCC		reg 1C							
				when	s_ltc_SET_ADDR_1C =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"0";
							I2C_ADDRESS		<= x"1C";	
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= s_ltc_READ_1C; 
							end if;
						end if;							
												

				when	s_ltc_READ_1C =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"2";
						if(DLY_CNT = 2) then
							I2C_RD_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_RD_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;								
								BRD1_VCC  <= DOUT_S1;
								BRD2_VCC  <= DOUT_S2;
								BRD3_VCC  <= DOUT_S3;
								BRD4_VCC  <= DOUT_S4;								
								BIAS_VCC  <= DOUT_S5;	
								WIB_VCC	 <= DOUT_S6;
								STATE 			<= s_ltc_SET_ADDR_0A; 
							end if;
						end if;							


						
-------------------------------------------------------------------------------------------------------------------------						
						
						
						
									
-------------------		ltc2991   v1		reg 0A
				when	s_ltc_SET_ADDR_0A =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"0";
							I2C_ADDRESS		<= x"0A";	
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= s_ltc_READ_0A; 
							end if;
						end if;							
												

				when	s_ltc_READ_0A =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"2";
						if(DLY_CNT = 2) then
							I2C_RD_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_RD_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;								
								BRD1_V1  <= DOUT_S1;
								BRD2_V1  <= DOUT_S2;
								BRD3_V1  <= DOUT_S3;
								BRD4_V1  <= DOUT_S4;								
								BRD1_V5  <= DOUT_S5;
								WIB_V1   <= DOUT_S6;	
								STATE 			<= s_ltc_SET_ADDR_0E; 
							end if;
						end if;							
												

-------------------		ltc2991   v3		reg 10						
				when	s_ltc_SET_ADDR_0E =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"0";
							I2C_ADDRESS		<= x"0E";	
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= s_ltc_READ_0E; 
							end if;
						end if;							
												

				when	s_ltc_READ_0E =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"2";
						if(DLY_CNT = 2) then
							I2C_RD_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_RD_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;								
								BRD1_V2  <= DOUT_S1;
								BRD2_V2  <= DOUT_S2;
								BRD3_V2  <= DOUT_S3;
								BRD4_V2  <= DOUT_S4;								
								BRD2_V5  <= DOUT_S5;	
								WIB_V2   <= DOUT_S6;	
								STATE 			<= s_ltc_SET_ADDR_12; 
							end if;
						end if;							
												
																							

-------------------		ltc2991   v5		reg 12							
				when	s_ltc_SET_ADDR_12  =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"0";
							I2C_ADDRESS		<= x"12";	
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= s_ltc_READ_12; 
							end if;
						end if;							
												

				when	s_ltc_READ_12 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"2";
						if(DLY_CNT = 2) then
							I2C_RD_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_RD_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;								
								BRD1_V3  <= DOUT_S1;
								BRD2_V3  <= DOUT_S2;
								BRD3_V3  <= DOUT_S3;
								BRD4_V3  <= DOUT_S4;								
								BRD3_V5  <= DOUT_S5;	
								WIB_V3   <= DOUT_S6;	
								STATE 			<= s_ltc_SET_ADDR_16;  
							end if;
						end if;							

						
-------------------		ltc2991   v7		reg 16							
				when	s_ltc_SET_ADDR_16 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"0";
							I2C_ADDRESS		<= x"16";	
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= s_ltc_READ_16; 
							end if;
						end if;							
												

				when	s_ltc_READ_16 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"90";
							I2C_NUM_BYTES	<= x"2";
						if(DLY_CNT = 2) then
							I2C_RD_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_RD_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;								
								BRD1_V4  <= DOUT_S1;
								BRD2_V4  <= DOUT_S2;
								BRD3_V4  <= DOUT_S3;
								BRD4_V4  <= DOUT_S4;								
								BRD4_V5  <= DOUT_S5;	
								WIB_V4   <= DOUT_S6;		
								STATE 			<= s_done; 
							end if;
						end if;														
	
				when s_done => 
					if 	(start_conv = '1') then
						STATE 	<= s_done;
					else
						STATE 	<= s_idle;
					end if;
           when others => 
						STATE 	<= s_idle;
           end case;   
         end if;
       end process ;
	
END behavior;
