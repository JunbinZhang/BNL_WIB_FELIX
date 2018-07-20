
--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: WIB_LED_STATUS.VHD           
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 08/08/2017
--////  Description:  WIB_LED_STATUS
--////					
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2016 Brookhaven National Laboratory
--////
--/////////////////////////////////////////////////////////////////////



library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;



--  Entity Declaration

entity WIB_LED_STATUS is
	port
	(
		SYS_CLK				: in  std_logic;
		RESET					: in  std_logic;
		FEMB_LINK_STATUS	: in  std_logic_vector(31 downto 0);                     -- Input CLK from MAC Reciever
		FEMB_BRD				: in  std_logic_vector(3 downto 0);  
		FEMB_RDBK_strb		: in  std_logic;
		LED_OUT				: out std_logic_vector(3 downto 0)
		
		);
end WIB_LED_STATUS;


--  Architecture Body

architecture WIB_LED_STATUS_arch OF WIB_LED_STATUS is

SIGNAL	FEMB_STRB_IN  	: std_logic_vector(3 downto 0);
SIGNAL	FEMB_STRB_OUT 	: std_logic_vector(3 downto 0);

BEGIN


	LED_OUT(0) <= FEMB_STRB_OUT(0) when (FEMB_LINK_STATUS(7  downto 0)  = x"ff") else '1';
	LED_OUT(1) <= FEMB_STRB_OUT(1) when (FEMB_LINK_STATUS(15 downto 8)  = x"ff") else '1';
	LED_OUT(2) <= FEMB_STRB_OUT(2) when (FEMB_LINK_STATUS(23 downto 16) = x"ff") else '1';
	LED_OUT(3) <= FEMB_STRB_OUT(3) when (FEMB_LINK_STATUS(31 downto 24) = x"ff") else '1';
		  
	 
	FEMB_STRB_IN(0)	<= FEMB_RDBK_strb when  (FEMB_BRD = x"0") else '0';
	FEMB_STRB_IN(1)	<= FEMB_RDBK_strb when  (FEMB_BRD = x"1") else '0';
	FEMB_STRB_IN(2)	<= FEMB_RDBK_strb when  (FEMB_BRD = x"2") else '0';
	FEMB_STRB_IN(3)	<= FEMB_RDBK_strb when  (FEMB_BRD = x"3") else '0';
	

	
 stretch_inst0 : entity work.stretch
 port MAP
 (
		clk 		=> SYS_CLK,				--100MHz
      reset 	=> RESET,
      sig_in 	=> FEMB_STRB_IN(0),
      len    	=> x"02faf080",  		---  1.5 Sec
      sig_out 	=> FEMB_STRB_OUT(0)
 );
          
 stretch_inst1 : entity work.stretch
 port MAP
 (
		clk 		=> SYS_CLK,				--100MHz
      reset 	=> RESET,
      sig_in 	=> FEMB_STRB_IN(1),
      len    	=> x"02faf080", 		---  1.5 Sec
      sig_out 	=> FEMB_STRB_OUT(1)
 );
        	 
 stretch_inst2 : entity work.stretch
 port MAP
 (
		clk 		=> SYS_CLK,				--100MHz
      reset 	=> RESET,
      sig_in 	=> FEMB_STRB_IN(2),
      len    	=> x"02faf080",   		---  1.5 Sec
      sig_out 	=> FEMB_STRB_OUT(2)
 );
        	 
	 stretch_inst3 : entity work.stretch
 port MAP
 (
		clk 		=> SYS_CLK,				--100MHz
      reset 	=> RESET,
      sig_in 	=> FEMB_STRB_IN(3),
      len    	=> x"02faf080",   		---  1.5 Sec
      sig_out 	=> FEMB_STRB_OUT(3)
 );
         
		  
END WIB_LED_STATUS_arch;
