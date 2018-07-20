--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: TX_HS_DATA.vhd
--////                                                                                                                                      
--////  Author: Jack Fried                                        
--////          jfried@bnl.gov                
--////  Created:  03/22/2014
--////  Modified: 12/11/2017
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

entity TX_HS_DATA is
			generic ( 
							pkt_wait_dly  		: integer := 20					-- delay till next packet transfer
						);	
	port
	(
	   clk         		  	: in  std_logic;                     -- Input CLK from MAC Reciever
      reset			        	: in  std_logic;                     -- Synchronous reset signal

		TX_HS_REQ_OUT			: OUT  std_logic;                     
		TX_HS_ACK				: IN  std_logic;                   	
		
		tx_fifo_clk		  	  	: in  std_logic;		
		tx_fifo_in			  	: in  std_logic_vector(15 downto 0);
		tx_fifo_wr		  	  	: in  std_logic;
		tx_fifo_full		  	: out std_logic;  
		tx_fifo_used		   : out STD_LOGIC_VECTOR (11 DOWNTO 0);		

		BRD_IP					: in 	STD_LOGIC_VECTOR(31 downto 0);
		BRD_MAC					: in 	STD_LOGIC_VECTOR(47 downto 0);

		UDP_HS_port				: in  STD_LOGIC_VECTOR(15 downto 0);  -- 0x7d03  default
		ip_dest_addr		  	: in  std_logic_vector(31 downto 0);
		mac_dest_addr		 	: in  std_logic_vector(47 downto 0);
      tx_dst_rdy  	 	  	: in  std_logic;    		-- Input destination ready 
		header_info	  			: in  std_logic_vector(63 downto 0);
		
	
		
		FRAME_SIZE				: in  std_logic_vector(11 downto 0);  -- 0x1f8
		TIME_OUT_wait			: in  std_logic_vector(31 downto 0);	
 		system_status			: in  std_logic_vector(31 downto 0);	 
		tx_rdy					: IN STD_LOGIC;		
		tx_data_out      		: out std_logic_vector(7 downto 0);  -- Output data
      tx_eop_out       		: out std_logic;                      -- Output end of frame
      tx_sop_out       		: out std_logic;                     -- Output start of frame		
		tx_src_rdy  	  	   : out std_logic;                    -- source ready
		tx_write					: out std_logic                    -- source working

      );
end TX_HS_DATA;






--  Architecture Body



architecture TX_HS_DATA_arch OF TX_HS_DATA is

    type state_type is (IDLE,TX_HEADER,TX_DATA_LOBYTE,TX_DATA_HIBYTE,TX_DONE,TX_DONE_WAIT);
    signal state: state_type;
	 
	 
	 signal TX_HS_REQ_i			: std_logic; 
	 signal TX_HS_REQ_clr		: std_logic; 
    signal headersel 			: INTEGER RANGE 0 TO 63;

	 signal packetbytecnt 		: std_logic_vector(15 downto 0);
	 signal packet_cnt			: std_logic_vector(31 downto 0);
	 signal tx_lobyte				: std_logic_vector(7 downto 0);	 
	 signal header_user_info	: std_logic_vector(63 downto 0);
	 
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

	 
	 signal	tx_fifo_empty		: std_logic;
	 signal	tx_fifo_rd			: std_logic;
	 signal  tx_fifo_data	   : std_logic_vector(15 downto 0);
	 signal  rd_fifo_used	   : std_logic_vector(11 downto 0);
	 signal  rd_fifo_used_dly1 : std_logic_vector(11 downto 0);	 
	 signal  rd_fifo_used_dly2 : std_logic_vector(11 downto 0);
	 signal  tx_packet_wait	   : std_logic_vector(31 downto 0); 
 	 signal  packet_size		   : std_logic_vector(15 downto 0);
	 
 	 signal	pkt_wait				: std_logic_vector(7 downto 0);
	 signal  FRAME_SIZE_S		: std_logic_vector(11 downto 0);
	 signal	wrfull				: std_logic;

	 
