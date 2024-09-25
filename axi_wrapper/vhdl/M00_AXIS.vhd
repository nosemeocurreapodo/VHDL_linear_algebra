library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.FPU_definitions_pack.all;

entity SCALAR_M_AXIS is
	generic (
		C_M_AXIS_TDATA_WIDTH	: integer	:= 32;
		SCALAR_FIFO_DEPTH : integer := 32
	);
	port (

		data_in_ok   : in std_logic;
		data_in      : in std_logic_vector(scalar_size-1 downto 0);

		-- Global ports
		M_AXIS_ACLK	: in std_logic;
		-- 
		M_AXIS_ARESETN	: in std_logic;
		-- Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		M_AXIS_TVALID	: out std_logic;
		-- TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		-- TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- TLAST indicates the boundary of a packet.
		M_AXIS_TLAST	: out std_logic;
		-- TREADY indicates that the slave can accept a transfer in the current cycle.
		M_AXIS_TREADY	: in std_logic
	);
end SCALAR_M_AXIS;

architecture implementation of SCALAR_M_AXIS is
	 -- function called clogb2 that returns an integer which has the   
	 -- value of the ceiling of the log base 2.                              
	function clogb2 (bit_depth : integer) return integer is                  
	 	variable depth  : integer := bit_depth;                               
	 	variable count  : integer := 1;                                       
	 begin                                                                   
	 	 for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
	      if (bit_depth <= 2) then                                           
	        count := 1;                                                      
	      else                                                               
	        if(depth <= 1) then                                              
	 	       count := count;                                                
	 	     else                                                             
	 	       depth := depth / 2;                                            
	          count := count + 1;                                            
	 	     end if;                                                          
	 	   end if;                                                            
	   end loop;                                                             
	   return(count);        	                                              
	 end;                                                                    

	signal scalar_fifo          : scalar_array(SCALAR_FIFO_DEPTH - 1 downto 0);
	signal scalar_fifo_valid    : std_logic_vector(SCALAR_FIFO_DEPTH - 1 downto 0);
	signal scalar_fifo_last_data : std_logic;
begin

	process(M_AXIS_ACLK)
	begin
		if(rising_edge(M_AXIS_ACLK)) then
			if(M_AXIS_ARESETN = '0') then
				-- Synchronous reset (active low)
				scalar_fifo_valid <= std_logic_vector(to_unsigned(0, SCALAR_FIFO_DEPTH));
			else
				for I in SCALAR_FIFO_DEPTH - 1 downto 1 loop
					scalar_fifo(I)        <= scalar_fifo(I - 1);
					scalar_fifo_valid(I)  <= scalar_fifo_valid(I - 1);
				end loop;
				scalar_fifo(0) <= to_scalar(data_in);
				if(data_in_ok = '1') then
					scalar_fifo_valid(0) <= '1';
				else
					scalar_fifo_valid(0) <= '0';
				end if;
			end if;
		end if;
	end process;

	-- check if fifo has some data
	process(M_AXIS_ACLK)
	    variable last_data : std_logic;
	begin
		if(rising_edge(M_AXIS_ACLK)) then
			if(M_AXIS_ARESETN = '0') then
				last_data := '0';
			else
			last_data := '0';
				for I in SCALAR_FIFO_DEPTH - 2 downto 0 loop
					last_data := last_data or scalar_fifo_valid(I);
				end loop;
			end if;
			last_data := not last_data and scalar_fifo_valid(SCALAR_FIFO_DEPTH - 1);
		end if;
		scalar_fifo_last_data <= last_data;
	end process;
                                                                           
	-- Streaming output data is read from FIFO                                      
	process(M_AXIS_ACLK)                                                          
	--variable  sig_one : integer := 1; 
	variable  sig_one : integer := 0;                                             
	begin                                                                         
	    if (rising_edge (M_AXIS_ACLK)) then                                         
	      	if(M_AXIS_ARESETN = '0') then                                             
		  		M_AXIS_TDATA <= std_logic_vector(to_unsigned(sig_one,C_M_AXIS_TDATA_WIDTH));  
				M_AXIS_TVALID <= '0';
				M_AXIS_TSTRB <= (others => '0');
	      --elsif (tx_en = '1') then -- && M_AXIS_TSTRB(byte_index)                   
	      --  stream_data_out <= std_logic_vector( to_unsigned(read_pointer,C_M_AXIS_TDATA_WIDTH) + to_unsigned(sig_one,C_M_AXIS_TDATA_WIDTH));
		  	elsif (scalar_fifo_valid(SCALAR_FIFO_DEPTH - 1) = '1' and M_AXIS_TREADY = '1') then
				M_AXIS_TDATA <= scalar_to_std_logic_vector(scalar_fifo(SCALAR_FIFO_DEPTH - 1));
				M_AXIS_TVALID <= '1';
				M_AXIS_TSTRB <= (others => '1');
			else
				M_AXIS_TDATA <= std_logic_vector(to_unsigned(sig_one,C_M_AXIS_TDATA_WIDTH));
				M_AXIS_TVALID <= '0';
				M_AXIS_TSTRB <= (others => '0');
	      	end if;                                                                   
	    end if;                                                                    
	end process;                                                                 
	   
	M_AXIS_TLAST <= '1' when (scalar_fifo_last_data = '1') else '0';

end implementation;
