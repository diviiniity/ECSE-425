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
    id_rf_out_A: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    id_rf_out_B: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    rf_write_enable: OUT STD_LOGIC
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

signal id_opcode: std_logic_vector(6 downto 0);
signal id_funct3: std_logic_vector(2 downto 0);
signal id_funct7: std_logic_vector(6 downto 0);
-- Hazard detection signals
signal id_uses_rs1: std_logic;  -- '1' when current ID instruction reads rs1
signal id_uses_rs2: std_logic;  -- '1' when current ID instruction reads rs2
signal id_stall: std_logic;  -- '1' when a data hazard requires stalling ID

signal id_RAM_write: std_logic;
signal id_RAM_read: std_logic;
signal id_ALU_src_regA: EXECUTE_OPERAND_A_SRC_TYPE_t := EXECUTE_SRC_REG_A;
signal id_ALU_src_regB: EXECUTE_OPERAND_B_SRC_TYPE_t := EXECUTE_SRC_REG_B;
signal id_dst_reg_write_en: std_logic;
signal id_wb_data_sel: WRITE_BACK_SRC_TYPE_t := WB_ALU_RESULT;
signal id_is_jump: std_logic;
signal id_is_branch: std_logic;

signal id_imm_src: IMM_SRC_TYPE_t;
signal id_imm_in: std_logic_vector(24 downto 0);
signal id_imm_out: std_logic_vector(31 downto 0);

-- signal id_rf_out_A: std_logic_vector(31 downto 0);
-- signal id_rf_out_B: std_logic_vector(31 downto 0);
signal id_ALU_Control: ALU_CONTROL_TYPE_t;


type id_ex_buffer_t is record
    rf_out_a: std_logic_vector(31 downto 0);
    rf_out_b: std_logic_vector(31 downto 0);
    -- inst: std_logic_vector(31 downto 0);
    inst_pc: INTEGER RANGE 0 to ram_size-1;
    -- for detecting hazards
    dst_reg_addr: std_logic_vector(4 downto 0);
    imm_out: std_logic_vector(31 downto 0);
    dst_reg_write_en: std_logic;
    ALU_Control: ALU_CONTROL_TYPE_t;
    ALU_operand_a_src: EXECUTE_OPERAND_A_SRC_TYPE_t;
    ALU_operand_b_src: EXECUTE_OPERAND_B_SRC_TYPE_t; 
    RAM_write : std_logic;
    RAM_read : std_logic;
    wb_data_sel: WRITE_BACK_SRC_TYPE_t;
    funct3: std_logic_vector(2 downto 0);
    is_jump: std_logic;
    is_branch: std_logic;
end record;

signal id_ex_buffer: id_ex_buffer_t := (
    rf_out_a => (others => '0'),
    rf_out_b => (others => '0'),
    -- inst => STALL_INST,
    inst_pc => 0,
    dst_reg_addr => (others => '0'),
    imm_out => (others => '0'),
    dst_reg_write_en => '0',
    ALU_Control => ALU_OP_TYPE_ADD,
    ALU_operand_a_src => EXECUTE_SRC_REG_A,
    ALU_operand_b_src => EXECUTE_SRC_REG_B,
    RAM_write => '0',
    RAM_read => '0',
    wb_data_sel => WB_ALU_RESULT,
    funct3 => (others => '0'),
    is_jump => '0',
    is_branch => '0'
);
--execute signals
signal ex_ALU_i_a: std_logic_vector(31 downto 0);
signal ex_ALU_i_b: std_logic_vector(31 downto 0);
signal ex_result: std_logic_vector(31 downto 0);
signal ex_zero : STD_LOGIC := '0';
signal ex_branch_taken: std_logic := '0';


--memory signals for execute to memory buffer
type ex_mem_buffer_t is record
    alu_result: std_logic_vector(31 downto 0);
    branch_taken: std_logic;
    -- -- probably unnecessary to carry full instruction here
    -- inst: std_logic_vector(31 downto 0);
    inst_pc: INTEGER RANGE 0 to ram_size-1;
    dst_reg_addr: std_logic_vector(4 downto 0);
    rf_out_B: std_logic_vector(31 downto 0);
    dst_reg_write_en: std_logic;
    RAM_write: std_logic;
    RAM_read: std_logic;
    wb_data_sel: WRITE_BACK_SRC_TYPE_t;
end record;

