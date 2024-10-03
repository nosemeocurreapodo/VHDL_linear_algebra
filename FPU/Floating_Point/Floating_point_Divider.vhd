library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Floating_point_utility_functions_pack.all;

entity Floating_Point_Divider is
	generic(
		IN_SIZE           : integer := 32;
		IN_MANTISSA_SIZE  : integer := 23;
		OUT_SIZE          : integer := 32;
		OUT_MANTISSA_SIZE : integer := 23;
		AUX_SIZE          : integer := 32
	);
	port(clk       : in  std_logic;
		 opa       : in  std_logic_vector(IN_SIZE - 1 downto 0);
		 opb       : in  std_logic_vector(IN_SIZE - 1 downto 0);
		 output    : out std_logic_vector(OUT_SIZE - 1 downto 0);
		 new_op    : in  std_logic;
		 aux_in    : in  std_logic_vector(AUX_SIZE -1 downto 0);
		 aux_out   : out std_logic_vector(AUX_SIZE -1 downto 0);
		 op_ready  : out std_logic);
end entity Floating_Point_Divider;

architecture RTL of Floating_Point_Divider is

	-- stage 1
	signal opa_sign_1      : std_logic;
	signal opb_sign_1      : std_logic;
	signal opa_exponent_1  : std_logic_vector(IN_SIZE - IN_MANTISSA_SIZE - 2 downto 0);
	signal opb_exponent_1  : std_logic_vector(IN_SIZE - IN_MANTISSA_SIZE - 2 downto 0);
	signal opa_mantissa_1  : std_logic_vector(IN_MANTISSA_SIZE - 1 downto 0);
	signal opb_mantissa_1  : std_logic_vector(IN_MANTISSA_SIZE - 1 downto 0);

	signal new_request_1 : std_logic;
	signal aux_1 : std_logic_vector(AUX_SIZE - 1 downto 0);

	-- stage 2
	signal sign_2 : std_logic;
	signal exponent_2 : unsigned(IN_SIZE - IN_MANTISSA_SIZE - 2 downto 0);
	signal mantissa_2 : unsigned(IN_MANTISSA_SIZE downto 0);

	signal new_request_2 : std_logic;
	signal aux_2 : std_logic_vector(AUX_SIZE - 1 downto 0);

	-- multiplication pipeline stages (this is required for infering pipeline in the dsps)
	-- 3 stages (four with the one I added for readability) is needed for single presicion floating point
	constant num_mult_pipe_stages : integer := 3;
	type exponent_array is array (num_mult_pipe_stages - 1 downto 0) of unsigned(IN_SIZE - IN_MANTISSA_SIZE - 2 downto 0);
	type mantissa_array is array (num_mult_pipe_stages - 1 downto 0) of unsigned(IN_MANTISSA_SIZE downto 0);
	type aux_array is array (num_mult_pipe_stages - 1 downto 0) of std_logic_vector(AUX_SIZE - 1 downto 0);

	signal mult_pipe_new_request    : std_logic_vector(num_mult_pipe_stages - 1 downto 0);
	signal mult_pipe_sign           : std_logic_vector(num_mult_pipe_stages - 1 downto 0);
	signal mult_pipe_exponent       : exponent_array;
	signal mult_pipe_mantissa       : mantissa_array;
	signal mult_pipe_aux            : aux_array;

	-- stage 3
	signal new_request_3    : std_logic;
	signal aux_3            : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal sign_3           : std_logic;
	signal exponent_3       : unsigned(IN_SIZE - IN_MANTISSA_SIZE - 2 downto 0);
	signal mantissa_3       : unsigned(IN_MANTISSA_SIZE downto 0);

	-- stage 4
	signal new_request_4    : std_logic;
	signal aux_4            : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal sign_4           : std_logic;
	signal exponent_4       : unsigned(OUT_SIZE - OUT_MANTISSA_SIZE - 2 downto 0);
	signal mantissa_4       : unsigned(OUT_MANTISSA_SIZE - 1 downto 0);
	
