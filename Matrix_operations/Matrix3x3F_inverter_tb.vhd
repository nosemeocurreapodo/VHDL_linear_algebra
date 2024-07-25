library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DTAM_FPGA_definitions_pack.all;

entity Matrix3x3F_inverter_tb is
end entity Matrix3x3F_inverter_tb;

architecture RTL of Matrix3x3F_inverter_tb is
	component Matrix3x3F_inverter is
		port(
			clk               : in  std_logic;
			start             : in  std_logic;
			invertion_ready   : out std_logic;
			Matrix_input      : in  Matrix3x3F;
			inv_Matrix_output : out Matrix3x3F
		);
	end component Matrix3x3F_inverter;

	signal clk                   : std_logic := '0';
	signal start                 : std_logic;
	signal invertion_ready       : std_logic;
	signal Matrix_input_reg      : Matrix3x3F;
	signal inv_Matrix_output_reg : Matrix3x3F;

	constant HALF_CLK_PERIOD : time := 5 ns;

	type state_type is (IDLE, BUSY, READY);
	signal state : state_type := IDLE;

begin
	Invert_3x3_Matrix_tb_intantiation : Matrix3x3F_inverter port map(
			clk               => clk,
			start             => start,
			invertion_ready   => invertion_ready,
			Matrix_input      => Matrix_input_reg,
			inv_Matrix_output => inv_Matrix_output_reg
		);

	clk <= not (clk) after HALF_CLK_PERIOD;

	invert_3x3_Matrix_testbench_state_machine : process(clk)
	begin
		if (rising_edge(clk)) then
			case state is
				when IDLE =>
					Matrix_input_reg(0) <= x"438a8000";
					Matrix_input_reg(1) <= x"00000000";
					Matrix_input_reg(2) <= x"43200000";
					Matrix_input_reg(3) <= x"00000000";
					Matrix_input_reg(4) <= x"438a8000";
					Matrix_input_reg(5) <= x"42f00000";
					Matrix_input_reg(6) <= x"00000000";
					Matrix_input_reg(7) <= x"00000000";
					Matrix_input_reg(8) <= x"3f800000";

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
