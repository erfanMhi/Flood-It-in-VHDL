library IEEE;
use IEEE.STD_LOGIC_1164.all;

package game_lib is

	type game_states is (pre_start, started, lost, win);
	type color_data is array (0 to 4) of std_logic_vector(11 downto 0);
	constant colors : color_data := (
		"111100000000", -- red
		"111111110000", -- yellow
		"000000001111", -- green
		"000011110000", -- blue
		"111111111111"	 -- white
	);
end game_lib;

package body game_lib is

end game_lib; 