begin
	process(clk)
	begin
		if (rising_edge(clk)) then
			
			-- stage 1
			opa_sign_1     <= get_sign(opa);
			opb_sign_1     <= get_sign(opb);
			opa_exponent_1 <= get_exponent(opa, IN_SIZE - IN_MANTISSA_SIZE - 1);
			opb_exponent_1 <= get_exponent(opb, IN_SIZE - IN_MANTISSA_SIZE - 1);
			opa_mantissa_1 <= get_mantissa(opa, IN_MANTISSA_SIZE);
			opb_mantissa_1 <= get_mantissa(opb, IN_MANTISSA_SIZE);
			aux_1          <= aux_in;
			new_request_1  <= new_op;

			-- stage 2
			sign_2     <= opa_sign_1 xor opb_sign_1;
			exponent_2 <= unsigned(((signed(opa_exponent_1) - 127) - (signed(opb_exponent_1) - 127)) + 128);
			mantissa_2 <= unsigned('1' & std_logic_vector(opa_mantissa_1)) / unsigned('1' & std_logic_vector(opb_mantissa_1));

			aux_2          <= aux_1;
			new_request_2  <= new_request_1;

			-- multiplication pipeline stages (required for pipeline in the dsp)
			mult_pipe_new_request(0) <= new_request_2;
			mult_pipe_aux(0)         <= aux_2;
			mult_pipe_sign(0)        <= sign_2;
			mult_pipe_exponent(0)    <= exponent_2;
			mult_pipe_mantissa(0)    <= mantissa_2;

			for I in num_mult_pipe_stages - 1 downto 1 loop
				mult_pipe_new_request(I) <= mult_pipe_new_request(I - 1);
				mult_pipe_aux(I)         <= mult_pipe_aux(I - 1);
				mult_pipe_sign(I)        <= mult_pipe_sign(I - 1);
				mult_pipe_exponent(I)    <= mult_pipe_exponent(I - 1);
				mult_pipe_mantissa(I)    <= mult_pipe_mantissa(I - 1);
			end loop;

			-- stage 3
			new_request_3 <= mult_pipe_new_request(num_mult_pipe_stages - 1);
			aux_3         <= mult_pipe_aux(num_mult_pipe_stages - 1);
			sign_3        <= mult_pipe_sign(num_mult_pipe_stages - 1);
			exponent_3    <= mult_pipe_exponent(num_mult_pipe_stages - 1);
			mantissa_3    <= mult_pipe_mantissa(num_mult_pipe_stages - 1);

			-- stage 4
			sign_4        <= sign_3;
			new_request_4 <= new_request_3;
			aux_4         <= aux_3;

			if(mantissa_3 = to_unsigned(0, (IN_MANTISSA_SIZE + 1)*2)) then
				exponent_4 <= to_unsigned(0, OUT_SIZE - OUT_MANTISSA_SIZE - 1);
				mantissa_4 <= to_unsigned(0, OUT_MANTISSA_SIZE);
			elsif(mantissa_3(mantissa_3'length - 1) = '1') then
				mantissa_4       <= mantissa_3(mantissa_3'length - 1 downto 1);
				exponent_4       <= exponent_3;
			else
				mantissa_4       <= mantissa_3(mantissa_3'length - 1 downto 1);
				exponent_4       <= exponent_3 - 1;
			end if;

			-- stage output
			output(OUT_SIZE - 1)                          <= sign_4;
			output(OUT_SIZE - 2 downto OUT_MANTISSA_SIZE) <= std_logic_vector(exponent_4);
			output(OUT_MANTISSA_SIZE - 1 downto 0)        <= std_logic_vector(mantissa_4);
			aux_out                                       <= aux_4;
			op_ready                                      <= new_request_4;

		end if;
	end process;
end architecture RTL;
