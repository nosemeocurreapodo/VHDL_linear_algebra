library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.FPU_utility_functions.all;

package Floating_point_definition is
	constant exponent_size       : integer := 8;
	constant mantissa_size       : integer := 23;
	constant floating_point_size : integer := 1 + exponent_size + mantissa_size;

	type floating_point is record
		sign     : std_logic;
		exponent : unsigned(exponent_size - 1 downto 0);
		mantissa : unsigned(mantissa_size - 1 downto 0);
	end record;

	function to_floating_point(slv : std_logic_vector(floating_point_size - 1 downto 0)) return floating_point;
	function to_floating_point(slv : signed(floating_point_size - 1 downto 0)) return floating_point;
	function to_floating_point(int : integer) return floating_point;
	function to_floating_point(float : real) return floating_point;
	function floating_point_to_std_logic_vector(fp : floating_point) return std_logic_vector;
	function floating_point_to_real(fp : floating_point) return real;
	function floating_point_to_signed(fp : floating_point) return signed;

	constant floating_point_zero : floating_point := to_floating_point(0.0);

end package Floating_point_definition;

package body Floating_point_definition is

	function to_floating_point(slv : std_logic_vector(floating_point_size - 1 downto 0)) return floating_point is
		variable fp : floating_point;
	begin
		fp.sign     := slv(floating_point_size - 1);
		fp.exponent := unsigned(slv(exponent_size + mantissa_size - 1 downto mantissa_size));
		fp.mantissa := unsigned(slv(mantissa_size - 1 downto 0));

		return fp;
	end function;

	function to_floating_point(slv : signed(floating_point_size - 1 downto 0)) return floating_point is
		variable fp  : floating_point;
		variable aux : signed(floating_point_size - 1 downto 0);
	begin
		fp.sign     := slv(floating_point_size - 1);
		fp.exponent := unsigned(slv(exponent_size + mantissa_size - 1 downto mantissa_size));
		fp.mantissa := unsigned(slv(mantissa_size - 1 downto 0));
		return fp;
	end function;
	
	function to_floating_point(int : integer) return floating_point is
		variable fp      : floating_point;
		variable m       : unsigned(mantissa_size - 1 downto 0);
		variable m_zeros : integer;
	begin
		if (int >= 0) then
			fp.sign := '0';
		else
			fp.sign := '1';
		end if;
		m           := to_unsigned(int, mantissa_size);
		m_zeros     := count_l_zeros_var(m);
		fp.mantissa := shift_left(m, m_zeros + 1);
		fp.exponent := to_unsigned(128, exponent_size) - m_zeros;
		return fp;
	end function;
	
	function to_floating_point(float : real) return floating_point is
		variable fp        : floating_point;
		variable abs_float : real;
		variable exponent  : real;
		variable mantissa  : real;
		variable quotient  : real;
	begin
		if (float >= 0.0) then
			fp.sign := '0';
		else
			fp.sign := '1';
		end if;
		
		abs_float := abs(float);

		if( abs_float = 0.0) then
			fp.exponent := to_unsigned(0, exponent_size);
			fp.mantissa := to_unsigned(0, mantissa_size);
		else
			exponent := floor(log2(abs_float));
			quotient := 2.0 ** exponent;
			mantissa := abs_float / quotient;
			
			fp.exponent := to_unsigned(natural(127.0+exponent), exponent_size);
			fp.mantissa := to_unsigned(natural(round(mantissa*(2.0**(mantissa_size)))), mantissa_size);
		end if;

		return fp;
	end function;

	function floating_point_to_std_logic_vector(fp : floating_point) return std_logic_vector is
		variable slv : std_logic_vector(floating_point_size - 1 downto 0);
	begin
		slv(floating_point_size - 1)                                := fp.sign;
		slv(exponent_size + mantissa_size - 1 downto mantissa_size) := std_logic_vector(fp.exponent);
		slv(mantissa_size - 1 downto 0)                             := std_logic_vector(fp.mantissa);
		return slv;
	end function;

	function floating_point_to_real(fp : floating_point) return real is
		variable r           : real;
		variable mantissa_r  : real;
		variable un          : unsigned(23 downto 0);
		variable int         : integer;
		variable mantissa_r2 : real;
	begin
		un          := unsigned('1' & std_logic_vector(fp.mantissa));
		int         := to_integer(un);
		mantissa_r  := real(int);
		mantissa_r2 := mantissa_r * (2 ** real(-23));
		if (fp.sign = '0') then
			r := (2 ** (real(to_integer(fp.exponent) - 127))) * mantissa_r2;
		else
			r := -(2 ** (real(to_integer(fp.exponent) - 127))) * mantissa_r2;
		end if;
		return r;
	end function;

	function floating_point_to_signed(fp : floating_point) return signed is
		variable r           : real;
		variable mantissa_r  : real;
		variable un          : unsigned(23 downto 0);
		variable int         : integer;
		variable mantissa_r2 : real;
	begin
		un          := unsigned('1' & std_logic_vector(fp.mantissa));
		int         := to_integer(un);
		mantissa_r  := real(int);
		mantissa_r2 := mantissa_r * (2 ** real(-23));
		if (fp.sign = '0') then
			r := (2 ** (real(to_integer(fp.exponent) - 127))) * mantissa_r2;
		else
			r := -(2 ** (real(to_integer(fp.exponent) - 127))) * mantissa_r2;
		end if;
		return to_signed(Integer(r), floating_point_size);
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

end package body Floating_point_definition;
