
--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: ProtoDUNE_FEMB_HSRX.VHD            
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 07/28/2016 
--////  Description:  NEEDS alot more WORK to finnish !!!!!!!!!!!!!!
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

entity ProtoDUNE_FEMB_HSRX is
	PORT
	(
			RESET						: IN STD_LOGIC;	
			SYS_CLK					: IN STD_LOGIC;
			FEMB_GXB_RX				: IN STD_LOGIC_VECTOR(15 downto 0);	 -- rx_serial_data		
			GXB_refclk_L			: IN STD_LOGIC;			
			GXB_refclk_R			: IN STD_LOGIC;				
			GXB_analogreset		: IN STD_LOGIC;
			GXB_digitalreset		: IN STD_LOGIC;
			
			
			UDP_DISABLE				: IN STD_LOGIC;					
			UDP_DATA_OUT			: OUT STD_LOGIC_VECTOR(15 downto 0);
			UDP_LATCH				: OUT STD_LOGIC;						
			UDP_fifo_full			: IN STD_LOGIC;				
			
			
			BRD_SEL					: IN STD_LOGIC_VECTOR(3 downto 0);
			CHIP_SEL					: IN STD_LOGIC_VECTOR(3 downto 0);
			

	
			UDP_BURST_MODE			: IN STD_LOGIC_VECTOR(3 downto 0);
			UDP_SAMP_TO_SAVE		: IN STD_LOGIC_VECTOR(15 downto 0);		
			UDP_BURST_EN			: IN STD_LOGIC;		 
			
			FEMB_EOF					: OUT std_logic_vector(15 downto 0);			
			RX_FF_DATA				: OUT SL_ARRAY_15_TO_0(0 to 15);
			RX_FF_EMPTY				: OUT std_logic_vector(15 downto 0);			
			RX_FF_RDREQ				: IN std_logic_vector(15 downto 0);			
			RX_FF_CLK				: IN STD_LOGIC_vector(15 downto 0);				
			RX_FF_RST				: IN STD_LOGIC_vector(15 downto 0);			
			----------add information for event builder---------
			TIME_STAMP_ev        : OUT SL_ARRAY_15_TO_0(0 to 15);
			CAPTURE_ERROR_ev     : OUT SL_ARRAY_15_TO_0(0 to 15);
			CD_ERROR_ev          : OUT SL_ARRAY_15_TO_0(0 to 15);
			probe                : out std_logic_vector(63 downto 0);
			-----------------------------------------------------

			LINK_DISABLE   		: IN STD_LOGIC_VECTOR(15 downto 0);

			DP_WFM_CLK_A			: OUT STD_LOGIC;
			DP_WFM_ADDR_A			: OUT STD_LOGIC_VECTOR(7 downto 0);
			DP_WFM_DATA_A 			: IN STD_LOGIC_VECTOR(23 downto 0);	
			
			DP_WFM_CLK_B			: OUT STD_LOGIC;
			DP_WFM_ADDR_B			: OUT STD_LOGIC_VECTOR(7 downto 0);
			DP_WFM_DATA_B 			: IN STD_LOGIC_VECTOR(23 downto 0);			
		
	
	
    		ProtoDUNE_ADC_CLK		: IN STD_LOGIC;
			TST_WFM_GEN_MODE		: IN STD_LOGIC_VECTOR(3 downto 0);	
			
			
			UDP_DATA_BRD_o			: OUT SL_ARRAY_15_TO_0(15 downto 0);	
			UDP_LATCH_L_o			: OUT std_logic_vector(15 downto 0);			
						
			
			ERR_CNT_RST				: IN STD_LOGIC; 
			LINK_SYNC_STATUS		: OUT STD_LOGIC_VECTOR(31 downto 0);						
			link_stat_sel			: IN STD_LOGIC_vector(3 downto 0);
			TS_latch					: IN STD_LOGIC; 	
			
			TIME_STAMP				: OUT STD_LOGIC_VECTOR(15 downto 0);	
			CHKSUM_ERROR			: OUT STD_LOGIC_VECTOR(15 downto 0);	
			FRAME_ERROR				: OUT STD_LOGIC_VECTOR(15 downto 0);		
			HEADER_ERROR			: OUT STD_LOGIC_VECTOR(15 downto 0);	
			ADC_ERROR				: OUT STD_LOGIC_VECTOR(15 downto 0);	--
			TS_ERROR             : OUT STD_LOGIC_VECTOR(15 downto 0)
	
	);
end ProtoDUNE_FEMB_HSRX;


architecture ProtoDUNE_FEMB_HSRX_arch of ProtoDUNE_FEMB_HSRX is




