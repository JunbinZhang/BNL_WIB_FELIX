
--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: SBND_HSRX.VHD            
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

entity SBND_HSRX is
	PORT
	(
	
			RESET						: IN STD_LOGIC;	
			SYS_CLK					: IN STD_LOGIC;
			FEMB_GXB_RX				: IN STD_LOGIC_VECTOR(7 downto 0);	 -- rx_serial_data		
			GXB_analogreset		: IN STD_LOGIC;
			GXB_digitalreset		: IN STD_LOGIC;
			GXB_refclk				: IN STD_LOGIC;			
			BRD_i						: IN integer range 3 downto 0;		
			BRD_ID					: IN STD_LOGIC;
			BRD_SEL					: IN STD_LOGIC_VECTOR(3 downto 0);
			CHIP_SEL					: IN STD_LOGIC_VECTOR(3 downto 0);
			
			UDP_fifo_full			: IN STD_LOGIC;			
			UDP_DISABLE				: IN STD_LOGIC;			
			UDP_BURST_MODE			: IN STD_LOGIC_VECTOR(3 downto 0);
			UDP_SAMP_TO_SAVE		: IN STD_LOGIC_VECTOR(15 downto 0);		
			UDP_BURST_EN			: IN STD_LOGIC;		 
			
			UDP_DATA_OUT			: OUT STD_LOGIC_VECTOR(15 downto 0);
			UDP_LATCH				: OUT STD_LOGIC;			
			LINK_DISABLE   		: IN STD_LOGIC_VECTOR(7 downto 0);

			DP_WFM_CLK				: OUT STD_LOGIC;
			DP_WFM_ADDR				: OUT STD_LOGIC_VECTOR(7 downto 0);
			DP_WFM_DATA 			: IN STD_LOGIC_VECTOR(23 downto 0);	
    		SBND_ADC_CLK			: IN STD_LOGIC;
			TST_WFM_GEN_MODE		: IN STD_LOGIC_VECTOR(3 downto 0);	
			
			
			FEMB_EOF					: OUT std_logic_vector(7 downto 0);			
			RX_FF_DATA				: OUT SL_ARRAY_15_TO_0(0 to 7);
			RX_FF_EMPTY				: OUT std_logic_vector(7 downto 0);			
			RX_FF_RDREQ				: IN std_logic_vector(7 downto 0);			
			RX_FF_CLK				: IN STD_LOGIC;				
			RX_FF_RST				: IN STD_LOGIC_vector(7 downto 0);								
			
			
			ERR_CNT_RST				: IN STD_LOGIC; 
			LINK_SYNC_STATUS		: OUT STD_LOGIC_VECTOR(15 downto 0);						
			link_stat_sel			: IN STD_LOGIC_vector(3 downto 0);
			TS_latch					: IN STD_LOGIC; 	
			
			TIME_STAMP				: OUT STD_LOGIC_VECTOR(15 downto 0);	
			CHKSUM_ERROR			: OUT STD_LOGIC_VECTOR(15 downto 0);	
			FRAME_ERROR				: OUT STD_LOGIC_VECTOR(15 downto 0);		
			HEADER_ERROR			: OUT STD_LOGIC_VECTOR(15 downto 0);	
			ADC_ERROR				: OUT STD_LOGIC_VECTOR(15 downto 0)	

	
	
	);
end SBND_HSRX;


