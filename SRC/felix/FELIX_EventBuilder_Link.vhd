library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;--added by junbin
USE work.SbndPkg.all;

entity FELIX_EventBuilder_Link is
	PORT
	(
			RESET						: IN STD_LOGIC;	
			clk_tx				   : IN STD_LOGIC; --clock from FELIX pcs 120M
			Stream_EN 				: IN STD_LOGIC;
			
			LINK_DISABLE			: IN  std_logic_vector(7 downto 0); --one link collects data from 8 tx links from FEMBs
			
			FEMB_EOF					: IN std_logic_vector(7 downto 0);	-- sync to RX_FF_CLK		
			RX_FF_DATA				: IN SL_ARRAY_15_TO_0(0 to 7);
			RX_FF_EMPTY				: IN std_logic_vector(7 downto 0);			
			RX_FF_RDREQ				: OUT std_logic_vector(7 downto 0);
			RX_FF_RST				: OUT std_logic_vector(7 downto 0);
			RX_FF_CLK				: OUT std_logic_vector(7 downto 0); --240MHz
			
			TIME_STAMP_ev        : IN SL_ARRAY_15_TO_0(0 to 7);      -- sync to RX_FF_CLK
			CAPTURE_ERROR_ev     : IN SL_ARRAY_15_TO_0(0 to 7);      -- sync to RX_FF_CLK
			CD_ERROR_ev          : IN SL_ARRAY_15_TO_0(0 to 7);      -- sync to RX_FF_CLK
			
			slot_No              : in std_logic_vector(2 downto 0);
			crate_No             : in std_logic_vector(4 downto 0);
			fiber_No             : in std_logic_vector(2 downto 0);
			version_No           : in std_logic_vector(4 downto 0);
			--------------probe signals----------------- 
			probe                : out std_logic_vector(7 downto 0);
			--------------FELIX_PCS interface----------------------
			data_out   : out std_logic_vector(63 downto  0);
			data_k_out : out std_logic_vector(7 downto  0)   
	);
end FELIX_EventBuilder_Link;


architecture FELIX_EventBuilder_Link_arch of FELIX_EventBuilder_Link is
	-----------------------------------------------------------------------
	--components
	-----------------------------------------------------------------------
	component felix_240M is
		port(
		refclk : in std_logic;
		rst    : in std_logic;
		outclk_0 : out std_logic
		);
	end component felix_240M;
	
  component FMchannelTXctrl_WIB is
    port (
          clk120 : in std_logic;
          clk240 : in std_logic;
          rst    : in std_logic;
          fifo_data : in std_logic_vector(31 downto 0);
          fifo_dtype: in std_logic_vector(1 downto 0);
          fifo_empty: in std_logic;
          busy      : in std_logic;
          fifo_rclk : out std_logic;
          fifo_re   : out std_logic;
          data      : out std_logic_vector(63 downto 0);
          k_data    : out std_logic_vector(7 downto 0)   
         );
  end component FMchannelTXctrl_WIB;  
  
  component wib_event_fifo is
    port (
      aclr    : IN  STD_LOGIC;
      data    : IN  STD_LOGIC_VECTOR (35 DOWNTO 0);
      wrclk   : IN  STD_LOGIC;
      wrreq   : IN  STD_LOGIC;
      wrfull  : OUT STD_LOGIC;

      rdclk   : IN  STD_LOGIC;
      rdreq   : IN  STD_LOGIC;
      rdempty : OUT STD_LOGIC;
      q       : OUT STD_LOGIC_VECTOR (35 DOWNTO 0)
      );
  end component wib_event_fifo;	

  
	------------------------------------------------------------------------
	--signals
	------------------------------------------------------------------------
	signal   clk        : std_logic; --240M
	
	
	TYPE 	 	state_type is (S_IDLE,S_wait_for_recovery, S_wait_for_all_eof , S_START_Of_FRAME);
	--TYPE     state_type_cnt is (S_START,S_SOP,S_DATA,S_EOP,S_IDLE);
	--signal   state : state_type_cnt;
	SIGNAL 	state				: state_type;	
	
	SIGNAL	TX_STREAM 						: std_logic_vector(4 downto 0);
	SIGNAL	TX_STREAM_L						: std_logic_vector(4 downto 0);
	SIGNAL	WORD_CNT						: integer range 127 downto 0;	
	SIGNAL	FEMB_EOF_s1						: std_logic_vector(7 downto 0); --remapped
	SIGNAL	FEMB_EOF_s2						: std_logic_vector(7 downto 0); --remapped
	SIGNAL	FEMB_DAT_RDY					: std_logic_vector(7 downto 0); --remapped
	SIGNAL	FEMB_DAT_RDY_LATCH				: std_logic_vector(7 downto 0); --remapped
	SIGNAL	CLR_DAT_RDY						: std_logic_vector(7 downto 0); --remapped
	SIGNAL	FIFO_RST						: std_logic_vector(7 downto 0); --remapped
	SIGNAL	CLR_RDY							: std_logic;
	SIGNAL	DLY_CNT						: integer range 127 downto 0;	

	signal   FIFO_RDREQ                 : std_logic_vector(7 downto 0);
	--signal   RX_FF_RDREQ_LATCH          : std_logic_vector(7 downto 0);

	SIGNAL   FIFO_DATA                  	: std_logic_vector(31 downto 0); --new added

	SIGNAL   FIFO_DTYPE                 	: std_logic_vector(1 downto 0);  --new added

	SIGNAL   FIFO_WR                    	: std_logic;

	signal chksumbufA: std_logic_vector(7 downto 0); --new added 0709
	signal chksumbufB: std_logic_vector(7 downto 0); --new added 0709
	  -----------fifo interface--------
   signal fifo_full : std_logic := '0';
   signal fifo_data_out : std_logic_vector(35 downto 0):=(others => '0');
   signal data_in : std_logic_vector(35 downto 0):=(others => '0');
   signal fifo_rclk  :std_logic;  --modified by junbin
   signal fifo_re    :std_logic;  --modified by junbin
   signal fifo_data_FM  :std_logic_vector(31 downto 0); --modified by junbin
   signal fifo_dtype_FM :std_logic_vector(1 downto 0);  --modified by junbin
   signal fifo_empty :std_logic; --modified by junbin
   signal fifo_busy  :std_logic :='0'; --modified by junbin
	
	