component tx_packet_fifo
	PORT
	(
		aclr		: IN STD_LOGIC  := '0';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdempty		: OUT STD_LOGIC ;
		rdusedw		: OUT STD_LOGIC_VECTOR (11 DOWNTO 0);
		wrfull		: OUT STD_LOGIC ;
		wrusedw		: OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
end component;



	 
BEGIN


	FRAME_SIZE_S <= FRAME_SIZE when ( FRAME_SIZE <= x"F00" and FRAME_SIZE >= x"0ff") else  x"1f8";
						 

	inst_tx_packet_fifo : tx_packet_fifo 
    port map (
   	aclr			=> reset,
		data			=> tx_fifo_in,
		rdclk			=> not clk, 
		rdreq			=> tx_fifo_rd,
		wrclk			=> tx_fifo_clk,
		wrreq			=> tx_fifo_wr,
		q				=> tx_fifo_data,
		rdempty		=> tx_fifo_empty,
		rdusedw		=> rd_fifo_used,
		wrfull		=> wrfull,
		wrusedw		=> tx_fifo_used
    );
		
	tx_fifo_full	<= wrfull;
		
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
		


  process(clk) 
  begin
     if (clk'event AND clk = '1') then
			rd_fifo_used_dly1	 	<= rd_fifo_used; 
			rd_fifo_used_dly2	 	<= rd_fifo_used_dly1; 		
     end if;
  end process;	
		
		
		
process(clk,reset) 

  begin
   if (reset = '1') or (TX_HS_REQ_clr = '1') then
			TX_HS_REQ_i		<= '0';
			tx_packet_wait		<= x"00000000";
	elsif (clk'event AND clk = '1') then
			if (tx_fifo_empty = '0')  and (tx_rdy = '1') and (TX_HS_REQ_i = '0') then
				if( rd_fifo_used_dly1 >= FRAME_SIZE_S)  or (wrfull = '1') then 							
						TX_HS_REQ_i		<= '1';
				elsif(tx_packet_wait >  TIME_OUT_wait) then
					if (rd_fifo_used_dly1  = rd_fifo_used_dly2) and (rd_fifo_used_dly1 /= 0) then
						TX_HS_REQ_i		<= '1';
					else
							tx_packet_wait		<= x"00000000";
					end if;
				elsif(rd_fifo_used_dly1  = rd_fifo_used_dly2) then
					tx_packet_wait <= tx_packet_wait  +1;
				else
					tx_packet_wait		<= x"00000000";
				end if;
			end if;		
     end if;
  end process;		
		
		
		TX_HS_REQ_OUT	<= TX_HS_REQ_i;
				
		
	
			 
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
			packetbytecnt		 		<= (others => '0');
			packet_cnt				 	<= (others => '0');
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
			udp_len						<= x"0000"; 
			udp_chksum					<= x"0000"; --set to zero to disable checksumming
			tx_fifo_rd					<= '0';
			packet_size					<= x"0000";
			TX_HS_REQ_clr				<= '0';
     elsif (clk'event AND clk = '1') then
        CASE state is
          when IDLE =>
                  		 				
               tx_eop_out   			<= '0';
					tx_write   				<= '0'; 
               packetbytecnt  		<= (others => '0');
					tx_fifo_rd				<= '0';
					mac_lentype       	<= x"0800"; 
					header_user_info		<= header_info;
					tx_data_out 			<= mac_dest_addr(47 downto 40);	
					headersel 				<= 0;					
					udp_dest_port			<= UDP_HS_port;   --x"7D03";	
					TX_HS_REQ_clr			<= '0'; 					
					if( TX_HS_ACK = '1') then 
						packet_cnt 			<= packet_cnt + 1;
						state 				<= tx_header; 	
						if( rd_fifo_used_dly1 >= FRAME_SIZE_S)  or (wrfull = '1') then 							
								ip_totallen			<= (b"000" & FRAME_SIZE_S & '0') + 32 + 12;
								udp_len				<= (b"000" & FRAME_SIZE_S & '0') + 12 + 12;
								packet_size			<=  b"000" & FRAME_SIZE_S & '0';				
						else
								ip_totallen			<= (b"000" & rd_fifo_used_dly1 & '0') + 32 + 12;
								udp_len				<= (b"000" & rd_fifo_used_dly1 & '0')  + 12 + 12;
								packet_size			<=  b"000" & rd_fifo_used_dly1 & '0' ;
						end if;		
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
						when 42 =>  	tx_data_out <= packet_cnt(31 downto 24);	--				tx_data_out <= packet_cnt(31 downto 24);
						when 43 => 		tx_data_out <= packet_cnt(23 downto 16);
						when 44 => 		tx_data_out <= packet_cnt(15 downto 8);
						when 45 => 		tx_data_out <= packet_cnt(7 downto 0);
						when 46 => 		tx_data_out <= header_user_info(63 downto 56);
						when 47 => 		tx_data_out <= header_user_info(55 downto 48);	  
						when 48 => 		tx_data_out <= header_user_info(47 downto 40);
						when 49 =>		tx_data_out <= header_user_info(39 downto 32);	
						when 50 =>		tx_data_out <= header_user_info(31 downto 24);		
						when 51 =>		tx_data_out <= header_user_info(23 downto 16);	
						when 52 =>		tx_data_out <= header_user_info(15 downto 8);
						when 53 =>  	tx_data_out <= header_user_info(7 downto 0);
						when 54 =>  	tx_data_out <= system_status(31 downto 24);
						when 55 =>  	tx_data_out <= system_status(23 downto 16);
						when 56 =>  	tx_data_out <= system_status(15 downto 8);						
						when 57 =>  	tx_data_out <= system_status(7 downto 0);
											state <= tx_data_hibyte;
											tx_fifo_rd 			<= '1';
						when others => tx_data_out <= x"00";
					                  state <= idle;    
					end case;					
           when TX_DATA_HIBYTE =>
		  					tx_write 			<= '0'; 
							tx_fifo_rd 			<= '0';
                     tx_data_out		 	<= tx_fifo_data(15 downto 8); 
                     tx_lobyte   		<= tx_fifo_data(7 downto 0);
							packetbytecnt 		<= packetbytecnt + 1;
							state 				<= tx_data_lobyte;
           when TX_DATA_LOBYTE =>
                 if (packetbytecnt  >=  packet_size-2) then
                     tx_data_out 		<=  tx_lobyte; 
                     tx_eop_out  		<= '1';
							tx_fifo_rd 			<= '0';
                     packetbytecnt  	<= (others => '0');
                     state 				<= tx_done;
                 else
							tx_fifo_rd 			<= '1';
                     tx_data_out 		<= tx_lobyte; 
                     packetbytecnt 		<= packetbytecnt + 1;
                     state 				<= tx_data_hibyte;
                 end if;		                  
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
							TX_HS_REQ_clr	<= '1';
							state 			<= idle;
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

END TX_HS_DATA_arch;