architecture SBND_HSRX_arch of SBND_HSRX is



	component GXB_RX is
		port (
			rx_analogreset          : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rx_analogreset
			rx_digitalreset         : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rx_digitalreset
			rx_cdr_refclk           : in  std_logic; -- rx_cdr_refclk
			rx_serial_data          : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rx_serial_data
			rx_std_coreclkin        : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rx_std_coreclkin
			rx_set_locktodata       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rx_set_locktodata
			rx_set_locktoref        : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rx_set_locktoref			
			rx_std_clkout           : out std_logic_vector(7 downto 0);                      -- rx_std_clkout
			rx_cal_busy             : out std_logic_vector(7 downto 0);                      -- rx_cal_busy
			reconfig_to_xcvr        : in  std_logic_vector(559 downto 0) := (others => 'X'); -- reconfig_to_xcvr
			reconfig_from_xcvr      : out std_logic_vector(367 downto 0);                    -- reconfig_from_xcvr
			rx_parallel_data        : out std_logic_vector(127 downto 0);                    -- rx_parallel_data
			rx_datak                : out std_logic_vector(15 downto 0);                     -- rx_datak
			rx_errdetect            : out std_logic_vector(15 downto 0);                     -- rx_errdetect
			rx_disperr              : out std_logic_vector(15 downto 0);                     -- rx_disperr
			rx_runningdisp          : out std_logic_vector(15 downto 0);                     -- rx_runningdisp
			rx_patterndetect        : out std_logic_vector(15 downto 0);                     -- rx_patterndetect
			rx_syncstatus           : out std_logic_vector(15 downto 0);                     -- rx_syncstatus
			unused_rx_parallel_data : out std_logic_vector(287 downto 0)                     -- unused_rx_parallel_data
		);
	end component GXB_RX;


	
type SL_ARRAY_7_to_0 is ARRAY(7 downto 0) of std_logic_vector(3 downto 0);
type SL_ARRAY_15_Dto_0 is ARRAY(15 downto 0) of std_logic_vector(3 downto 0);
constant	CHIP		:  SL_ARRAY_7_to_0 := (x"6",x"4",x"2",x"0",x"6",x"4",x"2",x"0");
constant	BRD		:  SL_ARRAY_15_Dto_0 := (x"3",x"3",x"3",x"3",x"2",x"2",x"2",x"2",x"1",x"1",x"1",x"1",x"0",x"0",x"0",x"0");

SIGNAL	rx_std_clkout           :  std_logic_vector(7 downto 0) ;   --;    
SIGNAL	rx_parallel_data        :  std_logic_vector(128 downto 0);                     -- rx_parallel_data
SIGNAL	rx_analogreset          :  std_logic_vector(7 downto 0);
SIGNAL	rx_digitalreset         :  std_logic_vector(7 downto 0);
	
SIGNAL	rx_set_locktoref        : std_logic_vector(7 downto 0);
SIGNAL	rx_datak						:  std_logic_vector(15 downto 0);		
SIGNAL	rx_errdetect				:  std_logic_vector(15 downto 0);
SIGNAL	rx_disperr					:  std_logic_vector(15 downto 0);
SIGNAL	rx_runningdisp				:  std_logic_vector(15 downto 0);
SIGNAL	rx_patterndetect			:  std_logic_vector(15 downto 0);
SIGNAL	rx_syncstatus				:  std_logic_vector(15 downto 0); 	
	
SIGNAL	DATA_PKT_I 					:  SL_2D_Array_15_to_0( 0 to 7);
SIGNAL	UDP_DATA_BRD				:  SL_ARRAY_15_TO_0(0 to 7);	
SIGNAL	DT_VALID						:  std_logic_vector(7 downto 0);
SIGNAL	DT_KCODE						:  std_logic_vector(7 downto 0);
SIGNAL	PKT_SOF						:  std_logic_vector(7 downto 0);	
SIGNAL	UDP_DATA_L					:  std_logic_vector(15 downto 0);

SIGNAL	TIME_STAMP_I				: SL_ARRAY_15_TO_0(0 to 7);
SIGNAL	TIME_STAMP_L				: SL_ARRAY_15_TO_0(0 to 7);
SIGNAL	CHKSUM_ERROR_I				: SL_ARRAY_15_TO_0(0 to 7);
SIGNAL	FRAME_ERROR_I				: SL_ARRAY_15_TO_0(0 to 7);	
SIGNAL	HEADER_ERROR_I				: SL_ARRAY_15_TO_0(0 to 7);
SIGNAL	ADC_ERROR_I					: SL_ARRAY_15_TO_0(0 to 7);

