library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Matrix_definitions_pack.all;
use work.Matrix_component_pack.all;

entity Vector8_convolution_fast is
	generic(
		IN_SIZE         : integer := 32;
		IN_FRAC_SIZE    : integer := 23;
		ADD_1_SIZE      : integer := 32;
		ADD_1_FRAC_SIZE : integer := 23;
		ADD_2_SIZE      : integer := 32;
		ADD_2_FRAC_SIZE : integer := 23;
		ADD_3_SIZE      : integer := 32;
		ADD_3_FRAC_SIZE : integer := 23;
		OUT_SIZE        : integer := 32;
		OUT_FRAC_SIZE   : integer := 23;
		AUX_SIZE        : integer := 32
	);
	port(
		clk       : in  std_logic;
		do_conv   : in  std_logic;
		conv_done : out std_logic;
		input     : in  std_logic_vector(IN_SIZE - 1 downto 0);
		output    : out std_logic_vector(OUT_SIZE - 1 downto 0)
	);
end entity;

architecture RTL of Vector8_convolution_fast is

	type state_type is (IDLE, LOADING, BUSY_1, BUSY_2);
	signal state : state_type := IDLE;

	signal Vector1_input : Vector(7 downto 0)(IN_SIZE - 1 downto 0);
	signal Vector2_input : Vector(7 downto 0)(IN_SIZE - 1 downto 0);
	signal scalar_output : std_logic_vector(OUT_SIZE - 1 downto 0);

	signal do_dot   : std_logic;
	signal dot_done : std_logic;

	signal counter    : integer := 1;
	
begin

	Vector8_dot_fast_instantiation : Vector8_dot_fast 
	generic map
	(
		IN_SIZE         => IN_SIZE,
		IN_FRAC_SIZE    => IN_FRAC_SIZE,
		ADD_1_SIZE      => ADD_1_SIZE,
		ADD_1_FRAC_SIZE => ADD_1_FRAC_SIZE,
		ADD_2_SIZE      => ADD_2_SIZE,
		ADD_2_FRAC_SIZE => ADD_2_FRAC_SIZE,
		ADD_3_SIZE      => ADD_3_SIZE,
		ADD_3_FRAC_SIZE => ADD_3_FRAC_SIZE,
		OUT_SIZE        => OUT_SIZE,
		OUT_FRAC_SIZE   => OUT_FRAC_SIZE,
		AUX_SIZE        => AUX_SIZE
	)
	port map
	(
		clk           => clk,
		new_op        => do_dot,
		op_done       => dot_done,
		aux_in        => std_logic_vector(to_unsigned(0, AUX_SIZE)),
		Vector1_input => Vector1_input,
		Vector2_input => Vector2_input,
		output        => scalar_output
	);

	displacement_filter : 
	process(clk)
	begin
		if (rising_edge(clk)) then
			for I in 0 to 6 loop
				Vector1_input(I) <= Vector1_input(I+1);
			end loop;
			Vector1_input(7) <= input;
			output  <= scalar_output;
			conv_done <= dot_done;
		end if;
	end process;

	state_machine : 
	process(clk)
	begin
		if (rising_edge(clk)) then
			case state is
				when IDLE =>
					if (do_conv = '1') then
						counter <= 1;
						Vector2_input(0) <= Vector1_input(0);
						state <= LOADING;
					else
						counter <= 0;
					end if;
				when LOADING =>
					if(do_conv = '0') then
						state <= IDLE;
					else
						counter <= counter + 1;
						Vector2_input(counter) <= Vector1_input(counter);
						if(counter = 7) then
							state <= BUSY_1;
							do_dot <= '1';
						end if;
					end if;
				when BUSY_1 =>
					if(do_conv = '0') then
						do_dot <= '0';
						state <= BUSY_2;
					end if;
				when BUSY_2 =>
					if(dot_done = '0') then
						state <= IDLE;
					end if;
			end case;
		end if;
	end process;

end architecture;

