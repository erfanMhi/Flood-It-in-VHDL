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
		   row_len_b 		: in integer;
			column_len_b 	: in integer;
			ColorOut			: out std_logic_vector(11 downto 0); -- RED & GREEN & BLUE
			SQUAREWIDTH		: in std_logic_vector(7 downto 0);
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
	type s_type is array (0 to 99, 0 to 1) of integer;
	type s_cell_type is array (0 to 1) of integer;
	
  shared variable ColorOutput: std_logic_vector(11 downto 0);
  
  signal row_width: std_logic_vector(9 downto 0) := "0000000001";
  
  
  shared variable s: integer := 8;
  signal food_size: std_logic_vector(10 downto 0) := "00000010110";
  signal food_inc: boolean:= false;
  
  signal SquareX: std_logic_vector(9 downto 0) := "0000001110";  
  signal SquareY: std_logic_vector(9 downto 0) := "0000010111";  
  signal SquareXMoveDir, SquareYMoveDir: std_logic := '0';
  --constant SquareWidth: std_logic_vector(4 downto 0) := "11001";
  constant SquareXmin: std_logic_vector(9 downto 0) := "0000000001";
  signal SquareXmax: std_logic_vector(9 downto 0); -- := "1010000000"-SquareWidth;
  constant SquareYmin: std_logic_vector(9 downto 0) := "0000000001";
  signal SquareYmax: std_logic_vector(9 downto 0); -- := "0111100000"-SquareWidth;
  signal ColorSelect: std_logic_vector(2 downto 0) := "001";
  signal Prescaler: std_logic_vector(40 downto 0) := (others => '0');
  
	signal cs_wr_t, cs_rd_t: STD_LOGIC := '1';
	shared variable rd_i, rd_j, wr_i, wr_j: integer := 0;					
	signal data_wr_t, data_rd_t: std_logic_vector(11 downto 0);
  
  signal is_initialized: std_logic := '0';
  signal initilize_counter: integer := 0;
  shared variable white_counter: integer := 0;
  
  signal rnd_val: std_logic_vector(31 downto 0);

	signal mem: mem_type;

	
	signal stack: s_type;
	signal stack_pointer: integer := -1;
	signal stack_wr_t: std_logic := '0';
	signal stack_wr_data: s_cell_type;
	signal current_cell_pointer: s_cell_type;
	signal current_color_pointer: std_logic_vector(11 downto 0);
	signal selected_color: std_logic_vector(11 downto 0);
	signal repaint_all: std_logic_vector(2 downto 0) := "000";
	
	signal started_counter: integer := 0;
	
  	component twoD_memory is
		generic(
			row_length: integer := 10;
			column_length: integer := 10;
			data_length: integer := 12
			);
		 port(
			 clk, cs_wr, cs_rd : in STD_LOGIC;
			 addr_rd_i, addr_rd_j, addr_wr_i, addr_wr_j : in integer;
			 data_wr : in std_logic_vector(data_length-1 downto 0);
			 data_rd : out std_logic_vector(data_length-1 downto 0)
			  );
	end component;
	
	component LFSR32 is
		Port(
			Resetn: in std_logic;
			Clk: in std_logic;
			LFSR32Out: out std_logic_vector(31 downto 0)
		);
	end component;


