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

    -- rf_read_reg_1: OUT INTEGER RANGE 0 to 31;
    -- rf_read_reg_2: OUT INTEGER RANGE 0 to 31;
    -- rf_write_reg: OUT INTEGER RANGE 0 to 31;
    -- rf_write_data: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
    -- rf_reg_out_1: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    -- rf_reg_out_2: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    -- rf_write_enable: OUT STD_LOGIC
);
END cpu;

ARCHITECTURE rtl OF cpu IS

constant STALL_INST: STD_LOGIC_VECTOR(31 DOWNTO 0) := "00000000000000000000000000010011";

signal if_pc: INTEGER RANGE 0 to ram_size-1 := 0;

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
signal id_ALU_src_regA: EXECUTE_OPERAND_A_SRC_TYPE_t := EXECUTE_SRC_ALU;
signal id_ALU_src_regB: EXECUTE_OPERAND_B_SRC_TYPE_t := EXECUTE_SRC_ALU;
signal id_dst_reg_write_en: std_logic;

signal id_imm_src: IMM_SRC_TYPE_t;
signal id_imm_in: std_logic_vector(24 downto 0);
signal id_imm_out: std_logic_vector(31 downto 0);

signal id_rf_out_A: std_logic_vector(31 downto 0);
signal id_rf_out_B: std_logic_vector(31 downto 0);
signal id_ALU_Control: ALU_CONTROL_TYPE_t;


type id_ex_buffer_t is record
    operand_a: std_logic_vector(31 downto 0);
    operand_b: std_logic_vector(31 downto 0);
    -- inst: std_logic_vector(31 downto 0);
    inst_pc: INTEGER RANGE 0 to ram_size-1;
    -- for detecting hazards
    dst_reg_addr: std_logic_vector(4 downto 0);
    imm_out: std_logic_vector(31 downto 0);
    dst_reg_write_en: std_logic;
    ALU_Control: ALU_CONTROL_TYPE_t;
    ALU_operand_a_src: EXECUTE_OPERAND_A_SRC_TYPE_t;
    ALU_operand_b_src: EXECUTE_OPERAND_B_SRC_TYPE_t; 
end record;

signal id_ex_buffer: id_ex_buffer_t := (
    operand_a => (others => '0'),
    operand_b => (others => '0'),
    -- inst => STALL_INST,
    inst_pc => 0,
    dst_reg_addr => (others => '0'),
    imm_out => (others => '0'),
    dst_reg_write_en => '0',
    ALU_Control => ALU_OP_TYPE_ADD,
    ALU_operand_a_src => EXECUTE_SRC_ALU,
    ALU_operand_b_src => EXECUTE_SRC_ALU

);
--execute signals
signal ex_ALU_i_a: std_logic_vector(31 downto 0);
signal ex_ALU_i_b: std_logic_vector(31 downto 0);
signal ex_result: std_logic_vector(31 downto 0);
signal ex_zero : STD_LOGIC := '0';


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
--connected to instruction memory
i_addr <= if_pc;

inst_fetch: process(clock)
begin
    if rising_edge(clock) then
        if ex_mem_buffer.branch_taken = '1' then
            if_pc <= to_integer(unsigned(ex_mem_buffer.alu_output));
            if_id_buffer.inst <= STALL_INST;
        else 
            if_pc <= if_pc + 4;
            if_id_buffer.inst <= i_readdata;
        end if;
        
        if_id_buffer.inst_pc <= if_pc;
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
    --Inputs
    op_code => id_opcode,
    funct3 => id_funct3,
    funct7 => id_funct7,
    --Outputs
    RAM_write => id_RAM_write,
    ALU_src_regA => id_ALU_src_regA,
    ALU_src_regB => id_ALU_src_regB,
    ALU_control => id_ALU_Control,
    Imm_src => id_imm_src,
    dst_reg_write_en => id_dst_reg_write_en
);
Imm_extension_inst: entity work.Imm_extension_decode
 port map(
    imm_in => id_imm_in,
    imm_src => id_imm_src,
    imm_out => id_imm_out
);
Register_file_decode: entity work.Register_file_decode
 port map(
    clock => clock,
    read_reg_1 => to_integer(unsigned(id_addr_regA)),
    read_reg_2 => to_integer(unsigned(id_addr_regB)),
    write_reg => to_integer(unsigned(id_dst_reg)),
    write_data => rf_write_data,
    write_enable => rf_write_enable,
    reg_out_1 => id_rf_out_A,
    reg_out_2 => id_rf_out_B
);

inst_decode: process(clock)
begin
    if rising_edge(clock) then
        
        id_ex_buffer.inst_pc <= if_id_buffer.inst_pc;
        id_ex_buffer.dst_reg_addr <= id_dst_reg;
        id_ex_buffer.imm_out <= id_imm_out;
        id_ex_buffer.dst_reg_write_en <= id_dst_reg_write_en;
        id_ex_buffer.operand_a <= id_rf_out_A;
        id_ex_buffer.operand_b <= id_rf_out_B;
        id_ex_buffer.ALU_Control <= id_ALU_Control;
        id_ex_buffer.ALU_operand_a_src <= id_ALU_src_regA;
        id_ex_buffer.ALU_operand_b_src <= id_ALU_src_regB;
         -- Hazard detection logic (simplified)

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

--combinatory logic for execute stage
-- Operand A selection
with id_ex_buffer.ALU_operand_a_src select
    ex_ALU_i_a <= id_ex_buffer.operand_a when EXECUTE_SRC_ALU,
                     std_logic_vector(to_unsigned(id_ex_buffer.inst_pc, 32)) when EXECUTE_SRC_PC,
                     (others => '0') when others;

-- Operand B selection
with id_ex_buffer.ALU_operand_b_src select
    ex_ALU_i_b <= id_ex_buffer.operand_b when EXECUTE_SRC_ALU,
                     id_ex_buffer.imm_out when EXECUTE_SRC_IMM,
                     (others => '0') when others;

 --ALU Instantiate
ALU: entity work.alu_execute(Behavioral)
    port map(
        operand_a => ex_ALU_i_a,
        operand_b => ex_ALU_i_b, 
        alu_control => id_ex_buffer.ALU_Control,

        result => ex_result,
        zero => ex_zero
    );
-- execute branch logic
execute_branch_logic:entity work.branch_logic(Behavioral)
    port map(
    i_operand_a => id_ex_buffer.operand_a,
    i_operand_b => id_ex_buffer.operand_b,
    i_zero => ex_zero,
    o_branch_taken => ex_mem_buffer.branch_taken
    );

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




    end if;
end process;



END ARCHITECTURE rtl;

    