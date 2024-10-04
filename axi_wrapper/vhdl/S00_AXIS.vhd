library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.FPU_utility_functions_pack.all;

entity SCALAR_S_AXIS is
	generic (
		-- AXI4Stream sink: Data Width
		SCALAR_SIZE           : integer := 32;
		SCALAR_FRAC_SIZE      : integer := 23;
		C_S_AXIS_TDATA_WIDTH  : integer	:= 32
	);
	port (

		data_out_ok   : out std_logic;
		data_out      : out std_logic_vector(SCALAR_SIZE-1 downto 0);
		data_out_last : out std_logic;

		-- AXI4Stream sink: Clock
		S_AXIS_ACLK	: in std_logic;
		-- AXI4Stream sink: Reset
		S_AXIS_ARESETN	: in std_logic;
		-- Ready to accept data in
		S_AXIS_TREADY	: out std_logic;
		-- Data in
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		-- Byte qualifier
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TKEEP	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- Indicates boundary of last packet
		S_AXIS_TLAST	: in std_logic;
		-- Data is in valid
		S_AXIS_TVALID	: in std_logic
	);
end SCALAR_S_AXIS;

architecture arch_imp of SCALAR_S_AXIS is
	-- function called clogb2 that returns an integer which has the 
	-- value of the ceiling of the log base 2.
	function clogb2 (bit_depth : integer) return integer is 
	variable depth  : integer := bit_depth;
	  begin
	    if (depth = 0) then
	      return(0);
	    else
	      for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
	        if(depth <= 1) then 
	          return(clogb2);      
	        else
	          depth := depth / 2;
	        end if;
	      end loop;
	    end if;
	end;    

begin

	process(S_AXIS_ACLK)
	begin
		if(rising_edge(S_AXIS_ACLK)) then
			if(S_AXIS_ARESETN = '0') then
				data_out_ok <= '0';
				data_out <= to_scalar(0, SCALAR_SIZE, SCALAR_FRAC_SIZE);
				data_out_last <= '0';
				S_AXIS_TREADY <= '0';
			else
				S_AXIS_TREADY <= '1';
				data_out_ok <= S_AXIS_TVALID;
				data_out    <= S_AXIS_TDATA(SCALAR_SIZE - 1 downto 0);
				data_out_last <= S_AXIS_TLAST;
			end if;
		end if;
	end process;

end arch_imp;
