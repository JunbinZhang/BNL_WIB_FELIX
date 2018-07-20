--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: UPD_IO.vhd
--////                                                                                                                                      
--////  Author: Jack Fried                                        
--////          jfried@bnl.gov                
--////  Created:  03/22/2014
--////  Modified: 4/23/2013
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


ENTITY UDP_IO IS 
	PORT
	(
	
		reset 					: IN  STD_LOGIC;	
		
		CLK_125Mhz 				: IN  STD_LOGIC;
		CLK_50MHz		 		: IN  STD_LOGIC;
		CLK_IO					: IN  STD_LOGIC;		-- 100MHz
		
		SPF_OUT 					: IN  STD_LOGIC;
		SFP_IN 					: OUT STD_LOGIC;		
		
		START						: IN  STD_LOGIC;
		BRD_IP					: IN 	STD_LOGIC_VECTOR(31 downto 0);
		BRD_MAC					: IN 	STD_LOGIC_VECTOR(47 downto 0);

		EN_WR_RDBK				: IN  std_logic; 		-- enable register write readback option		
  		TIME_OUT_wait			: IN  STD_LOGIC_VECTOR(31 downto 0);
		FRAME_SIZE				: IN  std_logic_vector(11 downto 0);  -- 0x1f8


		tx_fifo_clk 			: IN  STD_LOGIC;
		tx_fifo_wr 				: IN  STD_LOGIC;
		tx_fifo_in 				: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		tx_fifo_full 			: OUT STD_LOGIC;		
		tx_fifo_used			: OUT STD_LOGIC_VECTOR(11 DOWNTO 0);	
		
		header_user_info	  	: IN  STD_LOGIC_VECTOR(63 downto 0);
 		system_status			: IN  STD_LOGIC_VECTOR(31 downto 0);	
		
		data 						: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		rdout 					: IN  STD_LOGIC_VECTOR(31 DOWNTO 0);	
		wr_strb 					: OUT STD_LOGIC;
		rd_strb 					: OUT STD_LOGIC;
		WR_address 				: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		RD_address 				: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);	
		RD_WR_ADDR_SEL			: OUT STD_LOGIC;		--   value = '1' when read req
	 
		FEMB_BRD					: OUT std_logic_vector(3 downto 0);		
		FEMB_RD_strb			: OUT STD_LOGIC;
		FEMB_WR_strb			: OUT STD_LOGIC;	
		FEMB_RDBK_strb			: IN  STD_LOGIC;
		FEMB_RDBK_DATA			: IN  STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END UDP_IO;

ARCHITECTURE bdf_type OF UDP_IO IS 


	component WIB_TSE is
		port (
			CLK              : in  std_logic                      := 'X';             -- CLK
			reset            : in  std_logic                      := 'X';             -- reset
			reg_data_out     : out std_logic_vector(31 downto 0);                     -- readdata
			reg_rd           : in  std_logic                      := 'X';             -- read
			reg_data_in      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
			reg_wr           : in  std_logic                      := 'X';             -- write
			reg_busy         : out std_logic;                                         -- waitrequest
			reg_addr         : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- address
			ff_rx_clk        : in  std_logic                      := 'X';             -- CLK
			ff_tx_clk        : in  std_logic                      := 'X';             -- clk
			ff_rx_data       : out std_logic_vector(7 downto 0);                      -- data
			ff_rx_eop        : out std_logic;                                         -- endofpacket
			rx_err           : out std_logic_vector(5 downto 0);                      -- error
			ff_rx_rdy        : in  std_logic                      := 'X';             -- ready
			ff_rx_sop        : out std_logic;                                         -- startofpacket
			ff_rx_dval       : out std_logic;                                         -- valid
			ff_tx_data       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- data
			ff_tx_eop        : in  std_logic                      := 'X';             -- endofpacket
			ff_tx_err        : in  std_logic                      := 'X';             -- error
			ff_tx_rdy        : out std_logic;                                         -- ready
			ff_tx_sop        : in  std_logic                      := 'X';             -- startofpacket
			ff_tx_wren       : in  std_logic                      := 'X';             -- valid
			xon_gen          : in  std_logic                      := 'X';             -- xon_gen
			xoff_gen         : in  std_logic                      := 'X';             -- xoff_gen
			magic_wakeup     : out std_logic;                                         -- magic_wakeup
			magic_sleep_n    : in  std_logic                      := 'X';             -- magic_sleep_n
			ff_tx_crc_fwd    : in  std_logic                      := 'X';             -- ff_tx_crc_fwd
			ff_tx_septy      : out std_logic;                                         -- ff_tx_septy
			tx_ff_uflow      : out std_logic;                                         -- tx_ff_uflow
			ff_tx_a_full     : out std_logic;                                         -- ff_tx_a_full
			ff_tx_a_empty    : out std_logic;                                         -- ff_tx_a_empty
			rx_err_stat      : out std_logic_vector(17 downto 0);                     -- rx_err_stat
			rx_frm_type      : out std_logic_vector(3 downto 0);                      -- rx_frm_type
			ff_rx_dsav       : out std_logic;                                         -- ff_rx_dsav
			ff_rx_a_full     : out std_logic;                                         -- ff_rx_a_full
			ff_rx_a_empty    : out std_logic;                                         -- ff_rx_a_empty
			ref_clk          : in  std_logic                      := 'X';             -- clk
			led_crs          : out std_logic;                                         -- crs
			led_link         : out std_logic;                                         -- link
			led_panel_link   : out std_logic;                                         -- panel_link
			led_col          : out std_logic;                                         -- col
			led_an           : out std_logic;                                         -- an
			led_char_err     : out std_logic;                                         -- char_err
			led_disp_err     : out std_logic;                                         -- disp_err
			rx_recovclkout   : out std_logic;                                         -- rx_recovclkout
			reconfig_togxb   : in  std_logic_vector(139 downto 0) := (others => 'X'); -- reconfig_togxb
			reconfig_fromgxb : out std_logic_vector(91 downto 0);                     -- reconfig_fromgxb
			rxp              : in  std_logic                      := 'X';             -- rxp
			txp              : out std_logic                                          -- txp
		);
	end component WIB_TSE;
	
	
	

