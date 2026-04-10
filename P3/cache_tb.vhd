library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
end cache_tb;

architecture behavior of cache_tb is

component cache is
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
    m_read : out std_logic;
    m_readdata : in std_logic_vector (7 downto 0);
    m_write : out std_logic;
    m_writedata : out std_logic_vector (7 downto 0);
    m_waitrequest : in std_logic
);
end component;

component memory is 
GENERIC(
    ram_size : INTEGER := 32768;
    mem_delay : time := 10 ns;
    clock_period : time := 1 ns
);
PORT (
    clock: IN STD_LOGIC;
    writedata: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
    address: IN INTEGER RANGE 0 TO ram_size-1;
    memwrite: IN STD_LOGIC;
    memread: IN STD_LOGIC;
    readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
    waitrequest: OUT STD_LOGIC
);
end component;
	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 10 ns;

signal s_addr : std_logic_vector (31 downto 0) := (others => '0');
signal s_read : std_logic := '0';
signal s_readdata : std_logic_vector (31 downto 0);
signal s_write : std_logic := '0';
signal s_writedata : std_logic_vector (31 downto 0) := (others => '0');
signal s_waitrequest : std_logic;

signal m_addr : integer range 0 to 2147483647;
signal m_read : std_logic;
signal m_readdata : std_logic_vector (7 downto 0);
signal m_write : std_logic;
signal m_writedata : std_logic_vector (7 downto 0);
signal m_waitrequest : std_logic; 

begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: cache 
port map(
    clock => clk,
    reset => reset,

    s_addr => s_addr,
    s_read => s_read,
    s_readdata => s_readdata,
    s_write => s_write,
    s_writedata => s_writedata,
    s_waitrequest => s_waitrequest,

    m_addr => m_addr,
    m_read => m_read,
    m_readdata => m_readdata,
    m_write => m_write,
    m_writedata => m_writedata,
    m_waitrequest => m_waitrequest
);

MEM : memory
port map (
    clock => clk,
    writedata => m_writedata,
    address => m_addr,
    memwrite => m_write,
    memread => m_read,
    readdata => m_readdata,
    waitrequest => m_waitrequest
);
				

clk_process : process
begin
  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;
end process;

test_process : process
begin

