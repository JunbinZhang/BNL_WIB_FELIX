
--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: ProtoDUNE_TST_PULSE_GEN.VHD            
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 01/12/2018 
--////  Description:  		
--////					
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2018 Brookhaven National Laboratory
--////
--/////////////////////////////////////////////////////////////////////


library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity ProtoDUNE_TST_PULSE_GEN is
	PORT
	(
	
			RESET					: IN STD_LOGIC;	
			CLK_100MHz			: IN STD_LOGIC;
			src_SELECT			: IN STD_LOGIC_vector(3 downto 0);  
			Period				: IN STD_LOGIC_vector(31 downto 0);
			SW_Pulse_cntl		: IN STD_LOGIC;
			External_Pulse		: IN STD_LOGIC;
			Pulse_out			: OUT STD_LOGIC;
			Pulse_out_lemo		: OUT STD_LOGIC
					
	);
end ProtoDUNE_TST_PULSE_GEN;



architecture ProtoDUNE_TST_PULSE_GEN_arch of ProtoDUNE_TST_PULSE_GEN is


	SIGNAL	counter			: std_logic_vector(31 downto 0);
	SIGNAL	pulse 			: std_logic;
	
begin
	

Pulse_out_lemo	<=	'0' when (src_SELECT = x"0") else
						pulse;	
						
Pulse_out		<= '0'   				when (src_SELECT = x"0") else
						pulse					when (src_SELECT = x"1") else
						External_Pulse		when (src_SELECT = x"2") else
						SW_Pulse_cntl		when (src_SELECT = x"3") else
						'0';
						
process(CLK_100MHz,RESET) 
  begin		
 
		if(RESET = '1') then
			counter	<= x"00000000";
			pulse		<= '0';
		elsif (CLK_100MHz'event AND CLK_100MHz	 = '1') then
			counter <= counter + 1;
			if( counter >= Period) then
				counter <= x"00000000";
				pulse		<= not pulse;
			end if;
			
		end if;
end process;	

	
end ProtoDUNE_TST_PULSE_GEN_arch;


