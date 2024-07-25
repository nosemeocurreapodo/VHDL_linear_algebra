library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Matrix_definition_pack.all;

entity Matrix3x3F_MMultiplier_tb is
end entity Matrix3x3F_MMultiplier_tb;

architecture RTL of Matrix3x3F_MMultiplier_tb is
	component Matrix3x3F_MMultiplier is
		port(
			clk                  : in  std_logic;
			start                : in  std_logic;
			multiplication_ready : out std_logic;
			Matrix_input1        : in  Matrix3x3F;
			Matrix_input2        : in  Matrix3x3F;
			Matrix_output        : out Matrix3x3F
		);
	end component Matrix3x3F_MMultiplier;

	signal clk                  : std_logic := '0';
	signal start                : std_logic;
	signal multiplication_ready : std_logic;
	signal Matrix_input1        : Matrix3x3F;
	signal Matrix_input2        : Matrix3x3F;
	signal Matrix_output        : Matrix3x3F;

	constant HALF_CLK_PERIOD : time := 5 ns;

	type state_type is (IDLE, BUSY, READY);
	signal state : state_type := IDLE;

begin
	Multiply_3x3_Matrix_tb_intantiation : Matrix3x3F_MMultiplier port map(
			clk                  => clk,
			start                => start,
			multiplication_ready => multiplication_ready,
			Matrix_input1        => Matrix_input1,
			Matrix_input2        => Matrix_input2,
			Matrix_output        => Matrix_output
		);

	clk <= not (clk) after HALF_CLK_PERIOD;

	invert_3x3_Matrix_testbench_state_machine : process(clk)
	begin
		if (rising_edge(clk)) then
			case state is
				when IDLE =>
					Matrix_input1(0) <= x"438a8000";
					Matrix_input1(1) <= x"00000000";
					Matrix_input1(2) <= x"43200000";
					Matrix_input1(3) <= x"00000000";
					Matrix_input1(4) <= x"438a8000";
					Matrix_input1(5) <= x"42f00000";
					Matrix_input1(6) <= x"00000000";
					Matrix_input1(7) <= x"00000000";
					Matrix_input1(8) <= x"3f800000";

					Matrix_input2(0) <= x"438a8000";
					Matrix_input2(1) <= x"00000000";
					Matrix_input2(2) <= x"43200000";
					Matrix_input2(3) <= x"00000000";
					Matrix_input2(4) <= x"438a8000";
					Matrix_input2(5) <= x"42f00000";
					Matrix_input2(6) <= x"00000000";
					Matrix_input2(7) <= x"00000000";
					Matrix_input2(8) <= x"3f800000";

					start <= '1';
					state <= BUSY;
				when BUSY =>
					start <= '0';
					if (multiplication_ready = '1') then
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
