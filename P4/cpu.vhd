LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE work.cpu_package.all;

ENTITY cpu IS 
GENERIC (
    ram_size: INTEGER := 32768
);
PORT (
    clock: IN STD_LOGIC;
    i_readdata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
    i_addr: OUT INTEGER RANGE 0 TO ram_size-1;
    i_memread: OUT STD_LOGIC := '1';
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
    rf_reg_out_1: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    rf_reg_out_2: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    rf_write_enable: OUT STD_LOGIC
);
END cpu;

ARCHITECTURE rtl OF cpu IS

constant STALL_INST: STD_LOGIC_VECTOR(31 DOWNTO 0) := "00000000000000000000000000010011";

signal pc: INTEGER RANGE 0 to ram_size-1 := 0;

-- apparently storing next pc is unnecessary since we only store PC for branches / jumps
type if_id_buffer_t is record
    inst: std_logic_vector(31 downto 0);
    inst_pc: INTEGER RANGE 0 to ram_size-1;
end record;

signal if_id_buffer: if_id_buffer_t := (
    inst => STALL_INST,
    inst_pc => 0
);
signal id_dst_reg: std_logic_vector(4 downto 0) := (others => '0');
signal id_addr_regA: std_logic_vector(4 downto 0) := (others => '0');
signal id_addr_regB: std_logic_vector(4 downto 0) := (others => '0');
signal id_is_hazard: boolean := false;

signal id_opcode: std_logic_vector(6 downto 0);
signal id_funct3: std_logic_vector(2 downto 0);
signal id_funct7: std_logic_vector(6 downto 0);
signal id_RAM_write: std_logic;
signal id_ALU_src_regB: std_logic;
signal id_dst_reg_write_en: std_logic;

signal id_imm_src: IMM_SRC_TYPE_t;
signal id_imm_in: std_logic_vector(24 downto 0);
signal id_imm_out: std_logic_vector(31 downto 0);



type id_ex_buffer_t is record
    operand_a: std_logic_vector(31 downto 0);
    operand_b: std_logic_vector(31 downto 0);
    inst: std_logic_vector(31 downto 0);
    inst_pc: INTEGER RANGE 0 to ram_size-1;
    -- for detecting hazards
    dst_reg: std_logic_vector(4 downto 0);
end record;

signal id_ex_buffer: id_ex_buffer_t := (
    operand_a => (others => '0'),
    operand_b => (others => '0'),
    inst => STALL_INST,
    inst_pc => 0,
    dst_reg => (others => '0')
);


type ex_mem_buffer_t is record
    alu_output: std_logic_vector(31 downto 0);
    branch_taken: std_logic;
    -- probably unnecessary to carry full instruction here
    inst: std_logic_vector(31 downto 0);
    inst_pc: INTEGER RANGE 0 to ram_size-1;
    dst_reg: std_logic_vector(4 downto 0);
end record;

signal ex_mem_buffer: ex_mem_buffer_t := (
    alu_output => (others => '0'),
    branch_taken => '0',
    inst => STALL_INST,
    inst_pc => 0,
    dst_reg => (others => '0')
);


-- type mem_wb_buffer_t is record
--     is_wb: std_logic;
--     wb_data: std_logic_vector(31 downto 0);
--     dst_reg: std_logic_vector(4 downto 0);
-- end record;

-- signal mem_wb_buffer: mem_wb_buffer_t := (
--     is_wb => '0',
--     wb_data => (others => '0'),
--     dst_reg => (others => '0')
-- );



BEGIN

i_addr <= pc;
rf_read_reg_1 <= to_integer(unsigned(if_id_buffer.inst(19 downto 15)));
rf_read_reg_2 <= to_integer(unsigned(if_id_buffer.inst(24 downto 20)));

inst_fetch: process(clock)
begin
    if rising_edge(clock) then
        if ex_mem_buffer.branch_taken = '1' then
            pc <= to_integer(unsigned(ex_mem_buffer.alu_output));
            if_id_buffer.inst <= STALL_INST;
        else 
            pc <= pc + 4;
            if_id_buffer.inst <= i_readdata;
        end if;
        
        if_id_buffer.inst_pc <= pc;
    end if;
end process;

--combinatory logic for decode stage
id_opcode <= if_id_buffer.inst(6 downto 0);
id_addr_regA <= if_id_buffer.inst(19 downto 15);
id_addr_regB <= if_id_buffer.inst(24 downto 20);
id_dst_reg <= if_id_buffer.inst(11 downto 7);
id_imm_in <= if_id_buffer.inst(31 downto 7);
Control_unit_inst: entity work.Control_unit_
 port map(
    op_code => id_opcode,
    funct3 => id_funct3,
    funct7 => id_funct7,

    RAM_write => id_RAM_write,
    ALU_src_regB => id_ALU_src_regB,
    Imm_src => id_imm_src,
    dst_reg_write_en => id_dst_reg_write_en
);
Imm_extension_inst: entity work.Imm_extension_decode
 port map(
    imm_in => id_imm_in,
    imm_src => id_imm_src,
    imm_out => id_imm_out
);


inst_decode: process(clock)

begin
    if rising_edge(clock) then
        
        id_ex_buffer.inst_pc <= if_id_buffer.inst_pc;


        --Nizar: Preferbly we should have hazard unit seperate from this file
        -- is_hazard := (src_reg1 /= "00000" AND (id_ex_buffer.dst_reg = src_reg1 OR ex_mem_buffer.dst_reg = src_reg1 OR mem_wb_buffer.dst_reg = src_reg1)) OR (src_reg2 /= "00000" AND (id_ex_buffer.dst_reg = src_reg2 OR ex_mem_buffer.dst_reg = src_reg2 OR mem_wb_buffer.dst_reg = src_reg2));
        
        -- -- if a branch was taken or hazard is detected stall
        -- if ex_mem_buffer.branch_taken = '1' OR is_hazard then
        --     --stall
        --     id_ex_buffer.inst <= STALL_INST;
        --     id_ex_buffer.operand_a <= (others => '0');
        --     id_ex_buffer.operand_b <= (others => '0');
        --     id_ex_buffer.dst_reg <= (others => '0');
        -- else 
        --     id_ex_buffer.inst <= if_id_buffer.inst;
        --     id_ex_buffer.operand_a <= rf_reg_out_1;
        --     id_ex_buffer.operand_b <= rf_reg_out_2;
        --     id_ex_buffer.dst_reg <= dst_reg;
        -- end if;
    end if;
end process;

inst_execute: process(clock) 
begin
    if rising_edge(clock) then
        ex_mem_buffer.inst_pc <= id_ex_buffer.inst_pc;
        -- if ex_mem_buffer.branch_taken = '1' then
        --     ex_mem_buffer.inst <= STALL_INST;
        --     ex_mem_buffer.dst_reg <= (others => '0');
        -- else 
        --     ex_mem_buffer.inst <= id_ex_buffer.inst;
        --     ex_mem_buffer.dst_reg <= id_ex_buffer.dst_reg;
        -- end if;
        ex_mem_buffer.inst_pc <= id_ex_buffer.inst_pc;




    end if;
end process;



END ARCHITECTURE rtl;

    