begin

	--- counting white cells ---
	white_num <= white_counter;
	
	stack_mem_logic: process(CLK_50MHz)
	begin
		if (CLK_50MHz'event and CLK_50MHz='1') then	
			if (stack_wr_t = '1') then
				stack(stack_pointer, 0) <= stack_wr_data(0);
				stack(stack_pointer, 1) <= stack_wr_data(1);
			end if;
		end if;
	end process;
	
	white_count_proc: process(mem)
	begin
	white_counter := 0;
		for i in 0 to 9 loop
			for j in 0 to 9 loop
				if mem(i, j) = colors(4) then
					white_counter := white_counter + 1; 
				end if;
			end loop;
		end loop;
	end process;

	in1_logic: process(CLK_50MHz)
	begin
		if (CLK_50MHz'event and CLK_50MHz='1') then	
			if (cs_wr_t = '1') then
				mem(wr_i, wr_j) <= data_wr_t;
			end if;
		end if;
	end process;
	
	random_gen: LFSR32
		Port map(
			Resetn => '1',
			Clk => CLK_50MHz,
			LFSR32Out => rnd_val
		);

	initilize_proc: process(CLK_50MHz, RESET)
	begin
		if reset = '1' then
			is_initialized <= '0';
			wr_i := 0;
			wr_j := 0;
			initilize_counter <= 0;
			stack_pointer <= -1;
			repaint_all <= "000";
			HEX5_b <= "0000000";
			cs_wr_t <= '0';
			current_cell_pointer <= (0, 0);
			stack_wr_t <= '0';
			current_color_pointer <= (others => '0');
			selected_color <= (others => '0');
		elsif rising_edge(clk_50MHz) then
			case game_state_b is
				when input_catch =>
				when pre_start =>
					if is_initialized = '0' then
						cs_wr_t <= '1';
						if initilize_counter = 2 then
						---- create the array ---- 
							initilize_counter <= 0;
							if wr_j = column_len_b-1 then
								if wr_i = row_len_b-1 then
									is_initialized <= '1';
									cs_wr_t <= '0';
								else
									wr_j := 0;
									wr_i := wr_i + 1;
								end if;
							else
								wr_j := wr_j + 1;
							end if;
						else
							data_wr_t <= colors(to_integer(unsigned(rnd_val) mod 5));
							initilize_counter <= initilize_counter + 1;
						end if;
					end if;
				when started =>
					--cs_wr_t <= '0';
					--HEX5_b <= convSEG("0" & repaint_all);
						if repaint_all = "001" then
							--HEX5_b <= convSEG("0111");
							stack_wr_t <= '0';
							cs_wr_t <= '1';
							if stack_pointer = -1 then
								repaint_all <= "000";
								stack_wr_t <= '0';
								cs_wr_t <= '0';
								--HEX5_b <= convSEG("1101");
							else
								current_cell_pointer(0) <= stack(stack_pointer,0);
								current_cell_pointer(1) <= stack(stack_pointer,1);
								wr_i := current_cell_pointer(0);
								wr_j := current_cell_pointer(1);
								data_wr_t <= selected_color;
								repaint_all <= "110";	
							end if;
						elsif repaint_all = "110" then
							stack_wr_t <= '0';
							stack_pointer <= stack_pointer - 1;
							repaint_all <= "010";
						elsif repaint_all = "010" then 
							repaint_all <= "011";
							if current_cell_pointer(1)+1 < 10 then
								if mem(current_cell_pointer(0), current_cell_pointer(1)+1) = current_color_pointer then
									stack_wr_t <= '1';
									stack_pointer <= stack_pointer + 1;
									stack_wr_data <= (current_cell_pointer(0), current_cell_pointer(1)+1);
									cs_wr_t <= '1';
									wr_i := current_cell_pointer(0);
									wr_j := current_cell_pointer(1)+1;
									data_wr_t <= selected_color;
									--HEX5_b <= convSEG("1001");
								end if;
							end if;
						elsif repaint_all = "011" then 
							repaint_all <= "100";
							if current_cell_pointer(0)+1 < 10 then
								if mem(current_cell_pointer(0)+1, current_cell_pointer(1)) = current_color_pointer then
									stack_wr_t <= '1';
									stack_pointer <= stack_pointer + 1;
									stack_wr_data <= (current_cell_pointer(0)+1, current_cell_pointer(1));
									cs_wr_t <= '1';
									wr_i := current_cell_pointer(0)+1;
									wr_j := current_cell_pointer(1);
									data_wr_t <= selected_color;
									--HEX5_b <= convSEG("1010");
								end if;
							end if;
						elsif repaint_all = "100" then 
							repaint_all <= "101";
							if current_cell_pointer(0)-1 > -1 then
								if mem(current_cell_pointer(0)-1, current_cell_pointer(1)) = current_color_pointer then
									stack_wr_t <= '1';
									stack_pointer <= stack_pointer + 1;
									stack_wr_data <= (current_cell_pointer(0)-1, current_cell_pointer(1));
									cs_wr_t <= '1';
									wr_i := current_cell_pointer(0)-1;
									wr_j := current_cell_pointer(1);
									data_wr_t <= selected_color;
									--HEX5_b <= convSEG("1011");
								end if;
							end if;
						elsif repaint_all = "101" then 
							repaint_all <= "001";
							if current_cell_pointer(1)-1 > -1 then
								if mem(current_cell_pointer(0), current_cell_pointer(1)-1) = current_color_pointer then
									stack_wr_t <= '1';
									stack_pointer <= stack_pointer + 1;
									stack_wr_data <= (current_cell_pointer(0), current_cell_pointer(1)-1);
									cs_wr_t <= '1';
									wr_i := current_cell_pointer(0);
									wr_j := current_cell_pointer(1)-1;
									data_wr_t <= selected_color;
									--HEX5_b <= convSEG("1100");
								end if;
							end if;
						end if;


						if (key_reg_b /= keys_b) then	
							if (keys_b(0) = '0') then
								if (colors(0) /= mem(0, 0)) then
									stack_wr_t <= '1';
									stack_pointer <= 0;
									stack_wr_data <= (0, 0);
									selected_color <= colors(0);
									current_color_pointer <= mem(0, 0);
									repaint_all <= "001";
									HEX5_b <= convSEG("0000");
								end if;
							elsif (keys_b(1) = '0') then
								if (colors(1) /= mem(0, 0)) then
									stack_wr_t <= '1';
									stack_pointer <= 0;
									stack_wr_data <= (0, 0);
									selected_color <= colors(1);
									current_color_pointer <= mem(0, 0);
									repaint_all <= "001";
									HEX5_b <= convSEG("0001");
								end if;
							elsif (keys_b(2) = '0') then
								if (colors(2) /= mem(0, 0)) then
									stack_wr_t <= '1';
									stack_pointer <= 0;
									stack_wr_data <= (0, 0);
									selected_color <= colors(2);
									current_color_pointer <= mem(0, 0);
									repaint_all <= "001";
									HEX5_b <= convSEG("0010");
								end if;
							elsif (keys_b(3) = '0') then
								if (colors(3) /= mem(0, 0)) then
									stack_wr_t <= '1';
									stack_pointer <= 0;
									stack_wr_data <= (0, 0);
									selected_color <= colors(3);
									current_color_pointer <= mem(0, 0);
									repaint_all <= "001";
									HEX5_b <= convSEG("0011");
								end if;
							end if;
						end if;

				when lost =>
				when win =>
			end case;
		end if;
	
	
	end process;

	
	color_painter: process(ScanlineX, scanlineY)
	begin
		cs_rd_t <= '1';
		ColorOutput := "111111111111";
		for i in 0 to 9 loop
			for j in 0 to 9 loop
				colorOutput := ColorOutput and colorize_cell("00000011000" + std_logic_vector(to_unsigned(i, 11)), "00000011111" + std_logic_vector(to_unsigned(j, 11)), ScanlineX, ScanlineY, mem(i, j)) ;
			end loop;
		end loop;

	end process;
	
	ColorOut <= ColorOutput;
	
	SquareXmax <= "1010000000"-SquareWidth; -- (640 - SquareWidth)
	SquareYmax <= "0111100000"-SquareWidth;	-- (480 - SquareWidth)
	
end Behavioral;

