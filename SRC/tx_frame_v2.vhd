--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: tx_frame_v2.vhd
--////                                                                                                                                      
--////  Author: Jack Fried                                        
--////          jfried@bnl.gov                
--////  Created:  03/22/2014
--////  Modified: 12/11/2014
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

entity tx_frame_v2 is
	port
	(
	   clk         		  	: in  std_logic;                     -- Input CLK from MAC Reciever
      reset			        	: in  std_logic;                     -- Synchronous reset signal
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
		header_user_info	  	: in  std_logic_vector(63 downto 0);
		
		arp_req				   : in  std_logic;		 -- gen arp_responce
		
		PING_EN					: in std_logic;	 
		PING_DATA				: in std_logic_vector(7 downto 0); 	
		
		

		EN_WR_RDBK				: in  std_logic;    		
		WR_data					: in  std_logic_vector(31 downto 0);
		reg_wr_strb				: in  std_logic;    		-- Input destination ready 
		reg_rd_strb				: in  std_logic;    		-- Input destination ready 
		reg_start_address		: in  std_logic_vector(15 downto 0);
		reg_RDOUT_num			: in  std_logic_vector(3 downto 0);   -- number of registers to read out
		reg_address				: out  std_logic_vector(15 downto 0);
		reg_data					: in  std_logic_vector(31 downto 0);

		FEMB_BRD					: IN std_logic_vector(3 downto 0);		
		FEMB_RDBK_strb			: IN  STD_LOGIC;
		FEMB_RDBK_DATA			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
		
		
		
		FRAME_SIZE				: in  std_logic_vector(11 downto 0);  -- 0x1f8
		TIME_OUT_wait			: in  std_logic_vector(31 downto 0);	
 		system_status			: in  std_logic_vector(31 downto 0);	 
		tx_rdy					: IN STD_LOGIC;		
		tx_data_out      		: out std_logic_vector(7 downto 0);  -- Output data
      tx_eop_out       		: out std_logic;                      -- Output end of frame
      tx_sop_out       		: out std_logic;                     -- Output start of frame		
		tx_src_rdy  	  	   : out std_logic                    -- source ready

      );
end tx_frame_v2;





architecture tx_frame_V2_arch OF tx_frame_V2 is


    type state_type is (IDLE,S_ARP, S_REG, S_FEMB, S_PING, S_HS_DATA);
    signal state: state_type;
	 

    signal REG_ACK				: std_logic;
    signal REG_REQ_OUT			: std_logic;
	 
    signal FEMB_ACK				: std_logic;
	 signal FEMB_REQ_OUT			: std_logic;		 	 
			
    signal ARP_ACK				: std_logic;
    signal ARP_REQ_OUT			: std_logic;
		
    signal PING_ACK				: std_logic;
    signal PING_REQ_OUT			: std_logic;

	 
    signal TX_HS_ACK				: std_logic;
	 signal TX_HS_REQ_OUT		: std_logic;	
	 
	 

	 
	 
    signal tx_data_out_REG		: std_logic_vector(7 downto 0);
    signal tx_sop_out_REG		: std_logic;
    signal tx_eop_out_REG		: std_logic;
    signal tx_src_rdy_REG		: std_logic;

    signal tx_data_out_FEMB	: std_logic_vector(7 downto 0);
    signal tx_sop_out_FEMB		: std_logic;
    signal tx_eop_out_FEMB		: std_logic;
    signal tx_src_rdy_FEMB		: std_logic;
	 
	 
	
    signal tx_data_out_ARP		: std_logic_vector(7 downto 0);
    signal tx_sop_out_ARP		: std_logic;
    signal tx_eop_out_ARP		: std_logic;
    signal tx_src_rdy_ARP		: std_logic;


    signal tx_data_out_PING	: std_logic_vector(7 downto 0);
    signal tx_sop_out_PING		: std_logic;
    signal tx_eop_out_PING		: std_logic;
    signal tx_src_rdy_PING		: std_logic;

    signal tx_data_out_HSD		: std_logic_vector(7 downto 0);
    signal tx_sop_out_HSD		: std_logic;
    signal tx_eop_out_HSD		: std_logic;
    signal tx_src_rdy_HSD		: std_logic;
	
	 
BEGIN
	

