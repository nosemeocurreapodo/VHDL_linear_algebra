library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Floating_point_utility_functions_pack.all;
use work.FPU_utility_functions.all;

entity Floating_point_Adder is
	generic(
		IN_SIZE           : integer;-- := 32;
		IN_MANTISSA_SIZE  : integer;-- := 23;
		OUT_SIZE          : integer;-- := 32;
		OUT_MANTISSA_SIZE : integer;-- := 23;
		AUX_SIZE          : integer-- := 32
	);
	port(
		clk       : in  std_logic;
		opa       : in  std_logic_vector(IN_SIZE - 1 downto 0);
		opb       : in  std_logic_vector(IN_SIZE - 1 downto 0);
		output    : out std_logic_vector(OUT_SIZE - 1 downto 0);
		new_op    : in  std_logic;
		op_ready  : out std_logic;
		aux_in  : in  std_logic_vector(AUX_SIZE - 1 downto 0);
		aux_out : out std_logic_vector(AUX_SIZE - 1 downto 0)
	);
end entity Floating_point_Adder;

architecture RTL of Floating_point_Adder is

	constant IN_EXPONENT_SIZE : integer := IN_SIZE - IN_MANTISSA_SIZE - 1;
	constant OUT_EXPONENT_SIZE : integer := OUT_SIZE - OUT_MANTISSA_SIZE - 1;

	-- stage 1
	signal opa_sign_1      : std_logic;
	signal opb_sign_1      : std_logic;
	signal opa_exponent_1  : std_logic_vector(IN_EXPONENT_SIZE - 1 downto 0);
	signal opb_exponent_1  : std_logic_vector(IN_EXPONENT_SIZE - 1 downto 0);
	signal opa_mantissa_1  : std_logic_vector(IN_MANTISSA_SIZE - 1 downto 0);
	signal opb_mantissa_1  : std_logic_vector(IN_MANTISSA_SIZE - 1 downto 0);

	signal aux_1      : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_1   : std_logic;

	-- stage 2
	signal opa_sign_2      : std_logic;
	signal opb_sign_2      : std_logic;
	signal opa_exponent_2  : unsigned(IN_EXPONENT_SIZE - 1 downto 0);
	signal opb_exponent_2  : unsigned(IN_EXPONENT_SIZE - 1 downto 0);
	signal opa_mantissa_2  : unsigned(IN_MANTISSA_SIZE - 1 downto 0);
	signal opb_mantissa_2  : unsigned(IN_MANTISSA_SIZE - 1 downto 0);

	signal aux_2      : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_2   : std_logic;

	-- stage 3
	signal opa_mantissa_3    : signed(IN_MANTISSA_SIZE + 2 downto 0);
	signal opb_mantissa_3    : signed(IN_MANTISSA_SIZE + 2 downto 0);
	signal exponent_3        : signed(IN_EXPONENT_SIZE - 1 downto 0);

	signal exponent_diff_3   : unsigned(IN_EXPONENT_SIZE - 1 downto 0);

	signal aux_3             : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_3   : std_logic;

	-- stage 4
	signal opa_mantissa_4    : signed(IN_MANTISSA_SIZE + 2 downto 0);
	signal opb_mantissa_4    : signed(IN_MANTISSA_SIZE + 2 downto 0);
	signal exponent_4        : unsigned(IN_EXPONENT_SIZE - 1 downto 0);

	signal aux_4      : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_4   : std_logic;

	-- stage 5
	signal mantissa_5 : signed(IN_MANTISSA_SIZE + 2 downto 0);
	signal exponent_5 : unsigned(IN_EXPONENT_SIZE - 1 downto 0);

	signal aux_5      : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_5   : std_logic;

	-- stage 6
	signal sign_6     : std_logic;
	signal exponent_6 : unsigned(IN_EXPONENT_SIZE - 1 downto 0);
	signal mantissa_6 : unsigned(IN_MANTISSA_SIZE + 2 downto 0);

	signal aux_6    : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_6 : std_logic;

	-- stage 7
	signal sign_7     : std_logic;
	signal exponent_7 : unsigned(IN_EXPONENT_SIZE - 1 downto 0);
	signal mantissa_7 : unsigned(IN_MANTISSA_SIZE + 2 downto 0);
	signal l_zeros_7 : integer;

	signal aux_7    : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_7 : std_logic;

	-- stage 8
	signal sign_8     : std_logic;
	signal exponent_8 : unsigned(IN_EXPONENT_SIZE - 1 downto 0);
	signal mantissa_8 : unsigned(IN_MANTISSA_SIZE + 2 downto 0);

	signal aux_8    : std_logic_vector(AUX_SIZE - 1 downto 0);
	signal new_operation_8 : std_logic;

