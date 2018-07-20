-- asfl.vhd

-- Generated using ACDS version 16.0 211

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity asfl is
	port (
		asmi_access_granted : in  std_logic                    := '0';             -- asmi_access_granted.asmi_access_granted
		asmi_access_request : out std_logic;                                       -- asmi_access_request.asmi_access_request
		data_in             : in  std_logic_vector(3 downto 0) := (others => '0'); --             data_in.data_in
		data_oe             : in  std_logic_vector(3 downto 0) := (others => '0'); --             data_oe.data_oe
		data_out            : out std_logic_vector(3 downto 0);                    --            data_out.data_out
		dclk_in             : in  std_logic                    := '0';             --             dclk_in.dclkin
		ncso_in             : in  std_logic                    := '0';             --             ncso_in.scein
		noe_in              : in  std_logic                    := '0'              --              noe_in.noe
	);
end entity asfl;

architecture rtl of asfl is
	component altera_serial_flash_loader is
		generic (
			INTENDED_DEVICE_FAMILY  : string  := "";
			ENHANCED_MODE           : boolean := true;
			ENABLE_SHARED_ACCESS    : string  := "OFF";
			ENABLE_QUAD_SPI_SUPPORT : boolean := false;
			NCSO_WIDTH              : integer := 1
		);
		port (
			dclk_in             : in  std_logic                    := 'X';             -- dclkin
			ncso_in             : in  std_logic                    := 'X';             -- scein
			data_in             : in  std_logic_vector(3 downto 0) := (others => 'X'); -- data_in
			data_oe             : in  std_logic_vector(3 downto 0) := (others => 'X'); -- data_oe
			noe_in              : in  std_logic                    := 'X';             -- noe
			asmi_access_granted : in  std_logic                    := 'X';             -- asmi_access_granted
			data_out            : out std_logic_vector(3 downto 0);                    -- data_out
			asmi_access_request : out std_logic                                        -- asmi_access_request
		);
	end component altera_serial_flash_loader;

begin

	serial_flash_loader_0 : component altera_serial_flash_loader
		generic map (
			INTENDED_DEVICE_FAMILY  => "Arria V",
			ENHANCED_MODE           => true,
			ENABLE_SHARED_ACCESS    => "ON",
			ENABLE_QUAD_SPI_SUPPORT => true,
			NCSO_WIDTH              => 1
		)
		port map (
			dclk_in             => dclk_in,             --             dclk_in.dclkin
			ncso_in             => ncso_in,             --             ncso_in.scein
			data_in             => data_in,             --             data_in.data_in
			data_oe             => data_oe,             --             data_oe.data_oe
			noe_in              => noe_in,              --              noe_in.noe
			asmi_access_granted => asmi_access_granted, -- asmi_access_granted.asmi_access_granted
			data_out            => data_out,            --            data_out.data_out
			asmi_access_request => asmi_access_request  -- asmi_access_request.asmi_access_request
		);

end architecture rtl; -- of asfl