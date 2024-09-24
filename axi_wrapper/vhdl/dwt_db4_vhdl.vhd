library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;

use work.FPU_definitions_pack.all;
use work.Matrix_definition_pack.all;
use work.Matrix_component_pack.all;

entity dwt_db4_vhdl is
	generic (
		SHIFT_REG_LEN	: integer	:= 16;
		C_S00_AXIS_TDATA_WIDTH	: integer	:= 32;
		C_M00_AXIS_TDATA_WIDTH	: integer	:= 32
	);
	port (

		-- Ports of Axi Slave Bus Interface S00_AXIS
		s_axis_aclk  	: in std_logic;
		s_axis_aresetn	: in std_logic;
		s_axis_tready	: out std_logic;
		s_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
		s_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		s_axis_tlast	: in std_logic;
		s_axis_tvalid	: in std_logic;

		-- Ports of Axi Master Bus Interface M00_AXIS
		hi_m_axis_aclk	    : in std_logic;
		hi_m_axis_aresetn	: in std_logic;
		hi_m_axis_tvalid	: out std_logic;
		hi_m_axis_tdata  	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
		hi_m_axis_tstrb 	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		hi_m_axis_tlast	    : out std_logic;
		hi_m_axis_tready	: in std_logic;

		-- Ports of Axi Master Bus Interface M00_AXIS
		lo_m_axis_aclk  	: in std_logic;
		lo_m_axis_aresetn	: in std_logic;
		lo_m_axis_tvalid	: out std_logic;
		lo_m_axis_tdata	    : out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
		lo_m_axis_tstrb 	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		lo_m_axis_tlast 	: out std_logic;
		lo_m_axis_tready	: in std_logic

	);
end dwt_db4_vhdl;

architecture arch_imp of dwt_db4_vhdl is

	-- component declaration
	component SCALAR_S_AXIS is
		generic (
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
		);
		port (
		data_out_ok : out std_logic;
		data_out    : out std_logic_vector(scalar_size-1 downto 0);
		S_AXIS_ACLK	: in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TLAST	: in std_logic;
		S_AXIS_TVALID	: in std_logic
		);
	end component SCALAR_S_AXIS;

	component SCALAR_M_AXIS is
		generic (
		C_M_AXIS_TDATA_WIDTH  : integer	:= 32;
		SCALAR_FIFO_DEPTH	  : integer	:= 32
		);
		port (
		data_in_ok  : in std_logic;
		data_in     : in std_logic_vector(scalar_size-1 downto 0);
		M_AXIS_ACLK	: in std_logic;
		M_AXIS_ARESETN	: in std_logic;
		M_AXIS_TVALID	: out std_logic;
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M_AXIS_TLAST	: out std_logic;
		M_AXIS_TREADY	: in std_logic
		);
	end component SCALAR_M_AXIS;

	signal control_register  : std_logic_vector(7 downto 0) := "00000001";
	signal data_in_len_register : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(32, 32));
	signal data_out_len_register : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned((32 + 8 - 1)/2, 32));

	signal slave_data     : std_logic_vector(scalar_size - 1 downto 0);
	signal slave_data_ok  : std_logic;

	signal master_data    : scalar;
	signal master_data_ok : std_logic;

	signal shift_reg        : scalar_array(SHIFT_REG_LEN - 1 downto 0);
	signal filter_input     : Vector8;
	--signal lo_filter_coeff  : Vector8;
	--signal hi_filter_coeff  : Vector8;

	constant hi_filter_coeff : Vector8 := (to_scalar(-2.303778133088965008632911830440708500016152482483092977910968e-01),
										   to_scalar(7.148465705529156470899219552739926037076084010993081758450110e-01),
										   to_scalar(-6.308807679298589078817163383006152202032229226771951174057473e-01),
										   to_scalar(-2.798376941685985421141374718007538541198732022449175284003358e-02),
										   to_scalar(1.870348117190930840795706727890814195845441743745800912057770e-01),
										   to_scalar(3.084138183556076362721936253495905017031482172003403341821219e-02),
										   to_scalar(-3.288301166688519973540751354924438866454194113754971259727278e-02),
										   to_scalar(-1.059740178506903210488320852402722918109996490637641983484974e-02));
	
	--constant hi_filter_coeff : Vector8 := (to_scalar(-1.059740178506903210488320852402722918109996490637641983484974e-02),
	--									   to_scalar(-3.288301166688519973540751354924438866454194113754971259727278e-02),
	--									   to_scalar(3.084138183556076362721936253495905017031482172003403341821219e-02),
	--									   to_scalar(1.870348117190930840795706727890814195845441743745800912057770e-01),
	--									   to_scalar(-2.798376941685985421141374718007538541198732022449175284003358e-02),
	--									   to_scalar(-6.308807679298589078817163383006152202032229226771951174057473e-01),
	--									   to_scalar(7.148465705529156470899219552739926037076084010993081758450110e-01),
	--									   to_scalar(-2.303778133088965008632911830440708500016152482483092977910968e-01));

	--constant hi_filter_coeff : Vector8 := (to_scalar(0.0),
	--									   to_scalar(0.0),
	--									   to_scalar(0.0),
	--									   to_scalar(0.0),
	--									   to_scalar(1.0),
	--									   to_scalar(0.0),
	--									   to_scalar(0.0),
	--									   to_scalar(0.0));

	constant lo_filter_coeff : Vector8 := (to_scalar(-1.059740178506903210488320852402722918109996490637641983484974e-02),
										   to_scalar(3.288301166688519973540751354924438866454194113754971259727278e-02),
										   to_scalar(3.084138183556076362721936253495905017031482172003403341821219e-02),
										   to_scalar(-1.870348117190930840795706727890814195845441743745800912057770e-01),
										   to_scalar(-2.798376941685985421141374718007538541198732022449175284003358e-02),
										   to_scalar(6.308807679298589078817163383006152202032229226771951174057473e-01),
										   to_scalar(7.148465705529156470899219552739926037076084010993081758450110e-01),
										   to_scalar(2.303778133088965008632911830440708500016152482483092977910968e-01));

	signal lo_data     : scalar;
	signal lo_data_ok  : std_logic;

	signal hi_data     : scalar;
	signal hi_data_ok  : std_logic;

	signal data_in_count : unsigned(31 downto 0)  := to_unsigned(0, 32);
	signal data_in_new   : std_logic := '0';

	signal do_convolution : std_logic              := '0';

	type state_type is (IDLE, LESS_THAN_8, ADD_START_PADDING, WAITING_1, ADD_END_PADDING, WAITING_2);
	signal state : state_type := IDLE;


