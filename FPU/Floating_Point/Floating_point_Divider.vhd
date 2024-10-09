library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Floating_point_utility_functions_pack.all;
use work.FPU_utility_functions.all;

entity Floating_Point_Divider is
	generic(
		IN_SIZE           : integer;-- := 32;
		IN_MANTISSA_SIZE  : integer;-- := 23;
		OUT_SIZE          : integer;-- := 32;
		OUT_MANTISSA_SIZE : integer;-- := 23;
		AUX_SIZE          : integer-- := 32
	);
	port(clk       : in  std_logic;
		 opa       : in  std_logic_vector(IN_SIZE - 1 downto 0);
		 opb       : in  std_logic_vector(IN_SIZE - 1 downto 0);
		 output    : out std_logic_vector(OUT_SIZE - 1 downto 0);
		 new_op    : in  std_logic;
		 aux_in    : in  std_logic_vector(AUX_SIZE -1 downto 0);
		 aux_out   : out std_logic_vector(AUX_SIZE -1 downto 0);
		 op_ready  : out std_logic);
end entity;

architecture RTL of Floating_Point_Divider is

	constant IN_EXPONENT_SIZE : integer := IN_SIZE - IN_MANTISSA_SIZE - 1;
	constant OUT_EXPONENT_SIZE : integer := OUT_SIZE - OUT_MANTISSA_SIZE - 1;

	-- stage 1
	signal opa_sign_1      : std_logic;
	signal opb_sign_1      : std_logic;
	signal opa_exponent_1  : std_logic_vector(IN_EXPONENT_SIZE - 1 downto 0);
	signal opb_exponent_1  : std_logic_vector(IN_EXPONENT_SIZE - 1 downto 0);
	signal opa_mantissa_1  : std_logic_vector(IN_MANTISSA_SIZE - 1 downto 0);
	signal opb_mantissa_1  : std_logic_vector(IN_MANTISSA_SIZE - 1 downto 0);

	signal new_request_1 : std_logic;
	signal aux_1 : std_logic_vector(AUX_SIZE - 1 downto 0);

	-- stage 2 sign and unnormalization
	signal sign_2 : std_logic;
	signal opa_exponent_2 : signed(IN_EXPONENT_SIZE - 1 downto 0);
	signal opb_exponent_2 : signed(IN_EXPONENT_SIZE - 1 downto 0);
	signal opa_mantissa_2 : std_logic_vector(IN_MANTISSA_SIZE downto 0);
	signal opb_mantissa_2 : std_logic_vector(IN_MANTISSA_SIZE downto 0);

	signal new_request_2 : std_logic;
	signal aux_2 : std_logic_vector(AUX_SIZE - 1 downto 0);

	-- stage 3 add and multiplication
	signal sign_3 : std_logic;
	signal exponent_3 : unsigned(IN_EXPONENT_SIZE - 1 downto 0);
	signal mantissa_3 : unsigned((IN_MANTISSA_SIZE + 1) * 2 - 1 downto 0);

	signal new_request_3 : std_logic;
	signal aux_3 : std_logic_vector(AUX_SIZE - 1 downto 0);

	-- multiplication pipeline stages (this is required for infering pipeline in the dsps)
	-- 3 stages (four with the one I added for readability) is needed for single presicion floating point
	constant num_mult_pipe_stages : integer := 3;
	--type exponent_array is array (num_mult_pipe_stages - 1 downto 0) of unsigned(IN_SIZE - IN_MANTISSA_SIZE - 2 downto 0);
	--type mantissa_array is array (num_mult_pipe_stages - 1 downto 0) of unsigned((IN_MANTISSA_SIZE + 1) * 2 - 1 downto 0);
	--type aux_array is array (num_mult_pipe_stages - 1 downto 0) of std_logic_vector(AUX_SIZE - 1 downto 0);
	type exponent_array is array (integer range<>) of unsigned(IN_EXPONENT_SIZE - 1 downto 0);
	type mantissa_array is array (integer range<>) of unsigned((IN_MANTISSA_SIZE + 1) * 2 - 1 downto 0);
	type aux_array is array (integer range<>) of std_logic_vector(AUX_SIZE - 1 downto 0);

	signal mult_pipe_new_request    : std_logic_vector(num_mult_pipe_stages - 1 downto 0);
	signal mult_pipe_sign           : std_logic_vector(num_mult_pipe_stages - 1 downto 0);
	signal mult_pipe_exponent       : exponent_array(num_mult_pipe_stages - 1 downto 0);
	signal mult_pipe_mantissa       : mantissa_array(num_mult_pipe_stages - 1 downto 0);
	signal mult_pipe_aux            : aux_array(num_mult_pipe_stages - 1 downto 0);

	-- stage 4
	signal new_request_4    : std_logic;
	signal aux_4            : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal sign_4           : std_logic;
	signal exponent_4       : unsigned(IN_EXPONENT_SIZE - 1 downto 0);
	signal mantissa_4       : unsigned((IN_MANTISSA_SIZE + 1) * 2 - 1 downto 0);

	-- stage 5
	signal new_request_5    : std_logic;
	signal aux_5            : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal sign_5           : std_logic;
	signal exponent_5       : unsigned(IN_EXPONENT_SIZE - 1 downto 0);
	signal mantissa_5       : unsigned((IN_MANTISSA_SIZE + 1) * 2 - 1 downto 0);
	signal l_zeros_5        : integer;

	-- stage 6
	signal new_request_6    : std_logic;
	signal aux_6            : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal sign_6           : std_logic;
	signal exponent_6       : unsigned(IN_EXPONENT_SIZE - 1 downto 0);
	signal mantissa_6       : unsigned((IN_MANTISSA_SIZE + 1) * 2 - 1 downto 0);

