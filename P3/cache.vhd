library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
generic(
	ram_size : INTEGER := 32768
);
port(
	clock : in std_logic;
	reset : in std_logic;
	
	-- Avalon interface --
	s_addr : in std_logic_vector (31 downto 0);
	s_read : in std_logic;
	s_readdata : out std_logic_vector (31 downto 0);
	s_write : in std_logic;
	s_writedata : in std_logic_vector (31 downto 0);
	s_waitrequest : out std_logic; 
    
	m_addr : out integer range 0 to ram_size-1;
	m_read : out std_logic := '0';
	m_readdata : in std_logic_vector (7 downto 0);
	m_write : out std_logic := '0';
	m_writedata : out std_logic_vector (7 downto 0);
	m_waitrequest : in std_logic
);
end cache;

architecture arch of cache is
type cache_line is record
  valid : std_logic;
  dirty : std_logic;
  tag   : std_logic_vector(22 downto 0);
  data  : std_logic_vector(127 downto 0);
end record;

TYPE CACHE_ARR IS ARRAY(31 downto 0) OF cache_line;
signal cache_block: CACHE_ARR;

-- FSM states
type state_type is (IDLE, R_LOOKUP, W_LOOKUP, R_WB, R_FETCH, W_WB, W_FETCH);
signal state: state_type := IDLE;

signal s_tag: std_logic_vector(22 downto 0);
signal s_index: std_logic_vector(4 downto 0);
signal s_offset: std_logic_vector(1 downto 0);

signal byte_cnt: integer range 0 to 15;

signal dirty_tag  : std_logic_vector(22 downto 0);
signal dirty_index: std_logic_vector(4 downto 0);

begin
-- make circuits here

process (clock, reset) 
variable curr_line: cache_line;

begin

if reset = '1' then
	-- clear arrays, reset state
	for i in 0 to 31 loop
    		cache_block(i).valid <= '0';
	end loop;
	m_read         <= '0';   
   m_write        <= '0';   
   s_waitrequest  <= '1'; 
	
	state <= IDLE;
elsif rising_edge(clock) then
	if state = IDLE then
		s_waitrequest <= '1';
		if s_read = '1' OR s_write = '1' then
			s_tag <= s_addr(31 downto 9);
			s_index <= s_addr(8 downto 4);
			s_offset <= s_addr(3 downto 2);

			if s_read = '1' then
				state <= R_LOOKUP;
			elsif s_write = '1' then
				state <= W_LOOKUP;
			end if;
		end if;
	elsif state = R_LOOKUP then
		curr_line := cache_block(to_integer(unsigned(s_index)));


		if curr_line.valid = '1' AND curr_line.tag = s_tag then
			--hit
			case s_offset is
    				when "00" => s_readdata <= curr_line.data(31 downto 0);
    				when "01" => s_readdata <= curr_line.data(63 downto 32);
    				when "10" => s_readdata <= curr_line.data(95 downto 64);
    				when "11" => s_readdata <= curr_line.data(127 downto 96);
				when others => null;
			end case;

			s_waitrequest <= '0';
			state <= IDLE;
		else
			--miss
			if curr_line.valid = '1' AND curr_line.dirty = '1' then
				-- write ejected block to MM
				dirty_tag   <= curr_line.tag;
				dirty_index <= s_index;
				byte_cnt    <= 0;
				state <= R_WB;
			else
				-- read MM
				byte_cnt <= 0;
				m_read <= '1';
				m_addr <= to_integer(unsigned(s_tag & s_index & "0000"));	
				state <= R_FETCH;
			end if;
		end if;
	elsif state = W_LOOKUP then
		curr_line := cache_block(to_integer(unsigned(s_index)));

		if curr_line.valid = '1' AND curr_line.tag = s_tag then
			--hit
			curr_line.dirty := '1';
			case s_offset is
    				when "00" => curr_line.data(31 downto 0) := s_writedata;
    				when "01" => curr_line.data(63 downto 32) := s_writedata;
    				when "10" => curr_line.data(95 downto 64) := s_writedata;
    				when "11" => curr_line.data(127 downto 96) := s_writedata;
				when others => null;
			end case;

			cache_block(to_integer(unsigned(s_index))) <= curr_line;
			s_waitrequest <= '0';
			state <= IDLE;
		else

			--miss
			if curr_line.valid = '1' AND curr_line.dirty = '1' then
				-- write ejected block to MM
				dirty_tag   <= curr_line.tag;
				dirty_index <= s_index;
				byte_cnt    <= 0;
				state <= W_WB;
			else
				byte_cnt <= 0;
				m_read <= '1';
				m_addr <= to_integer(unsigned(s_tag & s_index & "0000"));			
				-- read MM
				state <= W_FETCH;
			end if;
		end if;
	elsif state = R_WB or state = W_WB then
		-- Write back dirty line to MM
		if m_waitrequest = '0' then
			curr_line := cache_block(to_integer(unsigned(dirty_index)));

			m_write <= '0';
			m_addr <= to_integer(unsigned(dirty_tag & dirty_index & std_logic_vector(to_unsigned(byte_cnt, 4))));
			m_writedata <= curr_line.data(byte_cnt * 8 + 7 downto byte_cnt * 8);

			if byte_cnt = 15 then
				-- finished
				curr_line.dirty := '0';
				cache_block(to_integer(unsigned(dirty_index))) <= curr_line;

				-- start fetching the *new* block
				byte_cnt <= 0;
				m_write <= '0';
				m_read   <= '1';
				m_addr   <= to_integer(unsigned(s_tag & s_index & "0000"));

				if state = W_WB then
					state <= W_FETCH;
				else
					state <= R_FETCH;
				end if;
			else
				byte_cnt <= byte_cnt + 1;
			end if;
		else
			-- keep asserting write while stalled
			m_write <= '1';
			m_read  <= '0';	
		end if;
	elsif state = W_FETCH OR state = R_FETCH then

		if m_waitrequest = '0' then
			curr_line := cache_block(to_integer(unsigned(s_index)));
			m_read <= '0';
			curr_line.data(byte_cnt * 8 + 7 downto byte_cnt * 8) := m_readdata;
			if byte_cnt = 15 then
				curr_line.valid := '1';
				curr_line.dirty := '0';
				curr_line.tag := s_tag;
				if state = W_FETCH then
					state <= W_LOOKUP;
				else
					state <= R_LOOKUP;
				end if;
			else
				byte_cnt <= byte_cnt + 1;
				m_addr <= to_integer(unsigned(s_tag & s_index & std_logic_vector(to_unsigned(byte_cnt + 1, 4))));
			end if;
			cache_block(to_integer(unsigned(s_index))) <= curr_line;
		else
			m_read <= '1';
		end if;                                                                       
	
	end if;
end if;

end process;


end arch;