-- put your tests here
	reset <= '1';
	wait for clk_period * 2;
	reset <= '0';
	wait for clk_period * 2;
	
	
	report "+++++++++ invalid, not dirty, read +++++++++";
	s_addr <= x"00000010";
	s_read <= '1';
	s_write <= '0';
	wait until m_read = '1' for 200 ns;
	assert m_read = '1' report "TIMEOUT : Should be reading in memory" severity error;
	assert m_write = '0' report "Should not be writing in memory" severity error;
	wait until s_waitrequest = '0' for 500 ns;
	assert s_waitrequest = '0' report "TIMEOUT: transaction should be completed" severity error;
	s_read <= '0';
	wait for clk_period;
	
	
	report "+++++++++ invalid, not dirty, write +++++++++";
	s_addr <= x"00000030"; 
   s_write <= '1';
   s_read  <= '0';
   s_writedata <= x"11111111";
   wait until m_read = '1' for 200 ns;
   assert m_read  = '1' report "TIMEOUT : Should be reading in memory" severity error;
   assert m_write = '0' report "Should not be writing in memory" severity error;
   wait until s_waitrequest = '0' for 500 ns;
   s_write <= '0';
   assert s_waitrequest = '0' report "TIMEOUT: transaction should be completed" severity error;
   wait for clk_period;
	wait until s_waitrequest = '1' for 500 ns;

	
	report "+++++++++ valid, not dirty, read +++++++++";
	s_addr  <= x"00000010"; 
   s_write <= '0';
   s_read  <= '1';
   wait until s_waitrequest = '0' for 200 ns;
   s_read <= '0';
   assert s_waitrequest = '0' report "TIMEOUT: hit should be completed" severity error;
   assert m_read  = '0' report "Should not read into memory" severity error;
   assert m_write = '0' report "Should not write into memory" severity error;
   wait for clk_period;
	wait until s_waitrequest = '1' for 500 ns;
	
	
	report "+++++++++ valid, not dirty, write, tag equal +++++++++";
	s_addr <= x"00000010"; 
   s_write <= '1';
   s_read <= '0';
   s_writedata <= x"22222222";
	wait until s_waitrequest = '0' for 200 ns;
   s_write <= '0';
   assert s_waitrequest = '0' report " TIMEOUT:  write hit should completed" severity error;
   assert m_read  = '0' report "Should not read into memory" severity error;
   assert m_write = '0' report "Should not write into memory" severity error;
   wait for clk_period;
	wait until s_waitrequest = '1' for 500 ns;
	
	
	report "+++++++++ valid, dirty, read, tag equal +++++++++";
	s_addr  <= x"00000010"; 
   s_write <= '0';
   s_read  <= '1';
   wait until s_waitrequest = '0' for 200 ns;
   s_read <= '0';
   assert s_waitrequest = '0' report "TIMEOUT - hit should be completed" severity error;
   assert m_read  = '0' report "Should not read into memory" severity error;
   assert m_write = '0' report "Should not write into memory" severity error;
   assert s_readdata = x"22222222" report "readdata mismatch on dirty hit" severity error;
   wait for clk_period;
	wait until s_waitrequest = '1' for 500 ns;
	
	
	report "+++++++++ valid, dirty, write, tag equal +++++++++";
   s_addr      <= x"00000010"; 
   s_write     <= '1';
   s_read      <= '0';
   s_writedata <= x"33333333";
   wait until s_waitrequest = '0' for 200 ns;
   s_write <= '0';
   assert s_waitrequest = '0' report "TIMEOUT - hit should be completed" severity error;
   assert m_read  = '0' report "Should not read into memory" severity error;
   assert m_write = '0' report "Should not write into memory" severity error;
   wait for clk_period;
	wait until s_waitrequest = '1' for 500 ns;
	
	
	report "+++++++++ valid, dirty, read, tag not equal +++++++++";
   s_addr  <= x"00000210"; 
   s_write <= '0';
   s_read  <= '1';
   --writeback
   wait until m_write = '1' for 200 ns;
   assert m_write = '1' report "TIMEOUT: Should write into memory" severity error;
	--read
   wait until m_read = '1' for 500 ns;
   assert m_read = '1' report "TIMEOUT: Should read into memory" severity error;
   wait until s_waitrequest = '0' for 500 ns;
   s_read <= '0';
   assert s_waitrequest = '0' report "TIMEOUT: transaction never completed" severity error;
   assert s_readdata = x"00000000" report "readdata mismatch" severity error;
   wait for clk_period;
	wait until s_waitrequest = '1' for 500 ns;
	
		
	report "+++++++++ valid, not dirty, read, tag not equal +++++++++";
   s_addr  <= x"00000010"; 
   s_write <= '0';
   s_read  <= '1';
   wait until m_read = '1' for 200 ns;
   assert m_read  = '1' report "TIMEOUT: Should read into memory" severity error;
   assert m_write = '0' report "Should not write into memory" severity error;
   wait until s_waitrequest = '0' for 500 ns;
   s_read <= '0';
   assert s_waitrequest = '0' report "TIMEOUT: transaction never completed" severity error;
   wait for clk_period;
	wait until s_waitrequest = '1' for 500 ns;
	
	
	report "+++++++++ valid, not dirty, write, tag not equal +++++++++";
   s_addr      <= x"00000210";
   s_write     <= '1';
   s_read      <= '0';
   s_writedata <= x"12345678";
   wait until m_read = '1' for 200 ns;
   assert m_read  = '1' report "Should read into memory" severity error;
   assert m_write = '0' report "Should not write into memory" severity error;
   wait until s_waitrequest = '0' for 500 ns;
   s_write <= '0';
   assert s_waitrequest = '0' report "TIMEOUT: write never completed" severity error;
   wait for clk_period;
	wait until s_waitrequest = '1' for 500 ns;
	
	
	report "+++++++++ valid, dirty, write, tag not equal +++++++++";
   s_addr      <= x"00000010"; 
   s_write     <= '1';
   s_read      <= '0';
   s_writedata <= x"22222222";
   --writeback
   wait until m_write = '1' for 200 ns;
   assert m_write = '1' report "TIMEOUT: Should write into memory" severity error;
   --fetch
   wait until m_read = '1' for 500 ns;
   assert m_read = '1' report "TIMEOUT: Should read into memory" severity error;
   wait until s_waitrequest = '0' for 500 ns;
   s_write <= '0';
   assert s_waitrequest = '0' report "TIMEOUT: write never completed" severity error;
   wait for clk_period;
	wait until s_waitrequest = '1' for 500 ns;
	
	
	report "+++++++++ invalid, not dirty, read, tag not equal +++++++++";
   s_addr  <= x"00000050"; 
   s_write <= '0';
   s_read  <= '1';
   wait until m_read = '1' for 200 ns;
   assert m_read  = '1' report "TIMEOUT: Should read into memory" severity error;
   assert m_write = '0' report "Should not write into memory" severity error;
   wait until s_waitrequest = '0' for 500 ns;
   s_read <= '0';
   assert s_waitrequest = '0' report "TIMEOUT: transaction never completed" severity error;
   wait for clk_period;
	wait until s_waitrequest = '1' for 500 ns;
	
	
	report "+++++++++ invalid, not dirty, write, tag not equal +++++++++";
   s_addr      <= x"00000070";
   s_write     <= '1';
   s_read      <= '0';
   s_writedata <= x"44444444";
   wait until m_read = '1' for 200 ns;
   assert m_read  = '1' report "TIMEOUT: Should read into memory" severity error;
   assert m_write = '0' report "Should not write into memory " severity error;
   wait until s_waitrequest = '0' for 500 ns;
   s_write <= '0';
   assert s_waitrequest = '0' report "TIMEOUT: write never completed" severity error;
   wait for clk_period;
	wait until s_waitrequest = '1' for 500 ns;

	
	
	
	report "--------- Testbench completed ---------";
	wait;
	
end process;
	
end;