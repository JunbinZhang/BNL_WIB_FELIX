--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: TX_PING.vhd
--////                                                                                                                                      
--////  Author: Jack Fried                                        
--////          jfried@bnl.gov                
--////  Created:  03/22/2014
--////  Modified: 12/08/2017
--////  Description:    This module will form and transmit UDP packets for both
--////                  REGister and variable size data packets upto 1024 bytes                     
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2014 Brookhaven National Laboratory
--////
--/////////////////////////////////////////////////////////////////////
library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;



--  Entity Declaration

entity TX_PING is
	port
	(
	   clk         		  	: IN  std_logic;                     -- Input CLK from MAC Reciever
      reset			        	: IN  std_logic;                     -- Synchronous reset signal	

		BRD_IP					: IN 	STD_LOGIC_VECTOR(31 downto 0);
		BRD_MAC					: IN 	STD_LOGIC_VECTOR(47 downto 0);

		ip_dest_addr		  	: IN  std_logic_vector(31 downto 0);
		mac_dest_addr		 	: in  std_logic_vector(47 downto 0);
		
		PING_ACK					: IN  std_logic;	
		PING_REQ_OUT			: OUT std_logic;			

		PING_EN					: IN std_logic;	 
		PING_DATA				: IN std_logic_vector(7 downto 0); 
				
		tx_rdy					: IN STD_LOGIC;		
		tx_data_out      		: OUT  std_logic_vector(7 downto 0);  -- Output data
      tx_eop_out       		: OUT  std_logic;                      -- Output end of frame
      tx_sop_out       		: OUT  std_logic;                     -- Output start of frame		
		tx_src_rdy  	  	   : OUT  std_logic                  -- source working


      );
end TX_PING;

--  Architecture Body

architecture TX_PING_arch OF TX_PING is



    type state_type is (IDLE,TX_HEADER,tx_done,TX_DONE_WAIT);
    signal state: state_type;
	 
	 
	 
    signal COUNT_PING 		: std_logic_vector(7 downto 0);	
	 
    signal headersel 		: INTEGER RANGE 0 TO 63;

	 
	 signal mac_lentype			: std_logic_vector(15 downto 0);
	 signal ip_version			: std_logic_vector(3 downto 0);
	 signal ip_ihl 				: std_logic_vector(3 downto 0);
	 signal ip_tos					: std_logic_vector(7 downto 0);
	 signal ip_totallen			: std_logic_vector(15 downto 0);		
	 signal ip_ident				: std_logic_vector(15 downto 0);		
	 signal ip_flags				: std_logic_vector(2 downto 0);		
	 signal ip_fragoffset		: std_logic_vector(12 downto 0);		
	 signal ip_ttl					: std_logic_vector(7 downto 0);					
	 signal ip_protocol			: std_logic_vector(7 downto 0);												
	 signal ip_src_addr			: std_logic_vector(31 downto 0);	
	 signal icmp_type				: std_logic_vector(7 downto 0);	
	 signal icmp_code				: std_logic_vector(7 downto 0);	
	 signal icmp_checksum		: std_logic_vector(15 downto 0);	
	 signal icmp_checksum_i		: std_logic_vector(31 downto 0);		 
	 signal mac_src_addr		   : std_logic_vector(47 downto 0);
	 signal Hchecksum				: std_logic_vector(15 downto 0);
	 signal Hchecksum00			: std_logic_vector(31 downto 0);
	 signal Hchecksum01			: std_logic_vector(31 downto 0);
 	 signal Hchecksum02			: std_logic_vector(15 downto 0);
	 signal Hchecksum03			: std_logic_vector(31 downto 0);
	 signal PING_REQ_clr			: std_logic;
	 signal PING_EN_DLy1			: std_logic;
	 signal PING_EN_DLy2			: std_logic;
	 
 	 signal pkt_wait				: std_logic_vector(7 downto 0);

 	 signal PING_fifo_rd			: std_logic;
 	 signal PING_DATA_OUT		: std_logic_vector(7 downto 0);
 	 signal PING_fifo_empty		: std_logic;
	 signal word_build			: std_logic;
	 signal PING_DATA_dly 		: std_logic_vector(7 downto 0);
	 signal ping_size				: std_logic_vector(8 downto 0);
BEGIN


