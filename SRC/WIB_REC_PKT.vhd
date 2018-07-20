
--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: WIB_REC_PKT.VHD            
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 09/14/2016 
--////  Description:   NEEDS SOME more WORK  !!!!!!!!!!!!!!
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


entity WIB_REC_PKT is
			generic ( 
							Frame_size  		: integer := 29;
							TIME_OUT		  		: integer := 28  -- use system clock  
						);	
	PORT
	(
		RESET		     	: IN STD_LOGIC;				-- reset		
		CLK			  	: IN STD_LOGIC;				-- GXB RECV CLOCK
		SYS_CLK			: IN STD_LOGIC;				-- SYSTEM CLOCK    link disable and watchdog err counting
		CHIP				: IN STD_LOGIC_VECTOR(3 downto 0);	
		BRD				: IN STD_LOGIC_VECTOR(3 downto 0);	
		LINK_DISABLE   : IN STD_LOGIC;
		DP_WFM_DATA 	: IN STD_LOGIC_VECTOR(23 downto 0);	
    	SBND_ADC_CLK	: IN STD_LOGIC;
		START_WFM		: IN STD_LOGIC;
		TST_WFM_GEN_MODE	: IN STD_LOGIC_VECTOR(3 downto 0);	
		DATA_IN			: IN STD_LOGIC_VECTOR(15 downto 0);		
		PKT_SOF		   : IN STD_LOGIC;
		DATA_VALID	   : IN STD_LOGIC;		

		ERR_CNT_RST		: IN STD_LOGIC;	
		CHKSUM_ERROR	: OUT STD_LOGIC_VECTOR(15 downto 0);	--for event builder capture error	
		FRAME_ERROR		: OUT STD_LOGIC_VECTOR(15 downto 0);
		HEADER_ERROR	: OUT STD_LOGIC_VECTOR(15 downto 0);
		ADC_ERROR		: OUT STD_LOGIC_VECTOR(15 downto 0);   --for event builder cd error
		TIME_STAMP		: OUT STD_LOGIC_VECTOR(15 downto 0);   --for event builder MM
		
		FEMB_EOF			: OUT STD_LOGIC;		
		RX_FF_DATA		: OUT STD_LOGIC_VECTOR(15 downto 0);
		RX_FF_EMPTY		: buffer STD_LOGIC;--change out to buffer 0621
		RX_FF_RDREQ		: IN STD_LOGIC;
		RX_FF_CLK		: IN STD_LOGIC;	
		RX_FF_RST		: IN STD_LOGIC;
		----------add message---------------
		TIME_STAMP_ev  : OUT STD_LOGIC_VECTOR(15 downto 0);
		CAPTURE_ERROR_ev : OUT STD_LOGIC_VECTOR(15 downto 0);
		CD_ERROR_ev    :  OUT STD_LOGIC_VECTOR(15 downto 0);
		probe          : out std_logic_vector(3 downto 0);
		
		UDP_DISABLE		: IN STD_LOGIC;
		UDP_SAMP_TO_SAVE:IN STD_LOGIC_VECTOR(15 downto 0);		
		UDP_BURST_MODE	: IN STD_LOGIC_VECTOR(3 downto 0);	
		BURST_LACH		: IN STD_LOGIC;				 


	
		CHIP_SEL			: IN STD_LOGIC_VECTOR(3 downto 0);
		UDP_LATCH		: OUT STD_LOGIC;
		UDP_DATA			: OUT STD_LOGIC_VECTOR(15 downto 0)

	);
end WIB_REC_PKT;


