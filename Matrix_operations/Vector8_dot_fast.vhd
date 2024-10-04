library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Matrix_definitions_pack.all;
use work.FPU_component_pack.all;

entity Vector8_dot_fast is
	generic(
		IN_SIZE         : integer := 32;
		IN_FRAC_SIZE    : integer := 23;
		ADD_1_SIZE      : integer := 32;
		ADD_1_FRAC_SIZE : integer := 23;
		ADD_2_SIZE      : integer := 32;
		ADD_2_FRAC_SIZE : integer := 23;
		ADD_3_SIZE      : integer := 32;
		ADD_3_FRAC_SIZE : integer := 23;
		OUT_SIZE        : integer := 32;
		OUT_FRAC_SIZE   : integer := 23;
		AUX_SIZE        : integer := 32
	);
	port(
		clk           : in  std_logic;
		new_op        : in  std_logic;
		op_done       : out std_logic;
		aux_in        : in  std_logic_vector(AUX_SIZE - 1 downto 0);
		aux_out       : out std_logic_vector(AUX_SIZE - 1 downto 0);
		Vector1_input : in  Vector(7 downto 0)(IN_SIZE - 1 downto 0);
		Vector2_input : in  Vector(7 downto 0)(IN_SIZE - 1 downto 0);
		output        : out std_logic_vector(OUT_SIZE - 1 downto 0)
	);
end entity;

architecture RTL of Vector8_dot_fast is

	-- 1 stage
	signal Vector1_input_reg       : Vector(7 downto 0)(IN_SIZE - 1 downto 0);
	signal Vector2_input_reg       : Vector(7 downto 0)(IN_SIZE - 1 downto 0);
	signal First_stage_request_id  : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal First_stage_enable      : std_logic;
	-- 2 stage
	signal Vector_aux1_stage2      : Vector(7 downto 0)(ADD_1_SIZE - 1 downto 0);
	signal Second_stage_request_id : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal Second_stage_enable     : std_logic;
	--3 stage
	signal Vector_aux1_stage3      : Vector(3 downto 0)(ADD_2_SIZE - 1 downto 0);
	signal Third_stage_request_id  : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal Third_stage_enable      : std_logic;
	--4 stage
	signal Vector_aux1_stage4      : Vector(1 downto 0)(ADD_3_SIZE - 1 downto 0);
	signal Forth_stage_request_id  : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal Forth_stage_enable      : std_logic;

