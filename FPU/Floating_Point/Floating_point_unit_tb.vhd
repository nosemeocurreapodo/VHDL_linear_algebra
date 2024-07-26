library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Floating_point_definition.all;
use work.Floating_point_unit_interface_pack.all;
use work.FPU_unit_common_pack.all;

use std.textio.all;
use work.txt_util.all;

entity Floating_point_unit_tb is
end Floating_point_unit_tb;

architecture rtl of Floating_point_unit_tb is
	component Floating_point_unit
		port(
			clk         : in  std_logic;
			FPU_BUS_in  : in  BUS_to_floating_point_unit;
			FPU_BUS_out : out BUS_from_floating_point_unit
		);
	end component;

	signal clk : std_logic := '1';

	signal FPU_BUS_in  : BUS_to_floating_point_unit := FPU_BUS_to_fpu_initial_state;
	signal FPU_BUS_out : BUS_from_floating_point_unit;

	signal correct_result_fp : floating_point;

begin

	-- instantiate fpu
	FPU_slow_tb_INSTANTIATION : Floating_point_unit port map(
			clk         => clk,
			FPU_BUS_in  => FPU_BUS_in,
			FPU_BUS_out => FPU_BUS_out);

	---------------------------------------------------------------------------
	-- toggle clock
	---------------------------------------------------------------------------
	clk <= not (clk) after 5 ns;

	verify : process(clk)
		--The operands and results are in Hex format. The test vectors must be placed in a strict order for the verfication to work.
		file testcases_file : TEXT open read_mode is "../../../../../testcases.txt"; --Name of the file containing the test cases. 

		--variable file_line: line;
		variable str_in     : string(8 downto 1);
		variable str_fpu_op : string(3 downto 1);
		variable str_rmode  : string(2 downto 1);
		
		variable correct_result : std_logic_vector(31 downto 0);
	begin
		if (rising_edge(clk)) then
			if (not endfile(testcases_file)) then
					FPU_BUS_in.new_request    <= '1';
					--FPU_BUS_in.new_request_id <= x"00000000";
					str_read(testcases_file, str_in);
					FPU_BUS_in.opa <= to_floating_point(strhex_to_slv(str_in));
					str_read(testcases_file, str_in);
					FPU_BUS_in.opb <= to_floating_point(strhex_to_slv(str_in));
					str_read(testcases_file, str_fpu_op);
					FPU_BUS_in.fpu_op <= to_fpu_operation(to_std_logic_vector(str_fpu_op));
					str_read(testcases_file, str_rmode);
					FPU_BUS_in.rmode <= to_fpu_rounding_mode(to_std_logic_vector(str_rmode));

					str_read(testcases_file, str_in);
					correct_result := strhex_to_slv(str_in);
					FPU_BUS_in.new_request_id <= signed(correct_result);
					correct_result_fp <= to_floating_point(correct_result);
					
					-- para que leer este??
					str_read(testcases_file, str_in);

			end if;
			if (FPU_BUS_out.request_ready = '1') then
				assert FPU_BUS_out.output = to_floating_point(std_logic_vector(FPU_BUS_out.request_ready_id))
					report "Error!!!"
					severity failure;
			end if;
		end if;
	end process verify;
end rtl;