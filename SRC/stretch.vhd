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

entity stretch is
 port
 (
		clk 		: in std_logic;
      reset 	: in std_logic;
      sig_in 	: in std_logic;
      len    	: in std_logic_vector(31 downto 0);
      sig_out 	: out std_logic
 );
                
end stretch;


--  Architecture Body

architecture stretch_architecture OF stretch is



	 signal trig_cnt			: std_logic_vector(31 downto 0);
	 signal trig_stretch 	: std_logic;
	 signal prev_sig_in 		: std_logic;
	 
BEGIN


u_trig_stretch : process(clk, reset)
   begin
      if (reset = '1') then  
         trig_stretch 	<= '0';
			trig_cnt 		<= x"00000000";
			prev_sig_in 	<= '0';
			sig_out 			<= '0';
		elsif (clk'event AND clk = '1') then 
			prev_sig_in <= sig_in;
			sig_out 			<= '0';
			if (prev_sig_in = '0') and (sig_in = '1') then 
				trig_stretch <= '1';
			end if;
	
			if (trig_stretch = '1') THEN
					trig_cnt <= trig_cnt + 1;
					if(trig_cnt >= len) then
						trig_stretch 	<= '0';
						trig_cnt 		<= x"00000000"; 
					end if;
					sig_out 			<= trig_cnt(23);
			end if;
					

		end if;
end process; 
		 

END stretch_architecture;