begin
	process(clk)
	begin
		if (rising_edge(clk)) then
			
			-- stage 1 input registers
			opa_sign_1 <= get_sign(opa);
			opb_sign_1 <= get_sign(opb);
			opa_exponent_1 <= get_exponent(opa, IN_EXPONENT_SIZE);
			opb_exponent_1 <= get_exponent(opb, IN_EXPONENT_SIZE);
			opa_mantissa_1 <= get_mantissa(opa, IN_MANTISSA_SIZE);
			opb_mantissa_1 <= get_mantissa(opb, IN_MANTISSA_SIZE);
			aux_1    <= aux_in;
			-- seems to be important, otherwise we propagate undifined states during simulation
			if(new_op = '1') then
				new_operation_1 <= '1';
			else
				new_operation_1	<= '0';
			end if;

			-- stage 2 check bigger
			if (opa_exponent_1 >= opb_exponent_1) then
				opa_sign_2 <= opa_sign_1;
				opb_sign_2 <= opb_sign_1;
				opa_exponent_2 <= unsigned(opa_exponent_1);
				opb_exponent_2 <= unsigned(opb_exponent_1);
				opa_mantissa_2 <= unsigned(opa_mantissa_1);
				opb_mantissa_2 <= unsigned(opb_mantissa_1);
			else
				opa_sign_2 <= opb_sign_1;
				opb_sign_2 <= opa_sign_1;
				opa_exponent_2 <= unsigned(opb_exponent_1);
				opb_exponent_2 <= unsigned(opa_exponent_1);
				opa_mantissa_2 <= unsigned(opb_mantissa_1);
				opb_mantissa_2 <= unsigned(opa_mantissa_1);
			end if;

			aux_2           <= aux_1;
			new_operation_2 <= new_operation_1;

			-- stage 3
			-- de normalizo
			exponent_diff_3 <= unsigned(opa_exponent_2) - unsigned(opb_exponent_2);

			if(unsigned(opa_exponent_2) = to_unsigned(0, opa_exponent_2'length)) then
				opa_mantissa_3 <= signed("000" & std_logic_vector(opa_mantissa_2));
			elsif (opa_sign_2 = '0') then -- de normalized number
				opa_mantissa_3 <= signed("001" & std_logic_vector(opa_mantissa_2));
			else
				opa_mantissa_3 <= -signed("001" & std_logic_vector(opa_mantissa_2));
			end if;

			if(unsigned(opb_exponent_2) = to_unsigned(0, opb_exponent_2'length)) then
				opb_mantissa_3 <= signed("000" & std_logic_vector(opb_mantissa_2));
			elsif (opb_sign_2 = '0') then
				opb_mantissa_3 <= signed("001" & std_logic_vector(opb_mantissa_2));
			else
				opb_mantissa_3 <= -signed("001" & std_logic_vector(opb_mantissa_2));
			end if;

			exponent_3 <= signed(opa_exponent_2) - integer(2**(IN_EXPONENT_SIZE - 1) - 1 ); -- - 127

			aux_3           <= aux_2;
			new_operation_3 <= new_operation_2;

			-- stage 4 shift_right
			opb_mantissa_4  <= shift_right(opb_mantissa_3, to_integer(exponent_diff_3));
			opa_mantissa_4  <= opa_mantissa_3;
			exponent_4      <= unsigned(exponent_3 + integer(2**(OUT_EXPONENT_SIZE - 1) - 1 )); -- + 128 -- idn why the extra -1

			aux_4           <= aux_3;
			new_operation_4 <= new_operation_3;

			-- stage 5 suma
			mantissa_5 <= opa_mantissa_4 + opb_mantissa_4;
			exponent_5 <= exponent_4;

			aux_5           <= aux_4;
			new_operation_5 <= new_operation_4;

			-- stage 6 calculo el signo
			if (mantissa_5 >= 0) then
				sign_6 <= '0';
			else
				sign_6 <= '1';
			end if;

			mantissa_6 <= unsigned( abs (mantissa_5));
			exponent_6 <= exponent_5;

			aux_6           <= aux_5;
			new_operation_6 <= new_operation_5;

			-- stage 7 -- count leading zeros
			sign_7          <= sign_6;
			aux_7           <= aux_6;
			new_operation_7 <= new_operation_6;
			exponent_7 <= exponent_6;
			mantissa_7 <= mantissa_6;
			l_zeros_7 <= count_l_zeros(mantissa_6);

			-- stage 8 shift left
			sign_8 <= sign_7;
			if(mantissa_7 = to_unsigned(0, mantissa_7'length)) then
				exponent_8 <= to_unsigned(0, exponent_8'length);
				mantissa_8 <= to_unsigned(0, mantissa_8'length);
			else
				mantissa_8 <= shift_left(mantissa_7, l_zeros_7 + 1);
				exponent_8 <= exponent_7 + 2 - l_zeros_7;
			end if;
			new_operation_8 <= new_operation_7;
			aux_8 <= aux_7;

			-- the last bit length - 1 bit should be always 0, the length - 3 should be always 1 
			--if(mantissa_6 = to_unsigned(0, IN_MANTISSA_SIZE + 2)) then
			--	exponent_7 <= to_unsigned(0, OUT_SIZE - OUT_MANTISSA_SIZE - 1);
			--	mantissa_7 <= to_unsigned(0, OUT_MANTISSA_SIZE);
			--elsif(mantissa_6(mantissa_6'length - 2 downto mantissa_6'length - 9) = "00000001") then
			--	exponent_7 <= exponent_6 - 6;
			--	mantissa_7 <= mantissa_6(mantissa_6'length - 10 downto 0) & "000000";
			--elsif(mantissa_6(mantissa_6'length - 2 downto mantissa_6'length - 8) = "0000001") then
			--	exponent_7 <= exponent_6 - 5;
			--	mantissa_7 <= mantissa_6(mantissa_6'length - 9 downto 0) & "00000";
			--elsif(mantissa_6(mantissa_6'length - 2 downto mantissa_6'length - 7) = "000001") then
			--	exponent_7 <= exponent_6 - 4;
			--	mantissa_7 <= mantissa_6(mantissa_6'length - 8 downto 0) & "0000";
			--elsif(mantissa_6(mantissa_6'length - 2 downto mantissa_6'length - 6) = "00001") then
			--	exponent_7 <= exponent_6 - 3;
			--	mantissa_7 <= mantissa_6(mantissa_6'length - 7 downto 0) & "000";
			--elsif(mantissa_6(mantissa_6'length - 2 downto mantissa_6'length - 5) = "0001") then
			--	exponent_7 <= exponent_6 - 2;
			--	mantissa_7 <= mantissa_6(mantissa_6'length - 6 downto 0) & "00";
			--elsif(mantissa_6(mantissa_6'length - 2 downto mantissa_6'length - 4) = "001") then
			--	exponent_7 <= exponent_6 - 1;
			--	mantissa_7 <= mantissa_6(mantissa_6'length - 5 downto 0) & '0';
			--elsif(mantissa_6(mantissa_6'length - 2 downto mantissa_6'length - 3) = "01") then
			--	exponent_7 <= exponent_6;
			--	mantissa_7 <= mantissa_6(mantissa_6'length - 4 downto 0);
			--else
			--	exponent_7 <= exponent_6 + 1;
			--	mantissa_7 <= mantissa_6(mantissa_6'length - 3 downto 1);
			--end if;

			-- stage output
			output(OUT_SIZE - 1)                          <= sign_8;

			if(OUT_EXPONENT_SIZE > IN_EXPONENT_SIZE) then
				output(OUT_SIZE - 2 downto OUT_MANTISSA_SIZE) <= std_logic_vector(to_unsigned(0, OUT_EXPONENT_SIZE - IN_EXPONENT_SIZE)) & std_logic_vector(exponent_8);
			else
				output(OUT_SIZE - 2 downto OUT_MANTISSA_SIZE) <= std_logic_vector(exponent_8(OUT_EXPONENT_SIZE - 1 downto 0));
			end if;
			
			if(OUT_MANTISSA_SIZE > IN_MANTISSA_SIZE + 3) then
				output(OUT_MANTISSA_SIZE - 1 downto 0)        <= std_logic_vector(mantissa_8) & std_logic_vector(to_unsigned(0, OUT_MANTISSA_SIZE - IN_MANTISSA_SIZE - 3));
			else
				output(OUT_MANTISSA_SIZE - 1 downto 0)        <= std_logic_vector(mantissa_8(mantissa_8'length - 1 downto mantissa_8'length - OUT_MANTISSA_SIZE));
			end if;

			aux_out  <= aux_8;
			op_ready <= new_operation_8;
		end if;
	end process;
end architecture RTL;