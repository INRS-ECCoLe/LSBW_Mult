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
--  Edge Computing, Communication and Learning Lab (ECCoLE) 
--
--  Author: Shervin Vakili, INRS University
--  Project: FP Multiplier 
--  Creation Date: 2023-11-12
--  Module Name: FP_Mult - Behavioral 
--  Description: Configurable floating-point multiplier
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use ieee.std_logic_arith.all; 
use ieee.std_logic_unsigned.all; 
--use ieee.std_logic_signed.all; 

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FP_Mult is
    generic(MANTISSA_WIDTH : integer:= 3;
            EXPONENT_WIDTH : integer:= 4;
            INOUT_BUF_EN : boolean:= True);
    Port ( a_i : in std_logic_vector(EXPONENT_WIDTH + MANTISSA_WIDTH downto 0);  -- Mult input 1
           b_i : in std_logic_vector(EXPONENT_WIDTH + MANTISSA_WIDTH downto 0);    -- Mult input 2
           clk, rst : in STD_LOGIC;
           
           result_o : out std_logic_vector (EXPONENT_WIDTH + MANTISSA_WIDTH downto 0)
           );
end FP_Mult;

architecture Behavioral of FP_Mult is
    signal a_buf : std_logic_vector(EXPONENT_WIDTH + MANTISSA_WIDTH downto 0);
    signal b_buf : std_logic_vector(EXPONENT_WIDTH + MANTISSA_WIDTH downto 0);
    signal a_mantissa :  std_logic_vector (MANTISSA_WIDTH-1 downto 0);
    signal b_mantissa :  std_logic_vector (MANTISSA_WIDTH-1 downto 0);
    signal a_exponent :  std_logic_vector (EXPONENT_WIDTH-1 downto 0);
    signal b_exponent :  std_logic_vector (EXPONENT_WIDTH-1 downto 0);
    signal result_mantissa :  std_logic_vector (2 * MANTISSA_WIDTH-1 downto 0);
    signal result_exponent :  std_logic_vector (EXPONENT_WIDTH downto 0);
    signal result_sign : std_logic;

begin
    a_mantissa <= a_buf(MANTISSA_WIDTH-1 downto 0);
    b_mantissa <= b_buf(MANTISSA_WIDTH-1 downto 0);
    a_exponent <= a_buf(MANTISSA_WIDTH+EXPONENT_WIDTH-1 downto MANTISSA_WIDTH);
    b_exponent <= b_buf(MANTISSA_WIDTH+EXPONENT_WIDTH-1 downto MANTISSA_WIDTH);
    
    result_mantissa <= a_mantissa * b_mantissa;
    result_exponent <= a_exponent + b_exponent;
    result_sign <= a_buf(EXPONENT_WIDTH + MANTISSA_WIDTH) xor b_buf(EXPONENT_WIDTH + MANTISSA_WIDTH);
    
    INOUT_BUF_ENABLE: if INOUT_BUF_EN=True generate
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                result_o <= (others => '0');
            else
                a_buf <= a_i;
                b_buf <= b_i;
                result_o <= (result_sign & result_exponent(EXPONENT_WIDTH downto 1) & result_mantissa(2 * MANTISSA_WIDTH-1 downto MANTISSA_WIDTH));
             end if;
        end if;
    end process;
    end generate;

    INOUT_BUF_DISABLE: if INOUT_BUF_EN=False generate
        result_o <= (result_sign & result_exponent(EXPONENT_WIDTH downto 1) & result_mantissa(2 * MANTISSA_WIDTH-1 downto MANTISSA_WIDTH));
        a_buf <= a_i;
        b_buf <= b_i;
    end generate;


end Behavioral;
