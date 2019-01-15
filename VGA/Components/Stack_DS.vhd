


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;


entity Stack_DS is
	generic(
		   Data_Width : integer := 8; 
		   Addr_Width : integer := 10
		   );
	 port(
		 clk, reset, en : in STD_LOGIC;
		 push_pop: in STD_LOGIC; -- 1 means push 0 means pop
		 StackEmpty, StackFull: out STD_Logic;
		 DataIn : in std_logic_vector(Data_Width-1 downto 0);
		 DataOut : out std_logic_vector(Data_Width-1 downto 0)
	     );
end Stack_DS;			  

Architecture Stack_DS_Arch of Stack_DS is 
	signal pointer_reg, pointer_next: std_logic_vector(Addr_Width-1 downto 0) := (others => '0');		  
	signal input, output: std_logic_vector(Data_Width-1 downto 0); 
	signal empty, full: std_logic;
	signal push_pop_n: std_logic;
	signal read_pointer: std_logic_vector(Addr_Width-1 downto 0) := (others => '0');
begin
	memory : entity work.DualPortMemory(DualPortMemory)
		port map ( clk => clk,
				   CS1 => push_pop,
				   CS2 => '1',
				   Data1 => input,
				   Data2 => output,
				   WE1 => '1',
				   WE2 => '0',
				   Addr1 => pointer_reg,
				   Addr2 => read_pointer
				   );
	empty <=  '1' when to_integer(unsigned(pointer_reg)) = 0 else '0';
	full <= '1' when to_integer(unsigned(pointer_reg)) = (Addr_Width**2-1) else '0';
	StackFull <= full;
	StackEmpty <= empty;  
	read_pointer <= (pointer_reg -1) when to_integer(unsigned(pointer_reg)) /= 0 else pointer_reg;
	push_pop_n <= not push_pop;
		
		
	input <= DataIn;
	DataOut <= output;
		
		
	data_reg: process(clk, reset)
	begin
		if reset = '1' then
			pointer_reg <= (others => '0');
		elsif (clk'event and clk='1') then
			pointer_reg <= pointer_next;	
		end if;
	end process;
	
	control_logic: process(pointer_reg, push_pop, empty, full, en)
	begin
		pointer_next <= pointer_reg;
		if en = '1' then
			if (push_pop ='1') then
				if 	full = '0' then
					pointer_next <= pointer_reg +1;
				end if;
			else
				if empty = '0' then
					pointer_next <= pointer_reg -1;
				end if;
			end if;	
		end if;
	end process;
	
	

end Stack_DS_Arch;