begin

SCALAR_S_AXIS_inst : SCALAR_S_AXIS
	generic map (
		C_S_AXIS_TDATA_WIDTH	=> C_S00_AXIS_TDATA_WIDTH
	)
	port map (
		data_out_ok     => slave_data_ok,
		data_out        => slave_data,
		S_AXIS_ACLK	    => s_axis_aclk,
		S_AXIS_ARESETN	=> s_axis_aresetn,
		S_AXIS_TREADY	=> s_axis_tready,
		S_AXIS_TDATA	=> s_axis_tdata,
		S_AXIS_TSTRB	=> s_axis_tstrb,
		S_AXIS_TLAST	=> s_axis_tlast,
		S_AXIS_TVALID	=> s_axis_tvalid
	);

SCALAR_hi_M_AXIS_inst : SCALAR_M_AXIS
	generic map (
		C_M_AXIS_TDATA_WIDTH  => C_M00_AXIS_TDATA_WIDTH,
		SCALAR_FIFO_DEPTH     => 32
	)
	port map (
		data_in_ok      => hi_data_ok,
		data_in         => scalar_to_std_logic_vector(hi_data),
		M_AXIS_ACLK	    => hi_m_axis_aclk,
		M_AXIS_ARESETN	=> hi_m_axis_aresetn,
		M_AXIS_TVALID	=> hi_m_axis_tvalid,
		M_AXIS_TDATA	=> hi_m_axis_tdata,
		M_AXIS_TSTRB	=> hi_m_axis_tstrb,
		M_AXIS_TLAST	=> hi_m_axis_tlast,
		M_AXIS_TREADY	=> hi_m_axis_tready
	);

