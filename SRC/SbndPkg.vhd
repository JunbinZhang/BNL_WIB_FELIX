LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

package SbndPkg is
   type SL_ARRAY_1_TO_0 	is array (natural range <>) of STD_LOGIC_VECTOR(1 downto 0);	
   type SL_ARRAY_3_TO_0 	is array (natural range <>) of STD_LOGIC_VECTOR(3 downto 0);		
   type SL_ARRAY_7_TO_0	  	is array (natural range <>) of STD_LOGIC_VECTOR(7 downto 0);	
   type SL_ARRAY_11_TO_0	is array (natural range <>) of STD_LOGIC_VECTOR(11 downto 0);		
   type SL_ARRAY_15_TO_0	is array (natural range <>) of STD_LOGIC_VECTOR(15 downto 0);	
   type SL_ARRAY_16_TO_0	is array (natural range <>) of STD_LOGIC_VECTOR(16 downto 0);	
   type SL_ARRAY_23_TO_0	is array (natural range <>) of STD_LOGIC_VECTOR(23 downto 0);	
	
	type ADC_array 	 		is array (natural range <>) of std_logic_vector(191 downto 0);
	type I2C_data_type      is array (natural range <>) of STD_LOGIC_VECTOR(31 downto 0);	
	type I2C_address_type   is array (natural range <>) of STD_LOGIC_VECTOR(11 downto 0); 
	type I2C_WR_type    	 	is array (natural range <>) of STD_LOGIC;	
	type I2C_data_out_type  is array (natural range <>) of STD_LOGIC_VECTOR(31 downto 0);	

   type SL_ARRAY_15_28		is array (0 to 28) of STD_LOGIC_VECTOR(15 downto 0);			
	type SL_2D_Array_15_to_0 is array (natural range <>) of SL_ARRAY_15_28;

	
	
   function PRBS_GEN   (input : STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR;
   function stream_SEL (BRD : STD_LOGIC_VECTOR; CHP : STD_LOGIC_VECTOR) return integer;
end package;

package body SbndPkg is



   function PRBS_GEN (input : STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
      variable temp : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
   begin
      for i in (14) downto 0 loop
         temp(i) := input(i+1);
      end loop;	
      temp(15) := input(15) xor input(4) xor input(2) xor input(1);
      return temp;
   end function;



    function stream_SEL (BRD : STD_LOGIC_VECTOR;CHP : STD_LOGIC_VECTOR) return integer is
	  variable temp : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    begin
			temp	:= BRD(1 downto 0) & CHP(2 downto 0);
          case temp is
             when "00000"  => return 0;
             when "00001"  => return 0;
             when "00010"  => return 1;
             when "00011"  => return 1;
             when "00100"  => return 2;
             when "00101"  => return 2;
             when "00110"  => return 3;
             when "00111"  => return 3;
             when "01000"  => return 4;
             when "01001"  => return 4;
             when "01010"  => return 5;
             when "01011"  => return 5;
             when "01100"  => return 6;
             when "01101"  => return 6;
             when "01110"  => return 7;
             when "01111"  => return 7;				 
             when "10000"  => return 8;
             when "10001"  => return 8;
             when "10010"  => return 9;
             when "10011"  => return 9;
             when "10100"  => return 10;
             when "10101"  => return 10;
             when "10110"  => return 11;
             when "10111"  => return 11;				 
             when "11000"  => return 12;
             when "11001"  => return 12;
             when "11010"  => return 13;
             when "11011"  => return 13;
             when "11100"  => return 14;
             when "11101"  => return 14;
             when "11110"  => return 15;
             when "11111"  => return 15;				 
             when others => return 0;
          end case;
    end function;  	
	
	
	
end package body SbndPkg;