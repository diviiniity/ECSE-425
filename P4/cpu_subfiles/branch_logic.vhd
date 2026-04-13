library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity branch_logic is
    port (
        i_operand_a : in  std_logic_vector(31 downto 0);  -- rs1
        i_operand_b : in  std_logic_vector(31 downto 0);  -- rs2
        i_zero : in  std_logic;                           -- ALU zero flag
        i_funct3 : in  std_logic_vector(2 downto 0);      -- branch condition type
        i_is_jump : in  std_logic;                        -- '1' for JAL/JALR (unconditional jump)
        i_is_branch : in  std_logic;                        -- '1' for conditional branch 
        o_branch_taken : out std_logic
    );
end branch_logic;

architecture behavioral of branch_logic is
begin
    process(i_operand_a, i_operand_b, i_funct3, i_is_jump)
    begin
        if i_is_jump = '1' then
            -- JAL / JALR: unconditional redirect
            o_branch_taken <= '1';
        elsif i_is_branch = '1' then
            case i_funct3 is
                when "000" => -- BEQ: branch if rs1 == rs2
                    if i_operand_a = i_operand_b then
                        o_branch_taken <= '1';
                    else
                        o_branch_taken <= '0';
                    end if;

                when "001" => -- BNE: branch if rs1 != rs2
                    if i_operand_a /= i_operand_b then
                        o_branch_taken <= '1';
                    else
                        o_branch_taken <= '0';
                    end if;

                when "100" => -- BLT: branch if rs1 < rs2 (signed)
                    if signed(i_operand_a) < signed(i_operand_b) then
                        o_branch_taken <= '1';
                    else
                        o_branch_taken <= '0';
                    end if;

                when "101" => -- BGE: branch if rs1 >= rs2 (signed)
                    if signed(i_operand_a) >= signed(i_operand_b) then
                        o_branch_taken <= '1';
                    else
                        o_branch_taken <= '0';
                    end if;

                when others =>
                    o_branch_taken <= '0';
            end case;
        else 
            o_branch_taken <= '0';
        end if;
    end process;
end Behavioral;
