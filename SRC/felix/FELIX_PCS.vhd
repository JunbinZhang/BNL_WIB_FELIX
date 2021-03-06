library IEEE;
use IEEE.std_logic_1164.all;
use work.types.all;


entity FELIX_PCS is
  generic (
    TX_COUNT   : integer := 2;
    WORD_WIDTH : integer := 8);
  port (
    reset           : in  std_logic;
    pll_powerdown   : in  std_logic_vector(TX_COUNT - 1 downto 0);
    tx_analogreset  : in  std_logic_vector(TX_COUNT - 1 downto 0);
    tx_digitalreset : in  std_logic_vector(TX_COUNT - 1 downto 0);
    tx_refclk       : in  std_logic;
    pll_locked      : out std_logic_vector(TX_COUNT - 1 downto 0);
    tx              : out std_logic_vector(TX_COUNT - 1 downto 0);
	 --clk_data        : out std_logic;    
    tx_clkout       : out std_logic_vector(TX_COUNT - 1 downto 0);--modified by junbin
    data_wr         : in  std_logic_Vector(TX_COUNT -1 downto 0);
    k_data          : in  std_logic_vector(TX_COUNT*WORD_WIDTH     - 1 downto 0);
    data            : in  std_logic_vector(TX_COUNT*WORD_WIDTH * 8 - 1 downto 0)  
    );
end entity FELIX_PCS;  

architecture behavioral of FELIX_PCS is

  COMPONENT encoder_8b10b
    GENERIC ( METHOD : INTEGER := 1 );
    PORT
      (
        clk		:	 IN STD_LOGIC;
        rst		:	 IN STD_LOGIC;
        kin_ena		:	 IN STD_LOGIC;
        ein_ena		:	 IN STD_LOGIC;
        ein_dat		:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        ein_rd		:	 IN STD_LOGIC;
        eout_val		:	 OUT STD_LOGIC;
        eout_dat		:	 OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        eout_rdcomb		:	 OUT STD_LOGIC;
        eout_rdreg		:	 OUT STD_LOGIC
	);
  END COMPONENT;
  
  component FELIX_LINK is
    port (
      pll_powerdown        : in  std_logic_vector(1 downto 0)   := (others => '0');     
      tx_analogreset       : in  std_logic_vector(1 downto 0)   := (others => '0');
      tx_digitalreset      : in  std_logic_vector(1 downto 0)   := (others => '0');
      tx_pll_refclk        : in  std_logic_vector(0 downto 0)   := (others => '0');
      tx_pma_clkout        : out std_logic_vector(1 downto 0);
      tx_serial_data       : out std_logic_vector(1 downto 0);
      tx_pma_parallel_data : in  std_logic_vector(159 downto 0) := (others => '0');
      pll_locked           : out std_logic_vector(1 downto 0);
      tx_cal_busy          : out std_logic_vector(1 downto 0);
      reconfig_to_xcvr     : in  std_logic_vector(279 downto 0) := (others => '0');
      reconfig_from_xcvr   : out std_logic_vector(183 downto 0));
  end component FELIX_LINK;


  signal clk_pcs        : std_logic_vector(1 downto 0);
  signal rdisp_in       : uint8_array_t(TX_COUNT - 1 downto 0) := (others => (others => '0'));
  signal valid_10b      : uint8_array_t(TX_COUNT - 1 downto 0) := (others => (others => '0'));
  signal rdisp_out_comb : uint8_array_t(TX_COUNT - 1 downto 0) := (others => (others => '0'));
  signal rdisp_out_reg  : uint8_array_t(TX_COUNT - 1 downto 0) := (others => (others => '0'));
  type link_10b_array_t is array (TX_COUNT -1 downto 0) of uint10_array_t(WORD_WIDTH - 1 downto 0);
  signal data_10b : link_10b_array_t := (others => (others => (others => '0')));  
  signal pma_parallel_data : std_logic_vector(TX_COUNT*WORD_WIDTH*10 -1 downto 0) := (others => '0');

  
begin  -- architecture behavioral
  --clk_data <= clk_pcs(0);
  tx_clkout <= clk_pcs; --modified by Junbin



  LINK_loop: for iLink in TX_COUNT - 1 downto 0 generate
    --Build the 8b to 10b parallel encoders for this channel
    encoder_chain: for iEnc in WORD_WIDTH - 1 downto 0 generate
      -- assumes LSB out first on PMA
      
      --Registered disparity from the last clock
      rdisp_in(iLink)(0) <= rdisp_out_reg(iLink)(WORD_WIDTH - 1);
      --Un-registered disparity from the 8b10b encoder previous in line
      rdisp_in(iLink)(WORD_WIDTH - 1 downto 1) <= rdisp_out_comb(iLink)(WORD_WIDTH - 2 downto 0);
      encoder_8b10b_ch0: encoder_8b10b
        generic map (
          METHOD => 1)
        port map (
          --clk         => clk_pcs(0),
			 clk         => clk_pcs(iLink), --modified by junbin
          rst         => reset,
          kin_ena     => k_data((iLink*WORD_WIDTH)+iEnc),
          ein_ena     => data_wr(iLink),
          ein_dat     => data( (iLink*WORD_WIDTH + iEnc+1)*8 -1 downto  (iLink*WORD_WIDTH + iEnc)*8),
          ein_rd      => rdisp_in(iLink)(iEnc),
          eout_val    => valid_10b(iLink)(iEnc),
          eout_dat    => data_10b(iLink)(iEnc),
          eout_rdcomb => rdisp_out_comb(iLink)(iEnc),
          eout_rdreg  => rdisp_out_reg(iLink)(iEnc));

      -- re-arrange into the PMA's input data format
      pma_parallel_data(iLink*80 + iEnc*10 + 9 downto iLink*80 + iEnc*10) <= data_10b(iLink)(iEnc);      
    end generate encoder_chain;       
  end generate LINK_loop;



  FELIX_LINK_1: FELIX_LINK
    port map (
      pll_powerdown        => pll_powerdown,
      tx_analogreset       => tx_analogreset,
      tx_digitalreset      => tx_digitalreset,
      tx_pll_refclk(0)     => tx_refclk,
      tx_pma_clkout        => clk_pcs,
      tx_serial_data       => tx,
      tx_pma_parallel_data => pma_parallel_data,
      pll_locked           => pll_locked,
      tx_cal_busy          => open,
      reconfig_to_xcvr     => (others => 'X'),
      reconfig_from_xcvr   => open);
  
end architecture behavioral;
