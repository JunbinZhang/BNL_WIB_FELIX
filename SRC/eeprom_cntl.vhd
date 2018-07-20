--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: EEPROM_cntl.VHD
--////                                                                                                                                      
--////  Author: Jack Fried                                        
--////          jfried@bnl.gov                
--////  Created:  10/24/2013
--////  Modified: 12/9/2014
--////  Description:  
--////                                  
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2014 Brookhaven National Laboratory
--////
--/////////////////////////////////////////////////////////////////////



library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_unsigned.all;


--  Entity Declaration

ENTITY EEPROM_cntl IS
	 
	PORT
	(
		rst					: IN 	STD_LOGIC;				
		clk	   			: IN 	STD_LOGIC;		
		SCL         		: OUT 	STD_LOGIC;
		SDA         		: INOUT 	STD_LOGIC;						
		EEPROM_RD			: IN 	STD_LOGIC;		
		EEPROM_WR			: IN 	STD_LOGIC;		
		EEPROM_ADDR			: IN 	STD_LOGIC_VECTOR(15 downto 0);	
		EEPROM_WR_DATA		: IN  STD_LOGIC_VECTOR(31 downto 0);
		EEPROM_RD_DATA		: OUT STD_LOGIC_VECTOR(31 downto 0);
		EEPROM_BUSY 		: OUT	STD_LOGIC	
	);
	
END EEPROM_cntl;


ARCHITECTURE behavior OF EEPROM_cntl IS



COMPONENT  I2c_master_16b_Addr
	PORT
	(
		rst   	   	: IN 	STD_LOGIC;				
		sys_clk	   	: IN 	STD_LOGIC;		
		
		SCL         	: OUT 	STD_LOGIC;
		SDA         	: INOUT 	STD_LOGIC;						
		I2C_WR_STRB 	: IN STD_LOGIC;
		I2C_RD_STRB 	: IN STD_LOGIC;
		I2C_DEV_ADDR	: IN  STD_LOGIC_VECTOR(6 downto 0);		
		I2C_NUM_BYTES	: IN  STD_LOGIC_VECTOR(3 downto 0);	  --I2C_NUM_BYTES --  For Writes 0 = address only,  1 = address + 1byte , 2 =  address + 2 bytes .... up to 4 bytes
																			  --I2C_NUM_BYTES --  For Reads  0 = read 1 byte,   1 = read 1 byte,  2 = read 2 bytes  ..  up to 4 bytes
		I2C_ADDRESS		: IN  STD_LOGIC_VECTOR(15 downto 0);	  -- used only with WR_STRB
		I2C_DOUT			: OUT STD_LOGIC_VECTOR(31 downto 0);	
		I2C_DIN			: IN  STD_LOGIC_VECTOR(31 downto 0);
		I2C_BUSY       : OUT	STD_LOGIC;
		I2C_DEV_AVL		: OUT STD_LOGIC
	);

END COMPONENT;


	type state_typ is (	s_idle ,S_WR_data_1,S_RD_data_1,S_RD_data_2, s_done );	

	
	SIGNAL STATE : state_typ;


	SIGNAL DLY_CNT 			: integer range 127 downto 0;		
	SIGNAL I2C_WR_STRB		: STD_LOGIC;
	SIGNAL I2C_RD_STRB		: STD_LOGIC;
	SIGNAL I2C_DEV_ADDR		: STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL I2C_NUM_BYTES		: STD_LOGIC_VECTOR(3 downto 0);
	SIGNAL I2C_ADDRESS		: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL I2C_DOUT_S1		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL I2C_DIN				: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL I2C_BUSY			: STD_LOGIC;

	
	SIGNAL DOUT_S1				: STD_LOGIC_VECTOR(15 downto 0);
	
begin
	

	I2c_master_16b_Addr_inst  : I2c_master_16b_Addr
	PORT MAP
	(
		rst   	   	=> rst,				
		sys_clk	   	=> clk,		
		SCL         	=> SCL,
		SDA         	=> SDA,					
		I2C_WR_STRB 	=> I2C_WR_STRB,
		I2C_RD_STRB 	=> I2C_RD_STRB,
		I2C_DEV_ADDR	=> I2C_DEV_ADDR(7 downto 1),
		I2C_NUM_BYTES	=> I2C_NUM_BYTES,	
		I2C_ADDRESS		=> I2C_ADDRESS,  -- used only with WR_STRB
		I2C_DOUT			=> I2C_DOUT_S1,
		I2C_DIN			=> I2C_DIN,
		I2C_BUSY       => I2C_BUSY,
		I2C_DEV_AVL		=> open
	);
	
	
		DOUT_S1	<= I2C_DOUT_S1(15 downto 0);


     process( clk , rst )
       begin
         if ( rst = '1' ) then			
				EEPROM_BUSY 	<= '0';
				DLY_CNT			<=  0;
				I2C_WR_STRB		<= '0';
				I2C_RD_STRB		<= '0';
				I2C_DEV_ADDR	<= x"A0";
				I2C_NUM_BYTES	<= x"0";
				I2C_ADDRESS		<= x"0000";
				I2C_DIN			<= x"00000000";			
				STATE 			<= s_idle;
		
         elsif rising_edge( clk ) then
	        case STATE is
            when s_idle =>		
						I2C_WR_STRB		<= '0';
						I2C_RD_STRB		<= '0';
						DLY_CNT			<= 0;
						EEPROM_BUSY 	<= '0';
						if (EEPROM_WR  = '1') then 					
							STATE 			<= S_WR_data_1; 
							EEPROM_BUSY 	<= '1';
						elsif(EEPROM_RD = '1') then
							EEPROM_BUSY 	<= '1';
							STATE 			<= S_RD_data_1; 
							end if;
				
						
				when	S_WR_data_1 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"A0";
							I2C_NUM_BYTES	<= x"5";
							I2C_ADDRESS		<= EEPROM_ADDR(13 downto 0) & b"00";	
							I2C_DIN			<= EEPROM_WR_DATA;		
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= s_done; 
							end if;
						end if;				
						
												
				when	S_RD_data_1 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"A0";
							I2C_NUM_BYTES	<= x"1";
							I2C_ADDRESS		<= EEPROM_ADDR(13 downto 0) & b"00";	
							I2C_DIN			<= x"00000000";		
						if(DLY_CNT = 2) then
							I2C_WR_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_WR_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;
								STATE 			<= S_RD_data_2; 
							end if;
						end if;				
						
				when	 S_RD_data_2 => 
							DLY_CNT 			<= DLY_CNT + 1;			
							I2C_DEV_ADDR	<= x"A0";
							I2C_NUM_BYTES	<= x"4";
						if(DLY_CNT = 2) then
							I2C_RD_STRB		<= '1';
						elsif	(DLY_CNT >= 10) then
							I2C_RD_STRB		<= '0';
							DLY_CNT 			<= 20;
							if(I2C_BUSY = '0') then
								DLY_CNT			<= 0;								
								EEPROM_RD_DATA <= I2C_DOUT_S1;						
								STATE 			<= s_done; 
							end if;
						end if;							
						
				when s_done => 
					if (EEPROM_WR  = '1'  or EEPROM_RD  = '1' )then
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
