library IEEE;
use IEEE.std_logic_1164.all;

entity branch_logic is
    port (
        i_operand_a    : in  std_logic_vector(31 downto 0);
        i_operand_b    : in  std_logic_vector(31 downto 0);
        i_zero        : in  std_logic;

        o_branch_taken : out std_logic
    );
end branch_logic;

architecture behavioral of branch_logic is
begin
    -- No logic implemented yet
    o_branch_taken <= '0';
end behavioral;