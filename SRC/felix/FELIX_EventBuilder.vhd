library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
USE work.SbndPkg.all;

entity FELIX_EventBuilder is
	PORT
	(
	
			RESET						: IN STD_LOGIC;	
			--SYS_CLK					: IN STD_LOGIC;
			Stream_EN 				: IN STD_LOGIC;
			LINK_DISABLE			: IN  std_logic_vector(15 downto 0);

			tx_serial_data       : out std_logic_vector(1 downto 0);--remapped
			tx_pll_refclk        : in  std_logic; -- tx_pll_refclk
			pll_locked           : out std_logic_vector(1 downto 0);--remapped
			tx_analogreset_EN    : in  std_logic;
			tx_digitalreset_EN   : in  std_logic;
			pll_powerdown_EN		: in  std_logic;
				
			FEMB_EOF					: IN std_logic_vector(15 downto 0);			
			RX_FF_DATA				: IN SL_ARRAY_15_TO_0(0 to 15);
			RX_FF_EMPTY				: IN std_logic_vector(15 downto 0);			
			RX_FF_RDREQ				: OUT std_logic_vector(15 downto 0);
			RX_FF_RST				: OUT std_logic_vector(15 downto 0);
			RX_FF_CLK				: OUT STD_LOGIC_vector(15 downto 0);
			-----------probe signals---------------
			probe                : out std_logic_vector(15 downto 0);
			--------add messages---------------------
			TIME_STAMP_ev        : IN SL_ARRAY_15_TO_0(0 to 15);     -- sync to RX_FF_CLK
			CAPTURE_ERROR_ev     : IN SL_ARRAY_15_TO_0(0 to 15);     -- sync to RX_FF_CLK
			CD_ERROR_ev          : IN SL_ARRAY_15_TO_0(0 to 15)      -- sync to RX_FF_CLK
			----------------------------------------------------------------------------		
	);
end FELIX_EventBuilder;



architecture FELIX_EventBuilder_arch of FELIX_EventBuilder is

	------------------------------------------------------
	--components-------
	------------------------------------------------------
	 component FELIX_PCS is
    generic (
      TX_COUNT   : integer;
      WORD_WIDTH : integer);
    port (
      reset           : in  std_logic;
      pll_powerdown   : in  std_logic_vector(TX_COUNT - 1 downto 0); --powerdown
      tx_analogreset  : in  std_logic_vector(TX_COUNT - 1 downto 0); --analog reset
      tx_digitalreset : in  std_logic_vector(TX_COUNT - 1 downto 0); --digital reset
      tx_refclk       : in  std_logic;                               --reference clock
      pll_locked      : out std_logic_vector(TX_COUNT - 1 downto 0); --pll locked
      tx              : out std_logic_vector(TX_COUNT - 1 downto 0); --tx out
      tx_clkout       : out std_logic_vector(TX_COUNT - 1 downto 0); --Note:tx_std_clockout modified by Junbin
      data_wr         : in  std_logic_Vector(TX_COUNT -1 downto 0);  --"constant 11"
      k_data          : in  std_logic_vector(TX_COUNT*WORD_WIDTH - 1 downto 0);
      data            : in  std_logic_vector(TX_COUNT*WORD_WIDTH * 8 - 1 downto 0));
    end component FELIX_PCS;


	SIGNAL	pll_powerdown					: std_logic_vector(1 downto 0); -- pll_powerdown remapped
	SIGNAL	tx_analogreset 				: std_logic_vector(1 downto 0); -- tx_analogreset remapped
	SIGNAL	tx_digitalreset 				: std_logic_vector(1 downto 0); -- tx_digitalreset remapped
	SIGNAL	tx_std_clkout					: std_logic_vector(1 downto 0); -- tx_std_clkout


	SIGNAL   tx_parallel_data           : std_logic_vector(127 downto 0);
	SIGNAL   tx_parallel_k_data         : std_logic_vector(15 downto 0);

	begin
		
		
	pll_powerdown			<=	"11" when (pll_powerdown_EN   = '1') else "00";
	tx_analogreset			<=	"11" when (tx_analogreset_EN  = '1') else "00";
	tx_digitalreset		<=	"11" when (tx_digitalreset_EN = '1') else "00";
 
	
	ProtoDUNE_PACK: for i in 0 to 1 generate
	FELIX_EventBuilder_Link_inst: entity work.FELIX_EventBuilder_Link
	port map
	(
		RESET					=> RESET,	
		clk_tx				=> tx_std_clkout(i),--clock from FELIX_PCS
		Stream_EN 			=> Stream_EN,
		
		LINK_DISABLE		=> LINK_DISABLE(i*8+7 downto i*8), --one link collects data from 8 tx links from FEMBs
		
		FEMB_EOF				=> FEMB_EOF(i*8+7 downto i*8),	--sync to RX_FF_CLK		
		RX_FF_DATA			=> RX_FF_DATA(i*8 to i*8+7 ),
		RX_FF_EMPTY			=> RX_FF_EMPTY(i*8+7 downto i*8),			
		RX_FF_RDREQ			=> RX_FF_RDREQ(i*8+7 downto i*8),
		RX_FF_RST			=> RX_FF_RST(i*8+7 downto i*8),
		RX_FF_CLK			=> RX_FF_CLK(i*8+7 downto i*8),
		
		TIME_STAMP_ev     => TIME_STAMP_ev(i*8 to i*8+7),        -- sync to RX_FF_CLK
		CAPTURE_ERROR_ev  => CAPTURE_ERROR_ev(i*8 to i*8+7),     -- sync to RX_FF_CLK
		CD_ERROR_ev       => CD_ERROR_ev(i*8 to i*8+7),          -- sync to RX_FF_CLK
		
		slot_No           => "111",
		crate_No          => "11111",
		fiber_No          => std_logic_vector(to_unsigned(i+1,3)),
		version_No        => "00001",
		--------------probe interface----------------
		probe             => probe(i*8+7 downto i*8),
		--------------FELIX_PCS interface----------------------
		data_out          => tx_parallel_data(i*64+63 downto i*64),
		data_k_out        => tx_parallel_k_data(i*8+7 downto i*8)  		
	);
	end generate;
	
	FELIX_PCS_inst: FELIX_PCS
	generic map(
      TX_COUNT   => 2,
      WORD_WIDTH => 8)
	port map
	(
      reset           => '0',            --pcs reset?
      pll_powerdown   => pll_powerdown,   --pll powerdown
      tx_analogreset  => tx_analogreset,  --analog reset
      tx_digitalreset => tx_digitalreset, --digital reset
      tx_refclk       => tx_pll_refclk,   --reference clock 120.234MHz
      pll_locked      => pll_locked,      --pll locked
      tx              => tx_serial_data,  --tx out
      tx_clkout       => tx_std_clkout,   --Note:tx_std_clockout modified by Junbin
      data_wr         => "11",
      k_data          => tx_parallel_k_data,
      data            => tx_parallel_data		
	);
	

end FELIX_EventBuilder_arch;