
LIBRARY IEEE;
USE STD.textio.all;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;


ENTITY cpu_tb IS
END cpu_tb;

ARCHITECTURE rtl OF cpu_tb IS
    constant clk_period : time := 1 ns;
    constant ram_size : INTEGER := 32768;

    COMPONENT cpu IS 
        GENERIC(
            ram_size: INTEGER := ram_size
        );
        PORT(
            clock: IN STD_LOGIC;
            i_readdata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
            i_addr: OUT INTEGER RANGE 0 TO ram_size-1;
            i_memread: OUT STD_LOGIC;
            i_waitrequest: IN STD_LOGIC;

            d_writedata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
            d_readdata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
            d_addr: OUT INTEGER RANGE 0 TO ram_size-1;
            d_memwrite: OUT STD_LOGIC;
            d_memread: OUT STD_LOGIC;
            d_waitrequest: IN STD_LOGIC;

            rf_read_reg_1: OUT INTEGER RANGE 0 to 31;
            rf_read_reg_2: OUT INTEGER RANGE 0 to 31;
            rf_write_reg: OUT INTEGER RANGE 0 to 31;
            rf_write_data: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
            id_rf_out_A: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            id_rf_out_B: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            rf_write_enable: OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT memory IS 
        GENERIC(
            ram_size: INTEGER := ram_size;
            mem_delay: TIME := 1 ns;
            clock_period: TIME := 1 ns
        );
        PORT(
            clock: IN STD_LOGIC;            
            writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
            address: IN INTEGER RANGE 0 TO ram_size-1;
            memwrite: IN STD_LOGIC := '0';
            memread: IN STD_LOGIC := '0';
            readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
            waitrequest: OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT Register_file_decode IS 
        PORT(
            clock: IN STD_LOGIC;
            read_reg_1: IN INTEGER RANGE 0 to 31;
            read_reg_2: IN INTEGER RANGE 0 to 31;
            write_reg: IN INTEGER RANGE 0 to 31;
            write_data: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
            reg_out_1: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            reg_out_2: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            write_enable: IN STD_LOGIC
        );
    END COMPONENT;


    signal clock: STD_LOGIC := '0';
    signal cpu_clock: STD_LOGIC := '0';


    signal i_readdata: STD_LOGIC_VECTOR (31 DOWNTO 0);
    signal i_writedata: STD_LOGIC_VECTOR (31 DOWNTO 0);
    signal i_addr: INTEGER RANGE 0 TO ram_size-1;
    signal i_memwrite: STD_LOGIC := '0';
    signal i_memread: STD_LOGIC := '0';
    signal i_waitrequest: STD_LOGIC;
    
    signal cpu_i_addr: INTEGER RANGE 0 TO ram_size-1;
    signal load_i_addr: INTEGER RANGE 0 TO ram_size-1;

    signal d_writedata: STD_LOGIC_VECTOR (31 DOWNTO 0);
    signal d_readdata: STD_LOGIC_VECTOR (31 DOWNTO 0);
    signal d_addr: INTEGER RANGE 0 TO ram_size-1;
    signal d_memwrite: STD_LOGIC := '0';
    signal d_memread: STD_LOGIC := '0';
    signal d_waitrequest: STD_LOGIC;

    signal cpu_d_addr: INTEGER RANGE 0 TO ram_size-1;
    signal dump_d_addr: INTEGER RANGE 0 TO ram_size-1;
    signal cpu_d_memwrite: STD_LOGIC := '0';
    signal cpu_d_memread: STD_LOGIC := '0';
    signal dump_d_memread: STD_LOGIC := '0';


    signal rf_read_reg_1: INTEGER RANGE 0 to 31;
    signal rf_read_reg_2: INTEGER RANGE 0 to 31;
    signal rf_write_reg: INTEGER RANGE 0 to 31;
    signal rf_write_data: STD_LOGIC_VECTOR (31 DOWNTO 0);
    signal rf_reg_out_1: STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal rf_reg_out_2: STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal rf_write_enable: STD_LOGIC;

    signal cpu_rf_read_reg_1: INTEGER RANGE 0 to 31;
    signal dump_rf_read_reg_1: INTEGER RANGE 0 to 31;
    signal cpu_rf_read_reg_2: INTEGER RANGE 0 to 31;
    signal dump_rf_read_reg_2: INTEGER RANGE 0 to 31;


    signal inst_loading_done: STD_LOGIC := '0';
    signal data_dump_ready: STD_LOGIC := '0';
    signal data_dump_done: STD_LOGIC := '0';
BEGIN

    i_memory: memory 
    PORT MAP(
        clock => clock,
        writedata => i_writedata,
        address => i_addr,
        memwrite => i_memwrite,
        memread => i_memread,
        readdata => i_readdata,
        waitrequest => i_waitrequest
    );

    d_memory: memory 
    PORT MAP(
        clock => clock,
        writedata => d_writedata,
        address => d_addr,
        memwrite => d_memwrite,
        memread => d_memread,
        readdata => d_readdata,
        waitrequest => d_waitrequest
    );

    rf: Register_file_decode
    PORT MAP(
        clock => clock,
        read_reg_1 => rf_read_reg_1,
        read_reg_2 => rf_read_reg_2,
        write_reg => rf_write_reg,
        write_data => rf_write_data,
        reg_out_1 => rf_reg_out_1,
        reg_out_2 => rf_reg_out_2,
        write_enable => rf_write_enable
    );

    dut: cpu
    PORT MAP(
        clock => cpu_clock,
        i_readdata => i_readdata,
        i_addr => cpu_i_addr,
        i_memread => i_memread,
        i_waitrequest => i_waitrequest,
        d_writedata => d_writedata,
        d_readdata => d_readdata,
        d_addr => cpu_d_addr,
        d_memwrite => cpu_d_memwrite,
        d_memread => cpu_d_memread,
        d_waitrequest => d_waitrequest,
        rf_read_reg_1 => cpu_rf_read_reg_1,
        rf_read_reg_2 => cpu_rf_read_reg_2,
        rf_write_reg => rf_write_reg,
        rf_write_data => rf_write_data,
        id_rf_out_A => rf_reg_out_1,
        id_rf_out_B => rf_reg_out_2,
        rf_write_enable => rf_write_enable
    );

    cpu_clock <= clock when data_dump_ready = '0' AND inst_loading_done = '1' else '0';

    i_addr <= cpu_i_addr when inst_loading_done = '1' else load_i_addr;

    d_addr <= cpu_d_addr when data_dump_ready = '0' else dump_d_addr;
    d_memwrite <= cpu_d_memwrite when data_dump_ready = '0' else '0';
    d_memread <= cpu_d_memread when data_dump_ready = '0' else dump_d_memread;

    rf_read_reg_1 <= cpu_rf_read_reg_1 when data_dump_ready = '0' else dump_rf_read_reg_1;
    rf_read_reg_2 <= cpu_rf_read_reg_2 when data_dump_ready = '0' else dump_rf_read_reg_2;


    clk_process: PROCESS
        variable clk_cnt: INTEGER := 0;
    BEGIN
        IF(clk_cnt >= 10000) THEN
            data_dump_ready <= '1';
        END IF;

        IF(data_dump_done = '0') THEN
            clock <= '0';
            wait for clk_period / 2;
            clock <= '1';
            wait for clk_period / 2;

            IF(inst_loading_done = '1') THEN
                clk_cnt := clk_cnt + 1;
            END IF;
        ELSE
            assert false report "Simulation finished";
            wait;
        END IF;
    END PROCESS;



    -- load contents of program.txt into instruction memory
    inst_load_process: PROCESS
        file f: text open read_mode is "program.txt";
        variable l: line;
        variable word: bit_vector(31 DOWNTO 0);
        variable addr: integer := 0;
    BEGIN
        wait until rising_edge(clock);

        while not endfile(f) LOOP
            readline(f, l);
            read(l, word);

            -- cpu_d_addr <= addr;
            -- d_writedata <= to_stdlogicvector(word);
            -- cpu_d_memwrite <= '1';
            load_i_addr <= addr;
            i_writedata <= to_stdlogicvector(word);
            i_memwrite <= '1';

            addr := addr + 4;
            wait until rising_edge(clock);
        END LOOP;
        i_memwrite <= '0';
        load_i_addr <= 0;
        wait until rising_edge(clock);
        wait until rising_edge(clock);

        inst_loading_done <= '1';
        wait;
    END PROCESS;

    data_dump_process: PROCESS
        file mem_f: text open write_mode is "memory.txt";
        file reg_f: text open write_mode is "register_file.txt";
        variable l: line;
        variable addr: integer := 0;
    BEGIN
        wait until data_dump_ready = '1';
        wait until rising_edge(clock); 

        for line in 0 to (ram_size/4)-1 LOOP
            dump_d_addr <= addr;
            dump_d_memread <= '1';

            wait until rising_edge(d_waitrequest);

            write(l, to_bitvector(d_readdata));
            writeline(mem_f, l);
            dump_d_memread <= '0';
            addr := addr + 4;

            wait for clk_period;
            
        END LOOP;

        wait until rising_edge(clock);

        for i in 0 to 15 LOOP
            dump_rf_read_reg_1 <= 2*i;
            dump_rf_read_reg_2 <= 2*i+1;

            wait until rising_edge(clock);

            write(l, to_bitvector(rf_reg_out_1));
            writeline(reg_f, l);
            write(l, to_bitvector(rf_reg_out_2));
            writeline(reg_f, l);
        END LOOP;
        data_dump_done <= '1';
        wait;
    END PROCESS;
END rtl;