
--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: SBND_TX_PACK.VHD            
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 09/21/2016 
--////  Description:  		NEEDS ALOT OF WORK!!!!!!!!!!!!!!
--////					
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2016 Brookhaven National Laboratory
--////
--/////////////////////////////////////////////////////////////////////


library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
USE work.SbndPkg.all;

entity SBND_TX_PACK_V2 is
	PORT
	(
	
			RESET						: IN STD_LOGIC;	
			SYS_CLK					: IN STD_LOGIC;
			Stream_EN 				: IN STD_LOGIC;
			LINK_DISABLE			: IN  std_logic_vector(15 downto 0);
--			Stream_SEL				: IN  range 15 downto 0;	
			tx_serial_data       : out std_logic_vector(7 downto 0);                       -- tx_serial_data
			tx_pll_refclk        : in  std_logic; -- tx_pll_refclk
			pll_locked           : out std_logic_vector(7 downto 0);
			tx_analogreset_EN    : in  std_logic;
			tx_digitalreset_EN   : in  std_logic;
			pll_powerdown_EN		: in  std_logic;
			
			
			FEMB_EOF					: IN std_logic_vector(15 downto 0);			
			RX_FF_DATA				: IN SL_ARRAY_15_TO_0(0 to 15);
			RX_FF_EMPTY				: IN std_logic_vector(15 downto 0);			
			RX_FF_RDREQ				: OUT std_logic_vector(15 downto 0);
			RX_FF_RST				: OUT std_logic_vector(15 downto 0);
			RX_FF_CLK				: OUT STD_LOGIC_vector(15 downto 0)					
					
	);
end SBND_TX_PACK_V2;



architecture SBND_TX_PACK_V2_arch of SBND_TX_PACK_V2 is


	component GXB_TX is
		port (
			pll_powerdown           : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- pll_powerdown
			tx_analogreset          : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- tx_analogreset
			tx_digitalreset         : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- tx_digitalreset
			tx_pll_refclk           : in  std_logic; -- tx_pll_refclk
			tx_serial_data          : out std_logic_vector(7 downto 0);                       -- tx_serial_data
			pll_locked              : out std_logic_vector(7 downto 0);                       -- pll_locked
			tx_std_coreclkin        : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- tx_std_coreclkin
			tx_std_clkout           : out std_logic_vector(7 downto 0);                       -- tx_std_clkout
			tx_cal_busy             : out std_logic_vector(7 downto 0);                       -- tx_cal_busy
			reconfig_to_xcvr        : in  std_logic_vector(1119 downto 0) := (others => 'X'); -- reconfig_to_xcvr
			reconfig_from_xcvr      : out std_logic_vector(735 downto 0);                     -- reconfig_from_xcvr
			tx_parallel_data        : in  std_logic_vector(127 downto 0)  := (others => 'X'); -- tx_parallel_data
			tx_datak                : in  std_logic_vector(15 downto 0)   := (others => 'X'); -- tx_datak
			unused_tx_parallel_data : in  std_logic_vector(207 downto 0)  := (others => 'X')  -- unused_tx_parallel_data
		);
	end component GXB_TX;


	TYPE 	 	state_type is (S_IDLE,S_wait_for_all_eof , S_START_Of_FRAME);
	SIGNAL 	state				: state_type;	
	
	
SIGNAL	tx_std_clkout					: std_logic_vector(7 downto 0);
SIGNAL	tx_parallel_data				: std_logic_vector(127 downto 0);
SIGNAL	tx_ctrlenable					: std_logic_vector(15 downto 0);
SIGNAL	TX_DATA							: SL_ARRAY_15_TO_0(0 to 7);
SIGNAL	tx_datak							: std_logic_vector(15 downto 0);
SIGNAL	FEMB_FIFO_CLK					: std_logic_vector(15 downto 0);
SIGNAL	tx_clk							: std_logic;




SIGNAL	TX_STREAM 						: SL_ARRAY_3_TO_0(0 to 7);
SIGNAL	TX_STREAM_L						: SL_ARRAY_3_TO_0(0 to 7);
SIGNAL	WORD_CNT							: integer range 127 downto 0;	
SIGNAL	FF_empty							: std_logic_vector(15 downto 0);
SIGNAL	FIFO_RST							: std_logic_vector(15 downto 0);