architecture WIB_REC_PKT_arch of WIB_REC_PKT is
	----------------------------------------------
	--components----------------------------------
	----------------------------------------------
	component PULSESYNC is
		port(
		clk_src : in std_logic;
		reset_n : in std_logic;
		pulse_src : in std_logic;
		clk_dst : in std_logic;
		pulse_dst : out std_logic
		);
	end component PULSESYNC;
	--------------------------------------

	TYPE 	 	state_type is (S_IDLE, S_START_Of_FRAME,S_START_Of_WFM_GEN_1,S_START_Of_WFM_GEN_2);

	SIGNAL 	state				: state_type;

	SIGNAL 	WORD_CNT			: integer range 63 downto 0;			
	SIGNAL	GEN_CNT			: integer range 31 downto 0;			
	SIGNAL	CHN_CNT			: STD_LOGIC_VECTOR(3 downto 0);	
	SIGNAL	CHECKSUM			: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	CHECKSUM_i		: STD_LOGIC_VECTOR(23 downto 0);	
	SIGNAL	CHKSUM_ERROR_i	: STD_LOGIC;
	SIGNAL	FRAME_ERROR_i	: STD_LOGIC;	

	SIGNAL	CS_ERROR_CNT	: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	FRM_ERROR_CNT	: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	PKT_LATCH_i		: STD_LOGIC;	
	SIGNAL	FRM_E_S1			: STD_LOGIC;	
	SIGNAL	FRM_E_S2			: STD_LOGIC;	
	SIGNAL	CSUM_S1			: STD_LOGIC;	
	SIGNAL	CSUM_S2			: STD_LOGIC;	


	SIGNAL 	UDP_DATA_VALID	: STD_LOGIC;
	SIGNAL 	UDP_DATA_I		: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	FF_UDP_empty	: STD_LOGIC;		
	SIGNAL	UDP_FF_aclr		: STD_LOGIC;	
	
	SIGNAL	CHP_STRM_SEL	: STD_LOGIC;
	SIGNAL	CHP_STRM_SEL_S	: STD_LOGIC;		
	
	SIGNAL	CHECKSUM_IN		: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	TIME_STAMP_IN	: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	ADC_ERROR_IN	: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	RESERVED_IN		: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	HEADER_IN		: STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL	UDP_DISABLE_s	: STD_LOGIC;		

	
	
	signal TIME_STAMP_ev_sync  : STD_LOGIC_VECTOR(15 downto 0);
	signal CAPTURE_ERROR_ev_sync : STD_LOGIC_VECTOR(15 downto 0);
	signal CD_ERROR_ev_sync    : STD_LOGIC_VECTOR(15 downto 0);
	
	
	SIGNAL	HEADER_ERROR_i : STD_LOGIC;			
	SIGNAL	HDR_E_S1			: STD_LOGIC;		
	SIGNAL	HDR_E_S2			: STD_LOGIC;		
	SIGNAL	HDR_ERROR_CNT	: STD_LOGIC_VECTOR(15 downto 0);	


	SIGNAL	FEMB_DATA_VALID : STD_LOGIC;	
	SIGNAL	FEMB_DATA		 : STD_LOGIC_VECTOR(15 downto 0);	
	SIGNAL   WFM_GEN_DATA	 : SL_ARRAY_15_TO_0(0 to 3);
	SIGNAL	CHN_LOC_DATA	 : SL_ARRAY_15_TO_0(0 to 3);
	SIGNAL	CHIP_S			 : STD_LOGIC_VECTOR(3 downto 0);				
	SIGNAL	UDP_BURST_MODE_L: STD_LOGIC_VECTOR(3 downto 0);	



	SIGNAL	UDP_FF_rdused	: STD_LOGIC_VECTOR(15 downto 0);	
	SIGNAL	FF_RDREQ			: STD_LOGIC;	
	SIGNAL	RX_FF_RST_LAT	: STD_LOGIC;	
	SIGNAL	RX_FF_RST_LAT1	: STD_LOGIC;		
	
	signal   RECV_FIFO_full : STD_LOGIC;
	--signal   RX_FF_EMPTY_LAT : std_logic;
	
