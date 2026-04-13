
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cpu_package.all;
entity Main_decoder_ is
    port (
        -- Inputs
        op_type : in  CONTROL_UNIT_OP_TYPE_t;
        -- Outputs
        RAM_write : out std_logic;
        RAM_read : out std_logic;
        ALU_src_regA : out EXECUTE_OPERAND_A_SRC_TYPE_t;
        ALU_src_regB : out EXECUTE_OPERAND_B_SRC_TYPE_t;
        Imm_src : out IMM_SRC_TYPE_t;
        dst_reg_write_en : out std_logic;
        ALU_op : out ALU_OP_TYPE_t;
        wb_data_sel : out WRITE_BACK_SRC_TYPE_t;
        is_jump : out std_logic
    );
end Main_decoder_;


architecture Behavioral of Main_decoder_ is
constant ENABLE : std_logic := '1';
constant DISABLE : std_logic := '0';
begin
    
    process(op_type)
    begin
        RAM_write <= DISABLE;
        RAM_read <= DISABLE;
        ALU_src_regA <= EXECUTE_SRC_REG_A;
        ALU_src_regB <= EXECUTE_SRC_REG_B;
        Imm_src <= IMM_I_TYPE;
        dst_reg_write_en <= DISABLE;
        ALU_op <= ALUOP_ADD;
        wb_data_sel <= WB_ALU_RESULT;
        is_jump <= DISABLE;

        case op_type is
            when OP_R_TYPE =>
                -- R-type instructions (ADD, SUB, MUL, AND, OR, XOR, SLT, SLL, SRL, SRA)
                dst_reg_write_en <= ENABLE;
                ALU_src_regA <= EXECUTE_SRC_REG_A;
                ALU_src_regB <= EXECUTE_SRC_REG_B;  -- both operands from registers
                ALU_op <= ALUOP_FUNCT;         -- ALU_decoder reads funct3/funct7
                wb_data_sel <= WB_ALU_RESULT;

            when OP_I_TYPE =>
                -- I-type instructions (ADDI, XORI, ORI, ANDI, SLTI, SLLI, SRLI, SRAI)
                dst_reg_write_en <= ENABLE;
                ALU_src_regA     <= EXECUTE_SRC_REG_A;  -- rs1
                ALU_src_regB     <= EXECUTE_SRC_IMM;    -- sign-extended 12-bit immediate
                Imm_src          <= IMM_I_TYPE;
                ALU_op           <= ALUOP_FUNCT;
                wb_data_sel      <= WB_ALU_RESULT;

            when OP_LOAD =>
                -- LOAD (lw): rd = Mem[rs1 + imm]
                dst_reg_write_en <= ENABLE;
                RAM_read         <= ENABLE;
                ALU_src_regA     <= EXECUTE_SRC_REG_A;  -- rs1 (base address)
                ALU_src_regB     <= EXECUTE_SRC_IMM;    -- offset
                Imm_src          <= IMM_I_TYPE;
                ALU_op           <= ALUOP_ADD;           -- effective address = rs1 + offset
                wb_data_sel      <= WB_MEM_DATA;

            when OP_STORE =>
                -- STORE (sw): Mem[rs1 + imm] = rs2
                dst_reg_write_en <= DISABLE;
                RAM_write        <= ENABLE;
                ALU_src_regA     <= EXECUTE_SRC_REG_A;  -- rs1 (base address)
                ALU_src_regB     <= EXECUTE_SRC_IMM;    -- offset
                Imm_src          <= IMM_S_TYPE;
                ALU_op           <= ALUOP_ADD;           -- effective address = rs1 + offset

            when OP_BRANCH =>
                -- BRANCH (beq, bne, blt, bge): ALU computes PC+imm (target),
                -- branch_logic independently compares rs1/rs2 using funct3
                dst_reg_write_en <= DISABLE;
                ALU_src_regA     <= EXECUTE_SRC_PC;     -- PC (for target = PC + offset)
                ALU_src_regB     <= EXECUTE_SRC_IMM;    -- branch offset
                Imm_src          <= IMM_B_TYPE;
                ALU_op           <= ALUOP_ADD;

            when OP_JAL =>
                -- JAL: rd = PC+4;  PC = PC + imm  (unconditional jump)
                dst_reg_write_en <= ENABLE;
                ALU_src_regA     <= EXECUTE_SRC_PC;     -- PC
                ALU_src_regB     <= EXECUTE_SRC_IMM;    -- J-type offset
                Imm_src          <= IMM_J_TYPE;
                ALU_op           <= ALUOP_ADD;           -- jump target = PC + offset
                wb_data_sel      <= WB_PC4;             -- link register = PC+4
                is_jump          <= ENABLE;             -- always redirect PC

            when OP_JALR =>
                -- JALR: rd = PC+4;  PC = (rs1 + imm) & ~1  (indirect jump)
                dst_reg_write_en <= ENABLE;
                ALU_src_regA     <= EXECUTE_SRC_REG_A;  -- rs1
                ALU_src_regB     <= EXECUTE_SRC_IMM;    -- I-type offset
                Imm_src          <= IMM_I_TYPE;
                ALU_op           <= ALUOP_ADD;           -- jump target = rs1 + offset
                wb_data_sel      <= WB_PC4;             -- link register = PC+4
                is_jump          <= ENABLE;             -- always redirect PC

            when OP_LUI =>
                -- LUI: rd = imm << 12  (upper immediate, lower 12 bits = 0)
                dst_reg_write_en <= ENABLE;
                ALU_src_regA     <= EXECUTE_SRC_ZERO;   -- 0 so result = 0 + imm = imm
                ALU_src_regB     <= EXECUTE_SRC_IMM;
                Imm_src          <= IMM_U_TYPE;
                ALU_op           <= ALUOP_ADD;
                wb_data_sel      <= WB_ALU_RESULT;

            when OP_AUIPC =>
                -- AUIPC: rd = PC + (imm << 12)
                dst_reg_write_en <= ENABLE;
                ALU_src_regA     <= EXECUTE_SRC_PC;
                ALU_src_regB     <= EXECUTE_SRC_IMM;
                Imm_src          <= IMM_U_TYPE;
                ALU_op           <= ALUOP_ADD;
                wb_data_sel      <= WB_ALU_RESULT;

            when others =>
                null; -- all outputs already set to safe defaults above

        end case;
    end process;

end Behavioral;
