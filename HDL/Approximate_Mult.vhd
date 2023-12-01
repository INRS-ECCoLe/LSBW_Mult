library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_SIGNED.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_arith.ALL;
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity test is
    generic(BITWIDTH : integer:= 8;   -- total bit width if operands and result
            MANTISSA_WIDTH : integer := 3;
            PARTIAL_PRODUCT_WIDTH : integer:= 4;
            INOUT_BUF_EN : boolean:= True);
    Port ( a_i : in STD_LOGIC_VECTOR(BITWIDTH-1 downto 0);  -- Mult input 1
           b_i : in STD_LOGIC_VECTOR(BITWIDTH-1 downto 0);  -- Mult input 2
           c : in STD_LOGIC_VECTOR(BITWIDTH-3 downto 0);  -- Mult input 2
           d : in STD_LOGIC_VECTOR(BITWIDTH-1 downto 0);  -- Mult input 2
           clk, rst : in STD_LOGIC;
           result_o : out STD_LOGIC_VECTOR (BITWIDTH-1 downto 0)
           );
end test;

architecture Behavioral of test is
    signal a            : STD_LOGIC_VECTOR(BITWIDTH-1 downto 0);
    signal b            : STD_LOGIC_VECTOR(BITWIDTH-1 downto 0);
    signal result_temp  : STD_LOGIC_VECTOR(BITWIDTH downto 0);  -- Mult input 2
    signal ps1_term1    : STD_LOGIC_VECTOR(4 downto 0);
    signal ps1_term2    : STD_LOGIC_VECTOR(4 downto 0);
    signal ps1_term3    : STD_LOGIC_VECTOR(4 downto 0);
    signal ps1          : STD_LOGIC_VECTOR(4 downto 0);
    signal ps2_term1    : STD_LOGIC_VECTOR(5 downto 0);
    signal ps2_term2    : STD_LOGIC_VECTOR(5 downto 0);
    signal ps2_term3    : STD_LOGIC_VECTOR(5 downto 0);
    signal ps2          : STD_LOGIC_VECTOR(5 downto 0);
    signal ps3_term1    : STD_LOGIC_VECTOR(5 downto 0);
    signal ps3_term2    : STD_LOGIC_VECTOR(5 downto 0);
    signal ps3_term3    : STD_LOGIC_VECTOR(5 downto 0);
    signal ps3          : STD_LOGIC_VECTOR(5 downto 0);

    signal ps4_term1    : STD_LOGIC_VECTOR(5 downto 0);
    signal ps4_term2    : STD_LOGIC_VECTOR(5 downto 0);
    signal ps4_term3    : STD_LOGIC_VECTOR(5 downto 0);
    signal ps4          : STD_LOGIC_VECTOR(5 downto 0);

begin
    --result_o <= a + b + c;
    a <= a_i;
    b <= b_i;

    -- PS1
    ps1_term1   <= ("00" & not(a(5) and b(7)) & (a(5) and b(6)) & (a(5) and b(5))       );
    ps1_term2   <= ('0'  & not(a(6) and b(7)) & (a(6) and b(6)) & (a(6) and b(5)) & '0' );
    ps1_term3   <= (          (a(7) and b(7)) & (a(7) and b(6)) & (a(7) and b(5)) & "00");
    ps1         <= ps1_term1 + ps1_term2 + ps1_term3;

    --PS2
    ps2_term1   <= ("000" & not(a(2) and b(7)) & (a(2) and b(6)) & (a(2) and b(5))       );
    ps2_term2   <= ("00"  & not(a(3) and b(7)) & (a(3) and b(6)) & (a(3) and b(5)) & '0' );
    ps2_term3   <= ('0'   & not(a(4) and b(7)) & (a(4) and b(6)) & (a(4) and b(5)) & "00");
    ps2         <= ps2_term1 + ps2_term2 + ps2_term3;

    --PS3
    ps3_term1   <= ("000" & (a(5) and b(4)) & (a(5) and b(3)) & (a(5) and b(3)));
    ps3_term2   <= ("00"  & (a(6) and b(4)) & (a(6) and b(3)) & (a(6) and b(3)) & '0');
    ps3_term3   <= ('0'   & (a(7) and b(4)) & (a(7) and b(3)) & (a(7) and b(3)) & "00");
    ps3         <= ps3_term1 + ps3_term2 + ps3_term3;

    --PS4
    ps4_term1   <= ("000" & (a(2) and b(4)) & (a(2) and b(3)) & (a(2) and b(3)));
    ps4_term2   <= ("00"  & (a(3) and b(4)) & (a(3) and b(3)) & (a(3) and b(3)) & '0');
    ps4_term3   <= ('0'   & (a(4) and b(4)) & (a(4) and b(3)) & (a(4) and b(3)) & "00");
    ps4         <= ps4_term1 + ps4_term2 + ps4_term3;



    result_temp(7 downto 0) <= (ps1 & "000") + ("00" & ps2) + ("00" & ps3) + ("00000" & ps3(5 downto 3));

    result_o(6 downto 0) <= result_temp(7 downto 1);



    end Behavioral;