TX_REG_inst : entity work.TX_REG
	PORT MAP (
	   clk         		  	=> CLK,
      reset			        	=> reset,
		BRD_IP					=> BRD_IP, 					--: IN 	STD_LOGIC_VECTOR(31 downto 0);
		BRD_MAC					=> BRD_MAC,					--: IN 	STD_LOGIC_VECTOR(47 downto 0);
		ip_dest_addr		  	=>	ip_dest_addr,			--: IN  std_logic_vector(31 downto 0);
		mac_dest_addr		 	=>	mac_dest_addr,			--: in  std_logic_vector(47 downto 0);
		REG_ACK					=>	REG_ACK,					--: IN  std_logic;	
		REG_REQ_OUT				=>	REG_REQ_OUT,			--: OUT std_logic;		

		
		EN_WR_RDBK				=>	EN_WR_RDBK,				--: in  std_logic;    		
		WR_data					=>	WR_data,					--: in  std_logic_vector(31 downto 0);		
		reg_wr_strb				=>	reg_wr_strb,			--: in  std_logic;    		-- Input destination ready 		
		REG_rd_strb				=>	REG_rd_strb,			--: IN  std_logic;    		-- Input destination ready 		
		REG_start_address		=>	REG_start_address,	--: IN  std_logic_vector(15 downto 0);
		REG_RDOUT_num			=>	REG_RDOUT_num,			--: IN  std_logic_vector(3 downto 0);   -- number of REGisters to read out
		REG_data					=>	REG_data,				--: IN  std_logic_vector(31 downto 0);	 
		REG_address				=>	REG_address,			--: OUT  std_logic_vector(15 downto 0);				


		tx_rdy					=>	tx_rdy,					--: IN STD_LOGIC;		
		tx_data_out      		=>	tx_data_out_REG,		--: OUT  std_logic_vector(7 downto 0);  -- Output data
      tx_eop_out       		=>	tx_eop_out_REG,		--: OUT  std_logic;                      -- Output end of frame
      tx_sop_out       		=>	tx_sop_out_REG,		--: OUT  std_logic;                     -- Output start of frame		
		tx_src_rdy  	  	   =>	tx_src_rdy_REG,		--: OUT  std_logic;                    -- source ready
		tx_write					=>	open						--: OUT  std_logic                    -- source working
      );


TX_FEMB_inst : entity work.TX_FEMB
	PORT MAP (
	   clk         		  	=> CLK,
      reset			        	=> reset,
		BRD_IP					=> BRD_IP, 					--: IN 	STD_LOGIC_VECTOR(31 downto 0);
		BRD_MAC					=> BRD_MAC,					--: IN 	STD_LOGIC_VECTOR(47 downto 0);
		ip_dest_addr		  	=>	ip_dest_addr,			--: IN  std_logic_vector(31 downto 0);
		mac_dest_addr		 	=>	mac_dest_addr,			--: in  std_logic_vector(47 downto 0);
		FEMB_ACK					=>	FEMB_ACK,				--: IN  std_logic;	
		FEMB_REQ_OUT			=>	FEMB_REQ_OUT,			--: OUT std_logic;	
		
		REG_start_address		=>	REG_start_address,	--: IN  std_logic_vector(15 downto 0);
		FEMB_BRD					=>	FEMB_BRD,				--: IN std_logic_vector(3 downto 0);		
		FEMB_RDBK_strb			=>	FEMB_RDBK_strb,		--: IN  STD_LOGIC;
		FEMB_RDBK_DATA			=>	FEMB_RDBK_DATA,		--: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			
		tx_rdy					=>	tx_rdy,					--: IN STD_LOGIC;		
		tx_data_out      		=>	tx_data_out_FEMB,		--: OUT  std_logic_vector(7 downto 0);  -- Output data
      tx_eop_out       		=>	tx_eop_out_FEMB,		--: OUT  std_logic;                      -- Output end of frame
      tx_sop_out       		=>	tx_sop_out_FEMB,		--: OUT  std_logic;                     -- Output start of frame		
		tx_src_rdy  	  	   =>	tx_src_rdy_FEMB,		--: OUT  std_logic;                    -- source ready
		tx_write					=>	open						--: OUT  std_logic                    -- source working
      );
		
		

		
