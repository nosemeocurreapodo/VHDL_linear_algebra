library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Floating_point_definition.all;
use work.FPU_utility_functions.all;
use work.Synthesis_definitions_pack.all;
use work.request_id_pack.all;

entity Floating_Point_Multiplier is
	port(clk       : in  std_logic;
		 opa       : in  floating_point;
		 opb       : in  floating_point;
		 output    : out floating_point;
		 new_op    : in  std_logic;
		 op_id_in  : in  request_id;
		 op_id_out : out request_id;
		 op_ready  : out std_logic);
end entity Floating_Point_Multiplier;

architecture RTL of Floating_Point_Multiplier is

	-- stage 1
	signal opa_1 : floating_point;
	signal opb_1 : floating_point;

	signal new_request_1 : std_logic;
	signal new_request_id_1 : request_id;

	-- stage 2
	signal sign_2 : std_logic;
	signal exponent_2 : unsigned(exponent_size - 1 downto 0);
	signal mantissa_2 : unsigned((mantissa_size + 1) * 2 - 1 downto 0);

	signal new_request_2 : std_logic;
	signal new_request_id_2 : request_id;

	-- multiplication pipeline stages (this is required for infering pipeline in the dsps)
	constant num_pipe_stages : integer := 7;
	type exponent_array is array (num_pipe_stages - 1 downto 0) of unsigned(exponent_size - 1 downto 0);
	type mantissa_array is array (num_pipe_stages - 1 downto 0) of unsigned((mantissa_size + 1) * 2 - 1 downto 0);

	signal pipe_new_request    : std_logic_vector(num_pipe_stages - 1 downto 0);
	signal pipe_new_request_id : request_id_array(num_pipe_stages - 1 downto 0);
	signal pipe_sign           : std_logic_vector(num_pipe_stages - 1 downto 0);
	signal pipe_exponent       : exponent_array;
	signal pipe_mantissa       : mantissa_array;

	-- stage 3
	signal mantissa_lz_3 : integer;

	signal new_request_3    : std_logic;
	signal new_request_id_3 : request_id;
	signal sign_3           : std_logic;
	signal exponent_3       : unsigned(exponent_size - 1 downto 0);
	signal mantissa_3       : unsigned((mantissa_size + 1) * 2 - 1 downto 0);

	-- stage 4
	signal new_request_4    : std_logic;
	signal new_request_id_4 : request_id;
	signal sign_4           : std_logic;
	signal exponent_4       : unsigned(exponent_size - 1 downto 0);
	signal mantissa_4       : unsigned((mantissa_size + 1) * 2 - 1 downto 0);

begin
	process(clk)

	begin
		if (rising_edge(clk)) then
			
			-- stage 1
			opa_1 <= opa;
			opb_1 <= opb;

			if (new_op = '1') then
				new_request_id_1 <= op_id_in;
				new_request_1    <= '1';
			else
				new_request_id_1 <= request_id_zero;
				new_request_1    <= '0';
			end if;

			-- stage 2
			sign_2     <= opa_1.sign xor opb_1.sign;
			exponent_2 <= opa_1.exponent + opb_1.exponent;
			mantissa_2 <= unsigned('1' & std_logic_vector(opa_1.mantissa)) * unsigned('1' & std_logic_vector(opb_1.mantissa));

			new_request_id_2 <= new_request_id_1;
			new_request_2    <= new_request_1;

			-- multiplication pipeline stages (required for pipeline in the dsp)
			pipe_new_request(0)    <= new_request_2;
			pipe_new_request_id(0) <= new_request_id_2;
			pipe_sign(0)           <= sign_2;
			pipe_exponent(0)       <= exponent_2;
			pipe_mantissa(0)       <= mantissa_2;

			for I in num_pipe_stages - 1 downto 1 loop
				pipe_new_request(I)    <= pipe_new_request(I - 1);
				pipe_new_request_id(I) <= pipe_new_request_id(I - 1);
				pipe_sign(I)           <= pipe_sign(I - 1);
				pipe_exponent(I)       <= pipe_exponent(I - 1);
				pipe_mantissa(I)       <= pipe_mantissa(I - 1);
			end loop;

			-- stage 3
			mantissa_lz_3    <= count_l_zeros(pipe_mantissa(num_pipe_stages - 1));

			new_request_3    <= pipe_new_request(num_pipe_stages - 1);
			new_request_id_3 <= pipe_new_request_id(num_pipe_stages - 1);
			sign_3           <= pipe_sign(num_pipe_stages - 1);
			exponent_3       <= pipe_exponent(num_pipe_stages - 1);
			mantissa_3       <= pipe_mantissa(num_pipe_stages - 1);

			-- stage 4
			new_request_4    <= new_request_3;
			new_request_id_4 <= new_request_id_3;
			sign_4           <= sign_3;
			exponent_4       <= exponent_3 - mantissa_lz_3;
			mantissa_4       <= shift_left(mantissa_3, mantissa_lz_3 + 1);
			-- mantissa_4       <= mantissa_3;

			-- stage 5
			output.sign     <= sign_4;
			output.exponent <= exponent_4;
			output.mantissa <= mantissa_4((mantissa_size + 1) * 2 - 1 downto (mantissa_size + 1) * 2 - 1 - mantissa_size + 1);
			-- output.mantissa <= mantissa_4((mantissa_size + 1) * 2 - 1 - mantissa_lz_3 - 1 downto (mantissa_size + 1) * 2 - 1 - mantissa_size + 1 - mantissa_lz_3 - 1);
			op_id_out       <= new_request_id_4;
			op_ready        <= new_request_4;

		end if;
	end process;
end architecture RTL;

