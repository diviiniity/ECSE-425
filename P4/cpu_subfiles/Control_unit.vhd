library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cpu_package.ALL;  

entity Control_unit_ is
    port (
        -- Inputs
        op_code   : in  std_logic_vector(6 downto 0);  -- Renamed to avoid conflict
        funct3    : in  std_logic_vector(2 downto 0);
        funct7    : in  std_logic_vector(6 downto 0);
        -- Outputs
        RAM_write : out std_logic;
        RAM_read : out std_logic;
        ALU_control : out ALU_CONTROL_TYPE_t;
        ALU_src_regA : out EXECUTE_OPERAND_A_SRC_TYPE_t;
        ALU_src_regB : out EXECUTE_OPERAND_B_SRC_TYPE_t;
        Imm_src : out IMM_SRC_TYPE_t;
        dst_reg_write_en : out std_logic;
        wb_data_sel : out WRITE_BACK_SRC_TYPE_t;
        is_jump : out std_logic 
    );
end Control_unit_;

architecture Behavioral of Control_unit_ is

signal ALU_op : ALU_OP_TYPE_t;
signal op_type : CONTROL_UNIT_OP_TYPE_t;  

begin

    -- Convert 7-bit opcode to ALU_OP_TYPE_t
    opcode_decode : process(op_code)  -- Use op_code in sensitivity list
    begin
        case op_code is  -- Use op_code in case statement
            when OP_R_TYPE_CODE =>
                op_type <= OP_R_TYPE;
            when OP_I_TYPE_CODE =>
                op_type <= OP_I_TYPE;
            when OP_LOAD_CODE =>
                op_type <= OP_LOAD;
            when OP_STORE_CODE =>
                op_type <= OP_STORE;
            when OP_BRANCH_CODE =>
                op_type <= OP_BRANCH;
            when OP_JAL_CODE =>
                op_type <= OP_JAL;
            when OP_JALR_CODE =>
                op_type <= OP_JALR;
            when OP_LUI_CODE =>
                op_type <= OP_LUI;
            when OP_AUIPC_CODE =>
                op_type <= OP_AUIPC;
            when others =>
                op_type <= OP_R_TYPE;
        end case;
    end process opcode_decode;
    
   ALU_decoder : entity work.ALU_decoder_CU(Behavioral)
        port map(
            op_bit5 => op_code(5),  -- Use op_code here
            funct3 => funct3,
            funct7_bit5 => funct7(5),
            funct7_bit0 => funct7(0),
            ALU_op => ALU_op,
            ALU_control => ALU_control
        ); 
        
    Main_decoder : entity work.Main_decoder_(Behavioral)
        port map(
            op_type => op_type,  -- Use op_type here       
            RAM_write => RAM_write,
            RAM_read => RAM_read,
            ALU_src_regA => ALU_src_regA,
            ALU_src_regB => ALU_src_regB,
            Imm_src => Imm_src,
            dst_reg_write_en => dst_reg_write_en,
            ALU_op => ALU_op,
            wb_data_sel => wb_data_sel,
            is_jump => is_jump
        );

end Behavioral;