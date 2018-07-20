--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: TX_ARP.vhd
--////                                                                                                                                      
--////  Author: Jack Fried                                        
--////          jfried@bnl.gov                
--////  Created:  03/22/2014
--////  Modified: 12/8/2017
--////  Description:    This module will form and transmit UDP packets for both
--////                  Register and variable size data packets upto 1024 bytes                     
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

entity TX_ARP is
	port
	(
	   clk         		  	: in  std_logic;                     -- Input CLK from MAC Reciever
      reset			        	: in  std_logic;                     -- Synchronous reset signal
	
		BRD_IP					: in 	STD_LOGIC_VECTOR(31 downto 0);
		BRD_MAC					: in 	STD_LOGIC_VECTOR(47 downto 0);

		ip_dest_addr		  	: in  std_logic_vector(31 downto 0);
		mac_dest_addr		 	: in  std_logic_vector(47 downto 0);

		ARP_REQ				   : in  std_logic;		 -- gen ARP_responce
		ARP_ACK					: in  std_logic;		 -- gen ARP_responce
		ARP_REQ_OUT				: OUT  std_logic;		 -- gen ARP_responce
		
		
		tx_rdy					: IN STD_LOGIC;		
		tx_data_out      		: out std_logic_vector(7 downto 0);  -- Output data
      tx_eop_out       		: out std_logic;                      -- Output end of frame
      tx_sop_out       		: out std_logic;                     -- Output start of frame		
		tx_src_rdy  	  	   : out std_logic

      );
end TX_ARP;

--  Architecture Body


architecture TX_ARP_arch OF TX_ARP is

    type state_type is (IDLE,TX_ARP,TX_DONE,TX_DONE_WAIT);
    signal state: state_type;
	 
	 
	 
    signal headersel 			: INTEGER RANGE 0 TO 63;
	 signal mac_lentype			: std_logic_vector(15 downto 0);											 
	 signal mac_src_addr		   : std_logic_vector(47 downto 0);
	 signal ip_src_addr			: std_logic_vector(31 downto 0);							
	 signal ARP_REQ_CLR			: std_logic;
 	 signal pkt_wait				: std_logic_vector(7 downto 0);

	 
BEGIN

		

process(clk,reset) 

  begin
	if (clk'event AND clk = '1') then
		ip_src_addr		<= BRD_IP;
		mac_src_addr	<= BRD_MAC;
     end if;
  end process;			
	
	
process(clk,reset,ARP_REQ,ARP_ACK) 

  begin
     if (reset = '1') or (ARP_REQ_CLR = '1') then
			ARP_REQ_OUT	<= '0';
     elsif (clk'event AND clk = '1') then
		if (ARP_REQ = '1') then
			ARP_REQ_OUT			<= '1';
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
         mac_lentype     		   <= x"0806"; 
			ARP_REQ_CLR					<= '0';
     elsif (clk'event AND clk = '1') then
        CASE state is
          when IDLE =>   
					tx_sop_out    	 		<= '0';
					tx_eop_out    	 		<= '0';
					tx_src_rdy      		<= '0'; 
					mac_lentype       	<= x"0806"; 
					tx_data_out 			<= mac_dest_addr(47 downto 40);	
					headersel 				<= 0;					
					ARP_REQ_CLR				<= '0';
					if(ARP_ACK = '1') then		
						state 				<= TX_ARP;	
					end if;
          when TX_ARP =>
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
						when 14 => 		tx_data_out <= x"00"; --HW_TYPE  
						when 15 =>     tx_data_out <= x"01"; --HW_TYPE
						when 16 => 		tx_data_out <= x"08"; --protocal type
						when 17 =>     tx_data_out <= x"00"; --protocal type
						when 18 => 		tx_data_out <= x"06"; --HW SIZE
						when 19 =>     tx_data_out <= x"04"; --PROTOCOL size
						when 20 => 		tx_data_out <= x"00"; -- opcode_REQ
						when 21 =>     tx_data_out <= x"02"; -- opcode REQ
						when 22 =>     tx_data_out <= mac_src_addr(47 downto 40);
						when 23 =>     tx_data_out <= mac_src_addr(39 downto 32);
						when 24 =>     tx_data_out <= mac_src_addr(31 downto 24);
						when 25 =>     tx_data_out <= mac_src_addr(23 downto 16);
					   when 26 =>     tx_data_out <= mac_src_addr(15 downto 8);
					   when 27 =>     tx_data_out <= mac_src_addr(7 downto 0); 
					   when 28 =>     tx_data_out <= ip_src_addr(31 downto 24);
					   when 29 =>     tx_data_out <= ip_src_addr(23 downto 16);
					   when 30 =>     tx_data_out <= ip_src_addr(15 downto 8);
					   when 31 =>     tx_data_out <= ip_src_addr(7 downto 0);
					   when 32 =>     tx_data_out <= mac_dest_addr(47 downto 40);
					   when 33 =>     tx_data_out <= mac_dest_addr(39 downto 32);
					   when 34 =>     tx_data_out <= mac_dest_addr(31 downto 24);
					   when 35 =>     tx_data_out <= mac_dest_addr(23 downto 16);
					   when 36 =>     tx_data_out <= mac_dest_addr(15 downto 8);
					   when 37 =>     tx_data_out <= mac_dest_addr(7 downto 0);
						when 38 =>     tx_data_out <= ip_dest_addr(31 downto 24);
						when 39 =>     tx_data_out <= ip_dest_addr(23 downto 16);
						when 40 =>     tx_data_out <= ip_dest_addr(15 downto 8);
						when 41 =>     tx_data_out <= ip_dest_addr(7 downto 0);
											tx_eop_out  <= '1';
											state 		<= tx_done;
						when others => tx_data_out <= x"00";
					                  state <= idle;    
					end case;	

					headersel 	<= headersel + 1;				                  
           when TX_DONE =>   	  
					  
					  tx_eop_out 	<= '0';
                 tx_src_rdy 	<= '0';
                 headersel 	<= 0;
					  pkt_wait		<= x"00";
					  state 			<= TX_DONE_WAIT;	  
				when TX_DONE_WAIT =>	 
						pkt_wait	<= pkt_wait + 1;
						if(pkt_wait >= 20) then
							ARP_REQ_CLR		<= '1';
							state 			<= idle;
						end if;		 
			when others => tx_data_out <= x"00";  
							   tx_eop_out 	<= '0';
							   tx_src_rdy 	<= '0';
							   headersel 	<= 0;
							   state 		<= idle;
        end case;
     end if;
  end process ;

END TX_ARP_arch;
