

--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: SBND_FEMB_PACK.VHD            
--////                                                                                                                                      
--////  Author: Jack Fried			                  
--////          jfried@bnl.gov	              
--////  Created: 05/22/2018
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
USE work.SbndPkg.all;

entity SBND_FEMB_PACK is
	PORT
	(
			RESET						: IN STD_LOGIC;	
			clk						: IN STD_LOGIC;
--			TX_clk					: IN STD_LOGIC;
			Stream_EN 				: IN STD_LOGIC;
			LINK_DISABLE			: IN  std_logic_vector(1 downto 0);
			FEMB_EOF					: IN std_logic_vector(1 downto 0);			
			RX_FF_DATA				: IN SL_ARRAY_15_TO_0(0 to 1);
			RX_FF_EMPTY				: IN std_logic_vector(1 downto 0);			
			RX_FF_RDREQ				: OUT std_logic_vector(1 downto 0);
			RX_FF_RST				: OUT std_logic_vector(1 downto 0);
			RX_FF_CLK				: OUT std_logic_vector(1 downto 0);
			tx_ctrlenable			: OUT std_logic_vector(1 downto 0);	
			TX_DATA			 		: OUT std_logic_vector(15 downto 0)
	);
end SBND_FEMB_PACK;


architecture SBND_FEMB_PACK_arch of SBND_FEMB_PACK is


	TYPE 	 	state_type is (S_IDLE,S_wait_for_all_eof , S_START_Of_FRAME);
	SIGNAL 	state				: state_type;	
	
	SIGNAL	TX_STREAM 						: std_logic_vector(3 downto 0);
	SIGNAL	TX_STREAM_L						: std_logic_vector(3 downto 0);
	SIGNAL	WORD_CNT							: integer range 127 downto 0;	
	SIGNAL	FEMB_EOF_s1						: std_logic_vector(1 downto 0);
	SIGNAL	FEMB_EOF_s2						: std_logic_vector(1 downto 0);
	SIGNAL	FEMB_DAT_RDY					: std_logic_vector(1 downto 0);
	SIGNAL	FEMB_DAT_RDY_LATCH			: std_logic_vector(1 downto 0);
	SIGNAL	CLR_DAT_RDY						: std_logic_vector(1 downto 0);
	SIGNAL	FIFO_RST							: std_logic_vector(1 downto 0);
	
	SIGNAL	CLR_RDY							: std_logic;
	SIGNAL	DLY_CNT							: std_logic_vector(7 downto 0);
	signal	tx_ctrlenable_s				: std_logic_vector(1 downto 0);	
	signal	TX_DATA_s				 		: std_logic_vector(15 downto 0);
begin



RX_FF_CLK(0)	<= clk;
RX_FF_CLK(1)	<= clk;
RX_FF_RST	<=	FIFO_RST;	
	
