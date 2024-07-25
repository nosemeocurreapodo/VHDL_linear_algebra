library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DTAM_FPGA_definitions_pack.all;

entity Pose_Inverter is
	port(
		clk                    : in  std_logic;
		start                  : in  std_logic;
		invertion_ready        : out std_logic;
		rotation_matrix        : in  Matrix3x3F;
		translation_vector     : in  Vector3F;
		inv_rotation_matrix    : out Matrix3x3F;
		inv_translation_vector : out Vector3F
	);
end entity Pose_Inverter;

architecture RTL of Pose_Inverter is
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

	component Matrix3x3F_Transposer is
		port(
			clk              : in  std_logic;
			enable           : in  std_logic;
			Matrix_input     : in  Matrix3x3F;
			Matrix_transpose : out Matrix3x3F
		);
	end component Matrix3x3F_Transposer;

	signal rotation_matrix_reg    : Matrix3x3F;
	signal translation_vector_reg : Vector3F;

	signal inv_rotation_matrix_reg    : Matrix3x3F;
	signal inv_translation_vector_reg : Vector3F;

	signal fpu_opa   : std_logic_vector(FP_SIZE - 1 downto 0);
	signal fpu_opb   : std_logic_vector(FP_SIZE - 1 downto 0);
	signal fpu_out   : std_logic_vector(FP_SIZE - 1 downto 0);
	signal fpu_op    : std_logic_vector(2 downto 0);
	signal fpu_rmode : std_logic_vector(1 downto 0);
	signal fpu_start : std_logic := '0';
	signal fpu_ready : std_logic;

	type state_type is (IDLE,
		                A0_MUL_0_0_X, B0_MUL_0_1_Y, C0_SUM_A0_B0, D0_MUL_0_2_Z, E0_SUM_C0_D0,
		                A1_MUL_1_0_X, B1_MUL_1_1_Y, C1_SUM_A1_B1, D1_MUL_1_2_Z, E1_SUM_C1_D1,
		                A2_MUL_2_0_X, B2_MUL_2_1_Y, C2_SUM_A2_B2, D2_MUL_2_2_Z, E2_SUM_C2_D2,
		                ALMOST_READY, READY
	);
	signal state              : state_type := IDLE;
	signal state_machine_aux1 : std_logic_vector(FP_SIZE - 1 downto 0);