begin
-----------probe signals---------------
--probe <= FEMB_DAT_RDY_LATCH;
probe <= FIFO_RDREQ;
-------------pll insertion--generate 240MHz clock-----
felix_clk : felix_240M
	port map(
		refclk => clk_tx,
		rst    => '0',
		outclk_0 => clk
	);
-----------re mapping signals-------------
RX_FF_CLK(0)<= clk;
RX_FF_CLK(1)<= clk;
RX_FF_CLK(2)<= clk;
RX_FF_CLK(3)<= clk;
RX_FF_CLK(4)<= clk;
RX_FF_CLK(5)<= clk;
RX_FF_CLK(6)<= clk;
RX_FF_CLK(7)<= clk;

RX_FF_RST	<=	FIFO_RST; --change here


-----------------------------------
--FIFO_RDREQ(0) <= '1' when ((FEMB_DAT_RDY_LATCH(0) = '1') and (RX_FF_EMPTY(0) = '0')) else '0';
--FIFO_RDREQ(1) <= FEMB_DAT_RDY_LATCH(1) and (not RX_FF_EMPTY(1));
--FIFO_RDREQ(2) <= FEMB_DAT_RDY_LATCH(2) and (not RX_FF_EMPTY(2));
--FIFO_RDREQ(3) <= FEMB_DAT_RDY_LATCH(3) and (not RX_FF_EMPTY(3));
--FIFO_RDREQ(4) <= FEMB_DAT_RDY_LATCH(4) and (not RX_FF_EMPTY(4));
--FIFO_RDREQ(5) <= FEMB_DAT_RDY_LATCH(5) and (not RX_FF_EMPTY(5));
--FIFO_RDREQ(6) <= FEMB_DAT_RDY_LATCH(6) and (not RX_FF_EMPTY(6));
--FIFO_RDREQ(7) <= FEMB_DAT_RDY_LATCH(7) and (not RX_FF_EMPTY(7));
FIFO_RDREQ(0) <= '1' when ((FEMB_DAT_RDY_LATCH(0) = '1') and (RX_FF_EMPTY(0) = '0')) else '0';
FIFO_RDREQ(1) <= '1' when ((FEMB_DAT_RDY_LATCH(1) = '1') and (RX_FF_EMPTY(1) = '0')) else '0';
FIFO_RDREQ(2) <= '1' when ((FEMB_DAT_RDY_LATCH(2) = '1') and (RX_FF_EMPTY(2) = '0')) else '0';
FIFO_RDREQ(3) <= '1' when ((FEMB_DAT_RDY_LATCH(3) = '1') and (RX_FF_EMPTY(3) = '0')) else '0';
FIFO_RDREQ(4) <= '1' when ((FEMB_DAT_RDY_LATCH(4) = '1') and (RX_FF_EMPTY(4) = '0')) else '0';
FIFO_RDREQ(5) <= '1' when ((FEMB_DAT_RDY_LATCH(5) = '1') and (RX_FF_EMPTY(5) = '0')) else '0';
FIFO_RDREQ(6) <= '1' when ((FEMB_DAT_RDY_LATCH(6) = '1') and (RX_FF_EMPTY(6) = '0')) else '0';
FIFO_RDREQ(7) <= '1' when ((FEMB_DAT_RDY_LATCH(7) = '1') and (RX_FF_EMPTY(7) = '0')) else '0';