SIGNAL	SBND_ADC_CLK_0				: std_logic;
SIGNAL	SBND_ADC_CLK_1 			: std_logic;		
SIGNAL	WFM_ADDR						:  std_logic_vector(7 downto 0);
SIGNAL	START_WFM					: std_logic;

SIGNAL	UDP_LATCH_L					: std_logic_vector(7 downto 0);
SIGNAL	UDP_LATCH_s					: std_logic;
SIGNAL	BURST_LACH					: STD_LOGIC_VECTOR(7 downto 0);		
begin
		rx_set_locktoref	 <= x"00" when  (TST_WFM_GEN_MODE = x"0") else x"FF";
		rx_analogreset     <= x"00" when  GXB_analogreset = '0' else x"FF";
		rx_digitalreset    <= x"00" when  GXB_digitalreset= '0' else x"FF";
		LINK_SYNC_STATUS	 <= rx_syncstatus;
		DP_WFM_CLK			<= rx_std_clkout(0);
		
	GXB_RX_INST1 : GXB_RX
		port map (
		
			rx_serial_data     => FEMB_GXB_RX(7 downto 0),							
			rx_analogreset     => rx_analogreset(7 downto 0),		
			rx_digitalreset    => rx_digitalreset(7 downto 0),   	
			rx_cdr_refclk      => GXB_refclk,		    						
			rx_std_coreclkin   => rx_std_clkout(7 downto 0),		
			rx_std_clkout      => rx_std_clkout(7 downto 0),	
			rx_set_locktodata	 => x"00",
			rx_set_locktoref	 => rx_set_locktoref,
			rx_cal_busy        => open,						
			reconfig_to_xcvr   => (others => 'X'),		
			reconfig_from_xcvr => OPEN,				
			rx_parallel_data   => rx_parallel_data(127 downto 0),		
			rx_datak           => rx_datak(15 downto 0), 				
			rx_errdetect       => rx_errdetect(15 downto 0), 				
			rx_disperr         => rx_disperr(15 downto 0), 						
			rx_runningdisp     => rx_runningdisp(15 downto 0), 					
			rx_patterndetect   => rx_patterndetect(15 downto 0), 					
			rx_syncstatus      => rx_syncstatus(15 downto 0), 			
			unused_rx_parallel_data 	=> OPEN  			
		);


	
	
CHK_1: for i in 0 to 7  generate 	

	DT_VALID(i)		<= ((not rx_errdetect(i*2)) and (not rx_errdetect(i*2 + 1)) and rx_syncstatus(i*2) and rx_syncstatus(i*2 +1 ));
	DT_KCODE(i) 	<= ((rx_datak(i*2)) and (rx_datak(i*2+1)) and DT_VALID(i));
	PKT_SOF(i) 		<= '1'  when ((DT_KCODE(i) = '1') and (rx_parallel_data((i*16+15) downto (i*16)) = x"3C3C") ) ELSE '0';

	
	
	WIB_REC_PKT_inst : entity work.WIB_REC_PKT
	PORT MAP
	(
		RESET		     	=> RESET,
		CLK		    	=> rx_std_clkout(i),
		SYS_CLK			=> SYS_CLK,
		LINK_DISABLE   => LINK_DISABLE(i),
		CHIP				=> CHIP(i),
		BRD				=> BRD(i + 8 * BRD_i),
		DP_WFM_DATA 	=> DP_WFM_DATA,
    	SBND_ADC_CLK	=> SBND_ADC_CLK,
		TST_WFM_GEN_MODE	=> TST_WFM_GEN_MODE,
		START_WFM		=> START_WFM,
		
		
		DATA_IN			=> rx_parallel_data((i*16+15) downto (i*16)),
		PKT_SOF		   => PKT_SOF(i),
		DATA_VALID	   =>	(DT_VALID(i) and (not PKT_SOF(i))),
		
		
		ERR_CNT_RST		=> ERR_CNT_RST,	
		CHKSUM_ERROR	=> CHKSUM_ERROR_I(i),
		FRAME_ERROR		=> FRAME_ERROR_I(i),
		HEADER_ERROR	=> HEADER_ERROR_I(i),
		ADC_ERROR		=> ADC_ERROR_I(i),
		TIME_STAMP		=> TIME_STAMP_I(i),
		
		
		RX_FF_DATA		=> RX_FF_DATA(i),
		RX_FF_EMPTY		=> RX_FF_EMPTY(i),
		RX_FF_RDREQ		=> RX_FF_RDREQ(i),
		RX_FF_CLK		=> RX_FF_CLK,
		RX_FF_RST		=> RX_FF_RST(i),
		
		FEMB_EOF			=> FEMB_EOF(i),
		UDP_DISABLE		=> UDP_DISABLE,
		UDP_BURST_MODE	=> UDP_BURST_MODE,	
		UDP_SAMP_TO_SAVE	=> UDP_SAMP_TO_SAVE,
		BURST_LACH		=> BURST_LACH(i),
		
		
		
		CHIP_SEL			=> CHIP_SEL,
		UDP_DATA			=> UDP_DATA_BRD(i),
		UDP_LATCH		=> UDP_LATCH_L(i)					
	);

