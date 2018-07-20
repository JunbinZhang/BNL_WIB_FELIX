--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: TX_REG.vhd
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

entity TX_FEMB is
			generic ( 
							pkt_wait_dly  		: integer := 20										-- delay till next packet transfer
						);		
	port
	(
	   clk         		  	: IN  std_logic;                     -- Input CLK from MAC Reciever
      reset			        	: IN  std_logic;                     -- Synchronous reset signal	

		BRD_IP					: IN 	STD_LOGIC_VECTOR(31 downto 0);
		BRD_MAC					: IN 	STD_LOGIC_VECTOR(47 downto 0);

		ip_dest_addr		  	: IN  std_logic_vector(31 downto 0);
		mac_dest_addr		 	: in  std_logic_vector(47 downto 0);
		

		FEMB_ACK					: IN  std_logic;	
		FEMB_REQ_OUT			: OUT std_logic;		
	
		REG_start_address		: IN  std_logic_vector(15 downto 0);
		FEMB_BRD					: IN std_logic_vector(3 downto 0);		
		FEMB_RDBK_strb			: IN  STD_LOGIC;
		FEMB_RDBK_DATA			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);			
		
		tx_rdy					: IN STD_LOGIC;			
		tx_data_out      		: OUT  std_logic_vector(7 downto 0);  -- Output data
      tx_eop_out       		: OUT  std_logic;                      -- Output end of frame
      tx_sop_out       		: OUT  std_logic;                     -- Output start of frame		
		tx_src_rdy  	  	   : OUT  std_logic;                    -- source ready
		tx_write					: OUT  std_logic                    -- source working


      );
end TX_FEMB;

--  Architecture Body

architecture TX_FEMB_arch OF TX_FEMB is



    type state_type is (IDLE,TX_HEADER,tx_done,TX_DONE_WAIT);
    signal state: state_type;
	 
	 
	 
    signal headersel 		: INTEGER RANGE 0 TO 63;

 	 signal udp_reg_port			: std_logic_vector(15 downto 0);			 
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
	 signal udp_src_port			: std_logic_vector(15 downto 0);							
	 signal udp_dest_port		: std_logic_vector(15 downto 0);			
	 signal udp_len				: std_logic_vector(15 downto 0);			
	 signal udp_chksum			: std_logic_vector(15 downto 0);				 
	 signal mac_src_addr		   : std_logic_vector(47 downto 0);
	 signal Hchecksum				: std_logic_vector(15 downto 0);
	 signal Hchecksum00			: std_logic_vector(31 downto 0);
	 signal Hchecksum01			: std_logic_vector(31 downto 0);
 	 signal Hchecksum02			: std_logic_vector(15 downto 0);
	 signal Hchecksum03			: std_logic_vector(31 downto 0);	 
	 signal REG_REQ_i				: std_logic;
	 signal REG_REQ_clr			: std_logic;
	 signal REG_data_s		   : std_logic_vector(31 downto 0);
	 signal REG_address_S	   : std_logic_vector(15 downto 0);
 
 	 signal pkt_wait				: std_logic_vector(7 downto 0);



	 
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
     end if;
  end process;		
		