begin
		
		
	
 process(RX_FF_CLK) 
 begin
		if (RX_FF_CLK'event AND RX_FF_CLK = '1') then
				FEMB_EOF	<= PKT_LATCH_i;
				--RX_FF_EMPTY_LAT <= RX_FF_EMPTY;
		end if;
end process;

 process(RX_FF_CLK)
 begin
		if (RX_FF_CLK'event AND RX_FF_CLK = '1') then
			TIME_STAMP_ev_sync <= TIME_STAMP_IN;
			CAPTURE_ERROR_ev_sync <= (CHECKSUM_i(23 downto 16) + CHECKSUM_i(15 downto 0));
			CD_ERROR_ev_sync <= ADC_ERROR_IN;
			
			TIME_STAMP_ev <= TIME_STAMP_ev_sync;
			CAPTURE_ERROR_ev <= CAPTURE_ERROR_ev_sync;
			CD_ERROR_ev <= CD_ERROR_ev_sync;
		end if;
 end process;
 
--------------------------------?-----------------------RX_FF_RST from fast clock domain, it can't latch
-- process(CLK) 
-- begin
--		if (CLK'event AND CLK = '1') then
--			RX_FF_RST_LAT1	<= RX_FF_RST;
--			RX_FF_RST_LAT	<= RX_FF_RST_LAT1;
--		end if;
--end process;
 FIFO_RST_INST : 	PULSESYNC
  PORT MAP
  (
		clk_src => RX_FF_CLK,
		reset_n => '1',
		pulse_src => RX_FF_RST,
		clk_dst => CLK,
		pulse_dst => RX_FF_RST_LAT	
  );
  
-- FEMB_EOF_INST : 	PULSESYNC
--  PORT MAP
--  (
--		clk_src => CLK,
--		reset_n => '1',
--		pulse_src => PKT_LATCH_i,
--		
--		clk_dst => RX_FF_CLK,
--		pulse_dst => FEMB_EOF	
--  );

 process(CLK) 
 begin
		if (CLK'event AND CLK = '1') then
			if( TST_WFM_GEN_MODE = x"0") then
				FEMB_DATA <= DATA_IN;
			elsif ( TST_WFM_GEN_MODE = x"1") then
				FEMB_DATA <= WFM_GEN_DATA(GEN_CNT);
			else
				FEMB_DATA <= CHN_LOC_DATA(GEN_CNT);
			end if;
		end if;
end process;


CHP_STRM_SEL	<= 	'0'	 WHEN  (CHIP_SEL = X"0") ELSE
							'1'	 WHEN  (CHIP_SEL = X"1") ELSE
							'0'	 WHEN  (CHIP_SEL = X"2") ELSE
							'1'	 WHEN  (CHIP_SEL = X"3") ELSE
							'0'	 WHEN  (CHIP_SEL = X"4") ELSE
							'1'	 WHEN  (CHIP_SEL = X"5") ELSE
							'0'	 WHEN  (CHIP_SEL = X"6") ELSE
							'1'	 WHEN  (CHIP_SEL = X"7") ELSE
							'0';
	
WFM_GEN_DATA(0)	<= DP_WFM_DATA(15 downto 0);
WFM_GEN_DATA(1)	<= DP_WFM_DATA(7 downto 0) &  DP_WFM_DATA(23 downto 16);
WFM_GEN_DATA(2)	<= DP_WFM_DATA(23 downto 8);


--
--CHN_LOC_DATA(0)	<= (CHN_CNT+1) & BRD         & CHIP        & CHN;
--CHN_LOC_DATA(1)	<= CHIP        & (CHN_CNT+2) & BRD         & CHIP;
--CHN_LOC_DATA(2)	<= BRD         & CHIP        & (CHN_CNT+3) & BRD;
-- 

  process(CLK,RESET) 
  begin
	 if ((RESET = '1') or (LINK_DISABLE = '1') or (RX_FF_RST_LAT = '1')) then
		CHKSUM_ERROR_i		<= '0';
		FRAME_ERROR_i		<= '0';
		HEADER_ERROR_i	 	<= '0';				
		WORD_CNT				<= 0;
		PKT_LATCH_i			<= '0';
		FEMB_DATA_VALID	<= '0';
		UDP_DATA_VALID		<= '0';
		CHECKSUM_i			<=	(others => '0');
		state 				<= S_idle;
		CHP_STRM_SEL_S 	<= '0';
		GEN_CNT				<= 0;
		CHN_CNT				<= x"0";
		UDP_BURST_MODE_L	<= x"0";
		elsif (CLK'event AND CLK = '1') then

			CASE state IS
			when S_IDLE =>
				CHECKSUM_i			<=	(others => '0');	
				PKT_LATCH_i			<= '0';
				WORD_CNT				<= 0;		
				FRAME_ERROR_i		<= '0';
				FEMB_DATA_VALID	<= '0';
				UDP_DATA_VALID		<= '0';
				CHIP_S				<= CHIP;
				UDP_BURST_MODE_L	<= UDP_BURST_MODE;
				if (CHECKSUM  /=  CHECKSUM_IN) then
						CHKSUM_ERROR_i	 <= '1'; 
				end if;	
				if(UDP_BURST_MODE_L = x"2" or UDP_BURST_MODE_L = x"3") then
					state 	<= S_IDLE;
				elsif (PKT_SOF  = '1') and ( TST_WFM_GEN_MODE = x"0") then
					PKT_LATCH_i				<= '1';		-- latch previous data packet
					FRAME_ERROR_i			<= '0';		
					CHP_STRM_SEL_S 		<= CHP_STRM_SEL;
					UDP_DISABLE_s			<= UDP_DISABLE;		
					state 					<= S_START_Of_FRAME;							
				elsif ( TST_WFM_GEN_MODE = x"1") and (START_WFM = '1') then
					PKT_LATCH_i				<= '1';		-- latch previous data packet	
					CHP_STRM_SEL_S 		<= CHP_STRM_SEL;
					UDP_DISABLE_s			<= UDP_DISABLE;	
					state 					<= S_START_Of_WFM_GEN_1;			
				elsif ( TST_WFM_GEN_MODE = x"2") and (START_WFM = '1') then
					PKT_LATCH_i				<= '1';		-- latch previous data packet	
					CHP_STRM_SEL_S 		<= CHP_STRM_SEL;
					UDP_DISABLE_s			<= UDP_DISABLE;	
					state 					<= S_START_Of_WFM_GEN_2;			
				end if;	
	
		   when S_START_Of_FRAME =>
					PKT_LATCH_i			<= '0';
					FRAME_ERROR_i	 	<= '0';
					CHKSUM_ERROR_i	 	<= '0'; 	
					HEADER_ERROR_i	 	<= '0';					
					FEMB_DATA_VALID	<= '0'; --bug here.
					UDP_DATA_VALID		 <= '0';			
					if((DATA_VALID = '1') and ( WORD_CNT <= (Frame_size-1))) then
						WORD_CNT 			<= WORD_CNT + 1;	
						UDP_DATA_VALID		<= '0';	
						if(WORD_CNT /= 0) then
							CHECKSUM_i	<= CHECKSUM_i + DATA_IN;	
						end if;						
						case WORD_CNT IS
							when 0 =>
								FEMB_DATA_VALID <= '1'; 
								CHECKSUM_IN		<= DATA_IN;
							when 1 =>
								FEMB_DATA_VALID <= '1'; --added here 0621
								TIME_STAMP_IN	<=	DATA_IN;
							when 2 =>
								FEMB_DATA_VALID <= '1'; --added here
								ADC_ERROR_IN	<= DATA_IN;
							when 3 =>
								FEMB_DATA_VALID <= '0'; --added here don't dump reserved word into fifo 0622
								RESERVED_IN		<= DATA_IN;
							when 4 =>
								FEMB_DATA_VALID <= '1'; --added here
								HEADER_IN		<= DATA_IN;
								if(UDP_DISABLE_s = '0')  then
									UDP_DATA_VALID	<= '1';
								end if;
								if(RESERVED_IN(0) = '0') then
									UDP_DATA_I		<= x"FACE";
								else
									UDP_DATA_I		<= x"FEED";
								end if;
							when others =>	
								UDP_DATA_I				<= DATA_IN;
								FEMB_DATA_VALID		<= '1'; --added here
								if(UDP_DISABLE_s = '1') then	
									UDP_DATA_VALID		 	<= '0';
								elsif(UDP_BURST_MODE_L = x"1") then
									UDP_DATA_VALID		 	<= '1';					
								elsif(CHP_STRM_SEL_S = '0' and WORD_CNT  < 17) then
									UDP_DATA_VALID		 	<= '1';
								elsif(CHP_STRM_SEL_S = '1' and WORD_CNT  >= 17) then
									UDP_DATA_VALID		 	<= '1';
								end if;
						end case; 
					else
						ADC_ERROR	<= ADC_ERROR_IN; --cd error.
						TIME_STAMP	<= TIME_STAMP_IN;--used for event builder MMbit
						CHECKSUM		<= (CHECKSUM_i(23 downto 16) + CHECKSUM_i(15 downto 0));	--capture error= checksum error?
		
						if ((HEADER_IN and x"7777") /= x"2222") then   -- remove MSB from header
							HEADER_ERROR_i	 <= '1';
						end if;
						if (WORD_CNT /= Frame_size) then
							FRAME_ERROR_i	 <= '1';
						end if;			
						state 	<= S_IDLE;
					end if;
		   when S_START_Of_WFM_GEN_1 =>									
					FEMB_DATA_VALID	<= '0';
					UDP_DATA_VALID		<= '0';			
					if WORD_CNT <= (Frame_size-1)then
						WORD_CNT <= WORD_CNT + 1;	
						UDP_DATA_VALID		<= '0';	
						case WORD_CNT IS
							when 0 to 3 => 
								GEN_CNT	<= 0;
							when 4 =>
								if(UDP_DISABLE_s = '0') then
									UDP_DATA_VALID	<= '1';
								end if;
								UDP_DATA_I		<= x"FACE";
							when others =>	
								GEN_CNT	<= GEN_CNT + 1;
								if(GEN_CNT >= 2) then
									GEN_CNT <= 0;
								end if;
								UDP_DATA_I			<= WFM_GEN_DATA(GEN_CNT);
								FEMB_DATA_VALID	<= '1';
								if(UDP_DISABLE_s = '1') then
									UDP_DATA_VALID		 	<= '0';
								elsif(CHP_STRM_SEL_S = '0' and WORD_CNT  < 17) then
									UDP_DATA_VALID		 	<= '1';
								elsif(CHP_STRM_SEL_S = '1' and WORD_CNT  >= 17) then
									UDP_DATA_VALID		 	<= '1';
								end if;
						end case; 
					else
						ADC_ERROR	<= x"0000";
						TIME_STAMP	<= x"0000";
						CHECKSUM		<= x"0000";			
						state 	<= S_IDLE;
					end if;	
			
		   when S_START_Of_WFM_GEN_2 =>									
					FEMB_DATA_VALID	<= '0';
					UDP_DATA_VALID		<= '0';			
					if WORD_CNT <= (Frame_size-1)then
						WORD_CNT <= WORD_CNT + 1;	
						UDP_DATA_VALID		<= '0';	
						case WORD_CNT IS
							when 0 to 3 => 
								GEN_CNT	<= 0;
								CHIP_S	<= CHIP;
								CHN_CNT	<= x"0";
							when 4 =>
								if(UDP_DISABLE_s = '0') then
									UDP_DATA_VALID	<= '1';
								end if;
								UDP_DATA_I		<= x"FACE";
								CHN_LOC_DATA(0)	<= x"6" 		& BRD    & CHIP_S & X"7";
								CHN_LOC_DATA(1)	<= CHIP_S   & x"5" 	& BRD    & CHIP_S;
								CHN_LOC_DATA(2)	<= BRD      & CHIP_S & x"4" 	& BRD; 
								CHN_CNT	<= CHN_CNT + 4;
							when others =>	
								GEN_CNT	<= GEN_CNT + 1;
								if(GEN_CNT >= 2) then
									CHN_CNT	<= CHN_CNT + 4;
									if(CHN_CNT >= 12) then
										CHN_CNT <= x"0";
										CHIP_S <= CHIP_S + 1;
									end if;								
									GEN_CNT <= 0;
									if(CHN_CNT = 0) then
										CHN_LOC_DATA(0)	<= x"6" 		& BRD    & CHIP_S & X"7";
										CHN_LOC_DATA(1)	<= CHIP_S   & x"5" 	& BRD    & CHIP_S;
										CHN_LOC_DATA(2)	<= BRD      & CHIP_S & x"4" 	& BRD; 								
									elsif(CHN_CNT = 4) then
										CHN_LOC_DATA(0)	<= x"2" 		& BRD    & CHIP_S  & x"3";
										CHN_LOC_DATA(1)	<= CHIP_S   & x"1" 	& BRD     & CHIP_S;
										CHN_LOC_DATA(2)	<= BRD      & CHIP_S & x"0" 	 & BRD; 	
									elsif(CHN_CNT = 8) then
										CHN_LOC_DATA(0)	<= x"e" 		& BRD    & CHIP_S  & x"f";
										CHN_LOC_DATA(1)	<= CHIP_S   & x"d" 	& BRD     & CHIP_S;
										CHN_LOC_DATA(2)	<= BRD      & CHIP_S & x"c" 	 & BRD; 		
									elsif(CHN_CNT = 12) then
										CHN_LOC_DATA(0)	<= x"a" 		& BRD    & CHIP_S  & x"b";
										CHN_LOC_DATA(1)	<= CHIP_S   & x"9" 	& BRD     & CHIP_S;
										CHN_LOC_DATA(2)	<= BRD      & CHIP_S & x"8" 	 & BRD; 											
									end if;
								end if;		
								UDP_DATA_I			<= CHN_LOC_DATA(GEN_CNT);
								FEMB_DATA_VALID	<= '1';
								if(UDP_DISABLE_s = '1') then
									UDP_DATA_VALID		 	<= '0';
								elsif(CHP_STRM_SEL_S = '0' and WORD_CNT  < 17) then
									UDP_DATA_VALID		 	<= '1';
								elsif(CHP_STRM_SEL_S = '1' and WORD_CNT  >= 17) then
									UDP_DATA_VALID		 	<= '1';
								end if;
						end case; 
					else
						ADC_ERROR	<= x"0000";
						TIME_STAMP	<= x"0000";
						CHECKSUM		<= x"0000";			
						state 	<= S_IDLE;
					end if;	

			when others =>		
				state 	<= S_IDLE;	
			end case; 
	 end if;
end process;



RX_FEMB_UDP_FF_INST : entity work.RX_FEMB_UDP_FF
	PORT MAP
	(
		aclr		=> UDP_FF_aclr,
		data		=> UDP_DATA_I,		
		wrclk		=> CLK,
		wrreq		=> UDP_DATA_VALID,		
		rdclk		=> SYS_CLK,
		rdreq		=> FF_RDREQ, --NOT FF_UDP_empty,
		q			=> UDP_DATA,
		rdempty	=> FF_UDP_empty,
		rdusedw	=> UDP_FF_rdused(14 downto 0),
		rdfull	=> open
	);
		

		UDP_FF_rdused(15) <= '0';
	
		
		
		FF_RDREQ		<= not FF_UDP_empty when (  UDP_BURST_MODE = x"0") else
							'0'	when ( UDP_FF_rdused < (UDP_SAMP_TO_SAVE)  and UDP_BURST_MODE = x"1") else
							'1'	when ( UDP_FF_rdused >= (UDP_SAMP_TO_SAVE) and UDP_BURST_MODE = x"1") else
							 BURST_LACH when (UDP_BURST_MODE = x"2") else
							 not FF_UDP_empty;
process(SYS_CLK) 
 begin
		if (SYS_CLK'event AND SYS_CLK = '1') then		
			UDP_FF_aclr	<= '0';
			if (  UDP_BURST_MODE = x"0") then	
				UDP_LATCH	<= not FF_UDP_empty;	
			elsif(UDP_BURST_MODE = x"1") then	-- load UDP FIFO 	
				UDP_LATCH	<=	'0';
			elsif(UDP_BURST_MODE = x"2") then	
				UDP_LATCH	<=	BURST_LACH and (not FF_UDP_empty);			
			elsif(UDP_BURST_MODE = x"3")  then
				UDP_FF_aclr	<= '1';
				UDP_LATCH	<=	'0';
			else
				UDP_LATCH	<= not FF_UDP_empty;		
			end if;
		end if;
end process;	

-------------add probe here-----------
probe(0) <= FEMB_DATA_VALID;
probe(1) <= RECV_FIFO_full;
probe(2) <= RX_FF_RDREQ;
--probe(3) <= RX_FF_RST_LAT;
probe(3) <= RX_FF_EMPTY;


--
--where is the full signal?
	RECV_FIFO_inst: entity work.RECV_FIFO
	PORT MAP
	(
		aclr		=> RX_FF_RST_LAT, --modified 0620 
		data		=> FEMB_DATA,
		rdclk		=> RX_FF_CLK,
		rdreq		=> RX_FF_RDREQ,
		wrclk		=> CLK,
		wrreq		=> FEMB_DATA_VALID and (not RECV_FIFO_full), --modified 0621
		wrfull   => RECV_FIFO_full,--modified 0620
		--wrreq		=> FEMB_DATA_VALID, --modified 0620
		--wrfull   => open,--modified 0620
		q			=> RX_FF_DATA,
		rdempty	=> RX_FF_EMPTY
	);


  process(SYS_CLK) 
  begin
	if (SYS_CLK'event AND SYS_CLK = '1') then
			FRM_E_S1	<= FRAME_ERROR_i;
			FRM_E_S2	<= FRM_E_S1;
			CSUM_S1	<= CHKSUM_ERROR_i;
			CSUM_S2	<= CSUM_S1;
			HDR_E_S1	<= HEADER_ERROR_i;
			HDR_E_S2	<= HDR_E_S1;		
		end if;
end process;

	
  process(SYS_CLK,RESET,ERR_CNT_RST) 
  begin
	 if ((RESET = '1') or (ERR_CNT_RST = '1')) then
		HDR_ERROR_CNT		<= x"0000";
		CS_ERROR_CNT		<= x"0000";
		FRM_ERROR_CNT		<= x"0000";
     elsif (SYS_CLK'event AND SYS_CLK = '1') then
			if(FRM_E_S1 = '1' and FRM_E_S2 = '0') then
				FRM_ERROR_CNT	<= FRM_ERROR_CNT + 1;
			end if;
			if(CSUM_S1 = '1' and CSUM_S2 = '0') then
				CS_ERROR_CNT		<= CS_ERROR_CNT	 + 1;
			end if;
			if(HDR_E_S1 = '1' and HDR_E_S2 = '0') then
				HDR_ERROR_CNT		<= HDR_ERROR_CNT	 + 1;
			end if;			
						
			CHKSUM_ERROR	<= CS_ERROR_CNT;
			FRAME_ERROR		<= FRM_ERROR_CNT;
			HEADER_ERROR	<= HDR_ERROR_CNT;
		end if;
end process;



end WIB_REC_PKT_arch;
