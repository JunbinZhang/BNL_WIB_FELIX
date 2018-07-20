--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: IMP_EEPROM_cntl.VHD 
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

ENTITY IMP_EEPROM_cntl IS
	 
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
		
		LOAD_EE_DATA		: IN 	STD_LOGIC;		
		EEPROM_DATA0		: OUT STD_LOGIC_VECTOR(31 downto 0);
		EEPROM_DATA1		: OUT STD_LOGIC_VECTOR(31 downto 0);
		EEPROM_DATA2		: OUT STD_LOGIC_VECTOR(31 downto 0);
		EEPROM_DATA3		: OUT STD_LOGIC_VECTOR(31 downto 0);
		EEPROM_DATA4		: OUT STD_LOGIC_VECTOR(31 downto 0);
		EEPROM_DATA5		: OUT STD_LOGIC_VECTOR(31 downto 0);
		EEPROM_DATA6		: OUT STD_LOGIC_VECTOR(31 downto 0);
		EEPROM_DATA7		: OUT STD_LOGIC_VECTOR(31 downto 0)
	);
	
END IMP_EEPROM_cntl;


ARCHITECTURE behavior OF IMP_EEPROM_cntl IS



COMPONENT  EEPROM_cntl
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

END COMPONENT;


	type state_typ is (	s_idle ,s_read_DATA_0,s_read_DATA_1,s_read_DATA_2,s_read_DATA_3,s_read_DATA_4,s_read_DATA_5,s_read_DATA_6,s_read_DATA_7, s_done );	

	SIGNAL STATE : state_typ;
	
	SIGNAL DLY_CNT 			: integer range 127 downto 0;		
	
	SIGNAL EEPROM_RD_r			: STD_LOGIC;		
	SIGNAL EEPROM_WR_r			: STD_LOGIC;		
	SIGNAL EEPROM_ADDR_r			: STD_LOGIC_VECTOR(15 downto 0);	
	SIGNAL EEPROM_RD_DATA_r		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL EEPROM_BUSY 			: STD_LOGIC	;


	SIGNAL EEPROM_RD_s			: STD_LOGIC;		
	SIGNAL EEPROM_ADDR_s			: STD_LOGIC_VECTOR(15 downto 0);	

	SIGNAL EEPROM_auto_scan		: STD_LOGIC;		
		
	
	
begin
	
	
	EEPROM_cntl_inst  : EEPROM_cntl
	PORT MAP
	(
		rst					=>	rst,	
		clk	   			=> clk,
		SCL         		=> SCL, 
		SDA         		=> SDA,
		EEPROM_RD			=> EEPROM_RD_r,
		EEPROM_WR			=> EEPROM_WR_r,
		EEPROM_ADDR			=> EEPROM_ADDR_r,			
		EEPROM_WR_DATA		=> EEPROM_WR_DATA,
		EEPROM_RD_DATA		=> EEPROM_RD_DATA_r,
		EEPROM_BUSY 		=> EEPROM_BUSY
	);
	
	
	
EEPROM_RD_r				<=	EEPROM_RD 		when  (EEPROM_auto_scan = '0') else
								EEPROM_RD_s;
EEPROM_WR_r				<= EEPROM_WR			when	(EEPROM_auto_scan = '0') else
								'0';
EEPROM_ADDR_r			<= EEPROM_ADDR		when  (EEPROM_auto_scan = '0') else
								EEPROM_ADDR_s;
