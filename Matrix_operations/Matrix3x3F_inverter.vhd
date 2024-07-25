library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DTAM_FPGA_definitions_pack.all;

-- M = 00, 01, 02
--     10, 11, 12
--     20, 21, 22

-- invM = (11*22 - 21*12, 02*21 - 01*22, 01*12 - 02*11
--		  12*20 - 10*22, 00*22 - 02*20, 02*10 - 00*12
--        10*21 - 11*20, 01*02 - 00*21, 00*11 - 01*10) / determinant;

-- determinant = 00*11*22 + 01*12*20 + 02*10*21 - 02*11*20 - 01*10*22 - 00*12*21

entity Matrix3x3F_inverter is
	port(
		clk               : in  std_logic;
		start             : in  std_logic;
		invertion_ready   : out std_logic;
		Matrix_input      : in  Matrix3x3F;
		inv_Matrix_output : out Matrix3x3F
	);
end entity Matrix3x3F_inverter;

architecture RTL of Matrix3x3F_inverter is
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

	signal Matrix_input_reg      : Matrix3x3F;
	signal inv_Matrix_output_reg : Matrix3x3F;

	signal fpu_opa   : std_logic_vector(FP_SIZE - 1 downto 0);
	signal fpu_opb   : std_logic_vector(FP_SIZE - 1 downto 0);
	signal fpu_out   : std_logic_vector(FP_SIZE - 1 downto 0);
	signal fpu_op    : std_logic_vector(2 downto 0);
	signal fpu_rmode : std_logic_vector(1 downto 0) := "00";
	signal fpu_start : std_logic                    := '0';
	signal fpu_ready : std_logic;

	type general_state_type is (IDLE,
		                        Determinant_1, Determinant_2,
		                        Determinant_3, Determinant_4,
		                        Determinant_5, Determinant_6,
		                        Determinant_READY,
		                        Processing_0_0, Processing_0_1, Processing_0_2,
		                        Processing_1_0, Processing_1_1, Processing_1_2,
		                        Processing_2_0, Processing_2_1, Processing_2_2,
		                        ALMOST_READY, READY);
	signal general_state : general_state_type := IDLE;

	type actual_state_type is (IDLE, MUL_1, MUL_2, SUB, DIV, CMUL_1, CMUL_2, CADD, READY);
	signal actual_state : actual_state_type := IDLE;

	signal actual_state_opA : std_logic_vector(FP_SIZE - 1 downto 0);
	signal actual_state_opB : std_logic_vector(FP_SIZE - 1 downto 0);
	signal actual_state_opC : std_logic_vector(FP_SIZE - 1 downto 0);
	signal actual_state_opD : std_logic_vector(FP_SIZE - 1 downto 0);

	signal actual_state_out1 : std_logic_vector(FP_SIZE - 1 downto 0);
	--signal actual_state_out2 : std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal actual_state_out  : std_logic_vector(FP_SIZE - 1 downto 0);

	signal actual_state_start : std_logic := '0';
	signal actual_state_ready : std_logic := '0';

	signal calculating_determinant : std_logic;
	signal determinant_reg         : std_logic_vector(FP_SIZE - 1 downto 0) := x"00000000";

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

	Invert_3x3_Matrix_Actual_StateMachine : process(clk)
	begin
		if (rising_edge(clk)) then
			case actual_state is
				when IDLE =>
					actual_state_ready <= '0';
					if (actual_state_start = '1') then
						if (calculating_determinant = '1') then
							actual_state <= CMUL_1;
						else
							actual_state <= MUL_1;
						end if;
					end if;
				-- PARA CALCULAR EL DETERMINANTE
				when CMUL_1 =>
					fpu_opa   <= actual_state_opA;
					fpu_opb   <= actual_state_opB;
					fpu_op    <= "010";
					--fpu_rmode <= "00";
					fpu_start <= '1';

					actual_state <= CMUL_2;
				when CMUL_2 =>
					fpu_start <= '0';
					if (fpu_ready = '1') then
						fpu_opa   <= actual_state_opC;
						fpu_opb   <= fpu_out;
						fpu_op    <= "010";
						--fpu_rmode <= "00";
						fpu_start <= '1';

						actual_state <= CADD;
					end if;
				when CADD =>
					fpu_start <= '0';
					if (fpu_ready = '1') then
						fpu_opa   <= actual_state_opD;
						fpu_opb   <= fpu_out;
						fpu_op    <= "000";
						--fpu_rmode <= "00";
						fpu_start <= '1';

						actual_state <= READY;
					end if;
				-- PARA CALCULAR LA INVERSA
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
						actual_state_out1 <= fpu_out;

						fpu_opa   <= actual_state_opC;
						fpu_opb   <= actual_state_opD;
						fpu_op    <= "010";
						--fpu_rmode <= "00";
						fpu_start <= '1';

						actual_state <= SUB;
					end if;
				when SUB =>
					fpu_start <= '0';
					if (fpu_ready = '1') then
						fpu_opa   <= actual_state_out1;
						fpu_opb   <= fpu_out;
						fpu_op    <= "001";
						--fpu_rmode <= "00";
						fpu_start <= '1';

						actual_state <= DIV;
					end if;
				when DIV =>
					fpu_start <= '0';
					if (fpu_ready = '1') then
						fpu_opa   <= fpu_out;
						fpu_opb   <= determinant_reg;
						fpu_op    <= "011";
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
					invertion_ready <= '0';
					if (start = '1') then
						Matrix_input_reg <= Matrix_input;

						calculating_determinant <= '1';
						general_state           <= Determinant_1;
					end if;
				-- PARA EL DETERMINANTE
				--determinant = 00*11*22 + 01*12*20 + 02*10*21 - 02*11*20 - 01*10*22 - 00*12*21
				when Determinant_1 =>
					actual_state_opA <= Matrix_input_reg(0);
					actual_state_opB <= Matrix_input_reg(4);
					actual_state_opC <= Matrix_input_reg(8);
					actual_state_opD <= x"00000000";

					actual_state_start <= '1';

					general_state <= Determinant_2;
				when Determinant_2 =>
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						actual_state_opA <= Matrix_input_reg(1);
						actual_state_opB <= Matrix_input_reg(5);
						actual_state_opC <= Matrix_input_reg(6);
						actual_state_opD <= actual_state_out;

						actual_state_start <= '1';

						general_state <= Determinant_3;
					end if;
				when Determinant_3 =>
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						actual_state_opA <= Matrix_input_reg(2);
						actual_state_opB <= Matrix_input_reg(3);
						actual_state_opC <= Matrix_input_reg(7);
						actual_state_opD <= actual_state_out;

						actual_state_start <= '1';

						general_state <= Determinant_4;
					end if;
				when Determinant_4 =>
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						--invierto el signo para restar!
						actual_state_opA <= not (Matrix_input_reg(2)(FP_SIZE - 1)) & Matrix_input_reg(2)(FP_SIZE - 2 downto 0);
						actual_state_opB <= Matrix_input_reg(4);
						actual_state_opC <= Matrix_input_reg(6);
						actual_state_opD <= actual_state_out;

						actual_state_start <= '1';

						general_state <= Determinant_5;
					end if;
				when Determinant_5 =>
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						actual_state_opA <= not (Matrix_input_reg(1)(FP_SIZE - 1)) & Matrix_input_reg(1)(FP_SIZE - 2 downto 0);
						actual_state_opB <= Matrix_input_reg(3);
						actual_state_opC <= Matrix_input_reg(8);
						actual_state_opD <= actual_state_out;

						actual_state_start <= '1';

						general_state <= Determinant_6;
					end if;
				when Determinant_6 =>
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						actual_state_opA <= not (Matrix_input_reg(0)(FP_SIZE - 1)) & Matrix_input_reg(0)(FP_SIZE - 2 downto 0);
						actual_state_opB <= Matrix_input_reg(5);
						actual_state_opC <= Matrix_input_reg(7);
						actual_state_opD <= actual_state_out;

						actual_state_start <= '1';

						general_state <= Determinant_READY;
					end if;
				when Determinant_READY =>
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						calculating_determinant <= '0';
						determinant_reg         <= actual_state_out;
						general_state           <= Processing_0_0;

					end if;
				-- PARA LA INVERSA
				when Processing_0_0 =>
					--11*22 - 21*12,
					actual_state_opA <= Matrix_input_reg(4);
					actual_state_opB <= Matrix_input_reg(8);
					actual_state_opC <= Matrix_input_reg(7);
					actual_state_opD <= Matrix_input_reg(5);

					actual_state_start <= '1';

					general_state <= Processing_0_1;
				when Processing_0_1 =>
					--02*21 - 01*22
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						inv_Matrix_output_reg(0) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(2);
						actual_state_opB <= Matrix_input_reg(7);
						actual_state_opC <= Matrix_input_reg(1);
						actual_state_opD <= Matrix_input_reg(8);

						actual_state_start <= '1';

						general_state <= Processing_0_2;
					end if;
				when Processing_0_2 =>
					--01*12 - 02*11
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						inv_Matrix_output_reg(1) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(1);
						actual_state_opB <= Matrix_input_reg(5);
						actual_state_opC <= Matrix_input_reg(2);
						actual_state_opD <= Matrix_input_reg(4);

						actual_state_start <= '1';

						general_state <= Processing_1_0;
					end if;
				when Processing_1_0 =>
					--12*20 - 10*22
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						inv_Matrix_output_reg(2) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(5);
						actual_state_opB <= Matrix_input_reg(6);
						actual_state_opC <= Matrix_input_reg(3);
						actual_state_opD <= Matrix_input_reg(8);

						actual_state_start <= '1';

						general_state <= Processing_1_1;
					end if;
				when Processing_1_1 =>
					--00*22 - 02*20
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						inv_Matrix_output_reg(3) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(0);
						actual_state_opB <= Matrix_input_reg(8);
						actual_state_opC <= Matrix_input_reg(2);
						actual_state_opD <= Matrix_input_reg(6);

						actual_state_start <= '1';

						general_state <= Processing_1_2;
					end if;
				when Processing_1_2 =>
					--02*10 - 00*12
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						inv_Matrix_output_reg(4) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(2);
						actual_state_opB <= Matrix_input_reg(3);
						actual_state_opC <= Matrix_input_reg(0);
						actual_state_opD <= Matrix_input_reg(5);

						actual_state_start <= '1';

						general_state <= Processing_2_0;
					end if;
				when Processing_2_0 =>
					--10*21 - 11*20
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						inv_Matrix_output_reg(5) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(3);
						actual_state_opB <= Matrix_input_reg(7);
						actual_state_opC <= Matrix_input_reg(4);
						actual_state_opD <= Matrix_input_reg(6);

						actual_state_start <= '1';

						general_state <= Processing_2_1;
					end if;
				when Processing_2_1 =>
					--01*02 - 00*21
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						inv_Matrix_output_reg(6) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(1);
						actual_state_opB <= Matrix_input_reg(2);
						actual_state_opC <= Matrix_input_reg(0);
						actual_state_opD <= Matrix_input_reg(7);

						actual_state_start <= '1';

						general_state <= Processing_2_2;
					end if;
				when Processing_2_2 =>
					--00*11 - 01*10 
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						inv_Matrix_output_reg(7) <= actual_state_out;

						actual_state_opA <= Matrix_input_reg(0);
						actual_state_opB <= Matrix_input_reg(4);
						actual_state_opC <= Matrix_input_reg(1);
						actual_state_opD <= Matrix_input_reg(3);

						actual_state_start <= '1';

						general_state <= ALMOST_READY;
					end if;
				when ALMOST_READY =>
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						inv_Matrix_output_reg(8) <= actual_state_out;

						general_state <= READY;
					end if;
				when READY =>
					inv_Matrix_output <= inv_Matrix_output_reg;
					invertion_ready   <= '1';
					general_state     <= IDLE;
			end case;
		end if;
	end process;

end architecture RTL;

