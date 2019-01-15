-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

LIBRARY work;
use work.Game_Lib.all;
use work.Graphic_lab.all;

entity CAD961Test is
	Port(
		--//////////// CLOCK //////////
		CLOCK_50 	: in std_logic;
		CLOCK2_50	: in std_logic;
		CLOCK3_50	: in std_logic;
		CLOCK4_50	: inout std_logic;
		
		--//////////// KEY //////////
		RESET_N	: in std_logic;
		Key 		: in std_logic_vector(3 downto 0);
	
		--//////////// SEG7 //////////
		HEX0	: out std_logic_vector(6 downto 0);
		HEX1	: out std_logic_vector(6 downto 0);
		HEX2	: out std_logic_vector(6 downto 0);
		HEX3	: out std_logic_vector(6 downto 0);
		HEX4	: out std_logic_vector(6 downto 0);
		HEX5	: out std_logic_vector(6 downto 0);
	
		--//////////// LED //////////
		LEDR	: out std_logic_vector(9 downto 0);
	
		--//////////// SW //////////
		Switch : in std_logic_vector(9 downto 0);
		
		--//////////// SDRAM //////////
		DRAM_ADDR	: out std_logic_vector (12 downto 0);
		DRAM_BA		: out std_logic_vector (1 downto 0); 
		DRAM_CAS_N	: out std_logic;
		DRAM_CKE		: out std_logic;
		DRAM_CLK		: out std_logic;
		DRAM_CS_N	: out std_logic;
		DRAM_DQ		: inout std_logic_vector(15 downto 0);
		DRAM_LDQM	: out std_logic;
		DRAM_RAS_N	: out std_logic;
		DRAM_UDQM	: out std_logic;
		DRAM_WE_N	: out std_logic;
		
		--//////////// microSD Card //////////
		SD_CLK	: out std_logic;
		SD_CMD	: inout std_logic;
		SD_DATA	: inout std_logic_vector(3 downto 0);
		
		--//////////// VGA //////////
		VGA_B		: out std_logic_vector(3 downto 0);
		VGA_G		: out std_logic_vector(3 downto 0);
		VGA_HS	: out std_logic;
		VGA_R		: out std_logic_vector(3 downto 0);
		VGA_VS	: out std_logic;
		
		--//////////// GPIO_1, GPIO_1 connect to LT24 - 2.4" LCD and Touch //////////
		MyLCDLT24_ADC_BUSY		: in std_logic;
		MyLCDLT24_ADC_CS_N		: out std_logic;
		MyLCDLT24_ADC_DCLK		: out std_logic;
		MyLCDLT24_ADC_DIN			: out std_logic;
		MyLCDLT24_ADC_DOUT		: in std_logic;
		MyLCDLT24_ADC_PENIRQ_N	: in std_logic;
		MyLCDLT24_CS_N				: out std_logic;
		MyLCDLT24_D					: out std_logic_vector(15 downto 0);
		MyLCDLT24_LCD_ON			: out std_logic;
		MyLCDLT24_RD_N				: out std_logic;
		MyLCDLT24_RESET_N			: out std_logic;
		MyLCDLT24_RS				: out std_logic;
		MyLCDLT24_WR_N				: out std_logic
	);
end CAD961Test;

--}} End of automatically maintained section

architecture CAD961Test of CAD961Test is

	signal game_state_reg, game_state_next : game_states := pre_start; -- States of the colorfill game
	signal Counter : integer;
	signal ScanlineX,ScanlineY	: std_logic_vector(10 downto 0);
	signal ColorTable	: std_logic_vector(11 downto 0);
	signal move_counter_g : integer := 0;
	signal time_counter_g : integer := 0;
	signal selected_color: std_logic_vector(11 downto 0);
	signal row_num, column_num: integer := 10;
	signal key_reg: std_logic_vector(3 downto 0) := "1111";
	signal white_number: integer;
	
	Component VGA_controller
		port ( CLK_50MHz		: in std_logic;
				VS					: out std_logic;
				HS					: out std_logic;
				RED				: out std_logic_vector(3 downto 0);
				GREEN				: out std_logic_vector(3 downto 0);
				BLUE				: out std_logic_vector(3 downto 0);
				RESET				: in std_logic;
				ColorIN			: in std_logic_vector(11 downto 0);
				ScanlineX		: out std_logic_vector(10 downto 0);
				ScanlineY		: out std_logic_vector(10 downto 0)
	  );
	end component;

	Component Board
		port ( CLK_50MHz		: in std_logic;
				RESET				: in std_logic;
				ColorOut			: out std_logic_vector(11 downto 0); -- RED & GREEN & BLUE
				game_state_b	: in game_states;
				ScanlineX		: in std_logic_vector(10 downto 0);
				ScanlineY		: in std_logic_vector(10 downto 0);
				white_num		: out integer;
				key_reg_b		: in std_logic_vector(3 downto 0);
				keys_b			: in std_logic_vector(3 downto 0);
				HEX5_b	: out std_logic_vector(6 downto 0)
		);
	end component;
	
	Component SevenSegments
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
				HEX4_s	: out std_logic_vector(6 downto 0)
				--HEX5_s	: out std_logic_vector(6 downto 0)		
		);
	end component;
	
	