TX_ARP_inst : entity work.TX_ARP
	port MAP
	(
	   clk         		  	=> clk,						--: in  std_logic;                     -- Input CLK from MAC Reciever
      reset			        	=> reset,					--: in  std_logic;                     -- Synchronous reset signal
		BRD_IP					=> BRD_IP,					--: in 	STD_LOGIC_VECTOR(31 downto 0);
		BRD_MAC					=> BRD_MAC,					--: in 	STD_LOGIC_VECTOR(47 downto 0);
		ip_dest_addr		  	=> ip_dest_addr,			--: in  std_logic_vector(31 downto 0);
		mac_dest_addr		 	=> mac_dest_addr,			--: in  std_logic_vector(47 downto 0);
		ARP_REQ				   => ARP_REQ,					--: in  std_logic;		 -- gen ARP_responce
		ARP_ACK					=> ARP_ACK,					--: in  std_logic;		 -- gen ARP_responce
		ARP_REQ_OUT				=> ARP_REQ_OUT,			--: OUT  std_logic;		 -- gen ARP_responce
		tx_rdy					=> tx_rdy,					--: IN STD_LOGIC;		
		tx_data_out      		=> tx_data_out_ARP,		--: out std_logic_vector(7 downto 0);  -- Output data
      tx_eop_out       		=> tx_eop_out_ARP,		--: out std_logic;                      -- Output end of frame
      tx_sop_out       		=> tx_sop_out_ARP,		--: out std_logic;                     -- Output start of frame		
		tx_src_rdy  	  	   => tx_src_rdy_ARP			--: out std_logic;                    -- source ready

      );
	
			
			
TX_HS_DATA_inst : entity work.TX_HS_DATA
	port map
	(
	   clk  						=>	CLK,						--: in  std_logic;                     -- Input CLK from MAC Reciever
      reset						=>	reset,					--: in  std_logic;                  
		TX_HS_REQ_OUT			=>	TX_HS_REQ_OUT,			--: OUT  std_logic;                                     
		TX_HS_ACK				=>	TX_HS_ACK,				--: IN  std_logic;               
		tx_fifo_clk				=>	tx_fifo_clk,			--: in  std_logic;		
		tx_fifo_in				=>	tx_fifo_in,				--: in  std_logic_vector(15 downto 0);
		tx_fifo_wr		  		=>	tx_fifo_wr,				--: in  std_logic;
		tx_fifo_full			=>	tx_fifo_full,			--: out std_logic;  
		tx_fifo_used			=>	tx_fifo_used,			-- : out STD_LOGIC_VECTOR (11 DOWNTO 0);		
		BRD_IP					=>	BRD_IP,					--: in 	STD_LOGIC_VECTOR(31 downto 0);
		BRD_MAC					=>	BRD_MAC,					--: in 	STD_LOGIC_VECTOR(47 downto 0);
		UDP_HS_port				=>	UDP_HS_port,			--: in  STD_LOGIC_VECTOR(15 downto 0);  -- 0x7d03  default
		ip_dest_addr		  	=>	ip_dest_addr,			--: in  std_logic_vector(31 downto 0);
		mac_dest_addr		 	=>	mac_dest_addr,			--: in  std_logic_vector(47 downto 0);
      tx_dst_rdy  	 	  	=>	tx_dst_rdy, 			--: in  std_logic;    		-- Input destination ready 
		header_info	  			=>	header_user_info,		--: in  std_logic_vector(63 downto 0);
		FRAME_SIZE				=>	FRAME_SIZE,				--: in  std_logic_vector(11 downto 0);  -- 0x1f8
		TIME_OUT_wait			=>	TIME_OUT_wait,			--: in  std_logic_vector(31 downto 0);	
 		system_status			=>	system_status,			--: in  std_logic_vector(31 downto 0);	 
		tx_rdy					=>	tx_rdy,					--: IN STD_LOGIC;		
		tx_data_out      		=>	tx_data_out_HSD,			--: out std_logic_vector(7 downto 0);  -- Output data
      tx_eop_out       		=>	tx_eop_out_HSD,				--: out std_logic;                      -- Output end of frame
      tx_sop_out       		=>	tx_sop_out_HSD,				--: out std_logic;                     -- Output start of frame		
		tx_src_rdy  	  	   =>	tx_src_rdy_HSD,				--: out std_logic;                    -- source ready
		tx_write					=>	open				--: out std_logic                    -- source working

      );

	
TX_PING_inst : entity work.TX_PING
	port map
	(
	   clk         		  	=>	clk,						--: IN  std_logic;                     -- Input CLK from MAC Reciever
      reset			        	=>	reset,					--: IN  std_logic;                     -- Synchronous reset signal	

		BRD_IP					=>	BRD_IP,					--: IN 	STD_LOGIC_VECTOR(31 downto 0);
		BRD_MAC					=>	BRD_MAC,					--: IN 	STD_LOGIC_VECTOR(47 downto 0);

		ip_dest_addr		  	=>	ip_dest_addr,			--: IN  std_logic_vector(31 downto 0);
		mac_dest_addr		 	=>	mac_dest_addr,			--: in  std_logic_vector(47 downto 0);
		
		PING_ACK					=>	PING_ACK,				--: IN  std_logic;	
		PING_REQ_OUT			=>	PING_REQ_OUT,			--: OUT std_logic;		

		PING_EN					=>	PING_EN,					--: IN std_logic;	 
		PING_DATA				=>	PING_DATA,				--: IN std_logic;
				
		tx_rdy					=>	tx_rdy,					--: IN STD_LOGIC;		
		tx_data_out      		=>	tx_data_out_PING,		--: OUT  std_logic_vector(7 downto 0);  -- Output data
      tx_eop_out       		=>	tx_eop_out_PING,		--: OUT  std_logic;                      -- Output end of frame
      tx_sop_out       		=>	tx_sop_out_PING,		--: OUT  std_logic;                     -- Output start of frame		
		tx_src_rdy  	  	   =>	tx_src_rdy_PING		--: OUT  std_logic;                    -- source ready

      );	
	
			
