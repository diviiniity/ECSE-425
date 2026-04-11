----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/03/2025 08:11:01 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_package.all;
entity alu_execute is
    port (
        operand_a : in std_logic_vector(31 downto 0);
        operand_b : in std_logic_vector(31 downto 0);
        alu_control : ALU_CONTROL_TYPE_t; -- ALU operation selector
        result : out std_logic_vector(31 downto 0);
        zero : out std_logic
    );
end alu_execute;

architecture Behavioral of alu_execute is
begin
    process(operand_a, operand_b, alu_control)
        variable temp_result : signed(31 downto 0);
        variable u_operand_a : unsigned(31 downto 0);
        variable u_operand_b : unsigned(31 downto 0);
    begin
        u_operand_a := unsigned(operand_a);
        u_operand_b := unsigned(operand_b);

        case alu_control is
            when ALU_OP_TYPE_ADD => -- ADD
                temp_result := signed(operand_a) + signed(operand_b);
            when ALU_OP_TYPE_SUB => -- SUB
                temp_result := signed(operand_a) - signed(operand_b);
            when ALU_OP_TYPE_AND => -- AND
                temp_result := signed(operand_a and operand_b);
            when ALU_OP_TYPE_OR => -- OR
                temp_result := signed(operand_a or operand_b);
            when ALU_OP_TYPE_XOR => -- XOR
                temp_result := signed(operand_a xor operand_b);
            when ALU_OP_TYPE_SLL => -- SLL (logical shift left)
                temp_result := signed(shift_left(u_operand_a, to_integer(u_operand_b(4 downto 0))));
            when ALU_OP_TYPE_SRL => -- SRL (logical shift right)
                temp_result := signed(shift_right(u_operand_a, to_integer(u_operand_b(4 downto 0))));
            when ALU_OP_TYPE_SRA => -- SRA (arithmetic shift right)
                temp_result := signed(shift_right(signed(operand_a), to_integer(u_operand_b(4 downto 0))));
            when ALU_OP_TYPE_SLT => -- SLT (signed less than)
                if signed(operand_a) < signed(operand_b) then
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


