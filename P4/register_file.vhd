LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

ENTITY Register_file_decode IS 
PORT (
    clock: IN STD_LOGIC;
    read_reg_1: IN INTEGER RANGE 0 to 31;
    read_reg_2: IN INTEGER RANGE 0 to 31;
    write_reg: IN INTEGER RANGE 0 to 31;
    write_data: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
    reg_out_1: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    reg_out_2: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    write_enable: IN STD_LOGIC
);
END Register_file_decode;

ARCHITECTURE rtl OF Register_file_decode IS

TYPE REG IS ARRAY(31 downto 0) OF STD_LOGIC_VECTOR(31 downto 0);
signal registers: REG := (others => (others => '0'));

BEGIN

proc: process(clock)
begin
    if rising_edge(clock) then
        reg_out_1 <= registers(read_reg_1);
        reg_out_2 <= registers(read_reg_2);

        if(write_enable = '1' AND write_reg /= 0) then
            registers(write_reg) <= write_data;
        end if;
    end if;
end process proc;
END ARCHITECTURE rtl;

    