begin
	InvertPose_FPU : Floating_point_unit port map(
			clk_i    => clk,
			opa_i    => fpu_opa,
			opb_i    => fpu_opb,
			fpu_op_i => fpu_op,
			rmode_i  => fpu_rmode,
			output_o => fpu_out,
			new_request  => fpu_start,
			ready_o  => fpu_ready
		);

	InvertPose_TM : Matrix3x3F_Transposer port map(
			clk              => clk,
			enable           => start,
			Matrix_input     => rotation_matrix,
			Matrix_transpose => inv_rotation_matrix_reg
		);

	-- fpu operations (fpu_op_i):
	-- ========================
	-- 000 = add, 
	-- 001 = substract, 
	-- 010 = multiply, 
	-- 011 = divide,
	-- 100 = square root
	-- 101 = unused
	-- 110 = unused
	-- 111 = unused
	-- Rounding Mode: 
	-- ==============
	-- 00 = round to nearest even(default), 
	-- 01 = round to zero, 
	-- 10 = round up, 
	-- 11 = round down

	InvertPose_StateMachine : process(clk)
	begin
		if (rising_edge(clk)) then
			case state is
				when IDLE =>
					invertion_ready <= '0';
					if (start = '1') then
						state                  <= A0_MUL_0_0_X;
						rotation_matrix_reg    <= rotation_matrix;
						translation_vector_reg <= translation_vector;
					end if;
				when A0_MUL_0_0_X =>
					fpu_opa   <= inv_rotation_matrix_reg(0);
					fpu_opb   <= translation_vector_reg(0);
					fpu_op    <= "010";
					fpu_rmode <= "00";
					fpu_start <= '1';

					state <= B0_MUL_0_1_Y;
				when B0_MUL_0_1_Y =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						state_machine_aux1 <= fpu_out;

						fpu_opa   <= inv_rotation_matrix_reg(1);
						fpu_opb   <= translation_vector_reg(1);
						fpu_op    <= "010";
						fpu_rmode <= "00";
						fpu_start <= '1';

						state <= C0_SUM_A0_B0;
					end if;
				when C0_SUM_A0_B0 =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						fpu_opa   <= state_machine_aux1;
						fpu_opb   <= fpu_out;
						fpu_op    <= "000";
						fpu_rmode <= "00";
						fpu_start <= '1';

						state <= D0_MUL_0_2_Z;
					end if;
				when D0_MUL_0_2_Z =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						state_machine_aux1 <= fpu_out;

						fpu_opa   <= inv_rotation_matrix_reg(2);
						fpu_opb   <= translation_vector_reg(2);
						fpu_op    <= "010";
						fpu_rmode <= "00";
						fpu_start <= '1';

						state <= E0_SUM_C0_D0;
					end if;
				when E0_SUM_C0_D0 =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						fpu_opa   <= state_machine_aux1;
						fpu_opb   <= fpu_out;
						fpu_op    <= "000";
						fpu_rmode <= "00";
						fpu_start <= '1';

						state <= A1_MUL_1_0_X;
					end if;
				when A1_MUL_1_0_X =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						-- listo el primer valor!
						inv_translation_vector_reg(0)(FP_SIZE - 2 downto 0) <= fpu_out(FP_SIZE - 2 downto 0);
						-- invierto el signo!
						inv_translation_vector_reg(0)(FP_SIZE - 1)          <= not fpu_out(FP_SIZE - 1);

						fpu_opa   <= inv_rotation_matrix_reg(3);
						fpu_opb   <= translation_vector_reg(0);
						fpu_op    <= "010";
						fpu_rmode <= "00";
						fpu_start <= '1';

						state <= B1_MUL_1_1_Y;
					end if;
				when B1_MUL_1_1_Y =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						state_machine_aux1 <= fpu_out;

						fpu_opa   <= inv_rotation_matrix_reg(4);
						fpu_opb   <= translation_vector_reg(1);
						fpu_op    <= "010";
						fpu_rmode <= "00";
						fpu_start <= '1';

						state <= C1_SUM_A1_B1;
					end if;
				when C1_SUM_A1_B1 =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						fpu_opa   <= state_machine_aux1;
						fpu_opb   <= fpu_out;
						fpu_op    <= "000";
						fpu_rmode <= "00";
						fpu_start <= '1';

						state <= D1_MUL_1_2_Z;
					end if;
				when D1_MUL_1_2_Z =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						state_machine_aux1 <= fpu_out;

						fpu_opa   <= inv_rotation_matrix_reg(5);
						fpu_opb   <= translation_vector_reg(2);
						fpu_op    <= "010";
						fpu_rmode <= "00";
						fpu_start <= '1';

						state <= E1_SUM_C1_D1;
					end if;
				when E1_SUM_C1_D1 =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						fpu_opa   <= state_machine_aux1;
						fpu_opb   <= fpu_out;
						fpu_op    <= "000";
						fpu_rmode <= "00";
						fpu_start <= '1';

						state <= A2_MUL_2_0_X;
					end if;
				when A2_MUL_2_0_X =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						-- listo el primer valor!
						inv_translation_vector_reg(1)(FP_SIZE - 2 downto 0) <= fpu_out(FP_SIZE - 2 downto 0);
						-- invierto el signo!
						inv_translation_vector_reg(1)(FP_SIZE - 1)          <= not fpu_out(FP_SIZE - 1);

						fpu_opa   <= inv_rotation_matrix_reg(6);
						fpu_opb   <= translation_vector_reg(0);
						fpu_op    <= "010";
						fpu_rmode <= "00";
						fpu_start <= '1';

						state <= B2_MUL_2_1_Y;
					end if;
				when B2_MUL_2_1_Y =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						state_machine_aux1 <= fpu_out;

						fpu_opa   <= inv_rotation_matrix_reg(7);
						fpu_opb   <= translation_vector_reg(1);
						fpu_op    <= "010";
						fpu_rmode <= "00";
						fpu_start <= '1';

						state <= C2_SUM_A2_B2;
					end if;
				when C2_SUM_A2_B2 =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						fpu_opa   <= state_machine_aux1;
						fpu_opb   <= fpu_out;
						fpu_op    <= "000";
						fpu_rmode <= "00";
						fpu_start <= '1';

						state <= D2_MUL_2_2_Z;
					end if;
				when D2_MUL_2_2_Z =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						state_machine_aux1 <= fpu_out;

						fpu_opa   <= inv_rotation_matrix_reg(8);
						fpu_opb   <= translation_vector_reg(2);
						fpu_op    <= "010";
						fpu_rmode <= "00";
						fpu_start <= '1';

						state <= E2_SUM_C2_D2;
					end if;
				when E2_SUM_C2_D2 =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						fpu_opa   <= state_machine_aux1;
						fpu_opb   <= fpu_out;
						fpu_op    <= "000";
						fpu_rmode <= "00";
						fpu_start <= '1';

						state <= ALMOST_READY;
					end if;
				when ALMOST_READY =>
					if (fpu_start = '1') then
						fpu_start <= '0';
					end if;
					if (fpu_ready = '1') then
						-- listo el primer valor!
						inv_translation_vector_reg(2)(FP_SIZE - 2 downto 0) <= fpu_out(FP_SIZE - 2 downto 0);
						-- invierto el signo!
						inv_translation_vector_reg(2)(FP_SIZE - 1)          <= not fpu_out(FP_SIZE - 1);

						--						fpu_opa   <= inv_rotation_2_0_reg;
						--						fpu_opb   <= translation_x_reg;
						--						fpu_op    <= "010";
						--						fpu_rmode <= "00";
						--						fpu_start <= '0';

						state <= READY;
					end if;
				when READY =>
					inv_rotation_matrix    <= inv_rotation_matrix_reg;
					inv_translation_vector <= inv_translation_vector_reg;

					invertion_ready <= '1';

					state <= IDLE;
			end case;
		end if;
	end process;
end architecture;