SIGNAL	HEADER_ERROR_i				: SL_ARRAY_15_TO_0(0 to 3);
SIGNAL	ADC_ERROR_i					: SL_ARRAY_15_TO_0(0 to 3);
SIGNAL	LINK_SYNC_STATUS_i		: SL_ARRAY_15_TO_0(0 to 3);
SIGNAL	TIME_STAMP_i				: SL_ARRAY_15_TO_0(0 to 3);
SIGNAL	CHKSUM_ERROR_i				: SL_ARRAY_15_TO_0(0 to 3);
SIGNAL	FRAME_ERROR_i				: SL_ARRAY_15_TO_0(0 to 3);
SIGNAL   TS_ERROR_i              : SL_ARRAY_15_TO_0(0 to 3);

SIGNAL	UDP_DATA_OUT_i				: SL_ARRAY_15_TO_0(0 to 3);
SIGNAL	UDP_LATCH_i 				: std_logic_vector(3 downto 0);  
SIGNAL	REF_CLK						: std_logic_vector(3 downto 0);  



SIGNAL	DP_WFM_CLK					: STD_LOGIC_VECTOR(3 downto 0);
SIGNAL	DP_WFM_ADDR					: SL_ARRAY_7_TO_0(3 downto 0);
SIGNAL	DP_WFM_DATA 				: SL_ARRAY_23_TO_0(3 downto 0);


begin

REF_CLK(0) <= GXB_refclk_L;
REF_CLK(1) <= GXB_refclk_R;
REF_CLK(2) <= GXB_refclk_R;
REF_CLK(3) <= GXB_refclk_R;



DP_WFM_CLK_A 	<= DP_WFM_CLK(0);
DP_WFM_CLK_B 	<= DP_WFM_CLK(1);
DP_WFM_ADDR_A	<= DP_WFM_ADDR(0);
DP_WFM_ADDR_B	<= DP_WFM_ADDR(1);
DP_WFM_DATA(0)	<= DP_WFM_DATA_A;
DP_WFM_DATA(1)	<= DP_WFM_DATA_B;
DP_WFM_DATA(2)	<= DP_WFM_DATA_A;
DP_WFM_DATA(3)	<= DP_WFM_DATA_B;




CHK_1: for i in 0 to 3  generate 
	

  ProtoDUNE_4_HSRX_inst1 :  entity work.ProtoDUNE_4_HSRX
	PORT MAP
	(
			RESET						=> RESET,
			SYS_CLK					=> SYS_CLK,
			FEMB_GXB_RX				=> FEMB_GXB_RX(i*4+3 downto i*4),
			GXB_analogreset		=> GXB_analogreset,
			GXB_digitalreset		=> GXB_digitalreset,
			GXB_refclk				=> REF_CLK(i),	
			
			UDP_DISABLE				=> UDP_DISABLE,
			UDP_DATA_OUT			=>	UDP_DATA_OUT_i(i),			
			UDP_LATCH				=> UDP_LATCH_i(i),	
			UDP_fifo_full			=> UDP_fifo_full,
			UDP_BURST_MODE			=> UDP_BURST_MODE,
			UDP_SAMP_TO_SAVE		=> UDP_SAMP_TO_SAVE,
			UDP_BURST_EN			=> UDP_BURST_EN,   -- added

			FEMB_EOF					=>	FEMB_EOF(i*4+3 downto i*4),
			RX_FF_DATA				=>	RX_FF_DATA(i*4 to i*4+3),
			RX_FF_EMPTY				=> RX_FF_EMPTY(i*4+3 downto i*4),
			RX_FF_RDREQ				=> RX_FF_RDREQ(i*4+3 downto i*4),
			RX_FF_RST				=> RX_FF_RST(i*4+3 downto i*4),
			RX_FF_CLK				=> RX_FF_CLK(i*4+3 downto i*4),
			--------------add messages-----------------------
			TIME_STAMP_ev        => TIME_STAMP_ev(i*4 to i*4+3),
			CAPTURE_ERROR_ev     => CAPTURE_ERROR_ev(i*4 to i*4+3),
			CD_ERROR_ev          => CD_ERROR_ev(i*4 to i*4+3),
			-------------------------------------------------
			probe                => probe(i*16+15 downto i*16),
			BRD_i						=>  i,	
			BRD_SEL					=> BRD_SEL,
			CHIP_SEL					=> CHIP_SEL,

			LINK_DISABLE   		=> x"00",	
			
			UDP_DATA_BRD_o			=> UDP_DATA_BRD_o(i*4+3 downto i*4),
			UDP_LATCH_L_o			=> UDP_LATCH_L_o(i*4+3 downto i*4),
			
			
			DP_WFM_CLK				=> DP_WFM_CLK(i),
			DP_WFM_ADDR				=> DP_WFM_ADDR(i),
			DP_WFM_DATA 			=> DP_WFM_DATA(i),			
			
    		ProtoDUNE_ADC_CLK		=> ProtoDUNE_ADC_CLK,
			TST_WFM_GEN_MODE		=> TST_WFM_GEN_MODE,
			
			
			ERR_CNT_RST				=> ERR_CNT_RST,			

			TS_latch					=> TS_latch,
								 
			link_stat_sel			=> link_stat_sel,			
			LINK_SYNC_STATUS		=>	LINK_SYNC_STATUS_i(i)(7 downto 0), 							 
			TIME_STAMP				=> TIME_STAMP_i(i),
			CHKSUM_ERROR			=> CHKSUM_ERROR_i(i),
			FRAME_ERROR				=>	FRAME_ERROR_i(i),
			HEADER_ERROR			=>	HEADER_ERROR_i(i),
			ADC_ERROR				=> ADC_ERROR_i(i),
			TS_ERR_CNT           => TS_ERROR_i(i)
	);
	
