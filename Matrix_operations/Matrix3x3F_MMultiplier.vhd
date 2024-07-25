library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- A = 00, 01, 02
--     10, 11, 12
--     20, 21, 22

--M00 = A00*B00 + A01*B10 + A02*B20
--M01 = A00*B01 + A01*B11 + A02*B21
--M02 = A00*B02 + A01*B12 + A02*B22

--M10 = A10*B00 + A11*B10 + A12*B20
--M11 = A10*B01 + A11*B11 + A12*B21
--M12 = A10*B02 + A11*B12 + A12*B22

--M20 = A20*B00 + A21*B10 + A22*B20
--M21 = A20*B01 + A21*B11 + A22*B21
--M22 = A20*B02 + A21*B12 + A22*B22

entity Matrix3x3F_MMultiplier is
	port(
		clk                  : in  std_logic;
		start                : in  std_logic;
		multiplication_ready : out std_logic;
		Matrix_input1        : in  Matrix3x3F;
		Matrix_input2        : in  Matrix3x3F;
		Matrix_output        : out Matrix3x3F
	);
end entity Matrix3x3F_MMultiplier;

architecture RTL of Matrix3x3F_MMultiplier is
	component Floating_point_unit is
		port(
			clk_i       : in  std_logic;
			opa_i       : in  std_logic_vector(FP_SIZE - 1 downto 0);
			opb_i       : in  std_logic_vector(FP_SIZE - 1 downto 0);
			fpu_op_i    : in  std_logic_vector(2 downto 0);
			rmode_i     : in  std_logic_vector(1 downto 0);
			output_o    : out std_logic_vector(FP_SIZE - 1 downto 0);
			ine_o       : out std_logic;
			overflow_o  : out std_logic;
			underflow_o : out std_logic;
			div_zero_o  : out std_logic;
			inf_o       : out std_logic;
			zero_o      : out std_logic;
			qnan_o      : out std_logic;
			snan_o      : out std_logic;
			new_request     : in  std_logic;
			ready_o     : out std_logic
		);
	end component Floating_point_unit;

	signal Matrix_input1_reg : Matrix3x3F;
	signal Matrix_input2_reg : Matrix3x3F;
	signal Matrix_output_reg : Matrix3x3F;

	signal fpu_opa   : std_logic_vector(FP_SIZE - 1 downto 0);
	signal fpu_opb   : std_logic_vector(FP_SIZE - 1 downto 0);
	signal fpu_out   : std_logic_vector(FP_SIZE - 1 downto 0);
	signal fpu_op    : std_logic_vector(2 downto 0);
	signal fpu_rmode : std_logic_vector(1 downto 0) := "00";
	signal fpu_start : std_logic                    := '0';
	signal fpu_ready : std_logic;

	type general_state_type is (IDLE,
		                        M_00, M_01, M_02,
		                        M_10, M_11, M_12,
		                        M_20, M_21, M_22,
		                        ALMOST_READY, READY);
	signal general_state : general_state_type := IDLE;

	type actual_state_type is (IDLE, MUL_1, MUL_2, ADD_1, MUL_3, ADD_2, READY);
	signal actual_state : actual_state_type := IDLE;

	signal actual_state_opA : std_logic_vector(FP_SIZE - 1 downto 0);
	signal actual_state_opB : std_logic_vector(FP_SIZE - 1 downto 0);
	signal actual_state_opC : std_logic_vector(FP_SIZE - 1 downto 0);
	signal actual_state_opD : std_logic_vector(FP_SIZE - 1 downto 0);
	signal actual_state_opE : std_logic_vector(FP_SIZE - 1 downto 0);
	signal actual_state_opF : std_logic_vector(FP_SIZE - 1 downto 0);

	signal actual_state_out   : std_logic_vector(FP_SIZE - 1 downto 0);
	signal actual_state_start : std_logic := '0';
	signal actual_state_ready : std_logic := '0';