SIGNAL	rd_strb_in 			: STD_LOGIC;
SIGNAL 	WR_strb_RESP		: STD_LOGIC;
SIGNAL	reg_addr 			: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	reg_bsy 				: STD_LOGIC;
SIGNAL	reg_data_in 		: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg_data_out 		: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg_rd 				: STD_LOGIC;
SIGNAL	reg_wr 				: STD_LOGIC;
SIGNAL	rx_data_in 			: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	rx_dval 				: STD_LOGIC;
SIGNAL	rx_eop 				: STD_LOGIC;
SIGNAL	rx_sop 				: STD_LOGIC;
SIGNAL	src_ip 				: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	src_mac 				: STD_LOGIC_VECTOR(47 DOWNTO 0);
SIGNAL	tx_eop 				: STD_LOGIC;
SIGNAL	tx_packet_data 	: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	tx_sop 				: STD_LOGIC;
SIGNAL	tx_wren 				: STD_LOGIC;
SIGNAL	tx_rdy				: STD_LOGIC;
SIGNAL	address_s			: STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	data_s		 		: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL   arp_req				: STD_LOGIC;
SIGNAL	arp_src_IP			: STD_LOGIC_VECTOR(31 downto 0);
SIGNAL	arp_src_MAC			: STD_LOGIC_VECTOR(47 downto 0);
SIGNAL   reg_RDOUT_num		: STD_LOGIC_VECTOR(3 downto 0);
SIGNAL	FEMB_BRD_r			: STD_LOGIC_VECTOR(3 downto 0);		

SIGNAL	PING_EN				: std_logic;	 
SIGNAL 	PING_DATA			: std_logic_vector(7 downto 0);

BEGIN 


WR_address 		<= address_s;
data				<= data_s;
reg_RDOUT_num	<= data_s(3 downto 0);
rd_strb 			<= rd_strb_in;
FEMB_BRD			<= FEMB_BRD_r;

mac_reg_cntl_inst : ENTITY WORK.mac_reg_cntl
PORT MAP(clk 				=> clk_50MHz,
		 reset 				=> reset,
		 start 				=> start,
		 reg_busy 			=> reg_bsy,
		 mac_addr 			=> BRD_MAC,
		 
		 reg_data_out 		=> reg_data_out,
		 reg_rd 				=> reg_rd,
		 reg_wr 				=> reg_wr,
		 reg_addr 			=> reg_addr,
		 reg_data_in 		=> reg_data_in);

		 
rx_frame_inst : ENTITY WORK.rx_frame
PORT MAP(clk 				=> CLK_IO,
		 reset 				=> reset,
		 BRD_IP				=> BRD_IP,
		 rx_dval 			=> rx_dval,
		 rx_eop 				=> rx_eop,
		 rx_sop 				=> rx_sop,
		 rx_data_in 		=> rx_data_in,
		 WR_strb 			=> wr_strb,
		 RD_strb 			=> RD_strb_in,
		 WR_strb_RESP		=> WR_strb_RESP,
		 IO_address 		=> address_s,
		 IO_data 			=> data_s,
		 src_IP 				=> src_ip,
		 src_MAC 			=> src_mac,
		 arp_req				=> arp_req,
 		 PING_EN				=>	PING_EN,
		 PING_DATA			=>	PING_DATA,
		 RD_WR_ADDR_SEL	=> RD_WR_ADDR_SEL,
		 FEMB_BRD			=> FEMB_BRD_r,
		 FEMB_RD_strb		=> FEMB_RD_strb,	
		 FEMB_WR_strb		=> FEMB_WR_strb 
		 );
		 

		