begin

	 --------- VGA Controller -----------
	 VGA_Control: vga_controller
			port map(
				CLK_50MHz	=> CLOCK3_50,
				VS				=> VGA_VS,
				HS				=> VGA_HS,
				RED			=> VGA_R,
				GREEN			=> VGA_G,
				BLUE			=> VGA_B,
				RESET			=> not RESET_N,
				ColorIN		=> ColorTable,
				ScanlineX	=> ScanlineX,
				ScanlineY	=> ScanlineY
			);
		
		--------- Board Manager -----------
		VGA_SQ: Board
			port map(
				CLK_50MHz		=> CLOCK3_50,
				RESET				=> not RESET_N,
				ColorOut			=> ColorTable,
				game_state_b	=> game_state_reg,
				ScanlineX		=> ScanlineX,
				ScanlineY		=> ScanlineY,
				white_num		=> white_number,
				key_reg_b		=> key_reg,
				keys_b			=> key,
				HEX5_b 			=> HEX5
			);
			
	 ------- Seven Segment Manager -----
	 	SevenSegments_SQ: SevenSegments
			port map(
				game_state_s => game_state_reg,
				time_counter => time_counter_g,
				move_counter => move_counter_g,
				rows => row_num,
				columns => column_num,
				HEX0_s => HEX0,
				HEX1_s => HEX1,
				HEX2_s => HEX2,
				HEX3_s => HEX3,
				HEX4_s => HEX4
				--HEX5_s => HEX5	
			);
			
	 ------- Second Calculator -------
	 second_calc: process(CLOCK3_50, RESET_N) 
	 begin
		if (RESET_N='0') then
			Counter <= 0;
			time_counter_g <= 0;
		elsif (rising_edge(CLOCK3_50)) then
			if (game_state_reg = started) then
				if (Counter = 50000000) then
					Counter <= 0;
					time_counter_g <= time_counter_g+1;
				else
					Counter <= Counter +1;
				end if;
			else
				time_counter_g <= 0;
				Counter <= 0;
			end if;
		end if;
	 end process;
	 
	 
	 --------- Move Counter Calc --------
	 process(CLOCK3_50, RESET_N) 
	 begin
		if (RESET_N='0') then
			move_counter_g <= 0;
		elsif (rising_edge(CLOCK3_50)) then
			if (game_state_reg = started) then
				if (key_reg /= key) then
					if (key(0) = '0') then
						move_counter_g <= move_counter_g + 1;
					elsif (key(1) = '0') then
						move_counter_g <= move_counter_g + 1;
					elsif (key(2) = '0') then
						move_counter_g <= move_counter_g + 1;
					elsif (key(3) = '0') then
						move_counter_g <= move_counter_g + 1;
					end if;
				end if;
			end if;
		end if;
	 end process;
	
	process (CLOCK3_50, ResET_N)
	begin
	if (ResET_N = '0') then
		key_reg <= "1111";
	elsif (rising_edge(CLOCK3_50)) then
		key_reg <= key;
	end if;
	end process;

 
	 game_state_reg_proc: process(CLOCK3_50, RESET_N) 
	 begin
		if (RESET_N='0') then
			game_state_reg <= pre_start;
		elsif (rising_edge(CLOCK3_50)) then
			game_state_reg <= game_state_next;
		end if;
	 end process;
	 
	 game_state_proc: process(game_state_reg, Switch, key) 
	 begin
		game_state_next <= game_state_reg;
		case game_state_reg is
			when pre_start =>
				if (key_reg /= key) then
					if (key(0) = '0') then
						game_state_next <= started;
					elsif (key(1) = '0') then
						game_state_next <= started;
					elsif (key(2) = '0') then
						game_state_next <= started;
					elsif (key(3) = '0') then
						game_state_next <= started;
					end if;
				end if;
			when started =>
				if time_counter_g = 99 then
					game_state_next <= lost;
				end if;
			when lost =>
			when win =>
		end case;
	 end process;
	 
end CAD961Test;