signal ex_mem_buffer: ex_mem_buffer_t := (
    alu_result => (others => '0'),
    branch_taken => '0',
    dst_reg_addr => (others => '0'),
    rf_out_B => (others => '0'),
    dst_reg_write_en => '0',
    RAM_write => '0',
    RAM_read => '0',
    wb_data_sel => WB_ALU_RESULT,
    inst_pc => 0
);

--memory signals
signal mem_readdata: std_logic_vector(31 downto 0);

--write back signals
type mem_wb_buffer_t is record
    RAM_readdata: std_logic_vector(31 downto 0);
    alu_result: std_logic_vector(31 downto 0);
    dst_reg_addr: std_logic_vector(4 downto 0);
    dst_reg_write_en: std_logic;
    wb_data_sel: WRITE_BACK_SRC_TYPE_t;
    inst_pc: INTEGER RANGE 0 to ram_size-1;
end record;

signal mem_wb_buffer: mem_wb_buffer_t := (
    RAM_readdata => (others => '0'),
    alu_result => (others => '0'),
    dst_reg_addr => (others => '0'),
    dst_reg_write_en => '0',
    wb_data_sel => WB_ALU_RESULT,
    inst_pc => 0
);
signal wb_data: std_logic_vector(31 downto 0);
BEGIN
--connected to instruction memory
i_addr <= if_pc;


-- Hazard detection
-- Determine which register fields the current ID instruction actually reads.
id_uses_rs1 <= '1' when (id_opcode = OP_R_TYPE_CODE or id_opcode = OP_I_TYPE_CODE or
                          id_opcode = OP_LOAD_CODE or id_opcode = OP_STORE_CODE or
                          id_opcode = OP_BRANCH_CODE or id_opcode = OP_JALR_CODE)
               else '0';

id_uses_rs2 <= '1' when (id_opcode = OP_R_TYPE_CODE or id_opcode = OP_STORE_CODE or
                          id_opcode = OP_BRANCH_CODE)
               else '0';

-- Stall when any in-flight write-back instruction targets a register we need.
id_stall <= '1' when (
    -- EX stage (id_ex_buffer) dependency
    (id_ex_buffer.dst_reg_write_en = '1' and id_ex_buffer.dst_reg_addr /= "00000" and
     ((id_uses_rs1 = '1' and id_ex_buffer.dst_reg_addr = id_addr_regA) or
      (id_uses_rs2 = '1' and id_ex_buffer.dst_reg_addr = id_addr_regB))) or
    -- MEM stage (ex_mem_buffer) dependency
    (ex_mem_buffer.dst_reg_write_en = '1' and ex_mem_buffer.dst_reg_addr /= "00000" and
     ((id_uses_rs1 = '1' and ex_mem_buffer.dst_reg_addr = id_addr_regA) or
      (id_uses_rs2 = '1' and ex_mem_buffer.dst_reg_addr = id_addr_regB))) or
    -- WB stage (mem_wb_buffer) dependency
    (mem_wb_buffer.dst_reg_write_en = '1' and mem_wb_buffer.dst_reg_addr /= "00000" and
     ((id_uses_rs1 = '1' and mem_wb_buffer.dst_reg_addr = id_addr_regA) or
      (id_uses_rs2 = '1' and mem_wb_buffer.dst_reg_addr = id_addr_regB)))
) else '0';

inst_fetch: process(clock)
begin
    if rising_edge(clock) then
        if ex_mem_buffer.branch_taken = '1' then
            -- Branch/jump taken: redirect PC and flush IF/ID with NOP.
            if_pc <= to_integer(unsigned(ex_mem_buffer.alu_result));
            if_id_buffer.inst     <= STALL_INST;
            if_id_buffer.inst_pc  <= if_pc;
        elsif id_stall = '1' then
            -- Data hazard stall
            null;
        else
            -- Normal fetch
            if_pc <= if_pc + 4;
            if_id_buffer.inst <= i_readdata;
            if_id_buffer.inst_pc <= if_pc;
        end if;
    end if;
end process;