process(clk,reset) 
  begin
	if (clk'event AND clk = '1') then
		ip_src_addr		<= BRD_IP;
		mac_src_addr	<= BRD_MAC;
		Hchecksum00 	<= ((x"0000" & ip_src_addr (15 downto  0)) + (x"0000" & ip_src_addr (31 downto 16))) +
								((x"0000" & ip_dest_addr(15 downto  0)) + (x"0000" & ip_dest_addr(31 downto 16)));  			
		Hchecksum01 	<= ((x"0000" & ip_totallen(15 downto 0)) + (x"0000" & ip_ident(15 downto 0))) +
								((x"0000" & ip_flags(2 downto 0) & ip_fragoffset(12 downto 0)) + 
								 (x"0000" & ip_ttl(7 downto 0) & ip_protocol(7 downto 0)));
		Hchecksum02		<= (ip_version(3 downto 0) & ip_ihl(3 downto 0) & ip_tos(7 downto 0));
		Hchecksum03		<= ((x"0000" & Hchecksum00(31 downto 16)) + (x"0000" & Hchecksum00(15 downto 0)) + 
								 (x"0000" & Hchecksum01(31 downto 16)) + (x"0000" & Hchecksum01(15 downto 0)) + 
								 (x"0000" & Hchecksum02));
		Hchecksum   	<= not (Hchecksum03(31 downto 16) + Hchecksum03(15 downto 0));
		PING_EN_DLy1	<= PING_EN;
		PING_EN_DLy2	<= PING_EN_DLy1;
     end if;
  end process;		
		
		
	inst_tx_ping_fifo : entity work.tx_ping_fifo 
    port map (
   	aclr			=> reset,
		clock			=> clk, 		
		data			=> PING_DATA,
		rdreq			=> PING_fifo_rd,
		wrreq			=> PING_EN,
		q				=> PING_DATA_OUT,
		empty			=> PING_fifo_empty,
		usedw			=> ping_size
    );		


process(clk,reset,PING_REQ_CLR) 

  begin
     if (reset = '1') or (PING_REQ_CLR = '1') then
			icmp_checksum_i	<= x"00000000";
			word_build 	   <=	'0';
     elsif (clk'event AND clk = '1') then
			PING_DATA_dly <= PING_DATA;
			if (PING_EN = '1') then 
				word_build 	  <= not word_build;			
				if  (word_build = '1') then					
					icmp_checksum_i	<= icmp_checksum_i + (x"0000" & (PING_DATA_dly & PING_DATA));
				end if;	
			else
				if (word_build = '1') then
					word_build <= '0';
					icmp_checksum_i	<= icmp_checksum_i + (x"0000" & (PING_DATA_dly & PING_DATA));
				end if;	
				icmp_checksum	<= not (icmp_checksum_i(31 downto 16) + icmp_checksum_i(15 downto 0) );
				
			end if;
     end if;
  end process;	
		

	
process(clk,reset,PING_REQ_CLR) 

  begin
     if (reset = '1') or (PING_REQ_CLR = '1') then
			PING_REQ_OUT	<= '0';
     elsif (clk'event AND clk = '1') then
			if (PING_EN_DLy1 = '0') and (PING_EN_DLy2 = '1') then
				PING_REQ_OUT			<= '1';
			end if;
     end if;
  end process;	
			
			 
process(clk,reset) 
  begin
     if (reset = '1') then
         state              		<= idle;
         tx_data_out     			<= (others => '0'); 
         tx_sop_out    	 			<= '0';
         tx_eop_out    	 			<= '0';
         tx_src_rdy      			<= '0'; 
         headersel          		<=  0;
         mac_lentype             <= x"0800"; 
		   ip_version					<= x"4";
		   ip_ihl						<= x"5";
			ip_tos						<= x"00";
			ip_totallen					<= x"003c";
			ip_ident						<= x"3DAA";
			ip_flags						<= "000";
			ip_fragoffset				<= (others => '0');
			ip_ttl						<= x"80";
			ip_protocol					<= x"01";	
			PING_REQ_clr				<= '0';			
			PING_fifo_rd				<= '0';
			icmp_type					<= x"00";
			icmp_code					<= x"00";

     elsif (clk'event AND clk = '1') then
        CASE state is
          when IDLE =>             
               tx_eop_out   			<= '0';
					tx_data_out 			<= mac_dest_addr(47 downto 40);	
					headersel 				<= 0;					
					PING_REQ_clr			<= '0';
					PING_fifo_rd			<= '0';
					ip_totallen				<= x"0014" + ping_size + x"0004";   -- x"14" = ip header   ping_size = data in fifo   x"4" = icmp header+checksum
               if (PING_ACK = '1') then	
						state 					<= tx_header;						
					end if;
           when TX_HEADER =>
			      headersel <= headersel + 1;
					case headersel is 
					   when 0 =>      tx_data_out <= mac_dest_addr(47 downto 40);
											tx_sop_out  <= '1';
											tx_src_rdy  <= '1';						
					   when 1 =>      tx_data_out <= mac_dest_addr(39 downto 32);
											tx_sop_out  <= '0';
						when 2 =>      tx_data_out <= mac_dest_addr(31 downto 24);
					   when 3 =>      tx_data_out <= mac_dest_addr(23 downto 16);
					   when 4 =>      tx_data_out <= mac_dest_addr(15 downto 8);
					   when 5 =>      tx_data_out <= mac_dest_addr(7 downto 0);
					   when 6 =>      tx_data_out <= mac_src_addr(47 downto 40);
					   when 7 =>      tx_data_out <= mac_src_addr(39 downto 32);
					   when 8 =>      tx_data_out <= mac_src_addr(31 downto 24);
					   when 9 =>      tx_data_out <= mac_src_addr(23 downto 16);
					   when 10 =>     tx_data_out <= mac_src_addr(15 downto 8);
					   when 11 =>     tx_data_out <= mac_src_addr(7 downto 0);   
					   when 12 =>     tx_data_out <= mac_lentype(15 downto 8);
					   when 13 =>     tx_data_out <= mac_lentype(7 downto 0); 
						when 14 => 		tx_data_out <= ip_version(3 downto 0) & ip_ihl(3 downto 0);
						when 15 =>     tx_data_out <= ip_tos(7 downto 0);
						when 16 => 		tx_data_out <= ip_totallen(15 downto 8);
						when 17 =>     tx_data_out <= ip_totallen(7 downto 0);	
						when 18 => 		tx_data_out <= ip_ident(15 downto 8);
						when 19 =>     tx_data_out <= ip_ident(7 downto 0);		
						when 20 => 		tx_data_out <= ip_flags(2 downto 0) & ip_fragoffset(12 downto 8);
						when 21 =>     tx_data_out <= ip_fragoffset(7 downto 0);	
						when 22 =>     tx_data_out <= ip_ttl(7 downto 0);
						when 23 =>     tx_data_out <= ip_protocol(7 downto 0);
						when 24 =>     tx_data_out <= Hchecksum(15 downto 8);
						when 25 =>     tx_data_out <= Hchecksum(7 downto 0);		
					   when 26 =>     tx_data_out <= ip_src_addr(31 downto 24);
					   when 27 =>     tx_data_out <= ip_src_addr(23 downto 16);
					   when 28 =>     tx_data_out <= ip_src_addr(15 downto 8);
					   when 29 =>     tx_data_out <= ip_src_addr(7 downto 0);  
					   when 30 =>     tx_data_out <= ip_dest_addr(31 downto 24);
					   when 31 =>     tx_data_out <= ip_dest_addr(23 downto 16);
					   when 32 =>     tx_data_out <= ip_dest_addr(15 downto 8);
					   when 33 =>     tx_data_out <= ip_dest_addr(7 downto 0);  
					   when 34 =>     tx_data_out <= icmp_type; 						
						when 35 =>     tx_data_out <= icmp_code;
						when 36 =>     tx_data_out <= icmp_checksum(15 downto 8);
											PING_fifo_rd	<= '1';
						when 37 =>     tx_data_out <= icmp_checksum(7 downto 0); 
						when others =>	headersel 		<= 38;			
											tx_data_out 	<= PING_DATA_OUT;
											if(PING_fifo_empty = '1') then
												tx_eop_out  	<= '1';
												PING_fifo_rd	<= '0';
												state 			<= tx_done;		 
											end if;
					end case;					   
           when TX_DONE =>   	  
					  tx_eop_out 	<= '0';
                 tx_src_rdy 	<= '0';
                 headersel 	<= 0;
					  pkt_wait		<= x"00";
					  state 			<= TX_DONE_WAIT;	  
				when TX_DONE_WAIT =>	  
						pkt_wait	<= pkt_wait + 1;
						if(pkt_wait >= 20) then
							state 			<= idle;
							PING_REQ_clr		<= '1';
						end if;		 	  
			when others => tx_data_out <= x"00";		  
							   tx_eop_out 	<= '0';
							   tx_src_rdy 	<= '0';
							   headersel 	<= 0;
							   state 		<= idle;
        end case;
     end if;
  end process;

END TX_PING_arch;