EEPROM_RD_DATA			<= EEPROM_RD_DATA_r;

	


     process( clk , rst )
       begin
         if ( rst = '1' ) then			
				DLY_CNT				<=  0;
				EEPROM_auto_scan	<= '1';					
				EEPROM_RD_s			<= '0';
				EEPROM_ADDR_s		<= (others => '0');
				EEPROM_DATA0		<= (others => '0');
				EEPROM_DATA1		<= (others => '0');
				EEPROM_DATA2		<= (others => '0');
				EEPROM_DATA3		<= (others => '0');
				EEPROM_DATA4		<= (others => '0');
				EEPROM_DATA5		<= (others => '0');
				EEPROM_DATA6		<= (others => '0');
				EEPROM_DATA7		<= (others => '0');		
				STATE 				<= s_read_DATA_0;	
         elsif rising_edge( clk ) then
	        case STATE is
            when s_idle =>
					DLY_CNT			<=  0;
					EEPROM_RD_s			<= '0';
					EEPROM_ADDR_s		<= (others => '0');
					EEPROM_auto_scan	<= '0';				
					if (LOAD_EE_DATA  = '1') then
						EEPROM_auto_scan	<= '1';						
						STATE 				<= s_read_DATA_0;	
					end if;		
					
				when	s_read_DATA_0	 =>
							EEPROM_auto_scan	<= '1';	
							DLY_CNT 			<= DLY_CNT + 1;			
							EEPROM_ADDR_s		<= x"0000";
						if(DLY_CNT = 2) then
							EEPROM_RD_s			<= '1';
						elsif	(DLY_CNT >= 10) then
							EEPROM_RD_s			<= '0';
							DLY_CNT 			<= 20;
							if(EEPROM_BUSY = '0') then
								DLY_CNT			<= 0;
								EEPROM_DATA0	<= EEPROM_RD_DATA_r;							
								STATE 			<= s_read_DATA_1; 
							end if;
						end if;				
						
							
					
				when	s_read_DATA_1	 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							EEPROM_ADDR_s		<= x"0001";
						if(DLY_CNT = 2) then
							EEPROM_RD_s			<= '1';
						elsif	(DLY_CNT >= 10) then
							EEPROM_RD_s			<= '0';
							DLY_CNT 			<= 20;
							if(EEPROM_BUSY = '0') then
								DLY_CNT			<= 0;
								EEPROM_DATA1	<= EEPROM_RD_DATA_r;							
								STATE 			<= s_read_DATA_2; 
							end if;
						end if;											
							
							
							
						
				when	s_read_DATA_2	 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							EEPROM_ADDR_s		<= x"0002";
						if(DLY_CNT = 2) then
							EEPROM_RD_s			<= '1';
						elsif	(DLY_CNT >= 10) then
							EEPROM_RD_s			<= '0';
							DLY_CNT 			<= 20;
							if(EEPROM_BUSY = '0') then
								DLY_CNT			<= 0;
								EEPROM_DATA2	<= EEPROM_RD_DATA_r;							
								STATE 			<= s_read_DATA_3; 
							end if;
						end if;											
							
							
					when	s_read_DATA_3	 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							EEPROM_ADDR_s		<= x"0003";
						if(DLY_CNT = 2) then
							EEPROM_RD_s			<= '1';
						elsif	(DLY_CNT >= 10) then
							EEPROM_RD_s			<= '0';
							DLY_CNT 			<= 20;
							if(EEPROM_BUSY = '0') then
								DLY_CNT			<= 0;
								EEPROM_DATA3	<= EEPROM_RD_DATA_r;							
								STATE 			<= s_read_DATA_4; 
							end if;
						end if;											
																			
					when	s_read_DATA_4	 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							EEPROM_ADDR_s		<= x"0004";
						if(DLY_CNT = 2) then
							EEPROM_RD_s			<= '1';
						elsif	(DLY_CNT >= 10) then
							EEPROM_RD_s			<= '0';
							DLY_CNT 			<= 20;
							if(EEPROM_BUSY = '0') then
								DLY_CNT			<= 0;
								EEPROM_DATA4	<= EEPROM_RD_DATA_r;							
								STATE 			<= s_read_DATA_5; 
							end if;
						end if;										
						when	s_read_DATA_5	 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							EEPROM_ADDR_s		<= x"0005";
						if(DLY_CNT = 2) then
							EEPROM_RD_s			<= '1';
						elsif	(DLY_CNT >= 10) then
							EEPROM_RD_s			<= '0';
							DLY_CNT 			<= 20;
							if(EEPROM_BUSY = '0') then
								DLY_CNT			<= 0;
								EEPROM_DATA5	<= EEPROM_RD_DATA_r;							
								STATE 			<= s_read_DATA_6; 
							end if;
						end if;													
						
						when	s_read_DATA_6	 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							EEPROM_ADDR_s		<= x"0006";
						if(DLY_CNT = 2) then
							EEPROM_RD_s			<= '1';
						elsif	(DLY_CNT >= 10) then
							EEPROM_RD_s			<= '0';
							DLY_CNT 			<= 20;
							if(EEPROM_BUSY = '0') then
								DLY_CNT			<= 0;
								EEPROM_DATA6	<= EEPROM_RD_DATA_r;							
								STATE 			<= s_read_DATA_7; 
							end if;
						end if;								
						
					when	s_read_DATA_7	 =>
							DLY_CNT 			<= DLY_CNT + 1;			
							EEPROM_ADDR_s		<= x"0007";
						if(DLY_CNT = 2) then
							EEPROM_RD_s			<= '1';
						elsif	(DLY_CNT >= 10) then
							EEPROM_RD_s			<= '0';
							DLY_CNT 			<= 20;
							if(EEPROM_BUSY = '0') then
								DLY_CNT			<= 0;
								EEPROM_DATA7	<= EEPROM_RD_DATA_r;							
								STATE 	<= s_done;
							end if;
						end if;														
							
				when s_done => 
					if (LOAD_EE_DATA  = '1' )then
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
