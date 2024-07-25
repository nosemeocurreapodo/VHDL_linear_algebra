library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.request_id_pack.all;
use work.FPU_interface_pack.all;
use work.Matrix_definition_pack.all;

entity Matrix_testbench is
end entity Matrix_testbench;

architecture rtl of Matrix_testbench is
	component Matrix3x3_VMultiplier_slow is
		port(
			clk                   : in  std_logic;
			new_operation_request : in  std_logic;
			new_operation_done    : out std_logic;
			Matrix_input          : in  Matrix3x3;
			Vector_input          : in  Vector3;
			Vector_output         : out Vector3;
			-- External FPU
			BUS_to_ROU            : out BUS_to_real_operation_unit;
			BUS_from_ROU          : in  BUS_from_real_operation_unit
		);
	end component;
	component Fixed_point_unit
		port(
			clk         : in  std_logic;
			FPU_BUS_in  : in  BUS_to_fixed_point_unit;
			FPU_BUS_out : out BUS_from_fixed_point_unit
		);
	end component;

	signal clk : std_logic := '1';

	-- FPU
	signal FPU_BUS_to   : BUS_to_fixed_point_unit;
	signal FPU_BUS_from : BUS_from_fixed_point_unit;

	-- Matrix3x3_VMultiplier
	signal new_operation_request : std_logic := '0';
	signal new_operation_done    : std_logic;
	signal Matrix_input          : Matrix3x3;
	signal Vector_input          : Vector3;
	signal Vector_ouput          : Vector3;

	signal BUS_to_ROU   : BUS_to_real_operation_unit;
	signal BUS_from_ROU : BUS_from_real_operation_unit;

	-- random number generator
	signal rand_num : integer := 0;

begin
	Matrix3x3_VMultiplier_INSTANTIATION : Matrix3x3_VMultiplier_slow port map(
			clk                   => clk,
			new_operation_request => new_operation_request,
			new_operation_done    => new_operation_done,
			Matrix_input          => Matrix_input,
			Vector_input          => Vector_input,
			Vector_output         => Vector_ouput,
			-- External FPU
			BUS_to_ROU            => BUS_to_ROU,
			BUS_from_ROU          => BUS_from_ROU);

	-- instantiate fpu
	FPU_slow_INSTANTIATION : Fixed_point_unit port map(
			clk         => clk,
			FPU_BUS_in  => FPU_BUS_to,
			FPU_BUS_out => FPU_BUS_from);

	FPU_BUS_to   <= BUS_to_ROU;
	BUS_from_ROU <= FPU_BUS_from;

	clk <= not (clk) after 5 ns;

	verify : process(clk)
		variable Matrix_input_A : Matrix3x3;
		variable Matrix_input_B : Matrix3x3;
		variable Vector_input_A : Vector3;
		variable Vector_input_B : Vector3;
		variable Matrix_output  : Matrix3x3;
		variable Vector_output  : Vector3;

		variable aux : integer := 0;

		variable out_of_time_request : integer := 0;

		--random number generator
		variable seed1, seed2  : positive; -- seed values for random generator
		variable rand          : real;  -- random real-number value in range 0 to 1.0  
		variable range_of_rand : real := 10.0; -- the range of random values created will be 0 to +1000.
	begin
		if (rising_edge(clk)) then
			if (new_operation_done = '1') then
				for I in 0 to 8 loop
					uniform(seed1, seed2, rand); -- generate random number
					rand_num          <= integer(rand * range_of_rand); -- rescale to 0..1000, convert integer part 
					Matrix_input_A(I) := to_fixed_point(std_logic_vector(to_signed(rand_num, fixed_point_size)));
				end loop;
				for I in 0 to 8 loop
					uniform(seed1, seed2, rand); -- generate random number
					rand_num          <= integer(rand * range_of_rand); -- rescale to 0..1000, convert integer part 
					Matrix_input_B(I) := to_fixed_point(std_logic_vector(to_signed(rand_num, fixed_point_size)));
				end loop;
				for I in 0 to 2 loop
					uniform(seed1, seed2, rand); -- generate random number
					rand_num          <= integer(rand * range_of_rand); -- rescale to 0..1000, convert integer part 
					Vector_input_A(I) := to_fixed_point(std_logic_vector(to_signed(rand_num, fixed_point_size)));
				end loop;
				for I in 0 to 2 loop
					uniform(seed1, seed2, rand); -- generate random number
					rand_num          <= integer(rand * range_of_rand); -- rescale to 0..1000, convert integer part 
					Vector_input_B(I) := to_fixed_point(std_logic_vector(to_signed(rand_num, fixed_point_size)));
				end loop;

				new_operation_request <= '1';
				Matrix_Input          <= Matrix_Input_A;
				Vector_Input          <= Vector_Input_A;

			--				aux := rand_num * rand_num + rand_num * rand_num + rand_num * rand_num;
			--
			--				Vector_output(0) := to_fixed_point(std_logic_vector(to_signed(aux, fixed_point_size)));
			--				Vector_output(1) := to_fixed_point(std_logic_vector(to_signed(aux, fixed_point_size)));
			--				Vector_output(2) := to_fixed_point(std_logic_vector(to_signed(aux, fixed_point_size)));
			--			
			--				FPU_BUS_to.new_request_id <= to_signed(aux, request_id_size);

			end if;
		--			if (FPU_BUS_from.request_ready = '1') then
		--				assert FPU_BUS_from.output = FPU_BUS_out.request_ready_id
		--					report "Error en el resultado"
		--					severity failure;
		--			end if;
		end if;
	end process verify;
end rtl;