process(clk,reset) 

  begin
     if (reset = '1') then
         state          <= idle;
         tx_data_out    <= (others => '0'); 
         tx_sop_out    	<= '0';
         tx_eop_out    	<= '0';
         tx_src_rdy     <= '0'; 

			REG_ACK			<= '0';
			FEMB_ACK			<= '0';			
			ARP_ACK			<= '0';
		   PING_ACK			<= '0';
			TX_HS_ACK		<= '0';

			
     elsif (clk'event AND clk = '1') then
        CASE state is
          when IDLE =>                
				REG_ACK		<= '0';
				FEMB_ACK		<= '0';			
				ARP_ACK		<= '0';
				PING_ACK		<= '0';
				TX_HS_ACK	<= '0';
				tx_sop_out  <= '0';
				tx_eop_out  <= '0';
				tx_src_rdy  <= '0'; 
				tx_data_out <= (others => '0'); 
				if (ARP_REQ_OUT = '1') then
					ARP_ACK			<= '1';
					state          <= S_ARP;
				elsif(REG_REQ_OUT = '1') then
					REG_ACK			<= '1';
					state          <= S_REG;
				elsif(FEMB_REQ_OUT = '1') then
					FEMB_ACK			<= '1';
					state          <= S_FEMB;					
				elsif(PING_REQ_OUT = '1') then
					PING_ACK			<= '1';
					state          <= S_PING;
				elsif(TX_HS_REQ_OUT = '1') then
					TX_HS_ACK		<= '1';	
					state          <= S_HS_DATA;
				else
					state          <= idle;
				end if;
			when  S_ARP =>  
				ARP_ACK		<= '0';
	         tx_data_out <= tx_data_out_ARP;
				tx_sop_out  <= tx_sop_out_ARP;
				tx_eop_out  <= tx_eop_out_ARP;
				tx_src_rdy  <= tx_src_rdy_ARP;
				if( ARP_REQ_OUT = '1') then
					state    	<= S_ARP;
				else
					state 		<= idle;
				end if;
			when  S_REG =>  
				REG_ACK		<= '0';
	         tx_data_out <= tx_data_out_REG;
				tx_sop_out  <= tx_sop_out_REG;
				tx_eop_out  <= tx_eop_out_REG;
				tx_src_rdy  <= tx_src_rdy_REG;
				if( REG_REQ_OUT= '1') then
					state    	<= S_REG;
				else
					state 		<= idle;
				end if;
				
			when  S_FEMB =>  
				FEMB_ACK		<= '0';
	         tx_data_out <= tx_data_out_FEMB;
				tx_sop_out  <= tx_sop_out_FEMB;
				tx_eop_out  <= tx_eop_out_FEMB;
				tx_src_rdy  <= tx_src_rdy_FEMB;
				if( FEMB_REQ_OUT= '1') then
					state    	<= S_FEMB;
				else
					state 		<= idle;
				end if;				

			when  S_PING =>  
				PING_ACK		<= '0';
	         tx_data_out <= tx_data_out_PING;
				tx_sop_out  <= tx_sop_out_PING;
				tx_eop_out  <= tx_eop_out_PING;	
				tx_src_rdy  <= tx_src_rdy_PING;
				if( PING_REQ_OUT = '1') then
					state    	<= S_PING;
				else
					state 		<= idle;
				end if;				
			when  S_HS_DATA =>  
				TX_HS_ACK	<= '0';
	         tx_data_out <= tx_data_out_HSD;	
				tx_sop_out  <= tx_sop_out_HSD;
				tx_eop_out  <= tx_eop_out_HSD;
				tx_src_rdy  <= tx_src_rdy_HSD;
				if( TX_HS_REQ_OUT = '1') then
					state    	<= S_HS_DATA;
				else
					state 		<= idle;
				end if;				
			when others =>
				state 		<= idle;
        end case;
     end if;
  end process;

END tx_frame_V2_arch;


