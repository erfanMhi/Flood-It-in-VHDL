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
			is_over			: out std_logic;
			key_reg_b		: in std_logic_vector(3 downto 0);
			keys_b			: in std_logic_vector(3 downto 0)
			--HEX5_b	: out std_logic_vector(6 downto 0)
  );
end Board;

architecture Behavioral of Board is
	type mem_type is array (0 to 11, 0 to 11) of std_logic_vector(11 downto 0);
   signal ColorOutput: std_logic_vector(11 downto 0);
  
	--- memory
	signal cs_wr_t: STD_LOGIC := '1';
	signal wr_i, wr_j, wr_i_reg, wr_j_reg, mem_wr_j, mem_wr_i: integer range 0 to 16:= 0;					
	signal data_wr_t: std_logic_vector(11 downto 0);
	signal mem: mem_type;
  
  
  
	type init_type is (initializing, write_to_mem, initialize_end);
	signal initial_state : init_type := initializing;
	signal initial_state_reg : init_type := initializing;
	
	signal is_initialized, is_initialized_reg: std_logic := '0';
  
  --- control status ---
   signal white_counter: integer range 0 to 255:= 0;
	signal selected_counter: integer range 0 to 255:=0;
  
   signal rnd_val: std_logic_vector(31 downto 0);

	signal is_over_t: std_logic := '0';
	
	signal ex_color, selected_color, ex_color_reg, selected_color_reg: std_logic_vector(11 downto 0);	
	signal clicked_state, clicked_state_reg: std_logic;
	
	signal en_t, StackEmpty_t, StackFull_t, push_pop_t: STD_LOGIC;				
	signal DataIn_t, DataOut_t: std_logic_vector(7 downto 0);
	
	component LFSR32 is
		Port(
			Resetn: in std_logic;
			Clk: in std_logic;
			LFSR32Out: out std_logic_vector(31 downto 0)
		);
	end component;
	
	Component Stack_DS is
	generic(
		   Data_Width : integer := 8; 
		   Addr_Width : integer := 7
		   );
	 port(
		 clk, reset, en : in STD_LOGIC;
		 push_pop: in STD_LOGIC; -- 1 means push 0 means pop
		 StackEmpty, StackFull: out STD_Logic;
		 DataIn : in std_logic_vector(Data_Width-1 downto 0);
		 DataOut : out std_logic_vector(Data_Width-1 downto 0)
	     );
	end Component;


begin

	random_gen: LFSR32
		Port map(
			Resetn => '1',
			Clk => CLK_50MHz,
			LFSR32Out => rnd_val
		);
		
	sd : Stack_DS
	port map (									 
		clk => CLK_50MHz,
		reset => RESET,
		en => en_t,
		push_pop => push_pop_t,
		StackEmpty => StackEmpty_t,
		StackFull => StackFull_t,
		DataIn => DataIn_t,
		DataOut => DataOut_t
	); 
	
	--- Color to display ---
	ColorOut <= ColorOutput;

	--- counting white cells ---
	is_over_t <=  '1' when ((selected_counter + white_counter) = 100) else '0';
	is_over <= is_over_t;
	
	---- Process to count white numbers ----
	white_count_proc: process(mem)
	variable tmp_white: integer; 
	begin
		tmp_white := 0;
		for i in 0 to 11 loop
			for j in 0 to 11 loop
				if mem(i, j) = colors(4) then
					tmp_white := tmp_white + 1; 
				end if;
			end loop;
		end loop;
		white_counter <= tmp_white;
	end process;
	
	selected_counter_proc: process(mem)
	variable tmp_select: integer; 
	begin
		tmp_select := 0;
		for i in 0 to 11 loop
			for j in 0 to 11 loop
				if mem(i, j) = selected_color_reg then
					tmp_select := tmp_select + 1; 
				end if;
			end loop;
		end loop;
		selected_counter <= tmp_select;
	end process;