SCALAR_lo_M_AXIS_inst : SCALAR_M_AXIS
	generic map (
		C_M_AXIS_TDATA_WIDTH  => C_M00_AXIS_TDATA_WIDTH,
		SCALAR_FIFO_DEPTH     => 32
	)
	port map (
		data_in_ok      => lo_data_ok,
		data_in         => scalar_to_std_logic_vector(lo_data),
		M_AXIS_ACLK	    => lo_m_axis_aclk,
		M_AXIS_ARESETN	=> lo_m_axis_aresetn,
		M_AXIS_TVALID	=> lo_m_axis_tvalid,
		M_AXIS_TDATA	=> lo_m_axis_tdata,
		M_AXIS_TSTRB	=> lo_m_axis_tstrb,
		M_AXIS_TLAST	=> lo_m_axis_tlast,
		M_AXIS_TREADY	=> lo_m_axis_tready
	);

	hi_filter : Vector8_dot_fast 
	port map(
		clk                      => s_axis_aclk,
		new_operation_request    => do_convolution,
		new_operation_request_id => request_id_zero,
		new_operation_done       => hi_data_ok,
		Vector1_input            => filter_input,
		Vector2_input            => hi_filter_coeff,
		output                   => hi_data
	);

	lo_filter : Vector8_dot_fast 
	port map(
		clk                      => s_axis_aclk,
		new_operation_request    => do_convolution,
		new_operation_request_id => request_id_zero,
		new_operation_done       => lo_data_ok,
		Vector1_input            => filter_input,
		Vector2_input            => lo_filter_coeff,
		output                   => lo_data
	);

  filter_input_gen: for i in 7 downto 0 generate
    filter_input(i) <= shift_reg(i+6);
  end generate;
    
  	--//not enough data read to do the convolution
	--if (shift_reg.count <= 7)
	--	continue;

	--// to make symmetric at the beggining of stream
	--if (shift_reg.count == 8)
	--	shift_reg.make_symmetric_up();
	--// to make symmetric at the end of stream
	--if (shift_reg.count > input_data_size)
	--{
	--	int index = (shift_reg.count - input_data_size) * 2 - 1;
	--	shift_reg.data[0] = shift_reg.data[index];
	--}

	shift_reg_process : process(s_axis_aclk)
	begin
		if (rising_edge(s_axis_aclk)) then
			if(control_register(0) = '1') then
				-- read from axi stream interface
				if(data_in_count < to_integer(unsigned(data_in_len_register))) then
					if(slave_data_ok = '1') then
						for I in SHIFT_REG_LEN - 1 downto 1 loop
							shift_reg(I) <= shift_reg(I-1);
						end loop;
						shift_reg(0) <= to_scalar(slave_data);
						data_in_new <= '1';
						data_in_count <= data_in_count + 1;
						do_convolution <= not do_convolution;
					else
						data_in_new <= '0';
					end if;
				else
				    -- add padding to the signal
					if(data_in_count < to_integer(unsigned(data_in_len_register)) + 8) then
						for I in SHIFT_REG_LEN - 1 downto 1 loop
							shift_reg(I) <= shift_reg(I-1);
						end loop;
						shift_reg(0) <= to_scalar(0);
						data_in_new <= '1';
						do_convolution <= not do_convolution;
						data_in_count <= data_in_count + 1;
						--shift_reg(0) <= shift_reg((data_in_count - data_in_len)*2 - 1);
					else
						data_in_new <= '0';
						control_register(0) <= '0';
					end if;
				end if;
			else
				data_in_new <= '0';
				do_convolution <= '0';
				data_in_count <= to_unsigned(0, 32);
			end if;
		end if;
	end process;


	counter_process : process(s_axis_aclk)
	begin
		if (rising_edge(s_axis_aclk)) then
			if(state = IDLE) then
				data_in_count <= to_unsigned(0, 32);
			else
				data_in_count <= data_in_count + '1';
			end if;
		end if;
	end process;

	shift_reg_process : process
	
	state_machine : process(s_axis_aclk)
	begin
		if (rising_edge(s_axis_aclk)) then
		
			case state is
				when IDLE =>
					data_in_new <= '0';
					do_convolution <= '0;;
					if(slave_data_ok = '1') then
						state <= LESS_THAN_8;
					end if;
				when LESS_THAN_8 =>
					if(data_in_count >= 8) then
						state <= ADD_START_PADDING;
					end if;
					
				when ADD_START_PADDING =>
					shift_reg(15) <= shift_reg(0);
					shift_reg(14) <= shift_reg(1);
					shift_reg(13) <= shift_reg(2);
					shift_reg(12) <= shift_reg(3);
					shift_reg(11) <= shift_reg(4);
					shift_reg(10) <= shift_reg(5);
					shift_reg(9) <= shift_reg(6);
					shift_reg(8) <= shift_reg(7);

					state <= WAITING_1;
				
				when WAITING_1 =>
					scalar_input_ok <= '0';
					scalar_input <= scalar_to_std_logic_vector(to_scalar(0));
					state <= READY;

				when ADD_END_PADDING =>
				when WAITING_2 =>
			end case;
		end if;
	end process;

end arch_imp;