FIFO_TX: for i in 0 to 1  generate 	

  process(clk) 
  begin
		if (clk'event AND clk = '1') then
			FEMB_EOF_s1(i)		<= FEMB_EOF(i);
			FEMB_EOF_s2(i)		<= FEMB_EOF_s1(i);	
	  end if;
end process;


  process(clk,RESET) 
  begin
		if(RESET = '1' or  CLR_DAT_RDY(i) = '1' or CLR_RDY = '1') then
			FEMB_DAT_RDY(i) 	<= '0';	
		elsif (clk'event AND clk = '1') then
			if( FEMB_EOF_s1(i) = '1' and FEMB_EOF_s2(i) = '0') then
				FEMB_DAT_RDY(i) 	<= ('1' and (not LINK_DISABLE(i)));
			end if;
	  end if;
end process;		
end generate;		
	

  process(clk,RESET) 
  begin		
			if(RESET = '1' ) then
				TX_STREAM 	<= x"0";  
				WORD_CNT		<= 0;
				CLR_DAT_RDY <= b"11";
				FIFO_RST		<= b"11";			
				state 		<= S_IDLE;	
				DLY_CNT		<= x"00";
			elsif (clk'event AND clk = '1') then
			CASE state IS
			when S_IDLE =>	
				WORD_CNT			<= 0;
				DLY_CNT			<= x"00";
				TX_STREAM 		<= x"0";  
				RX_FF_RDREQ		<= b"00";		
				CLR_DAT_RDY		<= b"00";		
				CLR_RDY			<= '0';	
				FIFO_RST			<= b"00";	
				if(Stream_EN = '0') then
					state 		<= S_IDLE;	
				elsif( (FEMB_DAT_RDY(0)  = '1') or (FEMB_DAT_RDY(1)  = '1')  ) then				
					if(RX_FF_EMPTY(0)	= '0' OR RX_FF_EMPTY(1)	= '0') then
						if(FEMB_DAT_RDY= B"11") then
							FEMB_DAT_RDY_LATCH	<= FEMB_DAT_RDY;
							CLR_DAT_RDY				<= b"11";
							state			 			<= S_START_Of_FRAME;
				--			TX_STREAM 	<= x"5";  
						else
							state						 <= S_wait_for_all_eof ;
						end if;
					else
						CLR_RDY			<= '1';	
					end if;		
				end if;	
		   when S_wait_for_all_eof =>		
				DLY_CNT		<= DLY_CNT +1;
				CLR_RDY		<= '0';	
				if((DLY_CNT >= 1) or FEMB_DAT_RDY = B"11") then  
					FEMB_DAT_RDY_LATCH	<= FEMB_DAT_RDY;
					CLR_DAT_RDY				<= b"11";
			--		TX_STREAM 	<= x"5";  
					state			 			<= S_START_Of_FRAME;
				end if;	
		   when S_START_Of_FRAME =>
						CLR_DAT_RDY	<= b"00";
						RX_FF_RDREQ	<= b"00";
						TX_STREAM 	<= x"0";  
						WORD_CNT		<= WORD_CNT +1;				
						if(WORD_CNT <= 23) then						
							if(FEMB_DAT_RDY_LATCH(0) = '1' and  RX_FF_EMPTY(0) = '0') then
								RX_FF_RDREQ(0)<= '1';
								TX_STREAM 	<= x"1";
							else
								TX_STREAM 	<= x"3";
							end if;	
						else
							if(FEMB_DAT_RDY_LATCH(1) = '1' and  RX_FF_EMPTY(1) = '0') then
								RX_FF_RDREQ(1) <= '1';
								TX_STREAM 	<= x"2";
							else							
								TX_STREAM 	<= x"4";
							end if;		
						end if;
						if(WORD_CNT  >= 47) then
							state 		<= S_IDLE;	
						end if;
			when others =>		
				state 	<= S_IDLE;	
			end case; 			

	  end if;
end process;



  process(clk,RESET) 
  begin		
 
		if (clk'event AND clk = '1') then	
			TX_STREAM_L	<= TX_STREAM;
			if(TX_STREAM_L = x"1") then
				tx_ctrlenable	<= b"00";	
				TX_DATA			<= RX_FF_DATA(0);
			elsif(TX_STREAM_L = x"2") then
				tx_ctrlenable	<= b"00";	
				TX_DATA 			<= RX_FF_DATA(1);
			elsif(TX_STREAM_L = x"3") then
				tx_ctrlenable 	<= b"00";	
				TX_DATA		 	<= x"BAD0";
			elsif(TX_STREAM_L = x"4") then
				tx_ctrlenable	<= b"00";	
				TX_DATA		 	<= x"BAD1";
			elsif(TX_STREAM_L = x"5") then
				tx_ctrlenable	<= b"11";	
				TX_DATA		 	<= x"f7f7";
			else
				tx_ctrlenable	<= b"01";	
				TX_DATA		 	<= x"c5BC";
			end if;
		end if;

end process;
 

-- 
-- 
--  process(TX_clk) 
--  begin		
-- 
--	if (TX_clk'event AND TX_clk = '1') then	
--
--				tx_ctrlenable	<= tx_ctrlenable_s;
--				TX_DATA		 	<= TX_DATA_s;
--		end if;
--
--end process;
-- 


end SBND_FEMB_PACK_arch;


