library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Fixed_point_interface_pack.all;
use work.Floatin_point_interface_pack.all;
use work.Matrix_definition_pack.all;

entity Matrix3x3_VMultiplier_slow is
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
end entity Matrix3x3_VMultiplier_slow;

architecture RTL of Matrix3x3_VMultiplier_slow is
	signal Matrix_input_reg       : Matrix3x3;
	signal Vector_input_reg       : Vector3;
	signal Vector_output_reg      : Vector3;
	signal new_operation_done_reg : std_logic := '1';

	type general_state_type is (IDLE,
		                        CV_0, CV_1, CV_2,
		                        ALMOST_READY, READY);
	signal general_state : general_state_type := IDLE;

	type actual_state_type is (IDLE, MUL_1, MUL_2, ADD_1, MUL_3, ADD_2, READY);
	signal actual_state : actual_state_type := IDLE;

	signal actual_state_opA : scalar_real;
	signal actual_state_opB : scalar_real;
	signal actual_state_opC : scalar_real;
	signal actual_state_opD : scalar_real;
	signal actual_state_opE : scalar_real;
	signal actual_state_opF : scalar_real;

	signal actual_state_out   : scalar_real;
	signal actual_state_aux1  : scalar_real;
	signal actual_state_start : std_logic := '0';
	signal actual_state_ready : std_logic := '0';

	signal BUS_to_ROU_reg : BUS_to_real_operation_unit := BUS_to_fixed_point_initial_state;

begin
	new_operation_done <= new_operation_done_reg;
	BUS_to_ROU         <= BUS_to_ROU_reg;

	Multiply_3x3_Vector_Actual_StateMachine : process(clk)
	begin
		if (rising_edge(clk)) then
			case actual_state is
				when IDLE =>
					actual_state_ready         <= '0';
					BUS_to_ROU_reg.new_request <= '0';
					if (actual_state_start = '1') then
						actual_state <= MUL_1;
					end if;
				when MUL_1 =>
					if (BUS_from_ROU.ready_for_request = '1') then
						BUS_to_ROU_reg.opa            <= actual_state_opA;
						BUS_to_ROU_reg.opb            <= actual_state_opB;
						BUS_to_ROU_reg.fpu_op         <= MUL;
						BUS_to_ROU_reg.rmode          <= nearest_even;
						BUS_to_ROU_reg.new_request    <= '1';
						BUS_to_ROU_reg.new_request_id <= to_signed(0, request_id_size);

						actual_state <= MUL_2;
					end if;
				when MUL_2 =>
					BUS_to_ROU_reg.new_request <= '0';
					if (BUS_from_ROU.request_ready = '1' and BUS_from_ROU.ready_for_request = '1') then
						actual_state_aux1 <= BUS_from_ROU.output;

						BUS_to_ROU_reg.opa            <= actual_state_opC;
						BUS_to_ROU_reg.opb            <= actual_state_opD;
						BUS_to_ROU_reg.fpu_op         <= MUL;
						BUS_to_ROU_reg.rmode          <= nearest_even;
						BUS_to_ROU_reg.new_request    <= '1';
						BUS_to_ROU_reg.new_request_id <= to_signed(0, request_id_size);

						actual_state <= ADD_1;
					end if;
				when ADD_1 =>
					BUS_to_ROU_reg.new_request <= '0';
					if (BUS_from_ROU.request_ready = '1' and BUS_from_ROU.ready_for_request = '1') then
						BUS_to_ROU_reg.opa            <= actual_state_aux1;
						BUS_to_ROU_reg.opb            <= BUS_from_ROU.output;
						BUS_to_ROU_reg.fpu_op         <= ADD;
						BUS_to_ROU_reg.rmode          <= nearest_even;
						BUS_to_ROU_reg.new_request    <= '1';
						BUS_to_ROU_reg.new_request_id <= to_signed(0, request_id_size);

						actual_state <= MUL_3;
					end if;
				when MUL_3 =>
					BUS_to_ROU_reg.new_request <= '0';
					if (BUS_from_ROU.request_ready = '1' and BUS_from_ROU.ready_for_request = '1') then
						actual_state_aux1 <= BUS_from_ROU.output;

						BUS_to_ROU_reg.opa            <= actual_state_opE;
						BUS_to_ROU_reg.opb            <= actual_state_opF;
						BUS_to_ROU_reg.fpu_op         <= MUL;
						BUS_to_ROU_reg.rmode          <= nearest_even;
						BUS_to_ROU_reg.new_request    <= '1';
						BUS_to_ROU_reg.new_request_id <= to_signed(0, request_id_size);

						actual_state <= ADD_2;
					end if;
				when ADD_2 =>
					BUS_to_ROU_reg.new_request <= '0';
					if (BUS_from_ROU.request_ready = '1' and BUS_from_ROU.ready_for_request = '1') then
						BUS_to_ROU_reg.opa            <= actual_state_aux1;
						BUS_to_ROU_reg.opb            <=  BUS_from_ROU.output;
						BUS_to_ROU_reg.fpu_op         <= ADD;
						BUS_to_ROU_reg.rmode          <= nearest_even;
						BUS_to_ROU_reg.new_request    <= '1';
						BUS_to_ROU_reg.new_request_id <= to_signed(0, request_id_size);

						actual_state <= READY;
					end if;
				when READY =>
					BUS_to_ROU_reg.new_request <= '0';
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
						Vector_input_reg <= Vector_input;

						new_operation_done_reg <= '0';
						general_state          <= CV_0;
					end if;
				when CV_0 =>
					actual_state_opA <= Matrix_input_reg(0);
					actual_state_opB <= Vector_input_reg(0);
					actual_state_opC <= Matrix_input_reg(1);
					actual_state_opD <= Vector_input_reg(1);
					actual_state_opE <= Matrix_input_reg(2);
					actual_state_opF <= Vector_input_reg(2);

					actual_state_start <= '1';

					general_state <= CV_1;
				when CV_1 =>
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Vector_output_reg(0) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(3);
						actual_state_opB <= Vector_input_reg(0);
						actual_state_opC <= Matrix_input_reg(4);
						actual_state_opD <= Vector_input_reg(1);
						actual_state_opE <= Matrix_input_reg(5);
						actual_state_opF <= Vector_input_reg(2);

						actual_state_start <= '1';

						general_state <= CV_2;
					end if;
				when CV_2 =>
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Vector_output_reg(1) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(6);
						actual_state_opB <= Vector_input_reg(0);
						actual_state_opC <= Matrix_input_reg(7);
						actual_state_opD <= Vector_input_reg(1);
						actual_state_opE <= Matrix_input_reg(8);
						actual_state_opF <= Vector_input_reg(2);

						actual_state_start <= '1';

						general_state <= ALMOST_READY;
					end if;
				when ALMOST_READY =>
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Vector_output_reg(2) <= actual_state_out;

						general_state <= READY;
					end if;
				when READY =>
					Vector_output          <= Vector_output_reg;
					new_operation_done_reg <= '1';
					general_state          <= IDLE;
			end case;
		end if;
	end process;
end architecture RTL;

