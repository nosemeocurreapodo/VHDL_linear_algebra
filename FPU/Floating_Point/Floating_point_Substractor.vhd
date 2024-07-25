library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Floating_point_definition.all;
use work.FPU_utility_functions.all;

entity Floating_point_Substractor is
	port(
		clk       : in  std_logic;
		opa       : in  floating_point;
		opb       : in  floating_point;
		output    : out floating_point;
		new_op    : in  std_logic;
		op_id_in  : in  request_id;
		op_id_out : out request_id;
		op_ready  : out std_logic
	);
end entity Floating_point_Substractor;

architecture RTL of Floating_point_Substractor is

	-- 1 stage
	signal opa_sign_1       : std_logic;
	signal opb_sign_1       : std_logic;
	signal opa_exponent_1   : unsigned(exponent_size - 1 downto 0);
	signal opb_exponent_1   : unsigned(exponent_size - 1 downto 0);
	signal opa_mantissa_1   : unsigned(mantissa_size + 1 downto 0);
	signal opb_mantissa_1   : unsigned(mantissa_size + 1 downto 0);
	signal exponent_diff_1 : signed(exponent_size  downto 0);
	
	signal request_id_1 : request_id;
	signal new_operation_1 : std_logic; 
	-- 2 stage
	signal opa_sign_2       : std_logic;
	signal opb_sign_2       : std_logic;
	signal opa_mantissa_2 : unsigned(mantissa_size + 1 downto 0);
	signal opb_mantissa_2 : unsigned(mantissa_size + 1 downto 0);
	signal output_exponent_2 : unsigned(exponent_size - 1 downto 0);
	
	signal request_id_2 : request_id;
	signal new_operation_2 : std_logic; 
	-- 3 stage
	signal output_sign_3 : std_logic;
	signal output_mantissa_3 : std_logic_vector(mantissa_size + 1 downto 0);
	signal output_exponent_3 : unsigned(exponent_size - 1 downto 0);
	
	signal request_id_3 : request_id;
	signal new_operation_3 : std_logic; 
	-- 4 stage
	signal output_sign_4     : std_logic;
	signal output_exponent_4 : unsigned(exponent_size - 1 downto 0);
	signal output_mantissa_4 : unsigned(mantissa_size + 1 downto 0);
	
	signal request_id_4 : request_id;
	signal new_operation_4 : std_logic; 
	


begin
	process(clk)
		variable output_mantissa_3_lz : integer;
		variable output_mantissa_3_var : signed(mantissa_size + 1 downto 0);
	begin
		if (rising_edge(clk)) then
			-- 1 stage
			if (new_op = '1') then
				-- dependiendo de los signos la operacion que se realiza (suma, resta)
				opa_sign_1 <= opa.sign;
				opb_sign_1 <= opb.sign;

				opa_exponent_1 <= opa.exponent;
				opb_exponent_1 <= opb.exponent;
				
				-- le agrego el 1  que saca el normalizador y pongo el cero para mostrar que es positivo
				opa_mantissa_1 <= unsigned("01" & std_logic_vector(opa.mantissa));
				opb_mantissa_1 <= unsigned("01" & std_logic_vector(opb.mantissa));

				-- la differencia me da cual tengo que shift_right
				exponent_diff_1 <= signed('0'&std_logic_vector(opa.exponent)) - signed('0'&std_logic_vector(opb.exponent));

				request_id_1   <= op_id_in;
				new_operation_1 <= '1';
			else
				new_operation_1 <= '0';
			end if;

			-- 2 stage shift_right
			if (exponent_diff_1 > 0) then
				opb_mantissa_2  <= shift_right(opb_mantissa_1, to_integer(abs(exponent_diff_1)));
				opa_mantissa_2  <= opa_mantissa_1;
				output_exponent_2 <= opa_exponent_1;
			else
				opa_mantissa_2  <= shift_right(opa_mantissa_1, to_integer(abs(exponent_diff_1)));
				opb_mantissa_2  <= opb_mantissa_1;
				output_exponent_2 <= opb_exponent_1;
			end if;
			
			opa_sign_2 <= opa_sign_1;
			opb_sign_2 <= opb_sign_1;
			
			request_id_2   <= request_id_1;
			new_operation_2 <= new_operation_1;

			-- 3 stage suma
			if(opa_sign_2 = '0' and opb_sign_2 = '0') then
				output_mantissa_3_var := signed(opa_mantissa_2) - signed(opb_mantissa_2);
			elsif(opa_sign_2 = '0' and opb_sign_2 = '1') then
				output_mantissa_3_var := signed(opa_mantissa_2) + signed(opb_mantissa_2);
			elsif(opa_sign_2 = '1' and opb_sign_2 = '0') then
				output_mantissa_3_var := -(signed(opa_mantissa_2) + signed(opb_mantissa_2));
			else
				output_mantissa_3_var := signed(opb_mantissa_2) - signed(opa_mantissa_2);
			end if;
			-- calculo el signo
			if(output_mantissa_3_var >= 0) then
				output_sign_3 <= '0';
			else
				output_sign_3 <= '1';
			end if;
			-- lo demas se hace con el valor absoluto
			output_mantissa_3 <= std_logic_vector(abs(output_mantissa_3_var));
			output_exponent_3 <= output_exponent_2;
			
			request_id_3  <= request_id_2;
			new_operation_3 <= new_operation_2;

			-- 4 stage normalizo

			output_mantissa_3_lz := count_l_zeros(output_mantissa_3);
			output_mantissa_4 <= shift_left(unsigned(output_mantissa_3), output_mantissa_3_lz);
			output_exponent_4 <= output_exponent_3 - output_mantissa_3_lz;
			output_sign_4 <= output_sign_3;
			
			request_id_4  <= request_id_3;
			new_operation_4 <= new_operation_3;
			
			-- 5 stage salida!
			output.sign     <= output_sign_4;
			output.exponent <= output_exponent_4;
			output.mantissa <= output_mantissa_4(mantissa_size - 1 downto 0);

			op_id_out <= request_id_4;
			op_ready  <= new_operation_4;
		end if;
	end process;
end architecture RTL;