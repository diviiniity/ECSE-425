library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.cpu_package.all;

entity branch_logic is
    port (
        i_alu_result    : in  std_logic_vector(31 downto 0); -- ALU comparison result
        i_zero          : in  std_logic;                      -- ALU zero flag (rs1 - rs2 = 0)
        i_funct3        : in  std_logic_vector(2 downto 0);
        i_is_jump       : in  std_logic;                      -- '1' for JAL/JALR
        i_is_branch     : in  std_logic;                      -- '1' for conditional branches
        i_inst_pc       : in  std_logic_vector(31 downto 0); -- PC of branch instruction
        i_imm           : in  std_logic_vector(31 downto 0); -- sign-extended immediate
        o_branch_taken  : out std_logic;
        o_branch_target : out std_logic_vector(31 downto 0)
    );
end branch_logic;

architecture Behavioral of branch_logic is
begin
    process(i_alu_result, i_zero, i_funct3, i_is_jump, i_is_branch, i_inst_pc, i_imm)
    begin
        -- Default: not taken, target = PC + imm (used by conditional branches)
        o_branch_taken  <= '0';
        o_branch_target <= std_logic_vector(unsigned(i_inst_pc) + unsigned(i_imm));

        if i_is_jump = '1' then
            -- JAL/JALR: always taken; ALU already computed the target (PC+imm or rs1+imm)
            o_branch_taken  <= '1';
            o_branch_target <= i_alu_result;

        elsif i_is_branch = '1' then
            -- Conditional branch: target = PC + B-imm (default above)
            -- Taken/not-taken determined from ALU comparison result
            case i_funct3 is
                when F3_BR_BEQ  => o_branch_taken <= i_zero;
                when F3_BR_BNE  => o_branch_taken <= not i_zero;
                -- SLT/SLTU return 1 in bit 0 when less-than; BGE/BGEU invert that
                when F3_BR_BLT  => o_branch_taken <= i_alu_result(0);
                when F3_BR_BGE  => o_branch_taken <= not i_alu_result(0);
                when F3_BR_BLTU => o_branch_taken <= i_alu_result(0);
                when F3_BR_BGEU => o_branch_taken <= not i_alu_result(0);
                when others     => o_branch_taken <= '0';
            end case;
        end if;
    end process;
end Behavioral;
