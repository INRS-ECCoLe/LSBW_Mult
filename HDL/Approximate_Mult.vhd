library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_SIGNED.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_arith.ALL;
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity approximate_mult is
    generic(REFINEMENT_PART : INTEGER:= 3;   -- which solution (part of partial products) to be used for accuracy refinement
            ADD_BIAS : BOOLEAN:= True;
            INOUT_BUF_EN : BOOLEAN:= True);
    Port ( a_i : in STD_LOGIC_VECTOR(7 downto 0);  -- Mult input 1
           b_i : in STD_LOGIC_VECTOR(7 downto 0);  -- Mult input 2
           clk, rst : in STD_LOGIC;
           result_o : out STD_LOGIC_VECTOR (7 downto 0)
           );
end approximate_mult;

architecture Behavioral of approximate_mult is
    signal a            : STD_LOGIC_VECTOR(7 downto 0);
    signal b            : STD_LOGIC_VECTOR(7 downto 0);
    signal result_temp  : STD_LOGIC_VECTOR(8 downto 0);  -- Mult input 2
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
    ps1         <= ps1_term1 + ps1_term2 + ps1_term3 ;

    --PS2
    ps2_term1   <= ("000" & not(a(2) and b(7)) & (a(2) and b(6)) & (a(2) and b(5))       );
    ps2_term2   <= ("00"  & not(a(3) and b(7)) & (a(3) and b(6)) & (a(3) and b(5)) & '0' );
    ps2_term3   <= ('0'   & not(a(4) and b(7)) & (a(4) and b(6)) & (a(4) and b(5)) & "00");
    ps2         <= ps2_term1 + ps2_term2 + ps2_term3 + "00010";

    --PS3
    ps3_term1   <= ("000" & (a(5) and b(4)) & (a(5) and b(3)) & (a(5) and b(2))         );
    ps3_term2   <= ("00"  & (a(6) and b(4)) & (a(6) and b(3)) & (a(6) and b(2)) & '0'   );
    ps3_term3   <= ('0'   & (a(7) and b(4)) & (a(7) and b(3)) & (a(7) and b(2)) & "00"  );
    ps3         <= ps3_term1 + ps3_term2 + ps3_term3;

    --PS4
    PS4_0: if REFINEMENT_PART = 0 generate
        ps4 <= (others => '0');
    end generate;
    PS4_1: if REFINEMENT_PART = 1 generate
        ps4_term1   <= ("00" & not(a(0) and b(7)) & (a(0) and b(6)) & (a(0) and b(5)) & (a(0) and b(4))         );
        ps4_term2   <= ('0'  & not(a(1) and b(7)) & (a(1) and b(6)) & (a(1) and b(5)) & (a(1) and b(4)) & '0'   );
        WITH_BIAS: if ADD_BIAS = True generate
            ps4         <= ps4_term1 + ps4_term2 + "110010";
        end generate;
        NO_BIAS: if ADD_BIAS = False generate
            ps4         <= ps4_term1 + ps4_term2;
        end generate;
    end generate;
    
    PS4_2: if REFINEMENT_PART = 2 generate
        ps4_term1   <= ("000" & (a(2) and b(4)) & (a(2) and b(3)) & (a(2) and b(2)));
        ps4_term2   <= ("00"  & (a(3) and b(4)) & (a(3) and b(3)) & (a(3) and b(2)) & '0'   );
        ps4_term3   <= ('0'   & (a(4) and b(4)) & (a(4) and b(3)) & (a(4) and b(2)) & "00"  );
        ps4         <= ps4_term1 + ps4_term2 + ps4_term3;
        WITH_BIAS: if ADD_BIAS = True generate
            ps4         <= ps4_term1 + ps4_term2 + "110000";
        end generate;
        NO_BIAS: if ADD_BIAS = False generate
            ps4         <= ps4_term1 + ps4_term2;
        end generate;
    end generate;
    PS4_3: if REFINEMENT_PART = 3 generate
        ps4_term1   <= ('0' & (a(4) and b(4)) & (a(4) and b(3)) & "000");
        ps4_term2   <= ('0' & (a(7) and b(1)) & (a(7) and b(0)) & "000");
        ps4         <= ps4_term1 + ps4_term2;
        WITH_BIAS: if ADD_BIAS = True generate
            ps4         <= ps4_term1 + ps4_term2 + "110000";
        end generate;
        NO_BIAS: if ADD_BIAS = False generate
            ps4         <= ps4_term1 + ps4_term2;
        end generate;
    end generate;




    result_temp(7 downto 0) <= (ps1 & "000") + ("00" & ps2) + ("00" & ps3) + ("00000" & ps4(5 downto 3));

    result_o(6 downto 0) <= result_temp(7 downto 1);
    result_o(7) <= a(7) xor b(7);



    end Behavioral;