begin
	Invert_3x3_Matrix_FPU : Floating_point_unit port map(
			clk_i    => clk,
			opa_i    => fpu_opa,
			opb_i    => fpu_opb,
			fpu_op_i => fpu_op,
			rmode_i  => fpu_rmode,
			output_o => fpu_out,
			new_request  => fpu_start,
			ready_o  => fpu_ready
		);

	Multiply_3x3_Matrix_Actual_StateMachine : process(clk)
	begin
		if (rising_edge(clk)) then
			case actual_state is
				when IDLE =>
					actual_state_ready <= '0';
					if (actual_state_start = '1') then
						actual_state <= MUL_1;
					end if;
				when MUL_1 =>
					fpu_opa   <= actual_state_opA;
					fpu_opb   <= actual_state_opB;
					fpu_op    <= "010";
					--fpu_rmode <= "00";
					fpu_start <= '1';

					actual_state <= MUL_2;
				when MUL_2 =>
					fpu_start <= '0';
					if (fpu_ready = '1') then
						actual_state_out <= fpu_out;
						fpu_opa          <= actual_state_opC;
						fpu_opb          <= actual_state_opD;
						fpu_op           <= "010";
						--fpu_rmode <= "00";
						fpu_start        <= '1';

						actual_state <= ADD_1;
					end if;
				when ADD_1 =>
					fpu_start <= '0';
					if (fpu_ready = '1') then
						fpu_opa   <= actual_state_out;
						fpu_opb   <= fpu_out;
						fpu_op    <= "000";
						--fpu_rmode <= "00";
						fpu_start <= '1';

						actual_state <= MUL_3;
					end if;
				when MUL_3 =>
					fpu_start <= '0';
					if (fpu_ready = '1') then
						actual_state_out <= fpu_out;
						fpu_opa          <= actual_state_opE;
						fpu_opb          <= actual_state_opF;
						fpu_op           <= "010";
						--fpu_rmode <= "00";
						fpu_start        <= '1';

						actual_state <= ADD_2;
					end if;
				when ADD_2 =>
					fpu_start <= '0';
					if (fpu_ready = '1') then
						fpu_opa   <= actual_state_out;
						fpu_opb   <= fpu_out;
						fpu_op    <= "000";
						--fpu_rmode <= "00";
						fpu_start <= '1';

						actual_state <= READY;
					end if;
				when READY =>
					fpu_start <= '0';
					if (fpu_ready = '1') then
						actual_state_out   <= fpu_out;
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
					if (start = '1') then
						Matrix_input1_reg <= Matrix_input1;
						Matrix_input2_reg <= Matrix_input2;

						multiplication_ready <= '0';
						general_state        <= M_00;
					end if;
				when M_00 =>
					--M00 = A00*B00 + A01*B10 + A02*B20
					actual_state_opA <= Matrix_input1_reg(0);
					actual_state_opB <= Matrix_input2_reg(0);
					actual_state_opC <= Matrix_input1_reg(1);
					actual_state_opD <= Matrix_input2_reg(3);
					actual_state_opE <= Matrix_input1_reg(2);
					actual_state_opF <= Matrix_input2_reg(6);

					actual_state_start <= '1';

					general_state <= M_01;
				when M_01 =>
					--M01 = A00*B01 + A01*B11 + A02*B21
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(0) <= actual_state_out;

						actual_state_opA <= Matrix_input1_reg(0);
						actual_state_opB <= Matrix_input2_reg(1);
						actual_state_opC <= Matrix_input1_reg(1);
						actual_state_opD <= Matrix_input2_reg(4);
						actual_state_opE <= Matrix_input1_reg(2);
						actual_state_opF <= Matrix_input2_reg(7);

						actual_state_start <= '1';

						general_state <= M_02;
					end if;
				when M_02 =>
					--M02 = A00*B02 + A01*B12 + A02*B22
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(1) <= actual_state_out;

						actual_state_opA <= Matrix_input1_reg(0);
						actual_state_opB <= Matrix_input2_reg(2);
						actual_state_opC <= Matrix_input1_reg(1);
						actual_state_opD <= Matrix_input2_reg(5);
						actual_state_opE <= Matrix_input1_reg(2);
						actual_state_opF <= Matrix_input2_reg(8);

						actual_state_start <= '1';

						general_state <= M_10;
					end if;
				when M_10 =>
					--M10 = A10*B00 + A11*B10 + A12*B20
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(2) <= actual_state_out;

						actual_state_opA <= Matrix_input1_reg(3);
						actual_state_opB <= Matrix_input2_reg(0);
						actual_state_opC <= Matrix_input1_reg(4);
						actual_state_opD <= Matrix_input2_reg(3);
						actual_state_opE <= Matrix_input1_reg(5);
						actual_state_opF <= Matrix_input2_reg(6);

						actual_state_start <= '1';

						general_state <= M_11;
					end if;
				when M_11 =>
					--M11 = A10*B01 + A11*B11 + A12*B21
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(3) <= actual_state_out;

						actual_state_opA <= Matrix_input1_reg(3);
						actual_state_opB <= Matrix_input2_reg(1);
						actual_state_opC <= Matrix_input1_reg(4);
						actual_state_opD <= Matrix_input2_reg(4);
						actual_state_opE <= Matrix_input1_reg(5);
						actual_state_opF <= Matrix_input2_reg(7);

						actual_state_start <= '1';

						general_state <= M_12;
					end if;
				when M_12 =>
					--M12 = A10*B02 + A11*B12 + A12*B22
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(4) <= actual_state_out;

						actual_state_opA <= Matrix_input1_reg(3);
						actual_state_opB <= Matrix_input2_reg(2);
						actual_state_opC <= Matrix_input1_reg(4);
						actual_state_opD <= Matrix_input2_reg(5);
						actual_state_opE <= Matrix_input1_reg(5);
						actual_state_opF <= Matrix_input2_reg(8);

						actual_state_start <= '1';

						general_state <= M_20;
					end if;
				when M_20 =>
					--M20 = A20*B00 + A21*B10 + A22*B20
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(5) <= actual_state_out;

						actual_state_opA <= Matrix_input1_reg(6);
						actual_state_opB <= Matrix_input2_reg(0);
						actual_state_opC <= Matrix_input1_reg(7);
						actual_state_opD <= Matrix_input2_reg(3);
						actual_state_opE <= Matrix_input1_reg(8);
						actual_state_opF <= Matrix_input2_reg(6);

						actual_state_start <= '1';

						general_state <= M_21;
					end if;
				when M_21 =>
					--M21 = A20*B01 + A21*B11 + A22*B21
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(6) <= actual_state_out;

						actual_state_opA <= Matrix_input1_reg(6);
						actual_state_opB <= Matrix_input2_reg(1);
						actual_state_opC <= Matrix_input1_reg(7);
						actual_state_opD <= Matrix_input2_reg(4);
						actual_state_opE <= Matrix_input1_reg(8);
						actual_state_opF <= Matrix_input2_reg(7);

						actual_state_start <= '1';

						general_state <= M_22;
					end if;
				when M_22 =>
					--M22 = A20*B02 + A21*B12 + A22*B22
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Matrix_output_reg(7) <= actual_state_out;

						actual_state_opA <= Matrix_input1_reg(6);
						actual_state_opB <= Matrix_input2_reg(2);
						actual_state_opC <= Matrix_input1_reg(7);
						actual_state_opD <= Matrix_input2_reg(5);
						actual_state_opE <= Matrix_input1_reg(8);
						actual_state_opF <= Matrix_input2_reg(8);

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

					multiplication_ready <= '1';
					general_state        <= IDLE;
			end case;
		end if;
	end process;
end architecture RTL;
