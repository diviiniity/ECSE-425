

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
        ALU_op         : in  ALU_OP_TYPE_t; -- ALU operation type
        -- Outputs
        ALU_control    :  out ALU_CONTROL_TYPE_t -- ALU control signals
    );
end ALU_decoder_CU;

architecture Behavioral of ALU_decoder_CU is
    

begin
    process(ALU_op, funct3, funct7_bit5, op_bit5)
    begin
            case ALU_op is
                when ALUOP_ADD =>
                    -- Addition for loads, stores, AUIPC
                    ALU_control <= ALU_OP_TYPE_ADD;
                    
                when ALUOP_BRANCH =>
                    -- Subtraction for branches (BEQ, BNE)
                    case funct3 is
                        when "000" =>
                            -- BEQ (Branch if Equal)
                            ALU_control <= ALU_OP_TYPE_SUB;  -- Use subtraction to check equality
                        when "001" =>
                            -- BNE (Branch if Not Equal)
                            ALU_control <= ALU_OP_TYPE_SUB;  -- Use subtraction to check inequality
                        when "100"|"101" =>
                            -- BLT (Branch if Less Than) AND BGE (Branch if Greater or Equal)
                            ALU_control <= ALU_OP_TYPE_SLT;  -- Set Less Than

                        when "110"|"111" =>
                            -- BLTU (Branch if Less Than Unsigned)
                            ALU_control <= ALU_OP_TYPE_SLTU;  -- Set Less Than Unsigned
                        when others =>
                            
                    
                    end case;
                    
                when ALUOP_FUNCT =>
                    -- R-type and I-type operations - decode based on funct3
                    case funct3 is
                        when "000" =>
                            -- ADD/ADDI or SUB
                            -- For R-type: SUB if funct7[5] = 1, ADD if funct7[5] = 0
                            -- For I-type: Always ADD (ADDI)
                            if (op_bit5 = '1' and funct7_bit5 = '1') then
                                ALU_control <= ALU_OP_TYPE_SUB;  -- SUB (R-type only)
                            else
                                ALU_control <= ALU_OP_TYPE_ADD;  -- ADD/ADDI
                            end if;
                            
                        when "001" =>
                            -- SLL/SLLI - Shift Left Logical
                            ALU_control <= ALU_OP_TYPE_SLL;
                            
                        when "010" =>
                            -- SLT/SLTI - Set Less Than (signed)
                            ALU_control <= ALU_OP_TYPE_SLT;
                            
                        when "011" =>
                            -- SLTU/SLTIU - Set Less Than Unsigned
                            ALU_control <= ALU_OP_TYPE_SLTU;  -- Same operation, unsigned comparison
                            
                        when "100" =>
                            -- XOR/XORI - Bitwise XOR
                            ALU_control <= ALU_OP_TYPE_XOR;
                            
                        when "101" =>
                            if funct7_bit5 = '1' then
                                -- SRL/SRLI - Shift Right Logical
                                ALU_control <= ALU_OP_TYPE_SRL;
                            else
                                -- SRA/SRAI - Shift Right Arithmetic
                                ALU_control <= ALU_OP_TYPE_SRA;
                            end if;
                            
                        when "110" =>
                            -- OR/ORI - Bitwise OR
                            ALU_control <= ALU_OP_TYPE_OR;
                            
                        when "111" =>
                            -- AND/ANDI - Bitwise AND
                            ALU_control <= ALU_OP_TYPE_AND;
                            
                        when others =>
                            ALU_control <= ALU_OP_TYPE_ADD;  -- Default to ADD
                    end case;
                    
                when others =>
                    -- Default case - use ADD
                    ALU_control <= ALU_OP_TYPE_ADD; 

       end case;
    end process;
end Behavioral;
