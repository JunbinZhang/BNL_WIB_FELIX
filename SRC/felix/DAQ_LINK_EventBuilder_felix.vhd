library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;
use work.WIB_Constants.all;
use work.Convert_IO.all;
use work.EB_IO.all;
use work.COLDATA_IO.all;
use work.types.all;
use work.Gearbox_constants.all;
use work.GB_IO.all;
use work.WIB_IO.all;
use work.CD_EB_BRIDGE.all;

entity DAQ_Link_EventBuilder_felix is
  generic (
    OUTPUT_BYTE_COUNT : integer := 8;
    FIBER_ID   : integer := 1
    );
  port (
    clk        : in  std_logic;
    clk240     : in  std_logic; --modified by junbin
    reset      : in  std_logic;
    WIB_ID     : in  WIB_ID_t;
    convert    : in  convert_t;
    CD_stream  : in  CD_stream_array_t(CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0);
    CD_read    : out std_logic_vector( CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto  0);
    data_out   : out std_logic_vector((8*OUTPUT_BYTE_COUNT)-1 downto  0);
    data_k_out : out std_logic_vector(OUTPUT_BYTE_COUNT - 1 downto  0);   
    -----------------------------------------------------------------------------------------
    monitor    : out DAQ_Link_EB_Monitor_t;
    control    : in  DAQ_Link_EB_Control_t
    );

end entity DAQ_Link_EventBuilder_felix;

