library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.Game_Lib.all;
use work.Arithmatic_Lib.all;
use work.Graphic_Lab.all;

entity SevenSegments is
		port (
				game_state_s: in game_states;
				time_counter: in integer;
				move_counter: in integer;
				rows: in integer;
				columns: in integer;
				HEX0_s	: out std_logic_vector(6 downto 0);
				HEX1_s	: out std_logic_vector(6 downto 0);
				HEX2_s	: out std_logic_vector(6 downto 0);
				HEX3_s	: out std_logic_vector(6 downto 0);
				HEX4_s	: out std_logic_vector(6 downto 0);
				HEX5_s	: out std_logic_vector(6 downto 0)	
		);
end SevenSegments;
	
	
architecture sevenSegments_arch of SevenSegments is 

begin

	 process(game_state_s, rows, columns, move_counter, time_counter) 
	 variable tmp: std_logic_vector(11 downto 0);
	 begin
		case game_state_s is
			when pre_start =>
				tmp := to_bcd(std_logic_vector(to_unsigned(11, 8)));
				HEX0_s <= convSEG(tmp(3 downto 0));
				HEX1_s <= convSEG(tmp(7 downto 4));
				
				tmp := to_bcd(std_logic_vector(to_unsigned(1, 8)));
				HEX2_s <= convSEG(tmp(3 downto 0));
				HEX3_s <= convSEG(tmp(7 downto 4));
				
				HEX4_s <= convSEG("0000");
				HEX5_s <= convSEG("0000");
			when started =>
				tmp := to_bcd(std_logic_vector(to_unsigned(move_counter, 8)));
				HEX0_s <= convSEG(tmp(3 downto 0));
				HEX1_s <= convSEG(tmp(7 downto 4));
				
				tmp := to_bcd(std_logic_vector(to_unsigned(time_counter, 8)));
				HEX2_s <= convSEG(tmp(3 downto 0));
				HEX3_s <= convSEG(tmp(7 downto 4));
				
				HEX4_s <= convSEG("0000");
				HEX5_s <= convSEG("0000");
			when lost =>
				tmp := to_bcd(std_logic_vector(to_unsigned(22, 8)));
				HEX0_s <= convSEG(tmp(3 downto 0));
				HEX1_s <= convSEG(tmp(7 downto 4));
				
				tmp := to_bcd(std_logic_vector(to_unsigned(0, 8)));
				HEX2_s <= convSEG(tmp(3 downto 0));
				HEX3_s <= convSEG(tmp(7 downto 4));
				
				tmp := to_bcd(std_logic_vector(to_unsigned(0, 8)));
				HEX4_s <= convSEG(tmp(3 downto 0));
				HEX5_s <= convSEG(tmp(7 downto 4));
			when win =>
				tmp := to_bcd(std_logic_vector(to_unsigned(11, 8)));
				HEX0_s <= convSEG(tmp(3 downto 0));
				HEX1_s <= convSEG(tmp(7 downto 4));
				
				tmp := to_bcd(std_logic_vector(to_unsigned(0, 8)));
				HEX2_s <= convSEG(tmp(3 downto 0));
				HEX3_s <= convSEG(tmp(7 downto 4));
				
				tmp := to_bcd(std_logic_vector(to_unsigned(0, 8)));
				HEX4_s <= convSEG(tmp(3 downto 0));
				HEX5_s <= convSEG(tmp(7 downto 4));
		end case;
	 end process;


end sevenSegments_arch;
