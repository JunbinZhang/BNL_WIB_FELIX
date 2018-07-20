--/////////////////////////////////////////////////////////////////////
--////                              
--////  File: IP_ADDR_SELECT.VHD
--////                                                                                                                                      
--////  Author: Jack Fried                                        
--////          jfried@bnl.gov                
--////  Created:  07/05/2017
--////  Modified: 07/05/2017
--////  Description:  
--////                                  
--////
--/////////////////////////////////////////////////////////////////////
--////
--//// Copyright (C) 2017 Brookhaven National Laboratory
--////
--/////////////////////////////////////////////////////////////////////


library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


--  Entity Declaration

entity IP_ADDR_SELECT is
	port
	(
	  	CLK						: IN STD_LOGIC;     	-- 0 from BRD ID  1= from eeprom
		IP_JUMP_SEL				: IN STD_LOGIC;     	-- 0 from BRD ID  1= from eeprom
		IP_SEL					: IN STD_LOGIC;     	-- 0 from BRD ID  1= from eeprom
		BP_CRATE_ADDR			: IN 	STD_LOGIC_VECTOR(3 downto 0);		--	2.5V, default
		BP_SLOT_ADDR			: IN 	STD_LOGIC_VECTOR(3 downto 0);		--	2.5V, default	
		IP_IN_EEPROM			: IN STD_LOGIC_VECTOR(31 downto 0);  -- FROM EEPROM
		MAC_IN_EEPROM			: IN STD_LOGIC_VECTOR(47 downto 0);	-- FROM EEPROM
		IP_OUT					: OUT STD_LOGIC_VECTOR(31 downto 0);
		MAC_OUT					: OUT STD_LOGIC_VECTOR(47 downto 0)


      );
end IP_ADDR_SELECT;


--  Architecture Body


architecture IP_ADDR_SELECT_arch OF IP_ADDR_SELECT is

	signal	 ip_address   		: STD_LOGIC_VECTOR(31 downto 0);
	signal	 mac_address   	: STD_LOGIC_VECTOR(47 downto 0);
   type ip_byte_slot_table_t is array (0 to 4) of std_logic_vector(7 downto 0);
   type ip_byte_crate_table_t is array (0 to 9) of ip_byte_slot_table_t;	
   constant IP_BYTE_LOOKUP : ip_byte_crate_table_t := ((x"14",x"15",x"16",x"17",x"18"), --Crate0
                                                      (x"1a",x"1b",x"1c",x"1d",x"1e"), --crate1
                                                      (x"1f",x"20",x"21",x"22",x"23"), --crate2
                                                      (x"24",x"25",x"26",x"27",x"28"), --crate3
                                                      (x"29",x"2a",x"2b",x"2c",x"2d"), --crate4
                                                      (x"2e",x"2f",x"30",x"37",x"31"), --crate5
                                                      (x"32",x"33",x"34",x"35",x"36"), --crate6
                                                      (x"00",x"00",x"00",x"00",x"00"), --crate7
                                                      (x"00",x"00",x"00",x"00",x"00"), --crate8
                                                      (x"28",x"29",x"2A",x"2B",x"2C")  --crate9
                                                      );	
	
BEGIN


  process (clk) is
  begin 
	if clk'event and clk = '1' then 
      if ((BP_CRATE_ADDR = x"f" or BP_SLOT_ADDR = x"f") or (BP_SLOT_ADDR > x"5") )then
        ip_address  <= x"C0A87901";
        mac_address <= x"AABBCCDDEE10";
      else
        ip_address <= x"0a498900";
        mac_address <= x"AABBCCDD0000";
        case BP_CRATE_ADDR is          
          when x"0" | x"1" | x"2" | x"3" | x"4" | x"5" | x"6" | x"9" =>
            ip_address(7 downto 0) <= IP_BYTE_LOOKUP(to_integer(unsigned(BP_CRATE_ADDR)))(to_integer(unsigned(BP_SLOT_ADDR)));
            mac_address(11 downto  8) <= BP_CRATE_ADDR;
            mac_address( 3 downto  0) <= BP_SLOT_ADDR;
          when others => NULL;
        end case;
      end if;
    end if;
  end process;							
							
					

	IP_OUT		<= 	x"C0A87901"			when (IP_JUMP_SEL = '0') else
							ip_address			when (IP_SEL = '1') 		 else 
							IP_IN_EEPROM;
							
	MAC_OUT		<= 	x"AABBCCDDEE10"	when (IP_JUMP_SEL = '0') else
							mac_address			when (IP_SEL = '1') 		 else 
							MAC_IN_EEPROM;

												
					
--10.73.137.20
--10.73.137.21
--10.73.137.22
--10.73.137.23
--10.73.137.24
--10.73.137.26
--10.73.137.27
--10.73.137.28
--10.73.137.29
--10.73.137.30
--10.73.137.31
--10.73.137.32
--10.73.137.33
--10.73.137.34
--10.73.137.35
--10.73.137.36
--10.73.137.37
--10.73.137.38
--10.73.137.39
--10.73.137.40
--10.73.137.41
--10.73.137.42
--10.73.137.43
--10.73.137.44
--10.73.137.45
--10.73.137.46
--10.73.137.47
--10.73.137.48
--10.73.137.55
--10.73.137.49
--10.73.137.50
--10.73.137.51
--10.73.137.52
--10.73.137.53
--10.73.137.54
--10.73.138.40
--10.73.138.41
--10.73.138.42
--10.73.138.43
--10.73.138.44



		
END IP_ADDR_SELECT_arch;
