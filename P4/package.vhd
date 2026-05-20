
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
package cpu_package is

    type ALU_CONTROL_TYPE_t is (ALU_OP_TYPE_ADD, ALU_OP_TYPE_SUB, ALU_OP_TYPE_MUL,
                            ALU_OP_TYPE_SLT, ALU_OP_TYPE_SLTU, ALU_OP_TYPE_AND,
                            ALU_OP_TYPE_OR, ALU_OP_TYPE_XOR, ALU_OP_TYPE_SLL,
                            ALU_OP_TYPE_SRL, ALU_OP_TYPE_SRA);
    type CONTROL_UNIT_OP_TYPE_t is (OP_R_TYPE, OP_I_TYPE, OP_LOAD, OP_STORE, 
    OP_BRANCH, OP_JAL, OP_JALR, OP_LUI, OP_AUIPC);
    type ALU_OP_TYPE_t is (ALUOP_ADD, ALUOP_BRANCH, ALUOP_FUNCT);
    type IMM_SRC_TYPE_t is (IMM_I_TYPE, IMM_S_TYPE, IMM_B_TYPE, IMM_J_TYPE, IMM_U_TYPE);
    type EXECUTE_OPERAND_A_SRC_TYPE_t is (EXECUTE_SRC_REG_A, EXECUTE_SRC_PC, EXECUTE_SRC_ZERO);
    type EXECUTE_OPERAND_B_SRC_TYPE_t is (EXECUTE_SRC_REG_B, EXECUTE_SRC_IMM);
    type WRITE_BACK_SRC_TYPE_t is (WB_ALU_RESULT, WB_MEM_DATA, WB_PC4);
    -- type ALU_OP_SRC_t is (ALU_OP_SRC_IMM, ALU_OP_SRC_ALU_RES, ALU_OP_SRC_REG, 
    --                     ALU_OP_SRC_PC_IMM, ALU_OP_SRC_PC_4, ALU_OP_SRC_RD_DATA);
    -- RISC-V Instruction Type Opcodes (7 bits)
    constant OP_R_TYPE_CODE    : std_logic_vector(6 downto 0) := "0110011"; -- R-type (ADD, SUB, etc.)
    constant OP_I_TYPE_CODE    : std_logic_vector(6 downto 0) := "0010011"; -- I-type (ADDI, etc.)
    constant OP_LOAD_CODE      : std_logic_vector(6 downto 0) := "0000011"; -- Load instructions
    constant OP_STORE_CODE     : std_logic_vector(6 downto 0) := "0100011"; -- Store instructions
    constant OP_BRANCH_CODE    : std_logic_vector(6 downto 0) := "1100011"; -- Branch instructions
    constant OP_JAL_CODE       : std_logic_vector(6 downto 0) := "1101111"; -- JAL
    constant OP_JALR_CODE      : std_logic_vector(6 downto 0) := "1100111"; -- JALR
    constant OP_LUI_CODE       : std_logic_vector(6 downto 0) := "0110111"; -- LUI
    constant OP_AUIPC_CODE     : std_logic_vector(6 downto 0) := "0010111"; -- AUIPC

    constant ENABLE       : std_logic := '1';
    constant DISABLE      : std_logic := '0';

    -- funct3 codes for load/store width
    constant F3_LS_BYTE   : std_logic_vector(2 downto 0) := "000"; -- lb, sb
    constant F3_LS_HALF   : std_logic_vector(2 downto 0) := "001"; -- lh, sh
    constant F3_LS_WORD   : std_logic_vector(2 downto 0) := "010"; -- lw, sw
    constant F3_LS_BYTE_U : std_logic_vector(2 downto 0) := "100"; -- lbu
    constant F3_LS_HALF_U : std_logic_vector(2 downto 0) := "101"; -- lhu

    -- funct3 codes for branch conditions
    constant F3_BR_BEQ  : std_logic_vector(2 downto 0) := "000";
    constant F3_BR_BNE  : std_logic_vector(2 downto 0) := "001";
    constant F3_BR_BLT  : std_logic_vector(2 downto 0) := "100";
    constant F3_BR_BGE  : std_logic_vector(2 downto 0) := "101";
    constant F3_BR_BLTU : std_logic_vector(2 downto 0) := "110";
    constant F3_BR_BGEU : std_logic_vector(2 downto 0) := "111";

    -- funct3 codes for ALU operations (R-type and I-type)
    constant F3_ALU_ADD_SUB : std_logic_vector(2 downto 0) := "000";
    constant F3_ALU_SLL     : std_logic_vector(2 downto 0) := "001";
    constant F3_ALU_SLT     : std_logic_vector(2 downto 0) := "010";
    constant F3_ALU_SLTU    : std_logic_vector(2 downto 0) := "011";
    constant F3_ALU_XOR     : std_logic_vector(2 downto 0) := "100";
    constant F3_ALU_SRL_SRA : std_logic_vector(2 downto 0) := "101";
    constant F3_ALU_OR      : std_logic_vector(2 downto 0) := "110";
    constant F3_ALU_AND     : std_logic_vector(2 downto 0) := "111";





        
     
end package cpu_package;