architecture behavioral of DAQ_Link_EventBuilder_felix is

  
 -- component CRCD64_RCE is
 --   port (
 --     clk     : in  STD_LOGIC;
 --     init    : in  STD_LOGIC;
 --     ce      : in  STD_LOGIC;
 --     d       : in  STD_LOGIC_VECTOR (63 downto 0);
 --     crc     : out STD_LOGIC_VECTOR (31 downto 0);
 --     bad_crc : out STD_LOGIC);
 -- end component CRCD64_RCE;
 -- component CRCD64_FELIX is
 --   port (
 --     clk     : in  STD_LOGIC;
 --     init    : in  STD_LOGIC;
 --     ce      : in  STD_LOGIC;
 --     d       : in  STD_LOGIC_VECTOR (63 downto 0);
 --     crc     : out STD_LOGIC_VECTOR (19 downto 0));
 -- end component CRCD64_FELIX;

 -- component RCE_SPY_BUFFER is
 --   port (
 --     data    : IN  STD_LOGIC_VECTOR (71 DOWNTO 0);
 --     rdclk   : IN  STD_LOGIC;
 --     rdreq   : IN  STD_LOGIC;
 --     wrclk   : IN  STD_LOGIC;
 --     wrreq   : IN  STD_LOGIC;
 --     q       : OUT STD_LOGIC_VECTOR (35 DOWNTO 0);
 --     rdempty : OUT STD_LOGIC;
 --     wrfull  : OUT STD_LOGIC);
 -- end component RCE_SPY_BUFFER;

 -- component Gearbox is
 --   generic (
 --     DEFAULT_WORDS : std_logic_vector(BYTES_PER_WORD + (BYTES_PER_WORD * BITS_PER_BYTE)-1 downto 0));
 --   port (
 --     clk                  : in  std_logic;
 --     reset                : in  std_logic;
 --     data_in              : in  std_logic_vector(((WORD_COUNT + EXTRA_WORD_COUNT)*BYTES_PER_WORD * BITS_PER_BYTE) - 1 downto 0);
 --     data_in_count        : in  std_logic_vector(7 downto 0);
 --     data_out             : out std_logic_vector((WORD_COUNT *BYTES_PER_WORD * BITS_PER_BYTE) -1 downto 0);
 --     special_word_request : out std_logic_vector(7 downto 0); --combinatorical
 --     monitor              : out GB_Monitor_t;
 --     control              : in  GB_Control_t);
 -- end component Gearbox;
 --
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
      data    : IN  STD_LOGIC_VECTOR (71 DOWNTO 0);
      wrclk   : IN  STD_LOGIC;
      wrreq   : IN  STD_LOGIC;
      wrfull  : OUT STD_LOGIC;

      rdclk   : IN  STD_LOGIC;
      rdreq   : IN  STD_LOGIC;
      rdempty : OUT STD_LOGIC;
      q       : OUT STD_LOGIC_VECTOR (35 DOWNTO 0)
      );
  end component wib_event_fifo;
  component counter is
    generic (
      roll_over   : std_logic;
      end_value   : std_logic_vector;
      start_value : std_logic_vector;
      DATA_WIDTH  : integer);
    port (
      clk         : in  std_logic;
      reset_async : in  std_logic;
      reset_sync  : in  std_logic;
      enable      : in  std_logic;
      event       : in  std_logic;
      count       : out std_logic_vector(DATA_WIDTH-1 downto 0);
      at_max      : out std_logic);
  end component counter;

  component timed_counter is
    generic (
      timer_count : std_logic_vector;
      DATA_WIDTH  : integer);
    port (
      clk          : in  std_logic;
      reset_async  : in  std_logic;
      reset_sync   : in  std_logic;
      enable       : in  std_logic;
      event        : in  std_logic;
      update_pulse : out std_logic;
      timed_count  : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component timed_counter;
 -- 
 -- constant RCE_IDLE_2 : std_logic_vector(7 downto 0) := x"5C";
 -- constant RCE_IDLE_1 : std_logic_vector(7 downto 0) := x"3C";
 -- constant FELIX_IDLE : std_logic_vector(7 downto 0) := x"BC";
 -- signal   IDLE : std_logic_vector(17 downto 0);
 -- constant RCE_SOP : std_logic_vector(7 downto 0) := x"BC";
 -- constant FELIX_SOP : std_logic_vector(7 downto 0) := x"3C";
 -- constant FELIX_EOP : std_logic_vector(7 downto 0) := x"DC";
  
  -------------------------------------------------------------------------------
  -- state machine
  -------------------------------------------------------------------------------
 -- type EB_state_t is (EB_STATE_INIT_WAIT,  -- init state
 --                     EB_STATE_NEW_FRAME,  -- starting a new frame
 --                     EB_STATE_SKIP_WORD,  -- skip a word write for the gearbox
 --                     EB_STATE_EXTRA_IDLE, 
 --                     EB_STATE_IDLE_PATTERN, --an extra idle pattern for FELIX
 --                     EB_STATE_SEND_HEADER_2,
 --                     
 --                     EB_STATE_CD_HEADER,
 --                     EB_STATE_CD_DATA,
 --                     
 --                     EB_STATE_CRC_WAIT              -- CRC Engine's pipeline delay
 --                     );
  type EB_state_t is (EB_STATE_INIT_WAIT,  -- init state
                      EB_STATE_NEW_FRAME,  -- starting a new frame
                     -- EB_STATE_SKIP_WORD,  -- skip a word write for the gearbox
                      EB_STATE_EXTRA_IDLE, 
                     -- EB_STATE_IDLE_PATTERN, --an extra idle pattern for FELIX
                     -- EB_STATE_SEND_HEADER_2,
                      EB_STATE_WIB_HEADER,
                      EB_STATE_CD_HEADER,
                      EB_STATE_CD_DATA,
                      EB_STATE_IDLE_1,
                      EB_STATE_IDLE_2
                      --EB_STATE_CRC_WAIT              -- CRC Engine's pipeline delay
                      );
  signal EB_state             : EB_state_t                   := EB_STATE_INIT_WAIT;

  signal dtype_1 : std_logic_vector(1 downto 0) := (0 => '1',1 => '1');
  signal dtype_0 : std_logic_vector(1 downto 0) := (0 => '1',1 => '1');
  signal data_1  : std_logic_vector(31 downto 0) := x"DEADBEEF";
  signal data_0  : std_logic_vector(31 downto 0) := x"DEADBEEF";
  signal data_in : std_logic_vector(71 downto 0) := (others => '0');
  signal data_wr : std_logic:='0';
  -----------fifo interface--------
  signal fifo_full : std_logic := '0';
  signal fifo_data_out : std_logic_vector(35 downto 0):=(others => '0');
  signal fifo_rclk  :std_logic;  --modified by junbin
  signal fifo_re    :std_logic;  --modified by junbin
  signal fifo_data  :std_logic_vector(31 downto 0); --modified by junbin
  signal fifo_dtype :std_logic_vector(1 downto 0);  --modified by junbin
  signal fifo_empty :std_logic; --modified by junbin
  signal fifo_busy  :std_logic :='0'; --modified by junbin

 -- --Value keeping track of which CDA we are on
  signal CDA_readout_start : std_logic_vector(CDAS_PER_DAQ_LINK * 2 - 1 downto 0) := (0 => '1',1 => '1',others => '0');
  signal CDA_readout_end   : std_logic_vector(CDAS_PER_DAQ_LINK * 2 - 1 downto 0) := (others => '0');
  signal CDA_readout       : std_logic_vector(CDAS_PER_DAQ_LINK * 2 - 1 downto 0) := CDA_readout_start;
 
  signal EB_CD_read    : std_logic_vector( CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto  0) := (others => '0');
  signal debug_CD_read : std_logic_vector( CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto  0) := (others => '0');
  signal iCDA : integer := 0;
 -- 
 -- ---constant DAQ_SOF            : std_logic_vector(7 downto 0) := RCE_SOP when CDAS_PER_DAQ_LINK = 2 else FELIX_SOP;--x"BC";
 -- signal DAQ_SOF              : std_logic_vector(7 downto 0) ;
 -- constant ERR_ALIGNMENT      : integer                      := 8;
 -- constant ERR_CD_CAPTURE     : integer                      := 0;
 -- constant ERR_CD_DATA_ERRORS : integer                      := 4;
 -- 
 -- -------------------------------------------------------------------------------
 -- -- counter increment signals
 -- -------------------------------------------------------------------------------
 signal new_event : std_logic := '0';

 signal timestamp_mismatch : std_logic := '0';

 signal error_repeated_timestamp : std_logic;
 -- -------------------------------------------------------------------------------
 -- --remappings
 -- -------------------------------------------------------------------------------
  signal frame_valid          : std_logic_vector(CDAS_PER_DAQ_LINK*LINKS_PER_CDA-1 downto 0) := (others => '0');
  signal stream_convert_count : uint16_array_t(0 to CDAS_PER_FEMB-1)        := (others => (others => '0'));

 -- -------------------------------------------------------------------------------
 -- -- other signals
 -- -------------------------------------------------------------------------------
 -- type DAQ_word_array_t is array (integer range <>) of std_logic_vector(BYTES_PER_WORD*8-1 downto 0);
 -- signal event_data_8b         : DAQ_word_array_t(WORD_COUNT + EXTRA_WORD_COUNT -1 downto 0);
 -- signal event_data_k_8b       : std_logic_vector(BYTES_PER_WORD * (WORD_COUNT + EXTRA_WORD_COUNT) -1 downto 0) := (others => '1');
 -- signal event_data_8b_delay   : DAQ_word_array_t(WORD_COUNT + EXTRA_WORD_COUNT -1 downto 0);
 -- signal event_data_k_8b_delay : std_logic_vector(BYTES_PER_WORD * (WORD_COUNT + EXTRA_WORD_COUNT) -1 downto 0) := (others => '1');
 -- signal event_data_count       : std_logic_vector(7 downto 0)  := x"04";
 -- signal event_data_count_delay : std_logic_vector(7 downto 0)  := x"04";

 signal last_timestamp : std_logic_vector(63 downto 0);
 -- 
 -- signal debug_mode_data : std_logic_vector(63 downto 0) := x"00030002000100bc";
 -- 
 -- signal crc_input_data : std_logic_vector(63 downto 0) := (others => '0');
 -- 
 -- signal CD_odd_data_words : std_logic_vector(15 downto 0) := (others => '0');
 -- 
 -- signal header_errors       : std_logic_vector(15 downto 0) := x"0000";
 -- signal header_fiber_number : std_logic_vector(1 downto 0)  := "00";
 -- signal header_slot_number  : std_logic_vector(2 downto 0)  := "000";
 -- signal header_crate_number : std_logic_vector(4 downto 0)  := "00000";

 -- constant CDA_FIFO_START : integer range 1 to to_integer(ADDR_DATA_END/4) := to_integer(ADDR_DATA_END/4);
 -- signal CDA_send_counter : integer range 1 to to_integer(ADDR_DATA_END/4) := CDA_FIFO_START;
 -- constant CD_DATA_WORD_COUNT : integer := 14;
 --signal iCD_data_word_count : integer range 1 to CD_DATA_WORD_COUNT := 1;
 signal iCD_data_word_count : integer := 1;
 -- 
 -- signal empty_line_request : std_logic := '0';
 -- 


 signal monitor_buffer : DAQ_Link_EB_Monitor_t;

 -- signal gearbox_input  : std_logic_vector((WORD_COUNT+EXTRA_WORD_COUNT)*BYTES_PER_WORD*BITS_PER_BYTE - 1 downto 0);
 -- signal gearbox_output : std_logic_vector(WORD_COUNT*BYTES_PER_WORD*BITS_PER_BYTE - 1 downto 0);
 -- signal gearbox_output_buffer : std_logic_vector(WORD_COUNT*BYTES_PER_WORD*BITS_PER_BYTE - 1 downto 0);
 -- signal gearbox_output_buffer2 : std_logic_vector(WORD_COUNT*BYTES_PER_WORD*BITS_PER_BYTE - 1 downto 0);
 -- signal special_word_request : std_logic_vector(7 downto 0) := x"00";

 -- -------------------------------------------------------------------------------
 -- -- spy buffer signals
 -- -------------------------------------------------------------------------------
 type spy_buffer_state_t is (SPY_BUFFER_STATE_IDLE,
                             SPY_BUFFER_STATE_WAIT,
                             SPY_BUFFER_STATE_CAPTURE);
 signal spy_buffer_state : spy_buffer_state_t := SPY_BUFFER_STATE_IDLE;
 -- signal spy_buffer_write_enable : std_logic := '0';
 -- signal spy_buffer_write_enable_buffer : std_logic := '0';
 -- signal spy_buffer_full : std_logic := '0';
 -- signal spy_buffer_write : std_logic := '0';
 -- -------------------------------------------------------------------------------
 -- -- crc signals
 -- -------------------------------------------------------------------------------
 -- signal data_crc    : std_logic_vector(31 downto 0) := (others => '1');
 -- signal crc_reset   : std_logic                     := '1';
 -- signal crc_process : std_logic                     := '0';
 -- signal bad_crc     : std_logic                     := '0';
 -- signal crc_bytes : std_logic_vector(1 downto 0) := "00";
  signal bad_crc_masked_value : std_logic_vector(15 downto 0) := (others => '0');
 -- 
  signal convert_info : convert_t;


-----------------------------------------------------------------------------------------------------------------
begin
  monitor_buffer.FEMB_mask <= (FIBER_ID*(FEMB_COUNT/DAQ_LINK_COUNT) - 1 downto (FIBER_ID-1)*(FEMB_COUNT/DAQ_LINK_COUNT) => '1', others => '0');

  monitor_buffer.enable   <= control.enable;
  monitor_buffer.crate_id <= WIB_ID.crate;
  monitor_buffer.slot_id <= WIB_ID.slot;
  monitor_buffer.debug <= control.debug;
  monitor_buffer.enable_bad_crc  <= control.enable_bad_crc;
  
  monitor_buffer.fiber_number <= std_logic_vector(to_unsigned(FIBER_ID, 2));
  monitor_buffer.COLDATA_en   <= control.COLDATA_en;

  -- re-mapping variables
  FEMBLinks : for iLink in 0 to CDAS_PER_DAQ_LINK*LINKS_PER_CDA-1 generate
    frame_valid(iLink) <= CD_stream(iLink).valid;
  end generate FEMBLinks;
  CDLinks : for iCD in 0 to CDAS_PER_FEMB-1 generate --iCD = 0 -> 1
    stream_convert_count(iCD)(7 downto 0)  <= CD_stream(iCD*LINKS_PER_CDA + 0).CD_timestamp(7 downto 0);
    stream_convert_count(iCD)(15 downto 8) <= CD_stream(iCD*LINKS_PER_CDA + 1).CD_timestamp(15 downto 8);
  end generate CDLinks;

  bad_crc_masked_value <= control.bad_crc_bits and std_logic_vector(monitor_buffer.event_count(15 downto 0));


  monitor_buffer.CD_readout_debug <= control.CD_readout_debug;
  cd_readout_switch: process (control.CD_readout_debug) is
  begin  -- process cd_readout_switch
    if control.CD_readout_debug = '0' then
      cd_read <= EB_CD_read;
    else
      cd_read <= debug_CD_read;
    end if;
  end process cd_readout_switch;
  
  readout_debug: process (clk, reset) is
  begin  -- process readout_debug
    if reset = '1' then                 -- asynchronous reset (active high)
      
    elsif clk'event and clk = '1' then  -- rising clock edge
      debug_CD_read <= (others => '0');
      if control.CD_readout_debug = '1' then
        if (frame_valid = control.COLDATA_en) then
          debug_CD_read <= (others => '1');
        end if;
      end if;
    end if;
  end process readout_debug;

  data_in <= "00" & dtype_1 & data_1 & "00" & dtype_0 & data_0; --modified by junbin 
  fifo_busy <= '0';
  fifo_data <= fifo_data_out(31 downto 0);
  fifo_dtype <= fifo_data_out(33 downto 32);
  -----------fsm for new event builder-----------
  Event: process (clk, reset)
  begin
    if reset = '1' then
        EB_state <= EB_STATE_INIT_WAIT;
        dtype_0 <= "11";
        dtype_1 <= "11";
        data_0  <= x"DEADBEEF";
        data_1  <= x"DEADBEEF";
        data_wr <= '0';
        new_event <= '0';
        error_repeated_timestamp <= '0';
        EB_CD_read <= "00000000"; --disable all cd_read
    elsif clk'event and clk = '1' then
        --The case statement checks the value of the state variable
        case EB_state is
            when EB_STATE_INIT_WAIT =>
                new_event <= '0';
					 iCDA <= 0;
					 CDA_readout <= CDA_readout_start; --new added
                if (((frame_valid = control.COLDATA_en) and (or_reduce(control.COLDATA_en) = '1')) or control.debug = '1') then
                    EB_state <= EB_STATE_NEW_FRAME;
                else
                    EB_state <= EB_STATE_INIT_WAIT;
                end if;
            when EB_STATE_NEW_FRAME =>
					 --normal operation	
					 new_event <= '1'; 
					 convert_info <= convert; --cache the info about this trigger
					 data_wr <= '1';
					 dtype_0 <= "01"; --sop
					 dtype_1 <= "00";
					 ---data_0----
					 data_0(31 downto 24)  <= "00000000";
					 data_0(23 downto 21)  <= WIB_ID.slot(2 downto 0);
					 data_0(20 downto 16)  <= WIB_ID.crate & WIB_ID.slot(3);
					 data_0(15 downto 13)  <= std_logic_vector(to_unsigned(FIBER_ID,3));
					 data_0(12 downto 8)   <= DAQ_LINK_VERSION_NUMBER;
					 data_0(7 downto 0 )   <= "00000000";
					 ---data_1----
					 data_1(15 downto 2)   <= "00000000000000";
					 data_1(1)             <= convert_info.out_of_sync;
					 if((CD_stream(0).CD_timestamp = CD_stream(1).CD_timestamp) and
						(CD_stream(1).CD_timestamp = CD_stream(2).CD_timestamp) and
						(CD_stream(2).CD_timestamp = CD_stream(3).CD_timestamp) and
						(CD_stream(3).CD_timestamp = CD_stream(4).CD_timestamp) and
						(CD_stream(4).CD_timestamp = CD_stream(5).CD_timestamp) and
						(CD_stream(5).CD_timestamp = CD_stream(6).CD_timestamp) and
						(CD_stream(6).CD_timestamp = CD_stream(7).CD_timestamp) and
						(CD_stream(7).CD_timestamp = CD_stream(0).CD_timestamp)) then
						  -- timestamps match
						  data_1(0) <= '0';
						  timestamp_mismatch <= '0';     
					 else
						  -- timestampe missmatch
						  data_1(0) <= '1';
						  timestamp_mismatch <= '1';
					 end if;
					 ----------generate WIB_errors----------------
					 for iCDS in CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0 loop
						  data_1(iCDS*4 + 2) <= or_reduce(CD_stream(iCDS).CD_errors);
						  data_1(iCDS*4 + 3) <= or_reduce(CD_stream(iCDS).capture_errors);
					 end loop;
					 EB_state <= EB_STATE_WIB_HEADER;
					 --readout enable-----
					 EB_CD_read <= CDA_readout; --new added
					 CDA_readout(CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0) <= CDA_readout((CDAS_PER_DAQ_LINK-1) * LINKS_PER_CDA - 1 downto 0) & "00"; --new added
					 
					 if(frame_valid /= control.COLDATA_en) then
						--flag error, stay here never write bad message into fifo
						--EB_state <= EB_STATE_NEW_FRAME; --stay here 
						EB_state <= EB_STATE_EXTRA_IDLE; --add an extra idle line
						data_wr <= '0';
						EB_CD_read <= (others => '0');
						CDA_readout <= CDA_readout_start;
						timestamp_mismatch <= '0';
					 end if; 				 
			  when EB_STATE_EXTRA_IDLE =>
					 --fix bad data from last latch 
					 EB_state <= EB_STATE_WIB_HEADER;
					 data_wr <= '1';
					 dtype_0 <= "01"; --sop
					 dtype_1 <= "00";
					 ---data_0----
					 data_0(31 downto 24)  <= "00000000";
					 data_0(23 downto 21)  <= WIB_ID.slot(2 downto 0);
					 data_0(20 downto 16)  <= WIB_ID.crate & WIB_ID.slot(3);
					 data_0(15 downto 13)  <= std_logic_vector(to_unsigned(FIBER_ID,3));
					 data_0(12 downto 8)   <= DAQ_LINK_VERSION_NUMBER;
					 data_0(7 downto 0 )   <= "00000000";
					 ---data_1----
					 data_1(15 downto 2)   <= "00000000000000";
					 data_1(1)             <= convert_info.out_of_sync;
					 if((CD_stream(0).CD_timestamp = CD_stream(1).CD_timestamp) and
						(CD_stream(1).CD_timestamp = CD_stream(2).CD_timestamp) and
						(CD_stream(2).CD_timestamp = CD_stream(3).CD_timestamp) and
						(CD_stream(3).CD_timestamp = CD_stream(4).CD_timestamp) and
						(CD_stream(4).CD_timestamp = CD_stream(5).CD_timestamp) and
						(CD_stream(5).CD_timestamp = CD_stream(6).CD_timestamp) and
						(CD_stream(6).CD_timestamp = CD_stream(7).CD_timestamp) and
						(CD_stream(7).CD_timestamp = CD_stream(0).CD_timestamp)) then
						  -- timestamps match
						  data_1(0) <= '0';
						  timestamp_mismatch <= '0';     
					 else
						  -- timestampe missmatch
						  data_1(0) <= '1';
						  timestamp_mismatch <= '1';
					 end if;
					 ----------generate WIB_errors----------------
					 for iCDS in CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0 loop
						  data_1(iCDS*4 + 2) <= or_reduce(CD_stream(iCDS).CD_errors);
						  data_1(iCDS*4 + 3) <= or_reduce(CD_stream(iCDS).capture_errors);
					 end loop;
					 --readout enable-----
					 EB_CD_read <= CDA_readout; --new added
					 CDA_readout(CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0) <= CDA_readout((CDAS_PER_DAQ_LINK-1) * LINKS_PER_CDA - 1 downto 0) & "00"; --new added	
					 
					 if(frame_valid /= control.COLDATA_en) then
					 --flag an error
						EB_state <= EB_STATE_EXTRA_IDLE; --add an extra idle line
						data_wr <= '0';
						EB_CD_read <= (others => '0');
						CDA_readout <= CDA_readout_start;
						timestamp_mismatch <= '0';
					 end if;			  
           when EB_STATE_WIB_HEADER =>
					 --EB_CD_read <= "00000011"; --readout first CDA ,readout from here, doesn't work properly, one link is getting error data 2
                last_timestamp <= convert_info.time_stamp;
                if convert_info.time_stamp = last_timestamp then
                    error_repeated_timestamp <= '1';
                end if;
                
                dtype_0 <= "00";
                dtype_1 <= "00";
                ------data_0-------
                data_0  <= convert_info.time_stamp(31 downto 0);
                data_1  <= convert_info.time_stamp(63 downto 32);
                data_1(31) <= '0';
                EB_state <= EB_STATE_CD_HEADER;

           when EB_STATE_CD_HEADER =>   
                ------stream error-----
                data_0(7 downto 0)   <= CD_stream(iCDA + 0).capture_errors;
                data_0(15 downto 8)  <= CD_stream(iCDA + 1).capture_errors;
                ------checksum---------
                data_0(23 downto 16) <= CD_stream(iCDA + 0).data_out(15 downto 8);
                data_0(31 downto 24) <= CD_stream(iCDA + 1).data_out(15 downto 8);

                data_1(7 downto 0)   <= CD_stream(iCDA + 0).data_out(23 downto 16);
                data_1(15 downto 8)  <= CD_stream(iCDA + 1).data_out(23 downto 16);
                data_1(23 downto 16) <= CD_stream(iCDA + 0).data_out(31 downto 24);
                data_1(31 downto 24) <= CD_stream(iCDA + 1).data_out(31 downto 24);
                EB_state <= EB_STATE_CD_DATA;
                iCD_data_word_count <= 2;

           when EB_STATE_CD_DATA =>
                ---------send data---------
                data_0(7 downto 0)   <= CD_stream(iCDA + 0).data_out(7 downto 0);
                data_0(15 downto 8)  <= CD_stream(iCDA + 1).data_out(7 downto 0);
                data_0(23 downto 16) <= CD_stream(iCDA + 0).data_out(15 downto 8);
                data_0(31 downto 24) <= CD_stream(iCDA + 1).data_out(15 downto 8);
                data_1(7 downto 0)   <= CD_stream(iCDA + 0).data_out(23 downto 16);
                data_1(15 downto 8)  <= CD_stream(iCDA + 1).data_out(23 downto 16);
                data_1(23 downto 16) <= CD_stream(iCDA + 0).data_out(31 downto 24);
                data_1(31 downto 24) <= CD_stream(iCDA + 1).data_out(31 downto 24);
					 
--                if iCD_data_word_count /= 14 then
--                   iCD_data_word_count <= iCD_data_word_count + 1;
--                   EB_state <= EB_STATE_CD_DATA;
--					 end if;
					 
					 if iCD_data_word_count = 14 then
						 --if EB_CD_read /= "11000000" then
						 if CDA_readout /= CDA_readout_end then
							  EB_state <= EB_STATE_CD_HEADER;
							  iCDA <= iCDA + 2;
							  CDA_readout(CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0) <= CDA_readout((CDAS_PER_DAQ_LINK-1) * LINKS_PER_CDA - 1 downto 0) & "00";
							  --EB_CD_read <= EB_CD_read(5 downto 0) & "00"; not read here
						 else
							  dtype_0 <= "00";
							  dtype_1 <= "10"; --eop
							  EB_state <= EB_STATE_IDLE_1;			  
						 end if;
						 
					 elsif iCD_data_word_count = 13 then --readout next CDA
						  --if EB_CD_read /= "11000000" then
						  --if CDA_readout /= CDA_readout_end then
							 EB_CD_read <= CDA_readout;
							 iCD_data_word_count <= iCD_data_word_count + 1;
							 EB_state <= EB_STATE_CD_DATA;	 
							  --EB_CD_read <= EB_CD_read(5 downto 0) & "00";
						  --end if;
					 else
							  iCD_data_word_count <= iCD_data_word_count + 1;
							  EB_state <= EB_STATE_CD_DATA;						
					 end if;

           when EB_STATE_IDLE_1 =>
					 --EB_CD_read <= "00000000";--IDLE don't read out anything --should we disable the readout?
					 CDA_readout <= CDA_readout_start;
                iCDA <= 0;
                data_wr <= '0'; --stop writting fifo;
                dtype_0 <= "11";
                dtype_1 <= "11";
                data_0 <= x"DEADBEEF";
                data_1 <= x"DEADBEEF";
                EB_state <= EB_STATE_IDLE_2;
           when EB_STATE_IDLE_2 =>
                EB_state <= EB_STATE_NEW_FRAME;
           when others => EB_state <= EB_STATE_INIT_WAIT;
        end case;
    end if;
  end process Event; 

  event_fifo: wib_event_fifo
  port map (
    aclr    => reset, 
    data    => data_in,
    rdclk   => fifo_rclk,
    rdreq   => fifo_re,
    wrclk   => clk,
    wrreq   => data_wr and (not fifo_full),
    q       => fifo_data_out,
    rdempty => fifo_empty,
    wrfull  => fifo_full);


  link: FMchannelTXctrl_WIB
  port map(
        clk120 => clk,
        clk240 => clk240,
        rst    => reset,
        fifo_data => fifo_data,
        fifo_dtype => fifo_dtype,
        fifo_empty => fifo_empty,
        busy       => fifo_busy,
        fifo_rclk  => fifo_rclk,
        fifo_re    => fifo_re,
        data       => data_out,
        k_data     => data_k_out  
         );
  -------------------------------------------------------------------------------
  -- Generate the 8b byte stream for the next convert frame
  -------------------------------------------------------------------------------
 -- DAQ_SOF <=  RCE_SOP when CDAS_PER_DAQ_LINK = 2 else FELIX_SOP;--x"BC";
 -- EVB : process (clk, reset) is
 -- begin  -- process EVB
 --   if reset = '1' then                 -- asynchronous reset (active high)
 --     if CDAS_PER_DAQ_LINK = 2 then
 --       event_data_8b        <= (others => RCE_IDLE_2 & RCE_IDLE_1);
 --       event_data_8b_delay  <= (others => RCE_IDLE_2 & RCE_IDLE_1);
 --     else
 --       event_data_8b        <= (others => FELIX_IDLE & FELIX_IDLE);
 --       event_data_8b_delay  <= (others => FELIX_IDLE & FELIX_IDLE);
 --     end if;
 --     event_data_k_8b        <= (others => '1');
 --     event_data_k_8b_delay  <= (others => '1');
 --     event_data_count       <= x"00";
 --     event_data_count_delay <= x"00";
 --     
 --     crc_reset     <= '1';
 --     crc_process   <= '0';
 --     EB_state      <= EB_STATE_INIT_WAIT;
 --     EB_CD_read     <= (others => '0');
 --   elsif clk'event and clk = '1' then  -- rising clock edge
 --     if CDAS_PER_DAQ_LINK = 2 then
 --       event_data_8b        <= (others => RCE_IDLE_2 & RCE_IDLE_1);
 --     else
 --       event_data_8b        <= (others => FELIX_IDLE & FELIX_IDLE);
 --     end if;
 --     event_data_k_8b        <= (others => '1');
 --     event_data_count       <= x"04";

 --           
 --     --reset pulses
 --     new_event   <= '0';
 --     timestamp_mismatch <= '0';
 --     
 --     
 --     --Pass the event builder data to the delayed version
 --     event_data_8b_delay    <= event_data_8b;
 --     event_data_k_8b_delay  <= event_data_k_8b;
 --     event_data_count_delay <= event_data_count;
 --           
 --     --Default Don't reset the crc value and don't add current data to the crc
 --     crc_reset   <= '0';
 --     crc_process <= '0';
 --     
 --     --Default Don't read out any FEMB streams
 --     EB_CD_read <= (others => '0');

 --     error_repeated_timestamp <= '0';
 --     
 --     if control.enable = '0' then
 --       EB_state <= EB_STATE_INIT_WAIT;
 --     else             
 --       case EB_state is
 --         -------------------------------------------------------------------------
 --         -- Wait on a convert signal to begin sending data
 --         -------------------------------------------------------------------------
 --         when EB_STATE_INIT_WAIT =>
 --           crc_reset     <= '1';
 --           -- wait for alignment...                    
 --           -- we need to check from 
 --           -- We should have a new convert signal now, so lets go
----            if ( ((frame_valid = control.COLDATA_en) and (or_reduce(control.COLDATA_en) = '1') and (convert.trigger = '1')) or
 --           if ( ((frame_valid = control.COLDATA_en) and (or_reduce(control.COLDATA_en) = '1')) or
 --                control.debug = '1') then
 --             EB_state <= EB_STATE_NEW_FRAME;
 --             if CDAS_PER_DAQ_LINK = 4 then
 --               event_data_count <= x"04";
 --               event_data_8b(0) <= x"00" & FELIX_IDLE;
 --               event_data_8b(1) <= x"0000";
 --               event_data_8b(2) <= x"00" & FELIX_SOP;
 --               event_data_8b(3) <= x"0000";
 --               event_data_k_8b(7 downto 0) <= x"11";
 --             end if;
 --           end if;

 --           iCDA    <= 0;
 --           CDA_readout <= CDA_readout_start;

 --           
 --         when EB_STATE_NEW_FRAME =>
 --           --by default we are going to move on to sending data next clock.
 --           -- one exception is that if we are using the slip feature of the gear
 --           -- box (500ns 8byte word count is not a multiple of 8 words) we will
 --           -- have to check for a no write slip word request.  That will be
 --           -- handled by changing the EB state to EB_SKIP_WORD
 --           EB_state <= EB_STATE_SEND_HEADER_2;

 --           
 --           ---------------------------------------------------
 --           -- SPECIAL CODE FOR PIPLELINE DELAYING FOR CRC
 --           ---------------------------------------------------
 --           -- As a hold over from the last event, we have to override the
 --           -- normal delay of data_out -> data_out_delay because the CRC takes
 --           -- an extra step. We are now overriding the junk we put in data_out
 --           -- last tick and updating it with the correct crc data.

 --           --TODO check that crc is valid (only invalid on first event) and send
 --           --idle instead
 --           
 --           
 --           --handle idle/slip word differences between RCE and FELIX
 --           if CDAS_PER_DAQ_LINK = 2 then

 --             -- Assign CRC words
 --             event_data_8b_delay(0) <= data_crc(15 downto  0);
 --             event_data_8b_delay(1) <= data_crc(31 downto 16);
 --             event_data_k_8b_delay(3 downto 0) <= x"0";
 --             --debug CRC mode
 --             if control.enable_bad_crc = '1' and
 --               (bad_crc_masked_value = control.bad_crc_bits) then
 --               -- if we are testing crc checking, we can inject a bad crc            
 --               event_data_8b_delay(0) <= x"BEEF";
 --               event_data_8b_delay(1) <= x"DEAD";
 --             end if;
 --           
 --             -- reset the CRC value
 --             crc_reset <= '1';


 --             --RCE
 --             event_data_count_delay <= x"04";--x"05";
 --             event_data_8b_delay(2) <= RCE_IDLE_2 & RCE_IDLE_1;
 --             event_data_8b_delay(3) <= RCE_IDLE_2 & RCE_IDLE_1;
 --             event_data_8b_delay(4) <= RCE_IDLE_2 & RCE_IDLE_1;
 --             event_data_k_8b_delay(9 downto 4) <= (others => '1');            
 --             if special_word_request = x"00" then
 --               EB_state <= EB_STATE_SKIP_WORD;

 --             -- Begin readout of the first CDA during the skip word
 --             else
 --               --Begin readout of the first CDA
 --               EB_CD_read <= CDA_readout;
 --               CDA_readout(CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0) <= CDA_readout((CDAS_PER_DAQ_LINK-1) * LINKS_PER_CDA - 1 downto 0) & "00";
 --             end if;            
 --           else
 --             --Begin readout of the first CDA
 --             EB_CD_read <= CDA_readout;
 --             CDA_readout(CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0) <= CDA_readout((CDAS_PER_DAQ_LINK-1) * LINKS_PER_CDA - 1 downto 0) & "00";

 --           end if;

 --           
 --           
 --           ---------------------------------------------------
 --           --Back to normal state machine processing on non-delayed signals          

 --           --Assume we have a data ready to go, we'll fix this later if we dont'
 --           
 --           -- We are now sending an event (increment a counter)
 --           new_event <= '1';

 --           -- cache the info about this trigger
 --           convert_info <= convert;

 --           --Build data to send out
 --           event_data_count <= x"04";
 --           
 --           --word 0
 --           event_data_k_8b(1 downto 0) <= "01";
 --           event_data_8b(0)( 7 downto  0) <= DAQ_SOF; --update for RCE
 --           if CDAS_PER_DAQ_LINK = 4 then
 --             event_data_k_8b(1 downto 0) <= "00";
 --             event_data_8b(0)( 7 downto  0) <= x"00"; --update for FELIX              
 --           end if;
 --           event_data_8b(0)(12 downto  8) <= DAQ_LINK_VERSION_NUMBER;
 --           event_data_8b(0)(15 downto 13) <= std_logic_vector(to_unsigned(FIBER_ID, 3));

 --           
 --           --word 1
 --           event_data_8b(1)( 4 downto  0) <= WIB_ID.crate & WIB_ID.slot(3);
 --           event_data_8b(1)( 7 downto  5) <= WIB_ID.slot(2 downto 0);
 --           event_data_8b(1)(15 downto  8) <= x"00";
 --           event_data_k_8b(3 downto 2) <= "00";

 --           --word 2
 --           event_data_8b(2) <= x"0000";
 --           event_data_8b(2)(1) <= convert_info.out_of_sync;
 --           if CDAS_PER_DAQ_LINK = 4 then
 --             if ((CD_stream(0).CD_timestamp = CD_stream(1).CD_timestamp) and
 --                 (CD_stream(1).CD_timestamp = CD_stream(2).CD_timestamp) and
 --                 (CD_stream(2).CD_timestamp = CD_stream(3).CD_timestamp) and
 --                 (CD_stream(3).CD_timestamp = CD_stream(4).CD_timestamp) and
 --                 (CD_stream(4).CD_timestamp = CD_stream(5).CD_timestamp) and
 --                 (CD_stream(5).CD_timestamp = CD_stream(6).CD_timestamp) and
 --                 (CD_stream(6).CD_timestamp = CD_stream(7).CD_timestamp) and
 --                 (CD_stream(7).CD_timestamp = CD_stream(0).CD_timestamp)) then
 --               -- timestamps match
 --               event_data_8b(2)(0) <= '0';     
 --             else
 --               -- timestampe missmatch
 --               event_data_8b(2)(0) <= '1';
 --               timestamp_mismatch <= '1';
 --             end if;
 --           else
 --             if ((CD_stream(0).CD_timestamp = CD_stream(1).CD_timestamp) and
 --                 (CD_stream(1).CD_timestamp = CD_stream(2).CD_timestamp) and
 --                 (CD_stream(2).CD_timestamp = CD_stream(3).CD_timestamp) and
 --                 (CD_stream(3).CD_timestamp = CD_stream(0).CD_timestamp))then
 --               -- timestamps match
 --               event_data_8b(2)(0) <= '0';     
 --             else
 --               -- timestampe missmatch
 --               event_data_8b(2)(0) <= '1';
 --               timestamp_mismatch <= '1';
 --             end if;
 --           end if;
 --           event_data_k_8b(5 downto 4) <= "00";

 --           --word 3
 --           event_data_8b(3) <= (others => '0');
 --           for iCDS in CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0 loop
 --             --Set two bits per CD stream to store if there was any CDA errors
 --             --or any capture errors
 --             event_data_8b(3)(iCDS*2    ) <= or_reduce(CD_stream(iCDS).CD_errors);
 --             event_data_8b(3)(iCDS*2 + 1) <= or_reduce(CD_stream(iCDS).capture_errors);  
 --           end loop;
 --           event_data_k_8b(7 downto 6) <= "00";

 --           -- Other error bits
 --           -- time stamp / event number misalignment
 --           
 --           
 --           --debug mode reset
 --           -- DEBUG MODE
 --           if control.debug = '1' then
 --             event_data_k_8b(7 downto 0)  <= "00000001";

 --             event_data_8b(0) <= x"00"&DAQ_SOF;
 --             if CDAS_PER_DAQ_LINK = 4 then
 --               --felix
 --               event_data_8b(0) <= x"0000";
 --               event_data_k_8b(7 downto 0)  <= "00000000";
 --             end if;
 --             event_data_8b(1) <= x"0001";
 --             event_data_8b(2) <= x"0002";
 --             event_data_8b(3) <= x"0003";

 --             debug_mode_data <= x"0007000600050004";
 --           end if;

 --           -- add data to the CRC
 --           crc_process <= '1';
 --           
 --           -- We should have a new convert signal now, so lets go
 --           if (frame_valid /= control.COLDATA_en) then
 --             --flag error

 --             -- Add an extra idle line
 --             EB_state <= EB_STATE_EXTRA_IDLE;
 --             -- reset the fifo readou signals so they can be reset in extra word
 --             EB_CD_read <= (others => '0');
 --             CDA_readout <= CDA_readout_start;
 --             crc_process <= '0';
 --             timestamp_mismatch <= '0';


 --             if CDAS_PER_DAQ_LINK = 4 then                
 --               --override SOF for FELIX and do another FELIX idle
 --               event_data_count_delay <= x"0" & special_word_request(3 downto 0);

 --               event_data_8b_delay(0) <= x"00" & FELIX_IDLE;
 --               event_data_8b_delay(1) <= x"0000";
 --               event_data_8b_delay(2) <= x"00" & FELIX_IDLE;
 --               event_data_8b_delay(3) <= x"0000";
 --               event_data_k_8b_delay(7 downto 0) <= x"11";
 --             end if;
 --             
 --           end if;

 --           -------------------------------------------------------------------------
 --           -- Wait for each COLDATA stream for this FEMB to arrive and then start
 --           -- sending data header
 --           -------------------------------------------------------------------------

 --         when EB_STATE_SKIP_WORD =>
 --           event_data_count    <= x"00";            
 --           EB_State <= EB_STATE_SEND_HEADER_2;
 --           --Begin readout of the first CDA
 --           EB_CD_read <= CDA_readout;
 --           CDA_readout(CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0) <= CDA_readout((CDAS_PER_DAQ_LINK-1) * LINKS_PER_CDA - 1 downto 0) & "00";


 --         when EB_STATE_EXTRA_IDLE =>
 --           crc_reset <= '1';
 --           EB_State <= EB_STATE_SEND_HEADER_2;

 --           if CDAS_PER_DAQ_LINK = 2 then
 --             --RCE
 --             --Write one word of delay
 --             event_data_count_delay <= x"0" & special_word_request(3 downto 0);--x"04";--x"01";
 --             event_data_k_8b_delay(7 downto 0) <= x"FF";
 --             event_data_8b_delay(0) <= RCE_IDLE_2 & RCE_IDLE_1;
 --             event_data_8b_delay(1) <= RCE_IDLE_2 & RCE_IDLE_1;
 --             event_data_8b_delay(2) <= RCE_IDLE_2 & RCE_IDLE_1;
 --             event_data_8b_delay(3) <= RCE_IDLE_2 & RCE_IDLE_1;
 --           
 --             event_data_count <= event_data_count;
 --             event_data_8b <= event_data_8b;
 --             event_data_k_8b <= event_data_k_8b;
 --           else
 --             --FELIX
 --             event_data_count_delay <= x"0" & special_word_request(3 downto 0);

 --             event_data_8b_delay(0) <= x"00" & FELIX_IDLE;
 --             event_data_8b_delay(1) <= x"0000";
----              event_data_8b_delay(2) <= x"00" & FELIX_IDLE;
 --             event_data_8b_delay(2) <= x"00" & FELIX_SOP;
 --             event_data_8b_delay(3) <= x"0000";
 --             event_data_k_8b_delay(7 downto 0) <= x"11";

 --             event_data_count <= event_data_count;
 --             event_data_8b    <= event_data_8b;
 --             event_data_k_8b  <= event_data_k_8b;
 --           end if;
 --           --Fix bad data from last latch if not in debug mode

 --           if control.debug = '0' then
 --             --Word 2
 --             if CDAS_PER_DAQ_LINK = 4 then
 --               if ((CD_stream(0).CD_timestamp = CD_stream(1).CD_timestamp) and
 --                   (CD_stream(1).CD_timestamp = CD_stream(2).CD_timestamp) and
 --                   (CD_stream(2).CD_timestamp = CD_stream(3).CD_timestamp) and
 --                   (CD_stream(3).CD_timestamp = CD_stream(4).CD_timestamp) and
 --                   (CD_stream(4).CD_timestamp = CD_stream(5).CD_timestamp) and
 --                   (CD_stream(5).CD_timestamp = CD_stream(6).CD_timestamp) and
 --                   (CD_stream(6).CD_timestamp = CD_stream(7).CD_timestamp) and
 --                   (CD_stream(7).CD_timestamp = CD_stream(0).CD_timestamp)) then
 --                 -- timestamps match
 --                 event_data_8b(2)(0) <= '0';     
 --               else
 --                 -- timestampe missmatch
 --                 event_data_8b(2)(0) <= '1';
 --                 timestamp_mismatch <= '1';
 --               end if;
 --             else
 --               if ((CD_stream(0).CD_timestamp = CD_stream(1).CD_timestamp) and
 --                   (CD_stream(1).CD_timestamp = CD_stream(2).CD_timestamp) and
 --                   (CD_stream(2).CD_timestamp = CD_stream(3).CD_timestamp) and
 --                   (CD_stream(3).CD_timestamp = CD_stream(0).CD_timestamp))then
 --                 -- timestamps match
 --                 event_data_8b(2)(0) <= '0';     
 --               else
 --                 -- timestampe missmatch
 --                 event_data_8b(2)(0) <= '1';
 --                 timestamp_mismatch <= '1';
 --               end if;
 --             end if;
 --             event_data_k_8b(5 downto 4) <= "00";
 --             
 --             --Word 3
 --             event_data_8b(3) <= (others => '0');
 --             for iCDS in CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0 loop
 --               --Set two bits per CD stream to store if there was any CDA errors
 --               --or any capture errors
 --               event_data_8b(3)(iCDS*2    ) <= or_reduce(CD_stream(iCDS).CD_errors);
 --               event_data_8b(3)(iCDS*2 + 1) <= or_reduce(CD_stream(iCDS).capture_errors);  
 --             end loop;
 --             
 --           end if;
 --           --Begin readout of the first CDA
 --           EB_CD_read <= CDA_readout;
 --           CDA_readout(CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0) <= CDA_readout((CDAS_PER_DAQ_LINK-1) * LINKS_PER_CDA - 1 downto 0) & "00";

 --           
 --           crc_process <= '1';            


 --           -- We should have a new convert signal now, so lets go
 --           if (frame_valid /= control.COLDATA_en) then
 --             --flag error

 --             -- Add an extra idle line
 --             EB_state <= EB_STATE_EXTRA_IDLE;
 --             -- reset the fifo readou signals so they can be reset in extra word
 --             EB_CD_read <= (others => '0');
 --             CDA_readout <= CDA_readout_start;
 --             crc_process <= '0';
 --             timestamp_mismatch <= '0';

 --             if CDAS_PER_DAQ_LINK = 4 then                
 --               --override SOF for FELIX and do another FELIX idle
 --               event_data_count_delay <= x"0" & special_word_request(3 downto 0);

 --               event_data_8b_delay(0) <= x"00" & FELIX_IDLE;
 --               event_data_8b_delay(1) <= x"0000";
 --               event_data_8b_delay(2) <= x"00" & FELIX_IDLE;
 --               event_data_8b_delay(3) <= x"0000";
 --               event_data_k_8b_delay(7 downto 0) <= x"11";
 --             end if;

 --           end if;


 --           
 --         when EB_STATE_SEND_HEADER_2 =>
 --           -- Start sending the next event

 --           if convert_info.time_stamp = last_timestamp then
 --             error_repeated_timestamp <= '1';
 --           end if;
 --           last_timestamp <= convert_info.time_stamp;
 --           
 --           event_data_8b(0) <= convert_info.time_stamp(15 downto  0);
 --           event_data_8b(1) <= convert_info.time_stamp(31 downto 16);
 --           event_data_8b(2) <= convert_info.time_stamp(47 downto 32);
 --           event_data_8b(3) <= convert_info.time_stamp(63 downto 48);
 --           event_data_8b(3)(15) <= '0'; --long timestamp mode
 --           event_data_k_8b <= (others => '0');
 --           
 --           -- DEBUG MODE
 --           if control.debug = '1' then
 --             for iWord in WORD_COUNT -1 downto 0 loop
 --               event_data_8b(iWord) <= debug_mode_data(16*iWord + 15 downto 16*iWord);
 --               debug_mode_data(16*iWord + 15 downto 16*iWord) <=
 --                 std_logic_vector(unsigned(debug_mode_data(16*iWord + 15 downto 16*iWord)) + to_unsigned(WORD_COUNT,16)); 
 --             end loop;              
 --           end if;
 --           
 --           -- add data to the CRC
 --           crc_process <= '1';

 --           
 --           EB_state <= EB_STATE_CD_HEADER;

 --         when EB_STATE_CD_HEADER =>  
 --           event_data_8b(0)( 7 downto  0) <= CD_stream(iCDA + 0).capture_errors;
 --           event_data_8b(0)(15 downto  8) <= CD_stream(iCDA + 1).capture_errors;
 --           --checksum A & B first 8 bits
 --           event_data_8b(1)( 7 downto  0) <= CD_stream(iCDA + 0).data_out(15 downto  8);
 --           event_data_8b(1)(15 downto  8) <= CD_stream(iCDA + 1).data_out(15 downto  8);
 --           --checksum A & B second 8 bits
 --           event_data_8b(2)( 7 downto  0) <= CD_stream(iCDA + 0).data_out(23 downto 16);
 --           event_data_8b(2)(15 downto  8) <= CD_stream(iCDA + 1).data_out(23 downto 16);
 --           --timestamp for CDA built from channels A & B
 --           event_data_8b(3)( 7 downto  0) <= CD_stream(iCDA + 0).data_out(31 downto 24);
 --           event_data_8b(3)(15 downto  8) <= CD_stream(iCDA + 1).data_out(31 downto 24);
 --           event_data_k_8b <= (others => '0');

 --           -- DEBUG MODE
 --           if control.debug = '1' then
 --             for iWord in WORD_COUNT -1 downto 0 loop
 --               event_data_8b(iWord) <= debug_mode_data(16*iWord + 15 downto 16*iWord);
 --               debug_mode_data(16*iWord + 15 downto 16*iWord) <= std_logic_vector(unsigned(debug_mode_data(16*iWord + 15 downto 16*iWord)) + to_unsigned(WORD_COUNT,16)); 
 --             end loop;              
 --           end if;
 --           
 --           -- add data to the CRC
 --           crc_process <= '1';

 --           iCD_data_word_count <= 2;
 --           EB_state <= EB_STATE_CD_DATA;
 --           
 --         when EB_STATE_CD_DATA =>
 --           --Keep track of which send word we are on.
 --           if iCD_data_word_count /= CD_DATA_WORD_COUNT then --14
 --             iCD_data_word_count <= iCD_data_word_count + 1;            
 --           end if;
 --           
 --           --send data
 --           event_data_8b(0)( 7 downto  0) <= CD_stream(iCDA + 0).data_out( 7 downto  0);
 --           event_data_8b(0)(15 downto  8) <= CD_stream(iCDA + 1).data_out( 7 downto  0);
 --           event_data_8b(1)( 7 downto  0) <= CD_stream(iCDA + 0).data_out(15 downto  8);
 --           event_data_8b(1)(15 downto  8) <= CD_stream(iCDA + 1).data_out(15 downto  8);
 --           event_data_8b(2)( 7 downto  0) <= CD_stream(iCDA + 0).data_out(23 downto 16);
 --           event_data_8b(2)(15 downto  8) <= CD_stream(iCDA + 1).data_out(23 downto 16);
 --           event_data_8b(3)( 7 downto  0) <= CD_stream(iCDA + 0).data_out(31 downto 24);
 --           event_data_8b(3)(15 downto  8) <= CD_stream(iCDA + 1).data_out(31 downto 24);
 --           event_data_k_8b <= (others => '0');

 --           -- DEBUG MODE
 --           if control.debug = '1' then
 --             for iWord in WORD_COUNT -1 downto 0 loop
 --               event_data_8b(iWord) <= debug_mode_data(16*iWord + 15 downto 16*iWord);
 --               debug_mode_data(16*iWord + 15 downto 16*iWord) <= std_logic_vector(unsigned(debug_mode_data(16*iWord + 15 downto 16*iWord)) + to_unsigned(WORD_COUNT,16)); 
 --             end loop;              
 --           end if;
 --           
 --           -- add data to the CRC
 --           crc_process <= '1';


 --           --Make sure we send something for the correct number of words
 --           if iCD_data_word_count = CD_DATA_WORD_COUNT then
 --             EB_state <= EB_state_CD_HEADER;
 --             --Check for change of CDA (data valid is '0')
 --             --Start the readout for the next CDA if we aren't done yet
 --             if CDA_readout = CDA_readout_end then
 --               --We are done, send the CRC
 --               EB_state <= EB_state_CRC_WAIT;
 --             else
 --               --Begin readout of the next CDA
 --               iCDA    <= iCDA + LINKS_PER_CDA; --iCDA = iCDA + 2
 --               CDA_readout(CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0) <= CDA_readout((CDAS_PER_DAQ_LINK-1) * LINKS_PER_CDA - 1 downto 0) & "00";                
 --             end if;
 --           elsif iCD_data_word_count = (CD_DATA_WORD_COUNT-1) then
 --             if CDA_readout /= CDA_readout_end then
 --               --Begin readout of the next CDA
 --               EB_CD_read <= CDA_readout;
 --             end if;              
 --           end if;


 --         -------------------------------------------------------------------------
 --         -- Start sending data for COLDATA ASIC 1
 --         -------------------------------------------------------------------------
 --         when EB_STATE_CRC_WAIT =>
 --           if CDAS_PER_DAQ_LINK = 2 then
 --             --RCE
 --             EB_State       <= EB_STATE_NEW_FRAME;
 --           else
 --             --FELIX
 --             EB_State       <= EB_STATE_IDLE_PATTERN;
 --           end if;
 --           -- we are sending junk right now, but we will fix that on the next
 --           -- clock tick
 --           iCDA    <= 0;
 --           CDA_readout <= CDA_readout_start;
 --         when EB_STATE_IDLE_PATTERN =>

 --           ---------------------------------------------------
 --           -- SPECIAL CODE FOR PIPLELINE DELAYING FOR CRC
 --           ---------------------------------------------------
 --           -- As a hold over from the last event, we have to override the
 --           -- normal delay of data_out -> data_out_delay because the CRC takes
 --           -- an extra step. We are now overriding the junk we put in data_out
 --           -- last tick and updating it with the correct crc data.

 --           event_data_8b_delay(0) <= data_crc(7 downto 0) & FELIX_EOP;
 --           event_data_8b_delay(1) <= x"0" & data_crc(19 downto 8);
 --           event_data_8b_delay(2) <= x"00" & FELIX_IDLE;
 --           event_data_8b_delay(3) <= x"0000";

 --           event_data_k_8b_delay(7 downto 0) <= x"11";
 --           
 --           -- reset the CRC value
 --           crc_reset <= '1';

 --           ---------------------------------------------------
 --           -- Back to normal pipe-lining
 --           ---------------------------------------------------
 --           -- Idle pattern
 --           event_data_count <= x"04";
 --           event_data_8b(0) <= x"00" & FELIX_IDLE;
 --           event_data_8b(1) <= x"0000";
 --           event_data_8b(2) <= x"00" & FELIX_SOP;
 --           event_data_8b(3) <= x"0000";
 --           event_data_k_8b(7 downto 0) <= x"11";
 --           
 --           --go to next event
 --           EB_State       <= EB_STATE_NEW_FRAME;            

 --           
 --         when others => EB_State <= EB_STATE_INIT_WAIT;
 --       end case;
 --     end if;
 --   end if;
 -- end process EVB;

  -------------------------------------------------------------------------------
  -- Generate the CRC for the output data
  -------------------------------------------------------------------------------

  --crc_input_data(63 downto 48) <= event_data_8b(3);
  --crc_input_data(47 downto 32) <= event_data_8b(2);
  --crc_input_data(31 downto 16) <= event_data_8b(1);
  --crc_input_data(15 downto  0) <= event_data_8b(0);

  --CRC_RCE: if CDAS_PER_DAQ_LINK = 2 generate
  --  CRCD64_RCE_1 : entity work.CRCD64_RCE
  --    port map (
  --      clk     => clk,
  --      init    => crc_reset,
  --      ce      => crc_process,
  --      d       => crc_input_data,
  --      crc     => data_crc,
  --      bad_crc => bad_crc);    
  --end generate CRC_RCE;
  --
  --CRC_FELIX: if CDAS_PER_DAQ_LINK = 4 generate
  --  CRCD64_FELIX_1: entity work.CRCD64_FELIX
  --    port map (
  --      clk     => clk,
  --      init    => crc_reset,
  --      ce      => crc_process,
  --      d       => crc_input_data,
  --      crc     => data_crc(19 downto 0));    
  --end generate CRC_FELIX;

  --gearbox_setup: for iWord in (WORD_COUNT + Extra_WORD_COUNT) -1 downto 0 generate
  --  word_setup: for iByte in BYTES_PER_WORD -1 downto 0 generate
  --    --Merge separate k-char bit and data byte into a 9 bit object for the
  --    --gearbox to work on. 
  --    gearbox_input((iWORD*BYTES_PER_WORD + iByte + 1)*BITS_PER_BYTE - 1 downto (iWORD*BYTES_PER_WORD + iByte)*BITS_PER_BYTE) <= event_data_k_8b_delay(iWord*BYTES_PER_WORD + iByte) & event_data_8b_delay(iWord)(8*(iByte+1) - 1 downto 8*iByte);
  --  end generate word_setup;
  --end generate gearbox_setup;
  
--  gearbox_input <= event_data_k_8b_delay(9) & event_data_8b_delay(4)(15 downto  8) &
--                   event_data_k_8b_delay(8) & event_data_8b_delay(4)( 7 downto  0) &
--                   event_data_k_8b_delay(7) & event_data_8b_delay(3)(15 downto  8) &
--                   event_data_k_8b_delay(6) & event_data_8b_delay(3)( 7 downto  0) &
--                   event_data_k_8b_delay(5) & event_data_8b_delay(2)(15 downto  8) &
--                   event_data_k_8b_delay(4) & event_data_8b_delay(2)( 7 downto  0) &
--                   event_data_k_8b_delay(3) & event_data_8b_delay(1)(15 downto  8) &
--                   event_data_k_8b_delay(2) & event_data_8b_delay(1)( 7 downto  0) &
--                   event_data_k_8b_delay(1) & event_data_8b_delay(0)(15 downto  8) &
--                   event_data_k_8b_delay(0) & event_data_8b_delay(0)( 7 downto  0);

  --generate an ok idle pattern for the gearbox default
 -- IDLE <= "1"&RCE_IDLE_1 & "1"&RCE_IDLE_1 when CDAS_PER_DAQ_LINK = 2 else "1"&FELIX_IDLE & "1"&FELIX_IDLE;
 -- Gearbox_2: entity work.Gearbox
 --   generic map (
 --     DEFAULT_WORDS => "1"&RCE_IDLE_1&"1"&RCE_IDLE_1)
 --   port map (
 --     clk                  => clk,
 --     reset                => reset,
 --     data_in              => gearbox_input,
 --     data_in_count        => event_data_count_delay,
 --     data_out             => gearbox_output,
 --     special_word_request => special_word_request,
 --     monitor              => monitor_buffer.gearbox,
 --     control              => control.gearbox);

 -- gearbox_output_delay: process (clk) is
 -- begin  -- process gearbox_output_delay
 --   if clk'event and clk = '1' then  -- rising clock edge
 --     --add a pipeline delay to help timing
 --     gearbox_output_buffer          <= gearbox_output;
 --     gearbox_output_buffer2         <= gearbox_output_buffer;
 --   end if;
 -- end process gearbox_output_delay;
 -- 
 -- gearbox_rearange: for iByte in OUTPUT_BYTE_COUNT -1 downto 0 generate
----    data_out(iByte*8 +7 downto iByte*8) <= gearbox_output(iByte*9 +7 downto iByte * 9);
----    data_k_out(iByte) <= gearbox_output(iByte*9 + 8);
 --   data_out(iByte*8 +7 downto iByte*8) <= gearbox_output_buffer(iByte*9 +7 downto iByte * 9);
 --   data_k_out(iByte) <= gearbox_output_buffer(iByte*9 + 8);
 -- end generate gearbox_rearange;


-------------------------------------------------------------------------------
-- Spy buffer
-------------------------------------------------------------------------------
--  spy_buffer_control: process (clk, reset) is
--  begin  -- process spy_buffer_control
--    if reset = '1' then                 -- asynchronous reset (active high)
--      spy_buffer_state <= SPY_BUFFER_STATE_IDLE;
--      monitor_buffer.spy_buffer_running <= '0';
--      spy_buffer_write_enable <= '0';      
--    elsif clk'event and clk = '1' then  -- rising clock edge
--      --Some state variable defaults
--      monitor_buffer.spy_buffer_running <= '1';
--      spy_buffer_write_enable <= '0';
--      monitor_buffer.spy_buffer_wait_for_trigger <= control.spy_buffer_wait_for_trigger;
--      
--      if control.spy_buffer_start = '1' then
--        --When a 
--        spy_buffer_state <= SPY_BUFFER_STATE_WAIT;
--      else        
--        case spy_buffer_state is          
--          when  SPY_BUFFER_STATE_IDLE =>
--            --stay in idle state and report the spy buffer isn't running
--            spy_buffer_state <= SPY_BUFFER_STATE_IDLE;
--            monitor_buffer.spy_buffer_running <= '0';
--          when SPY_BUFFER_STATE_WAIT  =>
--            -- Wait in this state until something happens
--            spy_buffer_state <= SPY_BUFFER_STATE_WAIT;
--            if control.spy_buffer_wait_for_trigger = '1' then
--              -- if we are waiting for a trigger, wait here until one happens            
--              if convert.trigger = '1' then
--                spy_buffer_state <= SPY_BUFFER_STATE_CAPTURE;
--              end if;
--            else
--              -- start capturing data right away
--              spy_buffer_state <= SPY_BUFFER_STATE_CAPTURE;
--            end if;
--          when SPY_BUFFER_STATE_CAPTURE =>
--            if spy_buffer_full = '1' then
--              --We are done capturing, so go back to IDLE
--              spy_buffer_state <= SPY_BUFFER_STATE_IDLE;
--            else
--              spy_buffer_write_enable <= '1';
--            end if;
--          when others => spy_buffer_state <= SPY_BUFFER_STATE_IDLE;
--        end case;
--      end if;
--      
--    end if;
--  end process spy_buffer_control;
--
--  --  contorl spy buffer with the same signal that controls the serdes fifo
--  rce_spy_buffer_buffer: process (clk) is
--  begin  -- process rce_spy_buffer_buffer
--    if clk'event and clk = '1' then  -- rising clock edge
--      --Buffer the writes into this to ease timing
----      gearbox_output_buffer          <= gearbox_output;
----      spy_buffer_write_enable_buffer <= spy_buffer_write_enable and (not spy_buffer_full);
--    end if;
--  end process rce_spy_buffer_buffer;
--  RCE_SPY_BUFFER_1: RCE_SPY_BUFFER
--    port map (
--      data    => gearbox_output_buffer2,--gearbox_output,
--      rdclk   => clk,
--      rdreq   => control.spy_buffer_read,
--      wrclk   => clk,
--      wrreq   => spy_buffer_write_enable,--spy_buffer_write_enable_buffer,
--      q       => monitor_buffer.spy_buffer_data,
--      rdempty => monitor_buffer.spy_buffer_empty,
--      wrfull  => spy_buffer_full);
  
-------------------------------------------------------------------------------
-- Counters
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
  delay_counter : process (clk) is
  begin  -- process delay_counter
    if clk'event and clk = '1' then     -- rising clock edge
      monitor <= monitor_buffer;
    end if;
  end process delay_counter;
  counter_1 : entity work.counter
    port map (
      clk         => clk,
      reset_async => '0',
      reset_sync  => control.event_count_reset,
      enable      => '1',
      event       => new_event,
      count       => monitor_buffer.event_count,
      at_max      => open);
  
  counter_2 : entity work.counter
    port map (
      clk         => clk,
      reset_async => '0',
      reset_sync  => control.mismatch_count_reset,
      enable      => '1',
      event       => timestamp_mismatch,
      count       => monitor_buffer.mismatch_count,
      at_max      => open);

  counter_3 : entity work.counter
    port map (
      clk         => clk,
      reset_async => '0',
      reset_sync  => control.timestamp_repeated_count_reset,
      enable      => '1',
      event       => error_repeated_timestamp,
      count       => monitor_buffer.timestamp_repeated_count,
      at_max      => open);


  FELIX_counters: if CDAS_PER_DAQ_LINK = 4 generate
    timed_counter_FELIX: entity work.timed_counter
      generic map (
        timer_count => x"07735940") -- 125Mhz
      port map (
        clk          => clk,
        reset_async  => '0',
        reset_sync   => '0',
        enable       => '1',
        event        => new_event,
        update_pulse => open,
        timed_count  => monitor_buffer.event_rate);
    
  end generate FELIX_counters;

  --RCE_counters: if CDAS_PER_DAQ_LINK = 2 generate
  --  timed_counter_RCE: entity work.timed_counter
  --    generic map (
  --      timer_count => x"03B9ACA0") -- 62.5Mhz
  --    port map (
  --      clk          => clk,
  --      reset_async  => '0',
  --      reset_sync   => '0',
  --      enable       => '1',
  --      event        => new_event,
  --      update_pulse => open,
  --      timed_count  => monitor_buffer.event_rate);
  --  
  --end generate RCE_counters;

end architecture behavioral;
