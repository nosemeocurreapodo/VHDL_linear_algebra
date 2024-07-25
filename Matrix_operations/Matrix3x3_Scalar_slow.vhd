library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Fixed_point_interface_pack.all;
use work.Floatin_point_interface_pack.all;
use work.Matrix_definition_pack.all;

entity Matrix3x3_Scalar_slow is
	port(
		clk                             : in  std_logic;
		new_operation_request           : in  std_logic;
		new_operation_done              : out std_logic;
		Matrix_input                    : in  Matrix3x3;
		Scalar_input                    : in  scalar_real;
		Matrix_output                   : out Matrix3x3;

		-- External FPU
		BUS_to_ROU                      : out BUS_to_real_operation_unit;
		BUS_from_ROU                    : in  BUS_from_real_operation_unit
	);
end entity Matrix3x3_Scalar_slow;

architecture RTL of Matrix3x3_Scalar_slow is

	signal Matrix_input_reg  : Matrix3x3;
	signal Scalar_input_reg  : scalar_real;
	signal Matrix_output_reg : Matrix3x3;

	type general_state_type is (IDLE,
		                        M_00, M_01, M_02,
		                        M_10, M_11, M_12,
		                        M_20, M_21, M_22,
		                        ALMOST_READY, READY);
	signal general_state : general_state_type := IDLE;

	type actual_state_type is (IDLE, ISSUE_NEW_OP, WAIT_FOR_OP, READY);
	signal actual_state : actual_state_type := IDLE;

	signal actual_state_opA : scalar_real;
	signal actual_state_opB : scalar_real;

	signal actual_state_out   : scalar_real;
	signal actual_state_start : std_logic := '0';
	signal actual_state_ready : std_logic := '0';

begin
	Multiply_3x3_Matrix_Actual_StateMachine : process(clk)
	begin
		if (rising_edge(clk)) then
			case actual_state is
				when IDLE =>
					actual_state_ready <= '0';
					if (actual_state_start = '1') then
						actual_state <= ISSUE_NEW_OP;
					end if;
				when ISSUE_NEW_OP =>
					if (BUS_from_ROU.ready_for_request = '1') then
						BUS_to_ROU.opa            <= actual_state_opA;
						BUS_to_ROU.opb            <= actual_state_opB;
						BUS_to_ROU.fpu_op         <= DIV;
						BUS_to_ROU.rmode          <= nearest_even;
						BUS_to_ROU.new_request    <= '1';
						BUS_to_ROU.new_request_id <= to_signed(0, request_id_size);

						actual_state <= WAIT_FOR_OP;
					end if;
				when WAIT_FOR_OP =>
					if (BUS_from_ROU.request_ready = '1') then
						actual_state <= READY;
					end if;
				when READY =>
					if (BUS_from_ROU.request_ready = '1') then
						actual_state_out   <= BUS_from_ROU.output;
						actual_state_ready <= '1';
						actual_state       <= IDLE;
					end if;
			end case;
		end if;
	end process;

	Invert_3x3_Matrix_General_StateMachine : process(clk)
	begin
		if (rising_edge(clk)) then
			case general_state is
				when IDLE =>
					if (new_operation_request = '1') then
						Matrix_input_reg <= Matrix_input;
						Scalar_input_reg <= Scalar_input;

						new_operation_done <= '0';
						general_state      <= M_00;
					end if;
				when M_00 =>
					--M00 = A00*B00 + A01*B10 + A02*B20
					actual_state_opA <= Matrix_input_reg(0);
					actual_state_opB <= Scalar_input_reg;

					actual_state_start <= '1';

					general_state <= M_01;
				when M_01 =>
					--M01 = A00*B01 + A01*B11 + A02*B21
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(0) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(1);
						actual_state_opB <= Scalar_input_reg;

						actual_state_start <= '1';

						general_state <= M_02;
					end if;
				when M_02 =>
					--M02 = A00*B02 + A01*B12 + A02*B22
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(1) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(2);
						actual_state_opB <= Scalar_input_reg;

						actual_state_start <= '1';

						general_state <= M_10;
					end if;
				when M_10 =>
					--M10 = A10*B00 + A11*B10 + A12*B20
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(2) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(3);
						actual_state_opB <= Scalar_input_reg;

						actual_state_start <= '1';

						general_state <= M_11;
					end if;
				when M_11 =>
					--M11 = A10*B01 + A11*B11 + A12*B21
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(3) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(4);
						actual_state_opB <= Scalar_input_reg;

						actual_state_start <= '1';

						general_state <= M_12;
					end if;
				when M_12 =>
					--M12 = A10*B02 + A11*B12 + A12*B22
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(4) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(5);
						actual_state_opB <= Scalar_input_reg;

						actual_state_start <= '1';

						general_state <= M_20;
					end if;
				when M_20 =>
					--M20 = A20*B00 + A21*B10 + A22*B20
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(5) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(6);
						actual_state_opB <= Scalar_input_reg;

						actual_state_start <= '1';

						general_state <= M_21;
					end if;
				when M_21 =>
					--M21 = A20*B01 + A21*B11 + A22*B21
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(6) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(7);
						actual_state_opB <= Scalar_input_reg;

						actual_state_start <= '1';

						general_state <= M_22;
					end if;
				when M_22 =>
					--M22 = A20*B02 + A21*B12 + A22*B22
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(7) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(8);
						actual_state_opB <= Scalar_input_reg;

						actual_state_start <= '1';

						general_state <= ALMOST_READY;
					end if;

				when ALMOST_READY =>
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(8) <= actual_state_out;

						general_state <= READY;
					end if;
				when READY =>
					Matrix_output <= Matrix_output_reg;

					new_operation_done <= '1';
					general_state      <= IDLE;
			end case;
		end if;
	end process;
end architecture RTL;