--	
	
	
	--- Setting value of color for each pixel ---
	color_painter: process(ScanlineX, scanlineY)
	variable tmp_color_output: std_LOGIC_vector(11 downto 0);
	begin
	tmp_color_output := "111111111111" and colorize_cell("00000010011", "00000001111" + std_logic_vector(to_unsigned(4, 11)), ScanlineX, ScanlineY, colors(3)) 
												and colorize_cell("00000010011", "00000001111" + std_logic_vector(to_unsigned(5, 11)), ScanlineX, ScanlineY, colors(2)) 
												and colorize_cell("00000010011", "00000001111" + std_logic_vector(to_unsigned(6, 11)), ScanlineX, ScanlineY, colors(1)) 
												and colorize_cell("00000010011", "00000001111" + std_logic_vector(to_unsigned(7, 11)), ScanlineX, ScanlineY, colors(0));

		for i in 0 to 11 loop
			for j in 0 to 11 loop
				tmp_color_output := tmp_color_output and colorize_cell("00000000110" + std_logic_vector(to_unsigned(i, 11)), "00000001111" + std_logic_vector(to_unsigned(j, 11)), ScanlineX, ScanlineY, mem(i, j)) ;
			end loop;
		end loop;
	ColorOutput <= tmp_color_output;

	end process;
	
	-- WTF --
	in1_logic: process(CLK_50MHz)
	begin
		if (CLK_50MHz'event and CLK_50MHz='1') then	
			if (cs_wr_t = '1') then
				mem(mem_wr_i, mem_wr_j) <= data_wr_t;
			end if;
		end if;
	end process;
	
	
	


	initilize_proc: process(CLK_50MHz, RESET)
	begin
		if reset = '1' then
			initial_state_reg <= initializing;
			is_initialized_reg <= '0';
			wr_i_reg <= 0;
			wr_j_reg <= 0;
			ex_color_reg <= (others => '1');
			selected_color_reg <= (others => '1');
			clicked_state_reg <= '0';
		elsif rising_edge(clk_50MHz) then
			initial_state_reg <= initial_state;
			is_initialized_reg <= is_initialized;
			wr_i_reg <= wr_i;
			wr_j_reg <= wr_j;
			selected_color_reg <= selected_color;
			ex_color_reg <= ex_color;
			clicked_state_reg <= clicked_state;
		end if;
	
	
	end process;
	
	--HEX5_b <= convSEG("000" & is_over_t);
		
	data_logic_proc: process(initial_state_reg, is_initialized_reg, wr_i_reg, wr_j_reg, rnd_val, selected_color_reg, ex_color_reg, stackEmpty_t)
	begin
				-- initialization --
				cs_wr_t <= '0';
				data_wr_t <= (others => '0');
				wr_i <= 0;
				wr_j <= 0;
				is_initialized <= '0';
				mem_wr_i <= wr_i_reg;
				mem_wr_j <= wr_j_reg;
				selected_color <= selected_color_reg;
				ex_color <= ex_color_reg;
				dataIn_t <= (others => '0');
				clicked_state <= '0';
				push_pop_t <= '0';
				en_t <= '0';
				--HEX5_b <= "0000000";
				case game_state_b is
				when pre_start =>
					if is_initialized_reg = '0' then
						cs_wr_t <= '1';
						if not (wr_i_reg = 0 or wr_j_reg = 0 or wr_i_reg=11 or wr_j_reg=11) then
							data_wr_t <= Colors(to_integer(unsigned(rnd_val)) mod 5);
						end if;
						if (wr_i_reg = 11 and wr_j_reg = 11) then
							is_initialized <= '1';
						elsif wr_j_reg = 11 then
							wr_i <= wr_i_reg +1;
							wr_j <= 0;
						else
							wr_i <= wr_i_reg;
							wr_j <= wr_j_reg + 1;
						end if;
					else
						is_initialized <= '1';
						if (key_reg_b /= keys_b) then	
							if (keys_b(0) = '0') then
								if (colors(0) /= mem(1, 1)) then
									push_pop_t <= '1';
									en_t <= '1';
									cs_wr_t <= '1';
									
									clicked_state <= '1';
								
									selected_color <= Colors(0);
									ex_color <= mem(1,1);
									
									dataIn_t <= "00010001";
									
									mem_wr_i <= 1;
									mem_wr_j <= 1;
									data_wr_t <= Colors(0);
								end if;
							elsif (keys_b(1) = '0') then
								if (colors(1) /= mem(1, 1)) then
									selected_color <= Colors(1);
									ex_color <= mem(1,1);
									dataIn_t <= "00010001";
									clicked_state <= '1';
									push_pop_t <= '1';
									en_t <= '1';
									cs_wr_t <= '1';
									
									mem_wr_i <= 1;
									mem_wr_j <= 1;
									data_wr_t <= Colors(1);
								
								end if;
							elsif (keys_b(2) = '0') then
								if (colors(2) /= mem(1, 1)) then
									selected_color <= Colors(2);
									ex_color <= mem(1,1);
									dataIn_t <= "00010001";
									clicked_state <= '1';
									push_pop_t <= '1';
									en_t <= '1';
									cs_wr_t <= '1';
									
									mem_wr_i <= 1;
									mem_wr_j <= 1;
									data_wr_t <= Colors(2);
								
								end if;
							elsif (keys_b(3) = '0') then
								if (colors(3) /= mem(1, 1)) then
									selected_color <= Colors(3);
									ex_color <= mem(1,1);
									dataIn_t <= "00010001";
									clicked_state <= '1';
									push_pop_t <= '1';
									en_t <= '1';
									cs_wr_t <= '1';
									
									mem_wr_i <= 1;
									mem_wr_j <= 1;
									data_wr_t <= Colors(3);
								
								end if;
							end if;
						end if;
					end if;
				when started =>
					case clicked_state_reg is
					when '0' =>
						--HEX5_b <= "0000001";
						if (key_reg_b /= keys_b) then	
							if (keys_b(0) = '0') then
								if (colors(0) /= mem(1, 1)) then
									push_pop_t <= '1';
									en_t <= '1';
									cs_wr_t <= '1';
									
									clicked_state <= '1';
								
									selected_color <= Colors(0);
									ex_color <= mem(1,1);
									
									dataIn_t <= "00010001";
									
									mem_wr_i <= 1;
									mem_wr_j <= 1;
									data_wr_t <= Colors(0);
								end if;
							elsif (keys_b(1) = '0') then
								if (colors(1) /= mem(1, 1)) then
									selected_color <= Colors(1);
									ex_color <= mem(1,1);
									dataIn_t <= "00010001";
									clicked_state <= '1';
									push_pop_t <= '1';
									en_t <= '1';
									cs_wr_t <= '1';
									
									mem_wr_i <= 1;
									mem_wr_j <= 1;
									data_wr_t <= Colors(1);
								
								end if;
							elsif (keys_b(2) = '0') then
								if (colors(2) /= mem(1, 1)) then
									selected_color <= Colors(2);
									ex_color <= mem(1,1);
									dataIn_t <= "00010001";
									clicked_state <= '1';
									push_pop_t <= '1';
									en_t <= '1';
									cs_wr_t <= '1';
									
									mem_wr_i <= 1;
									mem_wr_j <= 1;
									data_wr_t <= Colors(2);
								
								end if;
							elsif (keys_b(3) = '0') then
								if (colors(3) /= mem(1, 1)) then
									selected_color <= Colors(3);
									ex_color <= mem(1,1);
									dataIn_t <= "00010001";
									clicked_state <= '1';
									push_pop_t <= '1';
									en_t <= '1';
									cs_wr_t <= '1';
									
									mem_wr_i <= 1;
									mem_wr_j <= 1;
									data_wr_t <= Colors(3);
								
								end if;
							end if;
						end if;
					--- clicked ---
					when '1' =>
						clicked_state <= '1';
						
						--tmp_i := to_integer(unsigned(DataOut_t(7 downto 4)));
						--tmp_j := to_integer(unsigned(DataOut_t(3 downto 0)));
						--HEX5_b <= convSEG(std_logic_vector(to_unsigned(tmp_j, 4)));
						if stackEmpty_t = '1' then
							clicked_state <= '0';
							cs_wr_t <= '0';
						elsif to_integer(unsigned(DataOut_t(3 downto 0))) /= 10 and 
									mem(to_integer(unsigned(DataOut_t(7 downto 4))), to_integer(unsigned(DataOut_t(3 downto 0)))+1) = ex_color_reg then
							push_pop_t <= '1';
							en_t <= '1';
							cs_wr_t <= '1';
							
							dataIn_t <= DataOut_t(7 downto 4) & (DataOut_t(3 downto 0)+1);
							
							mem_wr_i <= to_integer(unsigned(DataOut_t(7 downto 4)));
							mem_wr_j <= to_integer(unsigned(DataOut_t(3 downto 0)))+1;
							data_wr_t <= selected_color;
						elsif to_integer(unsigned(DataOut_t(3 downto 0))) /= 1 and 
									mem(to_integer(unsigned(DataOut_t(7 downto 4))), to_integer(unsigned(DataOut_t(3 downto 0)))-1) = ex_color_reg then
							push_pop_t <= '1';
							en_t <= '1';
							cs_wr_t <= '1';
							
							dataIn_t <= DataOut_t(7 downto 4) & (DataOut_t(3 downto 0)-1);
							
							mem_wr_i <= to_integer(unsigned(DataOut_t(7 downto 4)));
							mem_wr_j <= to_integer(unsigned(DataOut_t(3 downto 0)))-1;
							data_wr_t <= selected_color;
						elsif to_integer(unsigned(DataOut_t(7 downto 4))) /= 10 and 
									mem(to_integer(unsigned(DataOut_t(7 downto 4)))+1, to_integer(unsigned(DataOut_t(3 downto 0)))) = ex_color_reg then
							push_pop_t <= '1';
							en_t <= '1';
							cs_wr_t <= '1';
							
							dataIn_t <= (DataOut_t(7 downto 4)+1) & DataOut_t(3 downto 0);

						
							mem_wr_i <= to_integer(unsigned(DataOut_t(7 downto 4)))+1;
							mem_wr_j <= to_integer(unsigned(DataOut_t(3 downto 0)));
							data_wr_t <= selected_color;
						elsif to_integer(unsigned(DataOut_t(7 downto 4))) /= 1 and
									mem(to_integer(unsigned(DataOut_t(7 downto 4)))-1, to_integer(unsigned(DataOut_t(3 downto 0)))) = ex_color_reg then
							push_pop_t <= '1';
							en_t <= '1';
							cs_wr_t <= '1';

							dataIn_t <= (DataOut_t(7 downto 4)-1) & DataOut_t(3 downto 0);
						
							mem_wr_i <= to_integer(unsigned(DataOut_t(7 downto 4)))-1;
							mem_wr_j <= to_integer(unsigned(DataOut_t(3 downto 0)));
							data_wr_t <= selected_color;
						else
							push_pop_t <= '0';
							en_t <= '1';
							cs_wr_t <= '0';
						end if;
				
				end case;
				when lost =>
				when win =>
			end case;
	
	end process;
	
	

	
end Behavioral;

