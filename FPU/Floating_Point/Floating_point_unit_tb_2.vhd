library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Floating_point_utility_functions_pack.all;
use work.Floating_point_unit_interface_pack.all;
use work.FPU_unit_common_pack.all;

use ieee.math_real.all;
use ieee.math_complex.all;

use std.textio.all;
--use work.txt_util.all;

entity Floating_point_unit_tb_2 is
end Floating_point_unit_tb_2;

architecture rtl of Floating_point_unit_tb_2 is
	component Floating_point_unit
		port(
			clk     : in  std_logic;
			BUS_in  : in  BUS_to_floating_point_unit;
			BUS_out : out BUS_from_floating_point_unit
		);
	end component;

	signal clk : std_logic := '1';

	signal BUS_in  : BUS_to_floating_point_unit := BUS_to_floating_point_unit_initial_state;
	signal BUS_out : BUS_from_floating_point_unit;

begin

	-- instantiate fpu
	FPU_slow_tb_INSTANTIATION : 
	Floating_point_unit 
	port map
	(
		clk     => clk,
		BUS_in  => BUS_in,
		BUS_out => BUS_out
	);

	---------------------------------------------------------------------------
	-- toggle clock
	---------------------------------------------------------------------------
	clk <= not (clk) after 5 ns;

	verify : process(clk)
		-- integer
		--		variable int_min : integer := -(2 ** ((fixed_point_size-fraction_size)/2))+2;
		--		variable int_max : integer :=  (2 ** ((fixed_point_size-fraction_size)/2))-2;
		--		variable opa    : integer       := int_min;
		--		variable opb    : integer       := int_min;
		--		variable output : integer;

		-- real
		variable int_min : real := -2.0**(2);-- -2.0**((mantissa_size)/2-1)+1.0;
		variable int_max : real :=  2.0**(2);-- 2.0**((mantissa_size)/2-1)-1.0;
		variable opa_increment : real := 2.0**(-8);--2.0**(-fraction_size);
		variable opb_increment : real := 2.0**(-8);--2.0**(-fraction_size);
		variable opa     : real := int_min;
		variable opb     : real := int_min;
		variable output  : real;

		variable op : FPU_operation := ADD;

	begin
		if (rising_edge(clk)) then
			BUS_in.new_request <= '1';
			BUS_in.opa         <= to_floating_point(opa, INPUT_SIZE, INPUT_MANTISSA_SIZE);
			BUS_in.opb         <= to_floating_point(opb, INPUT_SIZE, INPUT_MANTISSA_SIZE);
			--FPU_BUS_in.opa         <= to_fixed_point(to_signed(opa, fixed_point_size));
			--FPU_BUS_in.opb         <= to_fixed_point(to_signed(opb, fixed_point_size));
			BUS_in.operation   <= op;

			case op is
				when ADD =>
					output := opa + opb;
				when SUB =>
					output := opa - opb;
				when MUL =>
					output := opa * opb;
				when DIV =>
					if(opb = 0.0) then
						output := 0.0;
					else
						output := opa / opb;
					end if;
				when SQRT =>
					output := opa / opb;
			end case;

			BUS_in.aux <= to_floating_point(output, OUTPUT_SIZE, OUTPUT_MANTISSA_SIZE);

			opa := opa + opa_increment;
			--uniform(seed1, seed2, opa); -- generate random number
			if (opa > int_max) then
				opa := int_min;
				opb := opb + opb_increment;
				if (opb > int_max) then
					opb := int_min;
					case op is
						when ADD =>
							op := SUB;
						when SUB =>
							op := MUL;
						when MUL =>
							op := DIV;
						when DIV =>
							op := ADD;
							--assert false
							--	report "All Done"
							--	severity failure;
						when SQRT =>
							op := SUB;
					end case;
				end if;
			end if;
			if (BUS_out.request_ready = '1') then
				assert BUS_out.output = BUS_out.aux
					report "Some error"
					severity failure;
			end if;
		end if;
	end process verify;
end rtl;