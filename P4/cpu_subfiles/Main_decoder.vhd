
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cpu_package.all;
entity Main_decoder_ is
    port (
        -- Inputs
        op_type        : in  CONTROL_UNIT_OP_TYPE_t;

        -- Outputs
        RAM_write      : out std_logic;
        RAM_read       : out std_logic;
        ALU_src_regA        : out EXECUTE_OPERAND_A_SRC_TYPE_t;
        ALU_src_regB        : out EXECUTE_OPERAND_B_SRC_TYPE_t;
        Imm_src        : out IMM_SRC_TYPE_t;
        dst_reg_write_en : out std_logic;
        ALU_op         : out ALU_OP_TYPE_t;
        wb_data_sel : out WRITE_BACK_SRC_TYPE_t
        );
end Main_decoder_;


architecture Behavioral of Main_decoder_ is
constant ENABLE : std_logic := '1';
constant DISABLE : std_logic := '0';
begin
    
    process(op_type)
    begin
        RAM_write <= DISABLE;
        ALU_src_regA <= EXECUTE_SRC_REG_A;
        ALU_src_regB <= EXECUTE_SRC_REG_B;
        Imm_src <= IMM_I_TYPE;
        dst_reg_write_en <= DISABLE;
        ALU_op <= ALUOP_ADD;
        wb_data_sel <= WB_ALU_RESULT;
        case op_type is
            when OP_R_TYPE =>
            -- R-type instructions (ADD, SUB, AND, OR, XOR, SLT, SLL, SRL, SRA)
            dst_reg_write_en <= ENABLE;     -- Write to register
            RAM_write <= DISABLE;           -- No memory write
            RAM_read <= DISABLE;            -- No memory read
            ALU_src_regA <= EXECUTE_SRC_REG_A;         
            ALU_src_regB <= EXECUTE_SRC_REG_B;         -- Use register (rs2) for ALU src B
            Imm_src <= IMM_I_TYPE;          -- Don't care for R-type
            ALU_op <= ALUOP_FUNCT;          -- Function field decode
            wb_data_sel <= WB_ALU_RESULT;

            when OP_I_TYPE =>
            -- I-type instructions (ADDI, ANDI, ORI, XORI, SLTI, SLLI, SRLI, SRAI)
            dst_reg_write_en <= ENABLE;     -- Write to register
            RAM_write <= DISABLE;           -- No memory write
            RAM_read <= DISABLE;            -- No memory read
            ALU_src_regA <= EXECUTE_SRC_REG_A;          -- Use register (rs1) for ALU src A
            ALU_src_regB <= EXECUTE_SRC_REG_B;          -- Use register (rs2) for ALU src B
            Imm_src <= IMM_I_TYPE;          -- I-type immediate
            ALU_op <= ALUOP_FUNCT;          -- Function field decode
            wb_data_sel <= WB_ALU_RESULT;
            
            when others =>
            -- Default case - NOP/Invalid instruction
            dst_reg_write_en <= DISABLE;
            RAM_write <= DISABLE;
            RAM_read <= DISABLE;
            ALU_src_regA <= EXECUTE_SRC_REG_A;
            ALU_src_regB <= EXECUTE_SRC_REG_B;
            Imm_src <= IMM_I_TYPE;
            ALU_op <= ALUOP_ADD;
            wb_data_sel <= WB_ALU_RESULT;
        end case;
        end process;
end Behavioral;