end generate;
		
	

		UDP_DATA_OUT			<= UDP_DATA_OUT_i(0) when (BRD_SEL = x"0") else
										UDP_DATA_OUT_i(1) when (BRD_SEL = x"1") else
										UDP_DATA_OUT_i(2) when (BRD_SEL = x"2") else
										UDP_DATA_OUT_i(3) when (BRD_SEL = x"3") else
										UDP_DATA_OUT_i(0);
		UDP_LATCH				<= UDP_LATCH_i(0)		when (BRD_SEL = x"0") else
										UDP_LATCH_i(1)		when (BRD_SEL = x"1") else
										UDP_LATCH_i(2)		when (BRD_SEL = x"2") else
										UDP_LATCH_i(3)		when (BRD_SEL = x"3") else
										UDP_LATCH_i(0);


		LINK_SYNC_STATUS	<= LINK_SYNC_STATUS_i(3)(7 downto 0) & LINK_SYNC_STATUS_i(2)(7 downto 0) & LINK_SYNC_STATUS_i(1)(7 downto 0) & LINK_SYNC_STATUS_i(0)(7 downto 0);
									
		TIME_STAMP	<= 		TIME_STAMP_i(0)  when  (link_stat_sel(3 downto 2) = b"00") else
									TIME_STAMP_i(1)  when  (link_stat_sel(3 downto 2) = b"01") else
									TIME_STAMP_i(2)  when  (link_stat_sel(3 downto 2) = b"10") else
									TIME_STAMP_i(3)  when  (link_stat_sel(3 downto 2) = b"11") else
									TIME_STAMP_i(0);									
		
		CHKSUM_ERROR	<= 	CHKSUM_ERROR_i(0)  when  (link_stat_sel(3 downto 2) = b"00") else
									CHKSUM_ERROR_i(1)  when  (link_stat_sel(3 downto 2) = b"01") else
									CHKSUM_ERROR_i(2)  when  (link_stat_sel(3 downto 2) = b"10") else
									CHKSUM_ERROR_i(3)  when  (link_stat_sel(3 downto 2) = b"11") else
									CHKSUM_ERROR_i(0);		
									
									
		FRAME_ERROR	<= 		FRAME_ERROR_i(0)  when  (link_stat_sel(3 downto 2) = b"00") else
									FRAME_ERROR_i(1)  when  (link_stat_sel(3 downto 2) = b"01") else
									FRAME_ERROR_i(2)  when  (link_stat_sel(3 downto 2) = b"10") else
									FRAME_ERROR_i(3)  when  (link_stat_sel(3 downto 2) = b"11") else
									FRAME_ERROR_i(0);	
									
		HEADER_ERROR	<= 	HEADER_ERROR_i(0)  when  (link_stat_sel(3 downto 2) = b"00") else
									HEADER_ERROR_i(1)  when  (link_stat_sel(3 downto 2) = b"01") else
									HEADER_ERROR_i(2)  when  (link_stat_sel(3 downto 2) = b"10") else
									HEADER_ERROR_i(3)  when  (link_stat_sel(3 downto 2) = b"11") else
									HEADER_ERROR_i(0);	
									
		ADC_ERROR	<= 		ADC_ERROR_i(0)  when  (link_stat_sel(3 downto 2) = b"00") else
									ADC_ERROR_i(1)  when  (link_stat_sel(3 downto 2) = b"01") else
									ADC_ERROR_i(2)  when  (link_stat_sel(3 downto 2) = b"10") else
									ADC_ERROR_i(3)  when  (link_stat_sel(3 downto 2) = b"11") else
									ADC_ERROR_i(0);										
									
		TS_ERROR		<= 		TS_ERROR_i(0)  when  (link_stat_sel(3 downto 2) = b"00") else
									TS_ERROR_i(1)  when  (link_stat_sel(3 downto 2) = b"01") else
									TS_ERROR_i(2)  when  (link_stat_sel(3 downto 2) = b"10") else
									TS_ERROR_i(3)  when  (link_stat_sel(3 downto 2) = b"11") else
									TS_ERROR_i(0);								

end ProtoDUNE_FEMB_HSRX_arch;
