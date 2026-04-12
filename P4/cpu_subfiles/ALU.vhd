
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_package.all;
entity alu_execute is
    port (
        i_operand_a : in std_logic_vector(31 downto 0);
        i_operand_b : in std_logic_vector(31 downto 0);
        alu_control : ALU_CONTROL_TYPE_t; -- ALU operation selector
        result : out std_logic_vector(31 downto 0);
        zero : out std_logic
    );
end alu_execute;

architecture Behavioral of alu_execute is
begin
    process(i_operand_a, i_operand_b, alu_control)
        variable temp_result : signed(31 downto 0);
        variable u_operand_a : unsigned(31 downto 0);
        variable u_operand_b : unsigned(31 downto 0);
    begin
        u_operand_a := unsigned(i_operand_a);
        u_operand_b := unsigned(i_operand_b);

        case alu_control is
            when ALU_OP_TYPE_ADD => -- ADD
                temp_result := signed(i_operand_a) + signed(i_operand_b);
            when ALU_OP_TYPE_SUB => -- SUB
                temp_result := signed(i_operand_a) - signed(i_operand_b);
            when ALU_OP_TYPE_AND => -- AND
                temp_result := signed(i_operand_a and i_operand_b);
            when ALU_OP_TYPE_OR => -- OR
                temp_result := signed(i_operand_a or i_operand_b);
            when ALU_OP_TYPE_XOR => -- XOR
                temp_result := signed(i_operand_a xor i_operand_b);
            when ALU_OP_TYPE_SLL => -- SLL (logical shift left)
                temp_result := signed(shift_left(u_operand_a, to_integer(u_operand_b(4 downto 0))));
            when ALU_OP_TYPE_SRL => -- SRL (logical shift right)
                temp_result := signed(shift_right(u_operand_a, to_integer(u_operand_b(4 downto 0))));
            when ALU_OP_TYPE_SRA => -- SRA (arithmetic shift right)
                temp_result := signed(shift_right(signed(i_operand_a), to_integer(u_operand_b(4 downto 0))));
            when ALU_OP_TYPE_SLT => -- SLT (signed less than)
                if signed(i_operand_a) < signed(i_operand_b) then
                    temp_result := to_signed(1, 32);
                else
                    temp_result := to_signed(0, 32);
                end if;
            when ALU_OP_TYPE_SLTU => -- SLTU (unsigned less than)
                if u_operand_a < u_operand_b then
                    temp_result := to_signed(1, 32);
                else
                    temp_result := to_signed(0, 32);
                end if;
            when others =>
                temp_result := (others => '0'); -- Default case, set result to zero
        end case;

        result <= std_logic_vector(temp_result);

        if temp_result = 0 then
            zero <= '1';
        else
            zero <= '0';
        end if;
    end process;
end Behavioral;