end generate;
	
						
				 BURST_LACH(0)  <= '1' when (UDP_BURST_EN = '1') and (UDP_fifo_full = '0') and (BRD_SEL(1) = BRD_ID) and (BRD_SEL(0) = '0') and ((CHIP_SEL = x"0") or (CHIP_SEL = x"1")) else '0';
				 BURST_LACH(1)  <= '1' when (UDP_BURST_EN = '1') and (UDP_fifo_full = '0') and (BRD_SEL(1) = BRD_ID) and (BRD_SEL(0) = '0') and ((CHIP_SEL = x"2") or (CHIP_SEL = x"3")) else '0';
				 BURST_LACH(2)  <= '1' when (UDP_BURST_EN = '1') and (UDP_fifo_full = '0') and (BRD_SEL(1) = BRD_ID) and (BRD_SEL(0) = '0') and ((CHIP_SEL = x"4") or (CHIP_SEL = x"5")) else '0';
				 BURST_LACH(3)  <= '1' when (UDP_BURST_EN = '1') and (UDP_fifo_full = '0') and (BRD_SEL(1) = BRD_ID) and (BRD_SEL(0) = '0') and ((CHIP_SEL = x"6") or (CHIP_SEL = x"7")) else '0';
				 BURST_LACH(4)  <= '1' when (UDP_BURST_EN = '1') and (UDP_fifo_full = '0') and (BRD_SEL(1) = BRD_ID) and (BRD_SEL(0) = '1') and ((CHIP_SEL = x"0") or (CHIP_SEL = x"1")) else '0';
				 BURST_LACH(5)  <= '1' when (UDP_BURST_EN = '1') and (UDP_fifo_full = '0') and (BRD_SEL(1) = BRD_ID) and (BRD_SEL(0) = '1') and ((CHIP_SEL = x"2") or (CHIP_SEL = x"3")) else '0';
				 BURST_LACH(6)  <= '1' when (UDP_BURST_EN = '1') and (UDP_fifo_full = '0') and (BRD_SEL(1) = BRD_ID) and (BRD_SEL(0) = '1') and ((CHIP_SEL = x"4") or (CHIP_SEL = x"5")) else '0';
				 BURST_LACH(7)  <= '1' when (UDP_BURST_EN = '1') and (UDP_fifo_full = '0') and (BRD_SEL(1) = BRD_ID) and (BRD_SEL(0) = '1') and ((CHIP_SEL = x"6") or (CHIP_SEL = x"7")) else '0';

	
			UDP_DATA_L	<=	UDP_DATA_BRD(0) when (BRD_SEL(0) = '0') and ((CHIP_SEL = x"0") or (CHIP_SEL = x"1"))else
								UDP_DATA_BRD(1) when (BRD_SEL(0) = '0') and ((CHIP_SEL = x"2") or (CHIP_SEL = x"3")) else
								UDP_DATA_BRD(2) when (BRD_SEL(0) = '0') and ((CHIP_SEL = x"4") or (CHIP_SEL = x"5"))else
								UDP_DATA_BRD(3) when (BRD_SEL(0) = '0') and ((CHIP_SEL = x"6") or (CHIP_SEL = x"7")) else	
								UDP_DATA_BRD(4) when (BRD_SEL(0) = '1')  and ((CHIP_SEL = x"0") or (CHIP_SEL = x"1"))else
								UDP_DATA_BRD(5) when (BRD_SEL(0) = '1')  and ((CHIP_SEL = x"2") or (CHIP_SEL = x"3"))else
								UDP_DATA_BRD(6) when (BRD_SEL(0) = '1')  and ((CHIP_SEL = x"4") or (CHIP_SEL = x"5"))else
								UDP_DATA_BRD(7) when (BRD_SEL(0) = '1')  and ((CHIP_SEL = x"6") or (CHIP_SEL = x"7"))else
								x"0000";

			UDP_LATCH_s	<=	UDP_LATCH_L(0) when (BRD_SEL(0) = '0') and ((CHIP_SEL = x"0") or (CHIP_SEL = x"1"))else
								UDP_LATCH_L(1) when (BRD_SEL(0) = '0') and ((CHIP_SEL = x"2") or (CHIP_SEL = x"3")) else
								UDP_LATCH_L(2) when (BRD_SEL(0) = '0') and ((CHIP_SEL = x"4") or (CHIP_SEL = x"5"))else
								UDP_LATCH_L(3) when (BRD_SEL(0) = '0') and ((CHIP_SEL = x"6") or (CHIP_SEL = x"7")) else	
								UDP_LATCH_L(4) when (BRD_SEL(0) = '1')  and ((CHIP_SEL = x"0") or (CHIP_SEL = x"1"))else
								UDP_LATCH_L(5) when (BRD_SEL(0) = '1')  and ((CHIP_SEL = x"2") or (CHIP_SEL = x"3"))else
								UDP_LATCH_L(6) when (BRD_SEL(0) = '1')  and ((CHIP_SEL = x"4") or (CHIP_SEL = x"5"))else
								UDP_LATCH_L(7) when (BRD_SEL(0) = '1')  and ((CHIP_SEL = x"6") or (CHIP_SEL = x"7"))else
								'0';
								
					
  process(SYS_CLK,RESET) 
  begin
		if (SYS_CLK'event AND SYS_CLK = '1') then
			UDP_DATA_OUT		<= UDP_DATA_L;
			UDP_LATCH		 	<= UDP_LATCH_s;
			if(TS_latch = '1') then
				TIME_STAMP_L	<= TIME_STAMP_I;
			end if;
	  end if;
end process;



			
	
			TIME_STAMP			<= TIME_STAMP_L(0) WHEN (link_stat_sel = X"0") ELSE
										TIME_STAMP_L(1) WHEN (link_stat_sel = X"1") ELSE
										TIME_STAMP_L(2) WHEN (link_stat_sel = X"2") ELSE
										TIME_STAMP_l(3) WHEN (link_stat_sel = X"3") ELSE
										TIME_STAMP_L(4) WHEN (link_stat_sel = X"4") ELSE
										TIME_STAMP_L(5) WHEN (link_stat_sel = X"5") ELSE
										TIME_STAMP_L(6) WHEN (link_stat_sel = X"6") ELSE
										TIME_STAMP_L(7) WHEN (link_stat_sel = X"7") ELSE
										X"FFFF";
			
			CHKSUM_ERROR		<= CHKSUM_ERROR_I(0) WHEN (link_stat_sel = X"0") ELSE
										CHKSUM_ERROR_I(1) WHEN (link_stat_sel = X"1") ELSE
										CHKSUM_ERROR_I(2) WHEN (link_stat_sel = X"2") ELSE
										CHKSUM_ERROR_I(3) WHEN (link_stat_sel = X"3") ELSE
										CHKSUM_ERROR_I(4) WHEN (link_stat_sel = X"4") ELSE
										CHKSUM_ERROR_I(5) WHEN (link_stat_sel = X"5") ELSE
										CHKSUM_ERROR_I(6) WHEN (link_stat_sel = X"6") ELSE
										CHKSUM_ERROR_I(7) WHEN (link_stat_sel = X"7") ELSE
										X"FFFF";
			
			FRAME_ERROR			<=	FRAME_ERROR_I(0) WHEN (link_stat_sel = X"0") ELSE
										FRAME_ERROR_I(1) WHEN (link_stat_sel = X"1") ELSE
										FRAME_ERROR_I(2) WHEN (link_stat_sel = X"2") ELSE
										FRAME_ERROR_I(3) WHEN (link_stat_sel = X"3") ELSE
										FRAME_ERROR_I(4) WHEN (link_stat_sel = X"4") ELSE
										FRAME_ERROR_I(5) WHEN (link_stat_sel = X"5") ELSE
										FRAME_ERROR_I(6) WHEN (link_stat_sel = X"6") ELSE
										FRAME_ERROR_I(7) WHEN (link_stat_sel = X"7") ELSE
										X"FFFF";
			
			HEADER_ERROR		<= HEADER_ERROR_I(0) WHEN (link_stat_sel = X"0") ELSE
										HEADER_ERROR_I(1) WHEN (link_stat_sel = X"1") ELSE
										HEADER_ERROR_I(2) WHEN (link_stat_sel = X"2") ELSE
										HEADER_ERROR_I(3) WHEN (link_stat_sel = X"3") ELSE
										HEADER_ERROR_I(4) WHEN (link_stat_sel = X"4") ELSE
										HEADER_ERROR_I(5) WHEN (link_stat_sel = X"5") ELSE
										HEADER_ERROR_I(6) WHEN (link_stat_sel = X"6") ELSE
										HEADER_ERROR_I(7) WHEN (link_stat_sel = X"7") ELSE
										X"FFFF";
										
			ADC_ERROR			<= ADC_ERROR_I(0) WHEN (link_stat_sel = X"0") ELSE
										ADC_ERROR_I(1) WHEN (link_stat_sel = X"1") ELSE
										ADC_ERROR_I(2) WHEN (link_stat_sel = X"2") ELSE
										ADC_ERROR_I(3) WHEN (link_stat_sel = X"3") ELSE
										ADC_ERROR_I(4) WHEN (link_stat_sel = X"4") ELSE
										ADC_ERROR_I(5) WHEN (link_stat_sel = X"5") ELSE
										ADC_ERROR_I(6) WHEN (link_stat_sel = X"6") ELSE
										ADC_ERROR_I(7) WHEN (link_stat_sel = X"7") ELSE
										X"FFFF";
	

	
		
process(rx_std_clkout(0)) 
  begin
	if (rx_std_clkout(0)'event AND rx_std_clkout(0) = '1') then
		SBND_ADC_CLK_0	<= SBND_ADC_CLK;
		SBND_ADC_CLK_1 <= SBND_ADC_CLK_0;
		DP_WFM_ADDR	<= WFM_ADDR;
		START_WFM 	<= '0';
		if(SBND_ADC_CLK_1 = '0' and SBND_ADC_CLK_0 = '1') then
			WFM_ADDR	<= WFM_ADDR + 1;
			START_WFM	<= '1';
		end if;
	end if;
end process;	 
	 

	

end SBND_HSRX_arch;
