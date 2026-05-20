

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cpu_package.all;
entity ALU_decoder_CU is
    port (
        -- Inputs
        op_bit5        : in  std_logic;                    -- Opcode bit 5
        funct3         : in  std_logic_vector(2 downto 0); -- Function field 3
        funct7_bit5    : in  std_logic;                    -- Function field 7 bit 5
        funct7_bit0    : in  std_logic;                    -- Function field 7 bit 0 (1 = RV32M, ex. MUL)
        ALU_op         : in  ALU_OP_TYPE_t; -- ALU operation type
        -- Outputs
        ALU_control    :  out ALU_CONTROL_TYPE_t -- ALU control signals
    );
end ALU_decoder_CU;

architecture Behavioral of ALU_decoder_CU is
    

begin
    process(ALU_op, funct3, funct7_bit5, funct7_bit0, op_bit5)
    begin
            case ALU_op is
                when ALUOP_ADD =>
                    -- Addition for loads, stores, AUIPC
                    ALU_control <= ALU_OP_TYPE_ADD;
                    
                when ALUOP_BRANCH =>
                    -- ALU performs the comparison; branch_logic reads the result.
                    case funct3 is
                        when F3_BR_BEQ  | F3_BR_BNE  => ALU_control <= ALU_OP_TYPE_SUB;
                        when F3_BR_BLT  | F3_BR_BGE  => ALU_control <= ALU_OP_TYPE_SLT;
                        when F3_BR_BLTU | F3_BR_BGEU => ALU_control <= ALU_OP_TYPE_SLTU;
                        when others                   => ALU_control <= ALU_OP_TYPE_SUB;
                    end case;

                when ALUOP_FUNCT =>
                    -- R-type and I-type operations - decode based on funct3
                    case funct3 is
                        when F3_ALU_ADD_SUB =>
                            if (op_bit5 = '1' and funct7_bit5 = '1') then
                                ALU_control <= ALU_OP_TYPE_SUB;  -- SUB (R-type only)
                            elsif (op_bit5 = '1' and funct7_bit0 = '1') then
                                ALU_control <= ALU_OP_TYPE_MUL;  -- MUL
                            else
                                ALU_control <= ALU_OP_TYPE_ADD;  -- ADD/ADDI
                            end if;

                        when F3_ALU_SLL  => ALU_control <= ALU_OP_TYPE_SLL;
                        when F3_ALU_SLT  => ALU_control <= ALU_OP_TYPE_SLT;
                        when F3_ALU_SLTU => ALU_control <= ALU_OP_TYPE_SLTU;
                        when F3_ALU_XOR  => ALU_control <= ALU_OP_TYPE_XOR;

                        when F3_ALU_SRL_SRA =>
                            if funct7_bit5 = '0' then
                                ALU_control <= ALU_OP_TYPE_SRL;
                            else
                                ALU_control <= ALU_OP_TYPE_SRA;
                            end if;

                        when F3_ALU_OR  => ALU_control <= ALU_OP_TYPE_OR;
                        when F3_ALU_AND => ALU_control <= ALU_OP_TYPE_AND;
                        when others     => ALU_control <= ALU_OP_TYPE_ADD;
                    end case;
                    
                when others =>
                    -- Default case - use ADD
                    ALU_control <= ALU_OP_TYPE_ADD; 

       end case;
    end process;
end Behavioral;
