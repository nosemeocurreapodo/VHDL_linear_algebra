library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DTAM_FPGA_definitions_pack.all;

entity Pose_Inverter_tb is
end entity Pose_Inverter_tb;

architecture RTL of Pose_Inverter_tb is
	component Pose_Inverter is
		port(
			clk                    : in  std_logic;
			start                  : in  std_logic;
			invertion_ready        : out std_logic;
			rotation_matrix        : in  Matrix3x3F;
			translation_vector     : in  Vector3F;
			inv_rotation_matrix    : out Matrix3x3F;
			inv_translation_vector : out Vector3F
		);
	end component Pose_Inverter;

	signal clk                        : std_logic := '0';
	signal start                      : std_logic := '0';
	signal invertion_ready            : std_logic;
	signal rotation_matrix_reg        : Matrix3x3F;
	signal translation_vector_reg     : Vector3F;
	signal inv_rotation_matrix_reg    : Matrix3x3F;
	signal inv_translation_vector_reg : Vector3F;

	constant HALF_CLK_PERIOD : time := 5 ns;

	type state_type is (IDLE, BUSY, READY);
	signal state : state_type := IDLE;

begin
	InvertPose_Instantiation : Pose_Inverter port map(
			clk                    => clk,
			start                  => start,
			invertion_ready        => invertion_ready,
			rotation_matrix        => rotation_matrix_reg,
			translation_vector     => translation_vector_reg,
			inv_rotation_matrix    => inv_rotation_matrix_reg,
			inv_translation_vector => inv_translation_vector_reg
		);

	clk <= not (clk) after HALF_CLK_PERIOD;

	invertPose_testbench_state_machine : process(clk)
	begin
		if (rising_edge(clk)) then
			case state is
				when IDLE =>
					rotation_matrix_reg(0)    <= x"3f800000";
					rotation_matrix_reg(1)    <= x"00000000";
					rotation_matrix_reg(2)    <= x"00000000";
					rotation_matrix_reg(3)    <= x"00000000";
					rotation_matrix_reg(4)    <= x"3f800000";
					rotation_matrix_reg(5)    <= x"00000000";
					rotation_matrix_reg(6)    <= x"00000000";
					rotation_matrix_reg(7)    <= x"00000000";
					rotation_matrix_reg(8)    <= x"3f800000";
					translation_vector_reg(0) <= x"3f800000";
					translation_vector_reg(1) <= x"3f800000";
					translation_vector_reg(2) <= x"3f800000";

					start <= '1';
					state <= BUSY;
				when BUSY =>
					start <= '0';
					if (invertion_ready = '1') then
						state <= READY;
					end if;
				when READY =>
					state <= IDLE;
					assert false
						report "invertion done!!"
						severity failure;
			end case;
		end if;
	end process;

end architecture RTL;
