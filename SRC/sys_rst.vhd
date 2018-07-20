--------------------------------------------------------------------
--  MODULE NAME: stretch

--  FUNCTIONAL DESCRIPTION:
--  This module will stretch a clock pulse by length clock ticks.
--  Useful for status LEDs.
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;



--  Entity Declaration

entity sys_rst is
	port
	(
		clk         		: in  std_logic;                     -- Input CLK from MAC Reciever
		reset_in				: in  std_logic;                     -- Synchronous reset signal
		start					: out  std_logic;                     -- Synchronous reset signal
		RST_OUT				: out std_logic
		);
end sys_rst;


--  Architecture Body

architecture sys_rst_arch OF sys_rst is

		 signal counter			 : std_logic_vector(15 downto 0) ;

BEGIN

        process(reset_in, clk)
        begin
        
                if (reset_in='1') then
                        counter 	<= x"0000";
                        RST_OUT	<= '1';
								start		<= '0';
                elsif (clk='1') and (clk'event) then
						counter <= counter + 1;
						if(counter <= x"1000") then
						      RST_OUT	<= '1';
								start		<= '0';
						elsif(counter <= x"1100") then
						 		RST_OUT	<= '0';
								start		<= '0';
						elsif(counter <= x"1200") then
						 		RST_OUT	<= '0';
								start		<= '1';
								counter 	<= x"1110";   
						end if ;
                end if;
        end process ;
        	  
		  
		
		 
		  
END sys_rst_arch;
