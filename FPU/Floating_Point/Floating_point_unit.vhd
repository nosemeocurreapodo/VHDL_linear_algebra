library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Floating_point_component_pack.all;
use work.Floating_point_unit_interface_pack.all;
use work.FPU_unit_common_pack.all;

entity Floating_point_unit is
	port(
		clk     : in  std_logic;
		BUS_in  : in  BUS_to_floating_point_unit;
		BUS_out : out BUS_from_floating_point_unit
	);
end entity;

architecture RTL2 of Floating_point_unit is
	signal opa_reg           : std_logic_vector(INPUT_SIZE - 1 downto 0);
	signal opb_reg           : std_logic_vector(INPUT_SIZE - 1 downto 0);
	signal op_reg            : FPU_operation;
	signal request_id_in_reg : std_logic_vector(AUX_SIZE - 1 downto 0);

	signal excep : FPU_exception := FPU_exceptions_initial_state;

	signal add_input_ready  : std_logic;
	signal add_out          : std_logic_vector(OUTPUT_SIZE - 1 downto 0);
	signal add_out_id       : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal add_output_ready : std_logic;
	signal sub_input_ready  : std_logic;
	signal sub_out          : std_logic_vector(OUTPUT_SIZE - 1 downto 0);
	signal sub_out_id       : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal sub_output_ready : std_logic;
	signal mul_input_ready  : std_logic;
	signal mul_out          : std_logic_vector(OUTPUT_SIZE - 1 downto 0);
	signal mul_out_id       : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal mul_output_ready : std_logic;
	signal div_input_ready  : std_logic;
	signal div_out          : std_logic_vector(OUTPUT_SIZE - 1 downto 0);
	signal div_out_id       : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal div_output_ready : std_logic;

begin
	adder_int : Floating_point_Adder 
	generic map(
			IN_SIZE            => INPUT_SIZE,
			IN_MANTISSA_SIZE   => INPUT_MANTISSA_SIZE,
			OUT_SIZE           => OUTPUT_SIZE,
			OUT_MANTISSA_SIZE  => OUTPUT_MANTISSA_SIZE,
			AUX_SIZE           => AUX_SIZE)
	port map(
			clk       => clk,
			opa       => opa_reg,
			opb       => opb_reg,
			output    => add_out,
			new_op    => add_input_ready,
			aux_in    => request_id_in_reg,
			aux_out   => add_out_id,
			op_ready  => add_output_ready);

	substractor_int : Floating_point_Substractor 
	generic map(
			IN_SIZE            => INPUT_SIZE,
			IN_MANTISSA_SIZE   => INPUT_MANTISSA_SIZE,
			OUT_SIZE           => OUTPUT_SIZE,
			OUT_MANTISSA_SIZE  => OUTPUT_MANTISSA_SIZE,
			AUX_SIZE           => AUX_SIZE)
	port map(
			clk       => clk,
			opa       => opa_reg,
			opb       => opb_reg,
			output    => sub_out,
			new_op    => sub_input_ready,
			aux_in  => request_id_in_reg,
			aux_out => sub_out_id,
			op_ready  => sub_output_ready);

	multiplier_int : Floating_Point_Multiplier 
	generic map(
			IN_SIZE            => INPUT_SIZE,
			IN_MANTISSA_SIZE   => INPUT_MANTISSA_SIZE,
			OUT_SIZE           => OUTPUT_SIZE,
			OUT_MANTISSA_SIZE  => OUTPUT_MANTISSA_SIZE,
			AUX_SIZE           => AUX_SIZE)
	port map(
			clk       => clk,
			opa       => opa_reg,
			opb       => opb_reg,
			output    => mul_out,
			new_op    => mul_input_ready,
			aux_in  => request_id_in_reg,
			aux_out => mul_out_id,
			op_ready  => mul_output_ready);

	divider_int : Floating_Point_Divider 
	generic map(
			IN_SIZE            => INPUT_SIZE,
			IN_MANTISSA_SIZE   => INPUT_MANTISSA_SIZE,
			OUT_SIZE           => OUTPUT_SIZE,
			OUT_MANTISSA_SIZE  => OUTPUT_MANTISSA_SIZE,
			AUX_SIZE           => AUX_SIZE)
	port map(
			clk       => clk,
			opa       => opa_reg,
			opb       => opb_reg,
			output    => div_out,
			new_op    => div_input_ready,
			aux_in    => request_id_in_reg,
			aux_out   => div_out_id,
			op_ready  => div_output_ready);

	BUS_out.exception <= excep;

	-- Input process
	input_process1 : process(clk)
	begin
		if (rising_edge(clk)) then
			if (BUS_in.new_request = '1') then
				opa_reg           <= BUS_in.opa;
				opb_reg           <= BUS_in.opb;
				op_reg            <= BUS_in.operation;
				request_id_in_reg <= BUS_in.aux;

				case BUS_in.operation is
					when ADD =>
						add_input_ready <= '1';
						sub_input_ready <= '0';
						mul_input_ready <= '0';
						div_input_ready <= '0';
					when SUB =>
						add_input_ready <= '0';
						sub_input_ready <= '1';
						mul_input_ready <= '0';
						div_input_ready <= '0';
					when MUL =>
						add_input_ready <= '0';
						sub_input_ready <= '0';
						mul_input_ready <= '1';
						div_input_ready <= '0';
					when DIV =>
						add_input_ready <= '0';
						sub_input_ready <= '0';
						mul_input_ready <= '0';
						div_input_ready <= '1';
					when SQRT =>
						add_input_ready <= '1';
						sub_input_ready <= '0';
						mul_input_ready <= '0';
						div_input_ready <= '0';
				end case;
			else
				add_input_ready <= '0';
				sub_input_ready <= '0';
				mul_input_ready <= '0';
				div_input_ready <= '0';
			end if;
		end if;
	end process;

	-- output process
	output_processs1 : process(clk)
	begin
		if (rising_edge(clk)) then
			if (add_output_ready = '1') then
				BUS_out.output           <= add_out;
				BUS_out.request_ready    <= '1';
				BUS_out.aux              <= add_out_id;
			elsif (sub_output_ready = '1') then
				BUS_out.output           <= sub_out;
				BUS_out.request_ready    <= '1';
				BUS_out.aux              <= sub_out_id;
			elsif (mul_output_ready = '1') then
				BUS_out.output           <= mul_out;
				BUS_out.request_ready    <= '1';
				BUS_out.aux              <= mul_out_id;
			elsif (div_output_ready = '1') then
				BUS_out.output           <= div_out;
				BUS_out.request_ready    <= '1';
				BUS_out.aux              <= div_out_id;
			else
			BUS_out.request_ready <= '0';
			end if;
		end if;
	end process;

end architecture RTL2;

