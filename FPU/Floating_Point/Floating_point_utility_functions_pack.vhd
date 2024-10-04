library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.FPU_utility_functions.all;

package Floating_point_utility_functions_pack is
	--constant exponent_size       : integer := 5;
	--constant mantissa_size       : integer := 10;
	--constant floating_point_size : integer := 1 + exponent_size + mantissa_size;

	--type floating_point is record
	--	sign     : std_logic;
	--	exponent : unsigned(exponent_size - 1 downto 0);
	--	mantissa : unsigned(mantissa_size - 1 downto 0);
	--end record;

	function get_sign(fp : std_logic_vector) return std_logic;
	function get_exponent(fp : std_logic_vector; exponent_size : integer) return std_logic_vector;
	function get_mantissa(fp : std_logic_vector; mantissa_size : integer) return std_logic_vector;

	--function to_floating_point(slv : std_logic_vector(floating_point_size - 1 downto 0)) return floating_point;
	function to_floating_point(int : integer; size : integer; mantissa_size : integer) return std_logic_vector;
	function to_floating_point(float : real; size : integer; mantissa_size : integer) return std_logic_vector;
	--function floating_point_to_std_logic_vector(fp : floating_point) return std_logic_vector;
	function floating_point_to_real(fp : std_logic_vector; size : integer; mantissa_size : integer) return real;

	--constant floating_point_zero : floating_point := to_floating_point(0.0);

end package;

package body Floating_point_utility_functions_pack is

	--function to_floating_point(slv : std_logic_vector(floating_point_size - 1 downto 0)) return floating_point is
	--	variable fp : floating_point;
	--begin
	--	fp.sign     := slv(floating_point_size - 1);
	--	fp.exponent := unsigned(slv(exponent_size + mantissa_size - 1 downto mantissa_size));
	--	fp.mantissa := unsigned(slv(mantissa_size - 1 downto 0));
    --
	--	return fp;
	--end function;

	function get_sign(fp : std_logic_vector) return std_logic is
	begin
		return fp(fp'length - 1);
	end function;

	function get_exponent(fp : std_logic_vector; exponent_size : integer) return std_logic_vector is
		variable exponent : std_logic_vector(exponent_size - 1 downto 0);
	begin
		exponent := fp(fp'length - 2 downto fp'length - 1 - exponent_size);
		return exponent;
	end function;

	function get_mantissa(fp : std_logic_vector; mantissa_size : integer) return std_logic_vector is
		variable mantissa : std_logic_vector(mantissa_size - 1 downto 0);
	begin
		mantissa := fp(mantissa_size - 1 downto 0);
		return mantissa;
	end function;

	function to_floating_point(int : integer; size : integer; mantissa_size : integer) return std_logic_vector is
		variable m       : unsigned(mantissa_size - 1 downto 0);
		variable m_zeros : integer;
		variable fp        : std_logic_vector(size - 1 downto 0);
		variable abs_int   : integer;
		--variable exponent  : real;
		--variable mantissa  : real;
		--variable quotient  : real;

	begin
		if (int >= 0) then
			fp(size - 1) := '0';
		else
			fp(size - 1) := '1';
		end if;
	
		abs_int := abs(int);
		
		if( abs_int = 0) then
			fp(size - 2 downto mantissa_size) := std_logic_vector(to_unsigned(0, size - mantissa_size - 1));
			fp(mantissa_size - 1 downto 0)    := std_logic_vector(to_unsigned(0, mantissa_size));
		else
			m                                                          := to_unsigned(abs_int, mantissa_size);
			m_zeros                                                    := count_l_zeros_var(m);
			fp(size - 2 downto mantissa_size) := std_logic_vector(shift_left(m, m_zeros + 1));
			fp(mantissa_size - 1 downto 0)    := std_logic_vector(to_unsigned(2**(size - mantissa_size - 2), mantissa_size) - m_zeros);
			--exponent := floor(log2(abs_int));
			--quotient := 2.0 ** exponent;
			--mantissa := abs_int / quotient;
			
			--fp.exponent := to_unsigned(natural(127.0+exponent), exponent_size);
			--fp.mantissa := to_unsigned(natural(round(mantissa*(2.0**(mantissa_size)))), mantissa_size);
		end if;
		return fp;
	end function;
	
	function to_floating_point(float : real; size : integer; mantissa_size : integer) return std_logic_vector is
		variable fp        : std_logic_vector(size - 1 downto 0);
		variable exponent_size : integer;
		variable abs_float : real;
		variable exponent  : real;
		variable mantissa  : real;
		variable quotient  : real;
	begin

		exponent_size := size - mantissa_size - 1;

		if (float >= 0.0) then
			fp(size - 1) := '0';
		else
			fp(size - 1) := '1';
		end if;
		
		abs_float := abs(float);

		if( abs_float = 0.0) then
			fp(size - 2 downto mantissa_size) := std_logic_vector(to_unsigned(0, exponent_size));
			fp(mantissa_size - 1 downto 0)    := std_logic_vector(to_unsigned(0, mantissa_size));
		else
			exponent := floor(log2(abs_float));
			quotient := 2.0 ** exponent;
			mantissa := abs_float / quotient;
			
			fp(size - 2 downto mantissa_size) := std_logic_vector(to_unsigned(natural(2**(exponent_size - 1) - 1 + exponent), size - mantissa_size - 1));
			fp(mantissa_size - 1 downto 0)    := std_logic_vector(to_unsigned(natural(round(mantissa*(2.0**(mantissa_size)))), mantissa_size));
		end if;

		return fp;
	end function;

--	function floating_point_to_std_logic_vector(fp : floating_point) return std_logic_vector is
--		variable slv : std_logic_vector(floating_point_size - 1 downto 0);
--	begin
--		slv(floating_point_size - 1)                                := fp.sign;
--		slv(exponent_size + mantissa_size - 1 downto mantissa_size) := std_logic_vector(fp.exponent);
--		slv(mantissa_size - 1 downto 0)                             := std_logic_vector(fp.mantissa);
--		return slv;
--	end function;

	function floating_point_to_real(fp : std_logic_vector; size : integer; mantissa_size : integer) return real is
		variable r           : real;
		variable mantissa_r  : real;
		variable un          : unsigned(23 downto 0);
		variable int         : integer;
		variable mantissa_r2 : real;
	begin
		un          := unsigned('1' & fp(mantissa_size - 1 downto 0));
		int         := to_integer(un);
		mantissa_r  := real(int);
		mantissa_r2 := mantissa_r * (2 ** real(-23));
		r := (2 ** (real(to_integer(unsigned(fp(size - 2 downto mantissa_size))) - 127))) * mantissa_r2;
		if (fp(size - 1) = '1') then
			r := -r;
		end if;
		return r;
	end function;

--	function to_float(uint       :  unsigned) return float is
--		variable count_zeros : integer;
--		variable exponent  : integer;
--		variable mantissa : integer;
--		variable mantissa_slv : std_logic_vector(23 downto 0);
--		variable fp : float;
--	begin
--		count_zeros := 0;
--		for i in uint'range loop
--			if (uint(i) = '0') then
--				count_zeros := count_zeros + 1;
--			else
--				exit;
--			end if;
--		end loop;
--
--		exponent := uint'length - count_zeros - 1;
--		mantissa := integer(uint); 
--		
--		fp.sign := '0';
--		fp.exponent := std_logic_vector(to_unsigned(exponent, 8));
--		mantissa_slv := to_unsigned(mantissa, )
--		
--		return fp;  
--
--	end to_float;

end package body;
