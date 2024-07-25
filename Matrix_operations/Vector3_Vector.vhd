library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Vector3F_VAdder is
	port(
		clk                  : in  std_logic;
		start                : in  std_logic;
		multiplication_ready : out std_logic;
		Vector_input1         : in Vector3F;
		Vector_input2         : in  Vector3F;
		Vector_output        : out Vector3F
	);
end entity Vector3F_VAdder;

architecture RTL of Vector3F_VAdder is
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
			new_request : in  std_logic;
			ready_o     : out std_logic
		);
	end component Floating_point_unit;

	signal Vector_input1_reg  : Vector3F;
	signal Vector_input2_reg  : Vector3F;
	signal Vector_output_reg : Vector3F;

	signal fpu_opa   : std_logic_vector(FP_SIZE - 1 downto 0);
	signal fpu_opb   : std_logic_vector(FP_SIZE - 1 downto 0);
	signal fpu_out   : std_logic_vector(FP_SIZE - 1 downto 0);
	signal fpu_op    : std_logic_vector(2 downto 0);
	signal fpu_rmode : std_logic_vector(1 downto 0) := "00";
	signal fpu_start : std_logic                    := '0';
	signal fpu_ready : std_logic;

	type general_state_type is (IDLE,
		                        CV_0, CV_1, CV_2,
		                        ALMOST_READY, READY);
	signal general_state : general_state_type := IDLE;

	type actual_state_type is (IDLE, ADD_1, READY);
	signal actual_state : actual_state_type := IDLE;

	signal actual_state_opA : std_logic_vector(FP_SIZE - 1 downto 0);
	signal actual_state_opB : std_logic_vector(FP_SIZE - 1 downto 0);

	signal actual_state_out   : std_logic_vector(FP_SIZE - 1 downto 0);
	signal actual_state_start : std_logic := '0';
	signal actual_state_ready : std_logic := '0';

begin
	Multiply_3x3_Vector_FPU : Floating_point_unit port map(
			clk_i    => clk,
			opa_i    => fpu_opa,
			opb_i    => fpu_opb,
			fpu_op_i => fpu_op,
			rmode_i  => fpu_rmode,
			output_o => fpu_out,
			new_request  => fpu_start,
			ready_o  => fpu_ready
		);

	Multiply_3x3_Vector_Actual_StateMachine : process(clk)
	begin
		if (rising_edge(clk)) then
			case actual_state is
				when IDLE =>
					actual_state_ready <= '0';
					if (actual_state_start = '1') then
						actual_state <= ADD_1;
					end if;
				when ADD_1 =>
					fpu_opa   <= actual_state_opA;
					fpu_opb   <= actual_state_opB;
					fpu_op    <= "000";
					--fpu_rmode <= "00";
					fpu_start <= '1';

					actual_state <= READY;
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
						Vector_input1_reg <= Vector_input1;
						Vector_input2_reg <= Vector_input2;

						multiplication_ready <= '0';
						general_state        <= CV_0;
					end if;
				when CV_0 =>
					actual_state_opA <= Vector_input1_reg(0);
					actual_state_opB <= Vector_input2_reg(0);

					actual_state_start <= '1';

					general_state <= CV_1;
				when CV_1 =>
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Vector_output_reg(0) <= actual_state_out;

						actual_state_opA <= Vector_input1_reg(1);
						actual_state_opB <= Vector_input2_reg(1);

						actual_state_start <= '1';

						general_state <= CV_2;
					end if;
				when CV_2 =>
					actual_state_start <= '0';
					if (actual_state_ready = '1') then
						Vector_output_reg(1) <= actual_state_out;

						actual_state_opA <= Vector_input1_reg(2);
						actual_state_opB <= Vector_input2_reg(2);

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
					Vector_output        <= Vector_output_reg;
					multiplication_ready <= '1';
					general_state        <= IDLE;
			end case;
		end if;
	end process;
end architecture RTL;