begin
	process(clk)
	begin
		if (rising_edge(clk)) then
			
			-- stage 1
			opa_sign_1      <= get_sign(opa);
			opb_sign_1      <= get_sign(opb);
			opa_exponent_1  <= get_exponent(opa, IN_EXPONENT_SIZE);
			opb_exponent_1  <= get_exponent(opb, IN_EXPONENT_SIZE);
			opa_mantissa_1  <= get_mantissa(opa, IN_MANTISSA_SIZE);
			opb_mantissa_1  <= get_mantissa(opb, IN_MANTISSA_SIZE);
			aux_1           <= aux_in;
			-- seems to be important, otherwise we propagate undifined states during simulation
			if(new_op = '1') then
				new_request_1 <= '1';
			else
				new_request_1 <= '0';
			end if;

			-- stage 2 sign and unnormalization
			sign_2         <= opa_sign_1 xor opb_sign_1;
			opa_exponent_2 <= signed(opa_exponent_1) - integer(2**(IN_EXPONENT_SIZE - 1) - 1); -- -127;
			opb_exponent_2 <= signed(opb_exponent_1) - integer(2**(IN_EXPONENT_SIZE - 1) - 1);
			if(unsigned(opa_exponent_1) = to_unsigned(0, opa_exponent_1'length)) then
				opa_mantissa_2 <= '0' & opa_mantissa_1;
			else
				opa_mantissa_2 <= '1' & opa_mantissa_1;
			end if;
			if(unsigned(opb_exponent_1) = to_unsigned(0, opb_exponent_1'length)) then
				opb_mantissa_2 <= '0' & opb_mantissa_1;
			else
				opb_mantissa_2 <= '1' & opb_mantissa_1;
			end if;

			aux_2          <= aux_1;
			new_request_2  <= new_request_1;

			-- stage 3 add and multiply
			sign_3     <= sign_2;
			exponent_3 <= unsigned(opa_exponent_2 + opb_exponent_2 + integer(2**(OUT_EXPONENT_SIZE - 1)));-- + 128
			mantissa_3 <= unsigned(opa_mantissa_2) * unsigned(opb_mantissa_2);

			aux_3          <= aux_2;
			new_request_3  <= new_request_2;

			-- multiplication pipeline stages (required for pipeline in the dsp)
			mult_pipe_new_request(0) <= new_request_3;
			mult_pipe_aux(0)         <= aux_3;
			mult_pipe_sign(0)        <= sign_3;
			mult_pipe_exponent(0)    <= exponent_3;
			mult_pipe_mantissa(0)    <= mantissa_3;

			for I in num_mult_pipe_stages - 1 downto 1 loop
				mult_pipe_new_request(I) <= mult_pipe_new_request(I - 1);
				mult_pipe_aux(I)         <= mult_pipe_aux(I - 1);
				mult_pipe_sign(I)        <= mult_pipe_sign(I - 1);
				mult_pipe_exponent(I)    <= mult_pipe_exponent(I - 1);
				mult_pipe_mantissa(I)    <= mult_pipe_mantissa(I - 1);
			end loop;

			-- stage 4
			new_request_4 <= mult_pipe_new_request(num_mult_pipe_stages - 1);
			aux_4         <= mult_pipe_aux(num_mult_pipe_stages - 1);
			sign_4        <= mult_pipe_sign(num_mult_pipe_stages - 1);
			exponent_4    <= mult_pipe_exponent(num_mult_pipe_stages - 1);
			mantissa_4    <= mult_pipe_mantissa(num_mult_pipe_stages - 1);

			-- stage 5 -- count leading zeros
			sign_5        <= sign_4;
			aux_5         <= aux_4;
			new_request_5 <= new_request_4;
			exponent_5    <= exponent_4;
			mantissa_5    <= mantissa_4;
			l_zeros_5     <= count_l_zeros(mantissa_4);

			-- stage 6 shift left
			if(mantissa_5 = to_unsigned(0, mantissa_5'length)) then
				exponent_6 <= to_unsigned(0, exponent_6'length);
				mantissa_6 <= to_unsigned(0, mantissa_6'length);
				sign_6 <= '0';
			else
				mantissa_6 <= shift_left(mantissa_5, l_zeros_5 + 1);
				exponent_6 <= exponent_5 - l_zeros_5;
				sign_6 <= sign_5;
			end if;
			new_request_6 <= new_request_5;
			aux_6 <= aux_5;

			-- stage 5 --normalization
			--new_request_6 <= new_request_4;
			--aux_6         <= aux_4;

			--if(mantissa_4 = to_unsigned(0, mantissa_4'length)) then
			--	exponent_6 <= to_unsigned(0, exponent_6'length);
			--	mantissa_6 <= to_unsigned(0, mantissa_6'length);
			--	sign_6     <= '0';
			--elsif(mantissa_4(mantissa_4'length - 1) = '1') then
			--	mantissa_6  <= mantissa_4(mantissa_4'length - 2 downto mantissa_4'length - 2 - OUT_MANTISSA_SIZE + 1);
			--	exponent_6  <= exponent_4(exponent_6'length - 1 downto 0);
			--	sign_6      <= sign_4;
			--else
			--	mantissa_6  <= mantissa_4(mantissa_4'length - 3 downto mantissa_4'length - 3 - OUT_MANTISSA_SIZE + 1);
			--	exponent_6  <= exponent_4(exponent_6'length - 1 downto 0) - 1;
			--	sign_6      <= sign_4;
			--end if;

			-- stage output
			--output(OUT_SIZE - 1)                          <= sign_6;
			--output(OUT_SIZE - 2 downto OUT_MANTISSA_SIZE) <= std_logic_vector(exponent_6);
			--output(OUT_MANTISSA_SIZE - 1 downto 0)        <= std_logic_vector(mantissa_6);
			--aux_out                                       <= aux_6;
			--op_ready                                      <= new_request_6;

			output(OUT_SIZE - 1)                          <= sign_6;

			if(OUT_EXPONENT_SIZE > IN_EXPONENT_SIZE) then
				output(OUT_SIZE - 2 downto OUT_MANTISSA_SIZE) <= std_logic_vector(to_unsigned(0, OUT_EXPONENT_SIZE - IN_EXPONENT_SIZE)) & std_logic_vector(exponent_6);
			else
				output(OUT_SIZE - 2 downto OUT_MANTISSA_SIZE) <= std_logic_vector(exponent_6(OUT_SIZE - OUT_MANTISSA_SIZE - 2 downto 0));
			end if;
			
			if(OUT_MANTISSA_SIZE > (IN_MANTISSA_SIZE + 1)*2) then
				output(OUT_MANTISSA_SIZE - 1 downto 0)  <= std_logic_vector(mantissa_6) & std_logic_vector(to_unsigned(0, OUT_MANTISSA_SIZE - (IN_MANTISSA_SIZE + 1)*2));
			else
				output(OUT_MANTISSA_SIZE - 1 downto 0)  <= std_logic_vector(mantissa_6(mantissa_6'length - 1 downto mantissa_6'length - OUT_MANTISSA_SIZE));
			end if;

			aux_out                                       <= aux_6;
			op_ready                                      <= new_request_6;

		end if;
	end process;
end architecture RTL;