begin

	--first stage
	process(clk)
	begin
		if (rising_edge(clk)) then
			Vector1_input_reg <= Vector1_input;
			Vector2_input_reg <= Vector2_input;
			First_stage_request_id <= aux_in;
			if(new_op = '1') then
				First_stage_enable     <= '1';
			else
				First_stage_enable     <= '0';	
			end if;
		end if;
	end process;
	-- second stage
	-- 8 multiplicadores
	--X
	Multiplier_stage1 : FPU_multiplier 
	generic map
	(
		IN_SIZE        => IN_SIZE,
		IN_FRAC_SIZE   => IN_FRAC_SIZE,
		OUT_SIZE       => ADD_1_SIZE,
		OUT_FRAC_SIZE  => ADD_1_FRAC_SIZE,
		AUX_SIZE       => AUX_SIZE
	)
	port map
	(
		clk       => clk,
		opa       => Vector1_input_reg(0),
		opb       => Vector2_input_reg(0),
		output    => Vector_aux1_stage2(0),
		new_op    => First_stage_enable,
		aux_in    => First_stage_request_id,
		op_ready  => Second_stage_enable,
		aux_out   => Second_stage_request_id
	);

	generate_multiplires : for I in 1 to 7 generate
		Multipliers_stage1 : FPU_multiplier 
		generic map
		(
			IN_SIZE       => IN_SIZE,
			IN_FRAC_SIZE  => IN_FRAC_SIZE,
			OUT_SIZE      => ADD_1_SIZE,
			OUT_FRAC_SIZE => ADD_1_FRAC_SIZE,
			AUX_SIZE      => AUX_SIZE
		)
		port map
		(
			clk    => clk,
			opa    => Vector1_input_reg(I),
			opb    => Vector2_input_reg(I),
			new_op => First_stage_enable,
			output => Vector_aux1_stage2(I),
			aux_in => First_stage_request_id
		);
	end generate;

	-- 3 stage
	-- 4 sumadores
	Adder_stage3 : FPU_adder 
	generic map
	(
		IN_SIZE       => ADD_1_SIZE,
		IN_FRAC_SIZE  => ADD_1_FRAC_SIZE,
		OUT_SIZE      => ADD_2_SIZE,
		OUT_FRAC_SIZE => ADD_2_FRAC_SIZE,
		AUX_SIZE      => AUX_SIZE
	)
	port map
	(
		clk      => clk,
		opa      => Vector_aux1_stage2(0),
		opb      => Vector_aux1_stage2(1),
		output   => Vector_aux1_stage3(0),
		new_op   => Second_stage_enable,
		aux_in   => Second_stage_request_id,
		op_ready => Third_stage_enable,
		aux_out  => Third_stage_request_id
	);

	generate_adders_stage3 : for I in 1 to 3 generate
	Adders_stage3 : FPU_adder 
	generic map
	(
		IN_SIZE       => ADD_1_SIZE,
		IN_FRAC_SIZE  => ADD_1_FRAC_SIZE,
		OUT_SIZE      => ADD_2_SIZE,
		OUT_FRAC_SIZE => ADD_2_FRAC_SIZE,
		AUX_SIZE      => AUX_SIZE
	)
	port map
	(
		clk    => clk,
		opa    => Vector_aux1_stage2(I*2),
		opb    => Vector_aux1_stage2(I*2+1),
		output => Vector_aux1_stage3(I),
		new_op => Second_stage_enable,
		aux_in => Second_stage_request_id
	);
	end generate;

	-- 4 stage
	-- 2 sumadores
	Adder_1_stage4 : FPU_adder 
	generic map
	(
		IN_SIZE       => ADD_2_SIZE,
		IN_FRAC_SIZE  => ADD_2_FRAC_SIZE,
		OUT_SIZE      => ADD_3_SIZE,
		OUT_FRAC_SIZE => ADD_3_FRAC_SIZE,
		AUX_SIZE      => AUX_SIZE
	)
	port map
	(
		clk      => clk,
		opa      => Vector_aux1_stage3(0),
		opb      => Vector_aux1_stage3(1),
		output   => Vector_aux1_stage4(0),
		new_op   => Third_stage_enable,
		aux_in   => Third_stage_request_id,
		op_ready => Forth_stage_enable,
		aux_out  => Forth_stage_request_id
	);

	Adder_2_stage4 : FPU_adder 
	generic map
	(
		IN_SIZE       => ADD_2_SIZE,
		IN_FRAC_SIZE  => ADD_2_FRAC_SIZE,
		OUT_SIZE      => ADD_3_SIZE,
		OUT_FRAC_SIZE => ADD_3_FRAC_SIZE,
		AUX_SIZE      => AUX_SIZE
	)
	port map
	(
		clk    => clk,
		opa    => Vector_aux1_stage3(2),
		opb    => Vector_aux1_stage3(3),
		output => Vector_aux1_stage4(1),
		new_op => Third_stage_enable,
		aux_in => Third_stage_request_id
	);

	-- 5 stage (output)
	-- 1 sumadores
	Adder_stage5 : FPU_adder 
	generic map
	(
		IN_SIZE       => ADD_3_SIZE,
		IN_FRAC_SIZE  => ADD_3_FRAC_SIZE,
		OUT_SIZE      => OUT_SIZE,
		OUT_FRAC_SIZE => OUT_FRAC_SIZE,
		AUX_SIZE      => AUX_SIZE
	)
	port map
	(
		clk       => clk,
		opa       => Vector_aux1_stage4(0),
		opb       => Vector_aux1_stage4(1),
		output    => output,
		new_op    => Forth_stage_enable,
		op_ready  => op_done,
		aux_in    => Forth_stage_request_id,
		aux_out   => aux_out
	);

end architecture RTL;