--combinatory logic for decode stage
id_opcode <= if_id_buffer.inst(6 downto 0);
id_funct3 <= if_id_buffer.inst(14 downto 12);
id_funct7 <= if_id_buffer.inst(31 downto 25);
id_addr_regA <= if_id_buffer.inst(19 downto 15);
id_addr_regB <= if_id_buffer.inst(24 downto 20);
id_dst_reg <= if_id_buffer.inst(11 downto 7);
id_imm_in <= if_id_buffer.inst(31 downto 7);
Control_unit_inst: entity work.Control_unit
 port map(
    --Inputs
    op_code => id_opcode,
    funct3 => id_funct3,
    funct7 => id_funct7,
    --Outputs
    RAM_write => id_RAM_write,
    RAM_read => id_RAM_read,
    ALU_src_regA => id_ALU_src_regA,
    ALU_src_regB => id_ALU_src_regB,
    ALU_control => id_ALU_Control,
    Imm_src => id_imm_src,
    dst_reg_write_en => id_dst_reg_write_en,
    wb_data_sel => id_wb_data_sel,
    is_jump => id_is_jump,
    is_branch => id_is_branch
);
Imm_extension_inst: entity work.Imm_extension_decode
 port map(
    imm_in => id_imm_in,
    imm_src => id_imm_src,
    imm_out => id_imm_out
);

rf_read_reg_1 <= to_integer(unsigned(id_addr_regA));
rf_read_reg_2 <= to_integer(unsigned(id_addr_regB));
rf_write_reg <= to_integer(unsigned(mem_wb_buffer.dst_reg_addr));
-- rf_reg_out_1 <= id_rf_out_A;
-- rf_reg_out_2 <= id_rf_out_B;

-- Register_file_decode: entity work.Register_file_decode
--  port map(
--     clock => clock,
--     read_reg_1 => read_reg_1_int,
--     read_reg_2 => read_reg_2_int,
--     write_reg => write_reg_int,
--     write_data => rf_write_data,
--     write_enable => rf_write_enable,
--     reg_out_1 => id_rf_out_A,
--     reg_out_2 => id_rf_out_B
-- );

inst_decode: process(clock)
begin
    if rising_edge(clock) then
        if ex_mem_buffer.branch_taken = '1' or id_stall = '1' then
            -- Insert NOP into ID/EX.
            id_ex_buffer.dst_reg_write_en <= '0';
            id_ex_buffer.RAM_write <= '0';
            id_ex_buffer.RAM_read <= '0';
            id_ex_buffer.is_jump <= '0';
            id_ex_buffer.is_branch <= '0';
            id_ex_buffer.dst_reg_addr <= (others => '0');
            id_ex_buffer.funct3 <= (others => '0');
            id_ex_buffer.inst_pc <= if_id_buffer.inst_pc;
            id_ex_buffer.imm_out <= (others => '0');
            id_ex_buffer.rf_out_a <= (others => '0');
            id_ex_buffer.rf_out_b <= (others => '0');
            id_ex_buffer.ALU_Control <= ALU_OP_TYPE_ADD;
            id_ex_buffer.ALU_operand_a_src <= EXECUTE_SRC_REG_A;
            id_ex_buffer.ALU_operand_b_src <= EXECUTE_SRC_REG_B;
            id_ex_buffer.wb_data_sel <= WB_ALU_RESULT;
        else
            -- Normal decode
            id_ex_buffer.inst_pc <= if_id_buffer.inst_pc;
            id_ex_buffer.dst_reg_addr <= id_dst_reg;
            id_ex_buffer.imm_out <= id_imm_out;
            id_ex_buffer.dst_reg_write_en <= id_dst_reg_write_en;
            id_ex_buffer.rf_out_a <= id_rf_out_A;
            id_ex_buffer.rf_out_b <= id_rf_out_B;
            id_ex_buffer.ALU_Control <= id_ALU_Control;
            id_ex_buffer.ALU_operand_a_src <= id_ALU_src_regA;
            id_ex_buffer.ALU_operand_b_src <= id_ALU_src_regB;
            id_ex_buffer.RAM_write <= id_RAM_write;
            id_ex_buffer.RAM_read <= id_RAM_read;
            id_ex_buffer.wb_data_sel <= id_wb_data_sel;
            id_ex_buffer.funct3 <= id_funct3;
            id_ex_buffer.is_jump <= id_is_jump;
            id_ex_buffer.is_branch <= id_is_branch;
        end if;
    end if;
end process;

--combinatory logic for execute stage
-- Operand A selection
with id_ex_buffer.ALU_operand_a_src select
    ex_ALU_i_a <= id_ex_buffer.rf_out_a when EXECUTE_SRC_REG_A,
                  std_logic_vector(to_unsigned(id_ex_buffer.inst_pc, 32)) when EXECUTE_SRC_PC,
                  (others => '0') when EXECUTE_SRC_ZERO,  -- LUI: 0 + imm
                  (others => '0') when others;