data_in <= "00" & FIFO_DTYPE & FIFO_DATA; --modified by junbin 
fifo_busy <= '0';
fifo_data_FM <= fifo_data_out(31 downto 0);
fifo_dtype_FM <= fifo_data_out(33 downto 32);
	
--generate FEMB_EOF signal and FEMB_DAT_RDY signal.	
FIFO_TX: for i in 0 to 7  generate 	

  process(clk) 
  begin
		if (clk'event AND clk = '1') then
			FEMB_EOF_s1(i)		<= FEMB_EOF(i);
			FEMB_EOF_s2(i)		<= FEMB_EOF_s1(i);	
	  end if;
end process;

  process(clk,RESET) 
  begin
		if((RESET = '1') or  CLR_DAT_RDY(i) = '1' or CLR_RDY = '1') then
			FEMB_DAT_RDY(i) 	<= '0';	
		elsif (clk'event AND clk = '1') then
			if( FEMB_EOF_s1(i) = '1' and FEMB_EOF_s2(i) = '0') then--rising edges detected
				FEMB_DAT_RDY(i) 	<= ('1' and (not LINK_DISABLE(i)));
			end if;
	  end if;
  end process;		
end generate;		
----------------------state machine--------0618-------------------
--process(clk, RESET)
--begin
--	if(RESET = '1') then
--		state <= S_START;
--		FIFO_WR <= '0';
--		FIFO_DATA <= x"DEADBEEF";
--		FIFO_DTYPE <= "11";
--		WORD_CNT <= 0;
--	elsif (clk'event and clk = '1') then
--		case state is
--			when S_START =>
--				FIFO_DATA <= (others => '0');
--				FIFO_DTYPE <= "01"; --sop
--				FIFO_WR <= '1';
--				state <= S_SOP;
--			when S_SOP => 
--				FIFO_DATA <= FIFO_DATA + 1;
--				WORD_CNT <= WORD_CNT + 1;
--				FIFO_DTYPE <= "00";
--				state <= S_DATA;
--			when S_DATA =>
--				if (WORD_CNT < 114) then
--					WORD_CNT <= WORD_CNT + 1;
--					FIFO_DATA <= FIFO_DATA + 1;
--					state <= S_DATA;
--				else
--					WORD_CNT <= WORD_CNT + 1;
--					FIFO_DATA <= FIFO_DATA + 1;
--					FIFO_DTYPE <= "10";
--					state <= S_EOP;
--				end if;
--			when S_EOP =>
--				WORD_CNT <= 0;
--				state <= S_IDLE;
--				FIFO_WR <= '0';
--				FIFO_DTYPE <= "11";
--				FIFO_DATA <= (others => '0');
--			when S_IDLE =>
--				if (WORD_CNT < 3) then
--					WORD_CNT <= WORD_CNT + 1;
--					state <= S_IDLE;
--				else
--					WORD_CNT <= 0;
--					FIFO_WR <= '1';
--					FIFO_DTYPE <= "01";
--					FIFO_DATA <= (others => '0');
--					state <= S_SOP;
--				end if;
--			when others =>
--				state <= S_START;
--		end case;
--	end if;
--end process;
----------------------state machine--------0609-------------------
  process(clk,RESET) 
  begin		
			if(RESET = '1' ) then
				WORD_CNT		<= 0;
				DLY_CNT		<= 0;
				CLR_DAT_RDY <= x"ff";--modified
				FIFO_RST		<= x"ff";--modified			
				state 		<= S_IDLE;	
				FIFO_DATA   <= x"00000000";
				FIFO_DTYPE  <= b"11";
				FIFO_WR     <= '0';
				RX_FF_RDREQ <= (others => '0');
				chksumbufA <= x"00"; --new added 0709
				chksumbufB <= x"00"; --new added 0709
			elsif (clk'event AND clk = '1') then
			CASE state IS
			when S_IDLE =>	
				WORD_CNT		<= 0;
				DLY_CNT			<= 0; 
				RX_FF_RDREQ <= (others => '0');
				CLR_DAT_RDY		<= x"00";		
				CLR_RDY			<= '0';	
				FIFO_RST		<= x"00";
				FIFO_DATA   <= x"00000000";--new added
				FIFO_DTYPE  <= b"11";	   --new added
				FIFO_WR     <= '0';
				chksumbufA <= x"00"; --0709
				chksumbufB <= x"00"; --0709
				if(Stream_EN = '0') then
					state 		<= S_IDLE;	
---------------------0626 version-------------------------------
--				elsif ((FEMB_DAT_RDY(3 downto 0) /= x"0") and (FEMB_DAT_RDY(7 downto 4) /= x"0")) then
--					if((RX_FF_EMPTY(3 downto 0) /= x"f") and (RX_FF_EMPTY(7 downto 4) /= x"f")) then
--						if(FEMB_DAT_RDY = x"ff") then
--							FEMB_DAT_RDY_LATCH	<= FEMB_DAT_RDY;
--							CLR_DAT_RDY				<= x"ff";
--							state			 			<= S_START_Of_FRAME; 
--						else
--							state <= S_wait_for_all_eof;
--						end if;
--					else --for the first time FEMB2 fifo empty are detected, but FEMB1 rx fifos are full
--						CLR_RDY <= '1'; --clear the ready signal
--						--FIFO_RST	<= x"ff"; --clear the fifo here
--						--state <= S_wait_for_recovery; -- turn to recovery, if not, there is a dead lock here. clear fifo-> empty detected -> clear fifo
--					end if;
--				end if;
-------------------modified version 0622----------------------------
				elsif (FEMB_DAT_RDY /= x"00") then
					if(RX_FF_EMPTY /= x"ff") then
						if(FEMB_DAT_RDY = x"ff") then
							FEMB_DAT_RDY_LATCH	<= FEMB_DAT_RDY;
							CLR_DAT_RDY				<= x"ff";
							state			 			<= S_START_Of_FRAME; 
						else
							state <= S_wait_for_all_eof;
						end if;
					else --for the first time FEMB2 fifo empty are detected, but FEMB1 rx fifos are full
						CLR_RDY <= '1'; --clear the ready signal
						--FIFO_RST	<= x"ff"; --clear the fifo here
						--state <= S_wait_for_recovery; -- turn to recovery, if not, there is a dead lock here. clear fifo-> empty detected -> clear fifo
					end if;
				end if;
---------------------------------jack version---------------
--				elsif((FEMB_DAT_RDY(0)  = '1') or (FEMB_DAT_RDY(1)  = '1') or (FEMB_DAT_RDY(2)  = '1') or(FEMB_DAT_RDY(3)  = '1') or
--						(FEMB_DAT_RDY(4)  = '1') or (FEMB_DAT_RDY(5)  = '1') or (FEMB_DAT_RDY(6)  = '1') or (FEMB_DAT_RDY(7)  = '1')) then
--					if(RX_FF_EMPTY(0)	= '0' or RX_FF_EMPTY(1)	= '0' or RX_FF_EMPTY(2)	= '0' or RX_FF_EMPTY(3)	= '0' or
--						RX_FF_EMPTY(4)	= '0' or RX_FF_EMPTY(5)	= '0' or RX_FF_EMPTY(6)	= '0' or RX_FF_EMPTY(7)	= '0') then
--						if(FEMB_DAT_RDY= "11111111") then
--							FEMB_DAT_RDY_LATCH	<= FEMB_DAT_RDY;
--							CLR_DAT_RDY				<= "11111111";
--							state			 			<= S_START_Of_FRAME; 
--						else
--							state						<= S_wait_for_all_eof ;
--						end if;
--					else --all fifos are empty, this is the first time clear the ready signal and wait for next when next cycle begins the fifo has at least one frame data.
--						CLR_RDY			<= '1';	
--					end if;		
--				end if;

--       don't need this any more
--			when S_wait_for_recovery =>
--				CLR_RDY <= '0'; --should disable this signal
--				FIFO_RST	<= x"00"; --release
--				if (DLY_CNT < 110) then --wait how many cycles? can't wait too short or too long. time taken for dumping 29 words 29/64 * 240 = 108.75
--					DLY_CNT <= DLY_CNT + 1;
--					state <= S_wait_for_recovery; 
--				else
--					DLY_CNT <= 0;
--					state <= S_IDLE; --turn back to Idle
--				end if;
		   when S_wait_for_all_eof =>		
				DLY_CNT		<= DLY_CNT +1;
				CLR_RDY		<= '0';	
				if((DLY_CNT >= 1) or FEMB_DAT_RDY = x"ff") then  
					FEMB_DAT_RDY_LATCH	<= FEMB_DAT_RDY;
					CLR_DAT_RDY				<= x"ff";  
					state			 		<= S_START_Of_FRAME;
				end if;	
			---builder event here----
		   when S_START_Of_FRAME =>
						DLY_CNT <= 0;
						CLR_DAT_RDY	<= x"00";
						WORD_CNT		<= WORD_CNT +1;
						case WORD_CNT is
							when 0 =>
								FIFO_WR <= '1';       --write fifo
								FIFO_DATA <= x"00" & slot_No & crate_No & fiber_No & version_No & x"00";
								FIFO_DTYPE <= "01"; --sop
							when 1 =>
								FIFO_DTYPE <= "00";
								if((TIME_STAMP_ev(0) = TIME_STAMP_ev(1)) and
									(TIME_STAMP_ev(1) = TIME_STAMP_ev(2)) and
								   (TIME_STAMP_ev(2) = TIME_STAMP_ev(3)) and
									(TIME_STAMP_ev(3) = TIME_STAMP_ev(4)) and
									(TIME_STAMP_ev(4) = TIME_STAMP_ev(5)) and
									(TIME_STAMP_ev(5) = TIME_STAMP_ev(6)) and
									(TIME_STAMP_ev(6) = TIME_STAMP_ev(7)) and
									(TIME_STAMP_ev(7) = TIME_STAMP_ev(0))) then
									FIFO_DATA(0) <= '0';
								else
									FIFO_DATA(0) <= '1';
								end if;
								FIFO_DATA(15 downto 1) <= "000000000000000";
								--generate WIB errors--
								for iCDS in 7 downto 0 loop
									FIFO_DATA(iCDS*4 + 3) <= or_reduce(CAPTURE_ERROR_ev(iCDS));
									FIFO_DATA(iCDS*4 + 2) <= or_reduce(CD_ERROR_ev(iCDS));
								end loop;
						
							when 2 =>
								FIFO_DATA <= x"f0f0f0f0"; --timestamp from dts		
--								--read fifos
								RX_FF_RDREQ <= (     0 => FIFO_RDREQ(0),
															1 => FIFO_RDREQ(1),
															others =>'0'								
														 );								
							when 3 =>
								FIFO_DATA <= x"0f0f0f0f"; --timestamp from dts							
								---read out first block
							--cold data block 1 28 32-bit words	each channel contains 28 16-bit words
							--we have to sparate the  cold data header and cold data.
							--cold data header --stream error, check sum
							when 4 =>
								FIFO_DATA(3 downto 0) <= CAPTURE_ERROR_ev(0)(3 downto 0);
								FIFO_DATA(7 downto 4) <= CAPTURE_ERROR_ev(1)(3 downto 0);
								FIFO_DATA(15 downto 8) <= X"00";
								FIFO_DATA(23 downto 16) <= RX_FF_DATA(0)(7 downto 0); --LSB CHECKSUM of Rx1
								FIFO_DATA(31 downto 24) <= RX_FF_DATA(1)(7 downto 0); --LSB CHECKSUM of Rx2		
								chksumbufA <= RX_FF_DATA(0)(15 downto 8); --MSB CHECKSUM of rx1
								chksumbufB <= RX_FF_DATA(1)(15 downto 8); --MSB CHECKSUM of rx2
							--check sum and convert count,timestamp
							when 5 =>
								FIFO_DATA(7 downto 0)   <= chksumbufA;
								FIFO_DATA(15 downto 8)  <= chksumbufB;
								FIFO_DATA(23 downto 16) <= RX_FF_DATA(0)(7 downto 0); --rx1 LSB
								FIFO_DATA(31 downto 24) <= RX_FF_DATA(1)(15 downto 8); --rx2 MSB
							--error register and reserved
							when 6 =>
								FIFO_DATA(7 downto 0) <= RX_FF_DATA(0)(7 downto 0);  --error register
								FIFO_DATA(15 downto 8) <= RX_FF_DATA(1)(7 downto 0); --error register
								FIFO_DATA(31 downto 16) <= X"0000"; --reserved
							--Header-2 Tx links = 4 ADCs = 8 Headers
							when 7 =>
								FIFO_DATA(15 downto 0)<= RX_FF_DATA(0)(15 downto 0);
								FIFO_DATA(31 downto 16) <= RX_FF_DATA(1)(15 downto 0);															
							when 8 to 31 =>
								case(FIFO_RDREQ(1 downto 0)) is
									when "11" =>
										FIFO_DATA(7 downto 0) <= RX_FF_DATA(0)(7 downto 0);
										FIFO_DATA(15 downto 8)<= RX_FF_DATA(1)(7 downto 0);
										FIFO_DATA(23 downto 16) <= RX_FF_DATA(0)(15 downto 8);
										FIFO_DATA(31 downto 24) <= RX_FF_DATA(1)(15 downto 8);
									when "10" =>
										FIFO_DATA(7 downto 0) <= x"D0";
										FIFO_DATA(15 downto 8)<= RX_FF_DATA(1)(7 downto 0);
										FIFO_DATA(23 downto 16) <= x"BA";
										FIFO_DATA(31 downto 24) <= RX_FF_DATA(1)(15 downto 8);	
									when "01" =>
										FIFO_DATA(7 downto 0) <= RX_FF_DATA(0)(7 downto 0);
										FIFO_DATA(15 downto 8)<= x"D1";
										FIFO_DATA(23 downto 16) <= RX_FF_DATA(0)(15 downto 8);
										FIFO_DATA(31 downto 24) <= x"BA";
									when "00" =>
										FIFO_DATA(7 downto 0) <= x"D0";
										FIFO_DATA(15 downto 8)<= x"D1";
										FIFO_DATA(23 downto 16) <= x"BA";
										FIFO_DATA(31 downto 24) <= x"BA";					
								end case;
								if(WORD_CNT = 30) then --change to 31
									RX_FF_RDREQ <= ( 		2 => FIFO_RDREQ(2),
																3 => FIFO_RDREQ(3),
																others =>'0'								
															 );
								end if;	
							--cold data header2 --stream error, check sum
							when 32 =>
								FIFO_DATA(3 downto 0) <= CAPTURE_ERROR_ev(2)(3 downto 0);
								FIFO_DATA(7 downto 4) <= CAPTURE_ERROR_ev(3)(3 downto 0);
								FIFO_DATA(15 downto 8) <= X"00";
								FIFO_DATA(23 downto 16) <= RX_FF_DATA(2)(7 downto 0); --LSB CHECKSUM of Rx1
								FIFO_DATA(31 downto 24) <= RX_FF_DATA(3)(7 downto 0); --LSB CHECKSUM of Rx2		
								chksumbufA <= RX_FF_DATA(2)(15 downto 8); --MSB CHECKSUM of rx1
								chksumbufB <= RX_FF_DATA(3)(15 downto 8); --MSB CHECKSUM of rx2
							--check sum and convert count,timestamp
							when 33 =>
								FIFO_DATA(7 downto 0)   <= chksumbufA;
								FIFO_DATA(15 downto 8)  <= chksumbufB;
								FIFO_DATA(23 downto 16) <= RX_FF_DATA(2)(7 downto 0); --rx1 LSB
								FIFO_DATA(31 downto 24) <= RX_FF_DATA(3)(15 downto 8); --rx2 MSB
							--error register and reserved
							when 34 =>
								FIFO_DATA(7 downto 0) <= RX_FF_DATA(2)(7 downto 0);  --error register
								FIFO_DATA(15 downto 8) <= RX_FF_DATA(3)(7 downto 0); --error register
								FIFO_DATA(31 downto 16) <= X"0000"; --reserved
							--Header-2 Tx links = 4 ADCs = 8 Headers
							when 35 =>
								FIFO_DATA(15 downto 0)<= RX_FF_DATA(2)(15 downto 0);
								FIFO_DATA(31 downto 16) <= RX_FF_DATA(3)(15 downto 0);								
							when 36 to 59 =>
								case(FIFO_RDREQ(3 downto 2)) is
									when "11" =>
										FIFO_DATA(7 downto 0) <= RX_FF_DATA(2)(7 downto 0);
										FIFO_DATA(15 downto 8)<= RX_FF_DATA(3)(7 downto 0);
										FIFO_DATA(23 downto 16) <= RX_FF_DATA(2)(15 downto 8);
										FIFO_DATA(31 downto 24) <= RX_FF_DATA(3)(15 downto 8);
									when "10" =>
										FIFO_DATA(7 downto 0) <= x"D2";
										FIFO_DATA(15 downto 8)<= RX_FF_DATA(3)(7 downto 0);
										FIFO_DATA(23 downto 16) <= x"BA";
										FIFO_DATA(31 downto 24) <= RX_FF_DATA(3)(15 downto 8);	
									when "01" =>
										FIFO_DATA(7 downto 0) <= RX_FF_DATA(2)(7 downto 0);
										FIFO_DATA(15 downto 8)<= x"D3";
										FIFO_DATA(23 downto 16) <= RX_FF_DATA(2)(15 downto 8);
										FIFO_DATA(31 downto 24) <= x"BA";
									when "00" =>
										FIFO_DATA(7 downto 0) <= x"D2";
										FIFO_DATA(15 downto 8)<= x"D3";
										FIFO_DATA(23 downto 16) <= x"BA";
										FIFO_DATA(31 downto 24) <= x"BA";					
								end case;

								if(WORD_CNT = 58) then --change to 59
									RX_FF_RDREQ <= ( 4 => FIFO_RDREQ(4),
														  5 => FIFO_RDREQ(5),
														  others =>'0'								
														);
								end if;						
							--cold data block 3	
							--cold data header --stream error, check sum
							when 60 =>
								FIFO_DATA(3 downto 0) <= CAPTURE_ERROR_ev(4)(3 downto 0);
								FIFO_DATA(7 downto 4) <= CAPTURE_ERROR_ev(5)(3 downto 0);
								FIFO_DATA(15 downto 8) <= X"00";
								FIFO_DATA(23 downto 16) <= RX_FF_DATA(4)(7 downto 0); --LSB CHECKSUM of Rx1
								FIFO_DATA(31 downto 24) <= RX_FF_DATA(5)(7 downto 0); --LSB CHECKSUM of Rx2		
								chksumbufA <= RX_FF_DATA(4)(15 downto 8); --MSB CHECKSUM of rx1
								chksumbufB <= RX_FF_DATA(5)(15 downto 8); --MSB CHECKSUM of rx2
							--check sum and convert count,timestamp
							when 61 =>
								FIFO_DATA(7 downto 0)   <= chksumbufA;
								FIFO_DATA(15 downto 8)  <= chksumbufB;
								FIFO_DATA(23 downto 16) <= RX_FF_DATA(4)(7 downto 0); --rx1 LSB
								FIFO_DATA(31 downto 24) <= RX_FF_DATA(5)(15 downto 8); --rx2 MSB
							--error register and reserved
							when 62 =>
								FIFO_DATA(7 downto 0) <= RX_FF_DATA(4)(7 downto 0);  --error register
								FIFO_DATA(15 downto 8) <= RX_FF_DATA(5)(7 downto 0); --error register
								FIFO_DATA(31 downto 16) <= X"0000"; --reserved
							--Header-2 Tx links = 4 ADCs = 8 Headers
							when 63 =>
								FIFO_DATA(15 downto 0)<= RX_FF_DATA(4)(15 downto 0);
								FIFO_DATA(31 downto 16) <= RX_FF_DATA(5)(15 downto 0);							
							when 64 to 87 =>
								case(FIFO_RDREQ(5 downto 4)) is
									when "11" =>
										FIFO_DATA(7 downto 0) <= RX_FF_DATA(4)(7 downto 0);
										FIFO_DATA(15 downto 8)<= RX_FF_DATA(5)(7 downto 0);
										FIFO_DATA(23 downto 16) <= RX_FF_DATA(4)(15 downto 8);
										FIFO_DATA(31 downto 24) <= RX_FF_DATA(5)(15 downto 8);
									when "10" =>
										FIFO_DATA(7 downto 0) <= x"D4";
										FIFO_DATA(15 downto 8)<= RX_FF_DATA(5)(7 downto 0);
										FIFO_DATA(23 downto 16) <= x"BA";
										FIFO_DATA(31 downto 24) <= RX_FF_DATA(5)(15 downto 8);	
									when "01" =>
										FIFO_DATA(7 downto 0) <= RX_FF_DATA(4)(7 downto 0);
										FIFO_DATA(15 downto 8)<= x"D5";
										FIFO_DATA(23 downto 16) <= RX_FF_DATA(4)(15 downto 8);
										FIFO_DATA(31 downto 24) <= x"BA";
									when "00" =>
										FIFO_DATA(7 downto 0) <= x"D4";
										FIFO_DATA(15 downto 8)<= x"D5";
										FIFO_DATA(23 downto 16) <= x"BA";
										FIFO_DATA(31 downto 24) <= x"BA";					
								end case;							
								if(WORD_CNT = 86) then --change to 87
									RX_FF_RDREQ <= ( 6 => FIFO_RDREQ(6),
														  7 => FIFO_RDREQ(7),
														  others =>'0'								
														);
								end if;
							--cold data header4 --stream error, check sum
							when 88 =>
								FIFO_DATA(3 downto 0) <= CAPTURE_ERROR_ev(6)(3 downto 0);
								FIFO_DATA(7 downto 4) <= CAPTURE_ERROR_ev(7)(3 downto 0);
								FIFO_DATA(15 downto 8) <= X"00";
								FIFO_DATA(23 downto 16) <= RX_FF_DATA(6)(7 downto 0); --LSB CHECKSUM of Rx1
								FIFO_DATA(31 downto 24) <= RX_FF_DATA(7)(7 downto 0); --LSB CHECKSUM of Rx2		
								chksumbufA <= RX_FF_DATA(6)(15 downto 8); --MSB CHECKSUM of rx1
								chksumbufB <= RX_FF_DATA(7)(15 downto 8); --MSB CHECKSUM of rx2
							--check sum and convert count,timestamp
							when 89 =>
								FIFO_DATA(7 downto 0)   <= chksumbufA;
								FIFO_DATA(15 downto 8)  <= chksumbufB;
								FIFO_DATA(23 downto 16) <= RX_FF_DATA(6)(7 downto 0); --rx1 LSB
								FIFO_DATA(31 downto 24) <= RX_FF_DATA(7)(15 downto 8); --rx2 MSB
							--error register and reserved
							when 90 =>
								FIFO_DATA(7 downto 0) <= RX_FF_DATA(6)(7 downto 0);  --error register
								FIFO_DATA(15 downto 8) <= RX_FF_DATA(7)(7 downto 0); --error register
								FIFO_DATA(31 downto 16) <= X"0000"; --reserved
							--Header-2 Tx links = 4 ADCs = 8 Headers
							when 91 =>
								FIFO_DATA(15 downto 0)<= RX_FF_DATA(6)(15 downto 0);
								FIFO_DATA(31 downto 16) <= RX_FF_DATA(7)(15 downto 0);								
							when 92 to 115 =>
								case(FIFO_RDREQ(7 downto 6)) is
									when "11" =>
										FIFO_DATA(7 downto 0) <= RX_FF_DATA(6)(7 downto 0);
										FIFO_DATA(15 downto 8)<= RX_FF_DATA(7)(7 downto 0);
										FIFO_DATA(23 downto 16) <= RX_FF_DATA(6)(15 downto 8);
										FIFO_DATA(31 downto 24) <= RX_FF_DATA(7)(15 downto 8);
									when "10" =>
										FIFO_DATA(7 downto 0) <= x"D6";
										FIFO_DATA(15 downto 8)<= RX_FF_DATA(7)(7 downto 0);
										FIFO_DATA(23 downto 16) <= x"BA";
										FIFO_DATA(31 downto 24) <= RX_FF_DATA(7)(15 downto 8);	
									when "01" =>
										FIFO_DATA(7 downto 0) <= RX_FF_DATA(6)(7 downto 0);
										FIFO_DATA(15 downto 8)<= x"D7";
										FIFO_DATA(23 downto 16) <= RX_FF_DATA(6)(15 downto 8);
										FIFO_DATA(31 downto 24) <= x"BA";
									when "00" =>
										FIFO_DATA(7 downto 0) <= x"D6";
										FIFO_DATA(15 downto 8)<= x"D7";
										FIFO_DATA(23 downto 16) <= x"BA";
										FIFO_DATA(31 downto 24) <= x"BA";					
								end case;
								
								if(WORD_CNT = 114) then
									RX_FF_RDREQ <= (others =>'0');						
								end if;	
								if(WORD_CNT = 115) then --changed for 0619_5
									--RX_FF_RDREQ <= (others =>'0');
									FIFO_DTYPE <= "10"; --eop
								end if;	
							when 116 =>
								FIFO_WR <= '0';
								RX_FF_RDREQ <= (others => '0');
								FIFO_DTYPE <= "11"; --ignore;
								FIFO_DATA <= x"DEADBEEF";
							--modified good at 
							when 118 =>
								state <= S_IDLE;
								WORD_CNT <= 0;
--							when 119 =>
--								state <= S_START_Of_FRAME;
--								WORD_CNT <= 0;
							when others =>
								FIFO_WR <= '0';
								RX_FF_RDREQ <= (others => '0');
								FIFO_DTYPE <= "11"; --ignore;
								FIFO_DATA <= x"DEADBEEF";
						end case;
			when others =>		
				state 	<= S_IDLE;	
			end case; 			

	  end if;
end process;
-------------------event_fifo-------------------------

event_fifo: wib_event_fifo
  port map (
	 aclr    => or_reduce(FIFO_RST), 
	 --aclr => '0',
	 data    => data_in, --
	 rdclk   => fifo_rclk,
	 rdreq   => fifo_re,
	 wrclk   => clk,
	 wrreq   => FIFO_WR and (not fifo_full),
	 q       => fifo_data_out,
	 rdempty => fifo_empty,
	 wrfull  => fifo_full);

	 
link: FMchannelTXctrl_WIB
port map(
		  clk120 => clk_tx,
		  clk240 => clk,
		  rst    => or_reduce(FIFO_RST),
		  --rst => '0',
		  fifo_data => fifo_data_FM,
		  fifo_dtype => fifo_dtype_FM,
		  fifo_empty => fifo_empty,
		  busy       => fifo_busy,
		  fifo_rclk  => fifo_rclk,
		  fifo_re    => fifo_re,
		  data       => data_out,
		  k_data     => data_k_out  
		);

 
end FELIX_EventBuilder_Link_arch;