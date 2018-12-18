library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package Arithmatic_Lib is
  function multiply(a,b: std_logic_vector(10 downto 0)) return std_logic_vector;
end Arithmatic_Lib; 

  
package body Arithmatic_Lib is

 function multiply(a,b: std_logic_vector(10 downto 0)) return std_logic_vector is
		variable ans:std_logic_vector(10 downto 0);
  begin
		ans := std_logic_vector(unsigned(a) * unsigned(b))(10 downto 0);
		return ans;
  
  end function multiply;

end package body Arithmatic_Lib;