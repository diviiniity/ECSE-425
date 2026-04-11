
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cpu_package.all;

entity Imm_extension_decode is
    port (
        imm_in  : in  std_logic_vector(24 downto 0); -- 25-bit immediate field
        imm_src : in  IMM_SRC_TYPE_t;  -- 3-bit selector for type
        imm_out : out std_logic_vector(31 downto 0)  -- sign-extended or shifted immediate
    );
end Imm_extension_decode;

architecture Behavioral of Imm_extension_decode is

begin

     process(imm_in, imm_src)
     begin
       case imm_src is
         when IMM_I_TYPE => -- I-type 00 {{20{Instr[31]}}, Instr[31:20]} 8 bw b 3 0I 12-bit signed immediate
           imm_out <= std_logic_vector(resize(signed(imm_in(24 downto 13)),32));
         when IMM_S_TYPE => -- S-type 01 {{20{Instr[31]}}, Instr[31:25], Instr[11:7]} S 12-bit signed immediate
           imm_out <= std_logic_vector(resize(signed(std_logic_vector'(imm_in(24 downto 18) & imm_in(4 downto 0))),32));
         when IMM_B_TYPE => -- B-type 10 {{20{Instr[31]}}, Instr[7], Instr[30:25], Instr[11:8], 1’b0} B 13-bit signed immediate
           imm_out <= (19 downto 0 => imm_in(24)) & imm_in(0) & imm_in(23 downto 18) & imm_in(4 downto 1)& '0';
         when IMM_J_TYPE => -- J-type 11 {{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[30:21], 1'b0} J 21-bit signed immediate
           imm_out <= (11 downto 0 => imm_in(24)) & imm_in(12 downto 5) & imm_in(13) & imm_in(23 downto 14) & '0';
         when IMM_U_TYPE => -- U-type
           imm_out <= imm_in(24 downto 5) & (11 downto 0 => '0'); -- 20-bit immediate for LUI and AUIPC
         when others =>
           imm_out <= (others => '0');
       end case;
     end process;

end Behavioral;