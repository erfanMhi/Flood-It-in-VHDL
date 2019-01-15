----------------------------------------------------------------------------------
-- Moving Square Demonstration 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

LIBRARY work;
use work.Graphic_Lab.all;
use work.Game_Lib.all;


entity Board is
  port ( CLK_50MHz		: in std_logic;
			RESET				: in std_logic;
			game_state_b	: in game_states;
			ColorOut			: out std_logic_vector(11 downto 0); -- RED & GREEN & BLUE
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0);
			white_num		: out integer;
			key_reg_b		: in std_logic_vector(3 downto 0);
			keys_b			: in std_logic_vector(3 downto 0);
			HEX5_b	: out std_logic_vector(6 downto 0)
  );
end Board;

architecture Behavioral of Board is
	type mem_type is array (0 to 9, 0 to 9) of std_logic_vector(11 downto 0);
	type Voltage_Level is range 0 to 5;
   signal ColorOutput: std_logic_vector(11 downto 0);
  
	--- memory
	signal cs_wr_t: STD_LOGIC := '1';
	signal wr_i, wr_j, wr_i_reg, wr_j_reg: integer range 0 to 10:= 0;					
	signal data_wr_t: std_logic_vector(11 downto 0);
	signal mem: mem_type;
  
  
	signal is_initialized, is_initialized_reg: std_logic := '0';
  
  --- control status ---
   signal white_counter: integer range 0 to 100:= 0;
  
   signal rnd_val: std_logic_vector(31 downto 0);


		
	component LFSR32 is
		Port(
			Resetn: in std_logic;
			Clk: in std_logic;
			LFSR32Out: out std_logic_vector(31 downto 0)
		);
	end component;


begin

	random_gen: LFSR32
		Port map(
			Resetn => '1',
			Clk => CLK_50MHz,
			LFSR32Out => rnd_val
		);
	
	--- Color to display ---
	ColorOut <= ColorOutput;

	--- counting white cells ---
	white_num <= white_counter;
	
	---- Process to count white numbers ----
	white_count_proc: process(mem)
	variable tmp_white: integer; 
	begin
		tmp_white := 0;
		for i in 0 to 9 loop
			for j in 0 to 9 loop
				if mem(i, j) = colors(4) then
					tmp_white := tmp_white + 1; 
				end if;
			end loop;
		end loop;
		white_counter <= tmp_white;
	end process;
	
	--- Setting value of color for each pixel ---
	color_painter: process(ScanlineX, scanlineY)
	variable tmp_color_output: std_LOGIC_vector(11 downto 0);
	begin
		tmp_color_output := "111111111111";
		for i in 0 to 9 loop
			for j in 0 to 9 loop
				tmp_color_output := tmp_color_output and colorize_cell("00000011000" + std_logic_vector(to_unsigned(i, 11)), "00000011111" + std_logic_vector(to_unsigned(j, 11)), ScanlineX, ScanlineY, mem(i, j)) ;
			end loop;
		end loop;
	ColorOutput <= tmp_color_output;

	end process;
	
	-- WTF --
	in1_logic: process(CLK_50MHz)
	begin
		if (CLK_50MHz'event and CLK_50MHz='1') then	
			if (cs_wr_t = '1') then
				mem(wr_i_reg, wr_j_reg) <= data_wr_t;
			end if;
		end if;
	end process;
	


	initilize_proc: process(CLK_50MHz, RESET)
	begin
		if reset = '1' then
			is_initialized_reg <= '0';
			wr_i_reg <= 0;
			wr_j_reg <= 0;
		elsif rising_edge(clk_50MHz) then
			is_initialized_reg <= is_initialized;
			wr_i_reg <= wr_i;
			wr_j_reg <= wr_j;
		end if;
	
	
	end process;
		
	HEX5_b <= convSEG("000" & is_initialized);
	data_logic_proc: process(is_initialized_reg, wr_i_reg, wr_j_reg, rnd_val)
	begin
				-- initialization --
				cs_wr_t <= '0';
				data_wr_t <= (others => '0');
				wr_i <= 0;
				wr_j <= 0;
				is_initialized <= '0';
				
				case game_state_b is
				when pre_start =>
					if is_initialized_reg = '0' then
						cs_wr_t <= '1';
						data_wr_t <= Colors(to_integer(unsigned(rnd_val)) mod 5);
						if (wr_i_reg = 9 and wr_j_reg = 9) then
							is_initialized <= '1';
						elsif wr_j_reg = 9 then
							wr_i <= wr_i_reg +1;
							wr_j <= 0;
						else
							wr_i <= wr_i_reg;
							wr_j <= wr_j_reg + 1;
						end if;
					else
						is_initialized <= '1';
					end if;
				when started =>
				
				
				
				when lost =>
				when win =>
			end case;
	
	end process;
	
	

	
end Behavioral;

