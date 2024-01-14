---------------------------------------------------------------------------------------------------
--                __________
--    ______     /   ________      _          ______
--   |  ____|   /   /   ______    | |        |  ____|
--   | |       /   /   /      \   | |        | |
--   | |____  /   /   /        \  | |        | |____
--   |  ____| \   \   \        /  | |        |  ____|   
--   | |       \   \   \______/   | |        | |
--   | |____    \   \________     | |_____   | |____
--   |______|    \ _________      |_______|  |______|
--
--  ECCoLe: Edge Computing, Communication and Learning Lab 
--
--  Author: Shervin Vakili, INRS University
--  Project: Internal Float Approximate Multiplier
--  Creation Date: 2023-11-21
--  Description: Testbench for INT8 Multiplier
------------------------------------------------------------------------------------------------


library IEEE;
library std;
use std.env.all;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_signed.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_arith.all;
use std.textio.all;
use ieee.math_real.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TB_Mult_INT8 is
--  Port ( );
end TB_Mult_INT8;

architecture Behavioral of TB_Mult_INT8 is
    constant BITWIDTH : integer := 8;
    constant clk_period : time := 10 ns;
    signal a_count: unsigned (BITWIDTH-1 downto 0);
    signal b_count: unsigned (BITWIDTH-1 downto 0);
    signal result: std_logic_vector (14 downto 0);
    signal result_signed: signed (14 downto 0);
    signal clk, rst         : STD_LOGIC;
    file output_lut_file    : text open write_mode is "../Emulation_Files/LUT_INT8_FP.h";    


    component approximate_mult is
        generic(REFINEMENT_PART : INTEGER:= 3;   -- which solution (part of partial products) to be used for accuracy refinement
                INOUT_BUF_EN : BOOLEAN:= True);
        Port ( a_i : in STD_LOGIC_VECTOR(7 downto 0);  -- Mult input 1
               b_i : in STD_LOGIC_VECTOR(7 downto 0);  -- Mult input 2
               clk, rst : in STD_LOGIC;
               result_o : out STD_LOGIC_VECTOR (14 downto 0)
               );
    end component;

    component Mult_FL_E2 is
        generic(BITWIDTH : integer:= 8;   -- total bit width if operands and result
                MANTISSA_WIDTH : integer := 3;
                PARTIAL_PRODUCT_WIDTH : integer:= 3;
                INOUT_BUF_EN : boolean:= True);
        Port ( a_i : in STD_LOGIC_VECTOR(BITWIDTH-1 downto 0);  -- Mult input 1
               b_i : in STD_LOGIC_VECTOR(BITWIDTH-1 downto 0);  -- Mult input 2
               clk, rst : in STD_LOGIC;
               result_o : out STD_LOGIC_VECTOR (BITWIDTH-1 downto 0)
               );
    end component;

begin

    clk_process :process
		begin
			clk <= '0';
			wait for clk_period/2;  --for 0.5 ns signal is '0'.
			clk <= '1';
			wait for clk_period/2;  --for next 0.5 ns signal is '1'.
		end process;				
	rst <=  '1' , '0' after 4 * clk_period;

    process(clk)    
        
        variable row                : line;
        variable result_normalized  : integer;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                a_count <= (others => '0');
                b_count <= (others => '0');
            else
                result_normalized := conv_integer(result_signed) ;
                if (conv_integer(a_count) = 0 and conv_integer(b_count) = 0) then
                    write(row,string'("#include <stdint.h>"), left, 1);
                    writeline(output_lut_file, row);
                    writeline(output_lut_file, row);                
                    write(row,string'("const int16_t lut [256][256] = {"), left, 1);
                    writeline(output_lut_file, row);
                    write(row,string'("{ "), left, 1);
                end if;
                if (conv_integer(a_count) = 2**BITWIDTH-1) then
                    a_count <= (others => '0');
                    if (conv_integer(b_count) = 2**BITWIDTH-1) then
                        write(row,result_normalized, left, 1);
                        write(row,string'("}}; "), left, 1);
                        writeline(output_lut_file, row);
                        file_close(output_lut_file);
                        finish;
                    else
                        b_count <= b_count + 1;
                        a_count <= a_count + 1;
                        write(row,result_normalized, left, 1);
                        write(row,string'("}, "), left, 1);
                        writeline(output_lut_file, row);
                        write(row,string'("{ "), left, 1);
                    end if;
                else
                    a_count <= a_count + 1;
                    write(row, result_normalized, left, 1);
                    write(row,string'(", "), left, 1);
                end if;
                

            end if;
        end if;
    end process;


    MUL_INST: approximate_mult
        generic map (REFINEMENT_PART => 0,   -- which solution (part of partial products) to be used for accuracy refinement
                    INOUT_BUF_EN => True)
        Port map( a_i => std_logic_vector(a_count),  -- Mult input 1
               b_i => std_logic_vector(b_count),  -- Mult input 2
               clk => clk,
               rst => rst,
               result_o => result
               );

    result_signed <= signed(result);



end Behavioral;