tx_frame_inst : ENTITY WORK.tx_frame_v2
PORT MAP(clk 				=> CLK_IO,
		 reset 				=> reset, 
		 BRD_IP				=> BRD_IP,
		 BRD_MAC				=> BRD_MAC,		
		 
  		 system_status		=> system_status, 
		 header_user_info	=> header_user_info, 		 
		 FRAME_SIZE			=> FRAME_SIZE,
		 UDP_HS_port		=> x"7d03",
		 tx_fifo_clk 		=> tx_fifo_clk,
		 tx_fifo_in 		=> tx_fifo_in,		 		 
		 tx_fifo_wr 		=> tx_fifo_wr,
		 tx_fifo_full 		=> tx_fifo_full,
		 tx_fifo_used		=> tx_fifo_used,		 
		 tx_dst_rdy			=> '1',		 
		 tx_rdy				=>	tx_rdy,
		 tx_data_out 		=> tx_packet_data,		 
		 tx_eop_out 		=> tx_eop,
		 tx_sop_out 		=> tx_sop,
		 tx_src_rdy 		=> tx_wren,		 


		 ip_dest_addr 		=> src_ip,
		 mac_dest_addr 	=> src_mac,
		 
		 EN_WR_RDBK			=> EN_WR_RDBK,
		 WR_data				=> data_s,	
		 reg_wr_strb		=>	WR_strb_RESP,	
		
		 reg_rd_strb 		=> RD_strb_in,		 
		 reg_start_address 	=> address_s,
		 reg_RDOUT_num		=> reg_RDOUT_num,
		 reg_address		=> RD_address,
		 reg_data 			=> rdout,

		 FEMB_BRD			=> FEMB_BRD_r,
		 FEMB_RDBK_strb	=> FEMB_RDBK_strb,
		 FEMB_RDBK_DATA	=> FEMB_RDBK_DATA,
 
		 TIME_OUT_wait		=> TIME_OUT_wait,
		 PING_EN				=>	PING_EN,
		 PING_DATA			=>	PING_DATA,		 
		 arp_req				=> arp_req);
		 
		 
WIB_TSE_inst : WIB_TSE
PORT MAP(
		 ff_tx_data 		=> tx_packet_data,
		 ff_tx_eop 			=> tx_eop,
		 ff_tx_err 			=> '0',
		 ff_tx_sop 			=> tx_sop,
		 ff_tx_wren 		=> tx_wren,
		 ff_tx_clk 			=> CLK_IO,
		 ff_rx_rdy 			=> '1',
		 ff_rx_clk 			=> CLK_IO,
		 reg_addr 			=> reg_addr,
		 reg_rd 				=> reg_rd,
		 reg_data_in		=> reg_data_in,
		 reg_wr 				=> reg_wr,
		 clk 					=> clk_50MHz,
		 reset 				=> reset,
		 rxp 					=> SPF_OUT,
		 ref_clk 			=> clk_125Mhz,
		 ff_tx_crc_fwd 	=> '0',
		 ff_tx_rdy 			=> tx_rdy,
		 ff_rx_data 		=> rx_data_in,
		 ff_rx_dval 		=> rx_dval,
		 ff_rx_eop 			=> rx_eop,
		 ff_rx_sop 			=> rx_sop,
		 rx_err 				=> open,
		 reg_data_out 		=> reg_data_out,
		 reg_busy 			=> reg_bsy,
		 led_an 				=> open,
		 led_char_err 		=> open,
		 led_link 			=> open,
		 led_disp_err 		=> open,	 
		 txp 					=> SFP_IN,
		 rx_recovclkout 	=> open,	 
		 ff_tx_septy 		=> open,
		 tx_ff_uflow 		=> open,
		 ff_tx_a_full 		=> open,
		 ff_tx_a_empty 	=> open,		 
		 rx_err_stat 		=> open,
		 rx_frm_type 		=> open,		 
		 ff_rx_dsav 		=> open,
		 ff_rx_a_full 		=> open,
		 ff_rx_a_empty 	=> open,
		 reconfig_togxb	=> (others => 'X'),		 
		 reconfig_fromgxb	=> open 
		 
		 );

		
	 
END bdf_type;