SIGNAL	pll_powerdown					: std_logic_vector(7 downto 0); -- pll_powerdown
SIGNAL	tx_analogreset 				: std_logic_vector(7 downto 0); -- tx_analogreset
SIGNAL	tx_digitalreset 				: std_logic_vector(7 downto 0); -- tx_digitalreset		

SIGNAL	TX_FIFO_Q						: SL_ARRAY_15_TO_0(0 to 15);
SIGNAL	comma								: std_logic_vector(15 downto 0);
SIGNAL	CLR_RDY							: std_logic;
SIGNAL	DLY_CNT							: std_logic_vector(7 downto 0);
SIGNAL	CHN_CNT							: std_logic_vector(15 downto 0);
begin
	
	
	pll_powerdown			<=	x"ff" when (pll_powerdown_EN   = '1') else x"00";
	tx_analogreset			<=	x"ff" when (tx_analogreset_EN  = '1') else x"00";
	tx_digitalreset		<=	x"ff" when (tx_digitalreset_EN = '1') else x"00";
 

GXB_TX_inst1 : GXB_TX
		port MAP (
		
			tx_serial_data         	=> tx_serial_data,
			tx_pll_refclk          	=> tx_pll_refclk ,
			pll_powerdown          	=> pll_powerdown,				--: in  std_logic_vector(3 downto 0)   := (others => 'X'); -- pll_powerdown
			tx_analogreset         	=> tx_analogreset, 			-- : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- tx_analogreset
			tx_digitalreset        	=> tx_digitalreset, 			--: in  std_logic_vector(3 downto 0)   := (others => 'X'); -- tx_digitalreset
			pll_locked             	=> pll_locked ,							--: out std_logic_vector(3 downto 0);                      -- pll_locked
			tx_std_coreclkin       	=> tx_std_clkout,				--: in  std_logic_vector(3 downto 0)   := (others => 'X'); -- tx_std_coreclkin
			tx_std_clkout          	=> tx_std_clkout,  			--: out std_logic_vector(3 downto 0);                      -- tx_std_clkout
			tx_cal_busy            	=> open,							--: out std_logic_vector(3 downto 0);                      -- tx_cal_busy
			reconfig_to_xcvr       	=> (others => 'X'),			--: in  std_logic_vector(559 downto 0) := (others => 'X'); -- reconfig_to_xcvr
			reconfig_from_xcvr     	=> open,							--: out std_logic_vector(367 downto 0);                    -- reconfig_from_xcvr
			tx_parallel_data       	=> tx_parallel_data(127 downto 0),			--: in  std_logic_vector(63 downto 0)  := (others => 'X'); -- tx_parallel_data
			tx_datak               	=> tx_ctrlenable , 					--: in  std_logic_vector(7 downto 0)   := (others => 'X'); -- tx_datak
			unused_tx_parallel_data =>(others => 'X')  			-- unused_tx_parallel_data
		);
		
	

	  tx_parallel_data	<= TX_DATA(7)	& TX_DATA(6)	& TX_DATA(5)	& TX_DATA(4)	& TX_DATA(3)	& TX_DATA(2)	& TX_DATA(1)	& TX_DATA(0);
	

	
SBND_PACK: for i in 0 to 7  generate 	

  SBND_FEMB_PACK_inst1 :  entity work.SBND_FEMB_PACK
	PORT MAP
	(
			RESET						=> RESET,
			CLK						=> tx_std_clkout(i),
--			tx_clk					=> tx_std_clkout(i),
			Stream_EN 				=> Stream_EN,
			LINK_DISABLE			=> LINK_DISABLE(i*2+1 downto i*2),
			FEMB_EOF					=> FEMB_EOF(i*2+1 downto i*2),			
			RX_FF_DATA				=> RX_FF_DATA(i*2 to i*2+1),
			RX_FF_EMPTY				=> RX_FF_EMPTY(i*2+1 downto i*2),		
			RX_FF_RDREQ				=> RX_FF_RDREQ(i*2+1 downto i*2),
			RX_FF_CLK				=>	RX_FF_CLK(i*2+1 downto i*2),				
			RX_FF_RST				=> RX_FF_RST(i*2 + 1 downto i*2),
			tx_ctrlenable			=> tx_ctrlenable(i*2+1 downto i*2),
			TX_DATA			 		=> TX_DATA(i)
	);

end generate;		
	

end SBND_TX_PACK_V2_arch;































