library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;

use work.FPU_definitions_pack.all;
use work.Matrix_definition_pack.all;
use work.Matrix_component_pack.all;

entity Vector8_convolution_fast is
	port(
		clk                      : in  std_logic;
		new_operation_request    : in  std_logic;
		new_operation_done       : out std_logic;
		input                    : in  scalar;
		output                   : out scalar
	);
end entity Vector8_convolution_fast;

architecture RTL of Vector8_convolution_fast is

	type state_type is (IDLE, LOADING, BUSY);
	signal state : state_type := IDLE;

	signal Vector1_input            : Vector8;
	signal Vector2_input            : Vector8;
	signal scalar_output            : scalar;

	signal op_request : std_logic := '0';
	signal op_done    : std_logic;

	signal counter    : integer := 1;
	
begin

	Vector8_dot_fast_instantiation : Vector8_dot_fast port map(
			clk                      => clk,
			new_operation_request    => op_request,
			new_operation_request_id => request_id_zero,
			new_operation_done       => op_done,
			Vector1_input            => Vector1_input,
			Vector2_input            => Vector2_input,
			output                   => scalar_output);

	new_operation_done <= op_done;

	state_machine : process(clk)
	begin
		if (rising_edge(clk)) then
			case state is
				when IDLE =>
					if (new_operation_request = '1') then
						Vector1_input(0) <= scalar_zero;
						Vector2_input(0) <= input;
						counter <= 1;
						state <= LOADING;
					end if;
				when LOADING =>
					Vector1_input(counter) <= scalar_zero;
					Vector2_input(counter) <= input;
					if(counter = 7) then
						state <= BUSY;
						op_request <= '1';
					end if;
					if(new_operation_request = '0') then
						state <= IDLE;
					end if;
					counter <= counter + 1;
				when BUSY =>
					for I in 0 to 6 loop
						Vector1_input(I) <= Vector1_input(I+1);
					end loop;
					Vector1_input(7) <= input;
					if (op_done = '1') then
						state <= IDLE;
						op_request <= '0';
					end if;
			end case;
		end if;
	end process state_machine;

end architecture RTL;

