library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package Arithmatic_Lib is
	function multiply(a,b: std_logic_vector(10 downto 0)) return std_logic_vector;
	function to_bcd( bin : std_logic_vector(7 downto 0) ) return std_logic_vector;
end Arithmatic_Lib; 

  
package body Arithmatic_Lib is

	 function multiply(a,b: std_logic_vector(10 downto 0)) return std_logic_vector is
			variable ans:std_logic_vector(10 downto 0);
	  begin
			ans := std_logic_vector(unsigned(a) * unsigned(b))(10 downto 0);
			return ans;
	  
	  end function multiply;
  
	function to_bcd ( bin : std_logic_vector(7 downto 0) ) return std_logic_vector is
		variable i : integer:=0;
		variable bcd : std_logic_vector(11 downto 0) := (others => '0');
		variable bint : std_logic_vector(7 downto 0) := bin;

	begin
		for i in 0 to 7 loop  -- repeating 8 times.
			bcd(11 downto 1) := bcd(10 downto 0);  --shifting the bits.
			bcd(0) := bint(7);
			bint(7 downto 1) := bint(6 downto 0);
			bint(0) :='0';


			if(i < 7 and bcd(3 downto 0) > "0100") then --add 3 if BCD digit is greater than 4.
			bcd(3 downto 0) := bcd(3 downto 0) + "0011";
			end if;

			if(i < 7 and bcd(7 downto 4) > "0100") then --add 3 if BCD digit is greater than 4.
			bcd(7 downto 4) := bcd(7 downto 4) + "0011";
			end if;

			if(i < 7 and bcd(11 downto 8) > "0100") then  --add 3 if BCD digit is greater than 4.
			bcd(11 downto 8) := bcd(11 downto 8) + "0011";
			end if;


		end loop;
		return bcd;
	end to_bcd;

end package body Arithmatic_Lib;