process(clk,reset,REG_REQ_clr) 

  begin
     if (reset = '1') or (REG_REQ_clr = '1') then
			REG_REQ_i			<= '0';
     elsif (clk'event AND clk = '1') then	  
			if (FEMB_RDBK_strb = '1') and (REG_REQ_i = '0')  then
				reg_address_S	<= reg_start_address;
				REG_REQ_i		<= '1';			
				if    (FEMB_BRD = x"0")  then
					udp_reg_port	<= x"7D12";
				elsif (FEMB_BRD = x"1")  then			
					udp_reg_port	<= x"7D22";
				elsif (FEMB_BRD = x"2")  then			
					udp_reg_port	<= x"7D32";
				elsif (FEMB_BRD = x"3")  then			
					udp_reg_port	<= x"7D42";
				end if;
			end if;	
	  end if;
  end process;
  
  
	FEMB_REQ_OUT <=  REG_REQ_i;
	
	
	
			 
process(clk,reset) 

  begin
     if (reset = '1') then
         state              		<= idle;
         tx_data_out     			<= (others => '0'); 
         tx_sop_out    	 			<= '0';
         tx_eop_out    	 			<= '0';
         tx_src_rdy      			<= '0'; 
			tx_write      				<= '0'; 
         headersel          		<=  0;
         mac_lentype             <= x"0800"; 
		   ip_version					<= x"4";
		   ip_ihl						<= x"5";
			ip_tos						<= x"00";
			ip_totallen					<= x"0044";
			ip_ident						<= x"3DAA";
			ip_flags						<= "000";
			ip_fragoffset				<= (others => '0');
			ip_ttl						<= x"80";
			ip_protocol					<= x"11";	
			udp_src_port				<= x"7D00";
			udp_dest_port				<= x"7D02";
			udp_len						<= x"0030"; --x"0408" --length of UDP header(src_port, dest_prot, len, chksum) and data
			udp_chksum					<= x"0000"; --set to zero to disable checksumming
			REG_data_s					<= (others => '0');	
			REG_REQ_clr					<= '0';
     elsif (clk'event AND clk = '1') then
        CASE state is
          when IDLE =>
                  
               tx_eop_out   			<= '0';
					tx_write   				<= '0'; 
					mac_lentype       	<= x"0800"; 
					tx_data_out 			<= mac_dest_addr(47 downto 40);	
					headersel 				<= 0;					
					udp_dest_port			<= udp_reg_port;
					REG_REQ_clr				<= '0';
					ip_totallen			<= x"002e";
					udp_len				<= x"001a";						
               if (FEMB_ACK = '1') then
						state 				<= tx_header;						
					end if;
           when TX_HEADER =>
			      headersel <= headersel + 1;
					tx_write <= '1'; 
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
					   when 34 =>     tx_data_out <= udp_src_port(15 downto 8);
					   when 35 =>     tx_data_out <= udp_src_port(7 downto 0);  						
					   when 36 =>     tx_data_out <= udp_dest_port(15 downto 8);
					   when 37 =>     tx_data_out <= udp_dest_port(7 downto 0);  	
					   when 38 =>     tx_data_out <= udp_len(15 downto 8);
					   when 39 =>     tx_data_out <= udp_len(7 downto 0);
					   when 40 =>     tx_data_out <= udp_chksum(15 downto 8);
					   when 41 =>     tx_data_out <= udp_chksum(7 downto 0);	
						when 42 =>  	tx_data_out <= reg_address_S(15 downto 8);
											reg_data_s	<= FEMB_RDBK_DATA;	
						when 43 =>		tx_data_out <= REG_address_S(7 downto 0);
						when 44 =>		tx_data_out <= REG_data_s(31 downto 24);						
						when 45 =>		tx_data_out <= REG_data_s(23 downto 16);
						when 46 =>		tx_data_out <= REG_data_s(15 downto 8);
						when 47 =>		tx_data_out <= REG_data_s(7 downto 0);			   
						when 48 =>		tx_data_out <= x"00";		
											tx_eop_out  <= '1';
											state 		<= tx_done;		
						when others => tx_data_out <= x"00";
					                  state <= idle;    
					end case;					   
           when TX_DONE =>   	  
					  tx_eop_out 	<= '0';
                 tx_src_rdy 	<= '0';
	  				  tx_write		<= '0'; 
                 headersel 	<= 0;
					  pkt_wait		<= x"00";
					  state 			<= TX_DONE_WAIT;	  
				when TX_DONE_WAIT =>	  
						pkt_wait	<= pkt_wait + 1;
						if(pkt_wait >= pkt_wait_dly) then
							state 			<= idle;
							REG_REQ_clr		<= '1';
						end if;		 	  
			when others => tx_data_out <= x"00";		  
							   tx_eop_out 	<= '0';
			  					tx_write 	<= '0'; 
							   tx_src_rdy 	<= '0';
							   headersel 	<= 0;
							   state 		<= idle;
        end case;
     end if;
  end process;

END TX_FEMB_arch;
