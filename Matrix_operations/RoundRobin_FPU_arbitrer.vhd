library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Matrix_definition_pack.all;

entity RoundRobin_FPU_arbitrer is
	port (
		clk : in std_logic;
		BUSES_in : BUSES_to_FPU;
		BUSES_out : BUSES_from_FPU
	);
end entity RoundRobin_FPU_arbitrer;

architecture RTL of RoundRobin_FPU_arbitrer is
	
begin
	
RoundRobin_State_Machine : process
begin
	if(rising_edge(clk)) then
	end if;
end process;

end architecture RTL;