-- Operand B selection
with id_ex_buffer.ALU_operand_b_src select
    ex_ALU_i_b <= id_ex_buffer.rf_out_b when EXECUTE_SRC_REG_B,
                     id_ex_buffer.imm_out when EXECUTE_SRC_IMM,
                     (others => '0') when others;

 --ALU Instantiate
ALU: entity work.alu_execute(Behavioral)
    port map(
        i_operand_a => ex_ALU_i_a,
        i_operand_b => ex_ALU_i_b,
        alu_control => id_ex_buffer.ALU_Control,

        result => ex_result,
        zero => ex_zero
    );
-- execute branch logic
execute_branch_logic: entity work.branch_logic(Behavioral)
    port map(
    i_operand_a => id_ex_buffer.rf_out_a,
    i_operand_b => id_ex_buffer.rf_out_b,
    i_zero => ex_zero,
    i_funct3 => id_ex_buffer.funct3,
    i_is_jump => id_ex_buffer.is_jump,
    i_is_branch => id_ex_buffer.is_branch,
    o_branch_taken => ex_branch_taken
    );

inst_execute: process(clock)
begin
    if rising_edge(clock) then
        if ex_mem_buffer.branch_taken = '1' then
            -- Flush EX/MEM
            ex_mem_buffer.branch_taken <= '0';
            ex_mem_buffer.dst_reg_write_en <= '0';
            ex_mem_buffer.RAM_write <= '0';
            ex_mem_buffer.RAM_read <= '0';
            ex_mem_buffer.dst_reg_addr <= (others => '0');
            ex_mem_buffer.alu_result <= (others => '0');
            ex_mem_buffer.rf_out_B <= (others => '0');
            ex_mem_buffer.wb_data_sel <= WB_ALU_RESULT;
            ex_mem_buffer.inst_pc <= 0;
        else
            -- Normal execute
            ex_mem_buffer.branch_taken <= ex_branch_taken;
            ex_mem_buffer.alu_result <= ex_result;
            ex_mem_buffer.rf_out_B <= id_ex_buffer.rf_out_b;
            ex_mem_buffer.dst_reg_addr <= id_ex_buffer.dst_reg_addr;
            ex_mem_buffer.dst_reg_write_en <= id_ex_buffer.dst_reg_write_en;
            ex_mem_buffer.RAM_write <= id_ex_buffer.RAM_write;
            ex_mem_buffer.RAM_read <= id_ex_buffer.RAM_read;
            ex_mem_buffer.wb_data_sel <= id_ex_buffer.wb_data_sel;
            ex_mem_buffer.inst_pc <= id_ex_buffer.inst_pc;
        end if;
    end if;
end process;


--memory comb logic
--connection to data memory(LOGIC FOR WAIT REQUEST NOT IMPLEMENTED YET)
--ouputs to memory
d_writedata <= ex_mem_buffer.rf_out_B;
d_addr <= to_integer(unsigned(ex_mem_buffer.alu_result(31 downto 0))); 
d_memwrite <= ex_mem_buffer.RAM_write;
d_memread <= ex_mem_buffer.RAM_read;
--inputs from memory
mem_readdata <= d_readdata;

inst_memory: process(clock)
begin
    if rising_edge(clock) then
        mem_wb_buffer.RAM_readdata <= d_readdata;
        mem_wb_buffer.alu_result <= ex_mem_buffer.alu_result;
        mem_wb_buffer.dst_reg_addr <= ex_mem_buffer.dst_reg_addr;
        mem_wb_buffer.dst_reg_write_en <= ex_mem_buffer.dst_reg_write_en;
        mem_wb_buffer.wb_data_sel <= ex_mem_buffer.wb_data_sel;
        mem_wb_buffer.inst_pc <= ex_mem_buffer.inst_pc;
    end if;
end process;
--comb logic for write back
rf_write_enable <= mem_wb_buffer.dst_reg_write_en;
--logic to determin what to write to register file
with mem_wb_buffer.wb_data_sel select
    rf_write_data <= mem_wb_buffer.alu_result when WB_ALU_RESULT,
                     mem_wb_buffer.RAM_readdata when WB_MEM_DATA,
                     std_logic_vector(to_unsigned(mem_wb_buffer.inst_pc + 4, 32)) when WB_PC4,  -- JAL/JALR link
                     (others => '0') when others;
END ARCHITECTURE rtl;

    