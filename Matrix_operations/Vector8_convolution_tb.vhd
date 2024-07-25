library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.request_id_pack.all;
use work.FPU_definitions_pack.all;
use work.Matrix_definition_pack.all;
use work.Matrix_component_pack.all;

entity Vector8_convolution_tb is
end entity Vector8_convolution_tb;

architecture rtl of Vector8_convolution_tb is

	component Vector8_dot_fast is
		port(
			clk                      : in  std_logic;
			new_operation_request    : in  std_logic;
			new_operation_request_id : in  request_id;
			new_operation_done       : out std_logic;
			new_operation_done_id    : out request_id;
			Vector1_input            : in  Vector8;
			Vector2_input            : in  Vector8;
			output                   : out scalar
		);
	end component Vector8_dot_fast;

	signal clk : std_logic := '1';

	signal new_operation_request    : std_logic := '0';
	signal new_operation_request_id : request_id;
	signal new_operation_done       : std_logic;
	signal new_operation_done_id    : request_id;
	signal Vector1_input            : Vector8;
	signal Vector2_input            : Vector8;
	signal scalar_output            : scalar;

	type state_type is (IDLE, BUSY, READY);
	signal state : state_type := IDLE;

	-- random number generator
	signal rand_num : integer := 0;

begin
	Vector8_dot_fast_instantiation : Vector8_dot_fast port map(
			clk                      => clk,
			new_operation_request    => new_operation_request,
			new_operation_request_id => new_operation_request_id,
			new_operation_done       => new_operation_done,
			new_operation_done_id    => new_operation_done_id,
			Vector1_input            => Vector1_input,
			Vector2_input            => Vector2_input,
			output                   => scalar_output);

	clk <= not (clk) after 5 ns;

	verify : process(clk)
		variable Vector_input_A : Vector8;
		variable Vector_input_B : Vector8;
		variable scalar_output  : scalar;

		--random number generator
		variable seed1, seed2  : positive; -- seed values for random generator
		variable rand          : real;  -- random real-number value in range 0 to 1.0  
		variable range_of_rand : real := 10.0; -- the range of random values created will be 0 to +1000.
	begin
		if (rising_edge(clk)) then
			case state is
				when IDLE =>
					--initialize data
					for I in 0 to 7 loop
						uniform(seed1, seed2, rand); -- generate random number
						rand_num          <= integer(rand * range_of_rand); -- rescale to 0..1000, convert integer part 
						Vector_input_A(I) := to_scalar(std_logic_vector(to_signed(rand_num, fixed_point_size)));
					end loop;
					for I in 0 to 7 loop
						uniform(seed1, seed2, rand); -- generate random number
						rand_num          <= integer(rand * range_of_rand); -- rescale to 0..1000, convert integer part 
						Vector_input_B(I) := to_scalar(std_logic_vector(to_signed(rand_num, fixed_point_size)));
					end loop;
					new_operation_request <= '1';
					state <= BUSY;
				when BUSY =>
					for I in 0 to 6 loop
						Vector_input_A(I) := Vector_input_A(I+1);
					end loop;
					uniform(seed1, seed2, rand); -- generate random number
					rand_num          <= integer(rand * range_of_rand); -- rescale to 0..1000, convert integer part 
					Vector_input_A(7) := to_scalar(std_logic_vector(to_signed(rand_num, fixed_point_size)));
			end case;

			new_operation_request <= '1';
			Vector1_Input         <= Vector_Input_A;
			Vector2_Input         <= Vector_Input_B;

			--				aux := rand_num * rand_num + rand_num * rand_num + rand_num * rand_num;
			--
			--				Vector_output(0) := to_fixed_point(std_logic_vector(to_signed(aux, fixed_point_size)));
			--				Vector_output(1) := to_fixed_point(std_logic_vector(to_signed(aux, fixed_point_size)));
			--				Vector_output(2) := to_fixed_point(std_logic_vector(to_signed(aux, fixed_point_size)));
			--			
			--				FPU_BUS_to.new_request_id <= to_signed(aux, request_id_size);

		end if;
	end process verify;
end rtl;