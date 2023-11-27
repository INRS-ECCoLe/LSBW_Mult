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
--  Project: Internal Float Approximate Multiplier
--  Creation Date: 2023-11-16
--  Module Name: Mult_FL_E2 - Behavioral 
--  Description: INT8 multiplier with internal float approximation with exponent of 2 bits
---------------------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_SIGNED.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_arith.ALL;
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Mult_FL_E2 is
    generic(BITWIDTH : integer:= 8;   -- total bit width if operands and result
            MANTISSA_WIDTH : integer := 3;
            PARTIAL_PRODUCT_WIDTH : integer:= 4;
            INOUT_BUF_EN : boolean:= True);
    Port ( a_i : in STD_LOGIC_VECTOR(BITWIDTH-1 downto 0);  -- Mult input 1
           b_i : in STD_LOGIC_VECTOR(BITWIDTH-1 downto 0);  -- Mult input 2
           clk, rst : in STD_LOGIC;
           result_o : out STD_LOGIC_VECTOR (BITWIDTH-1 downto 0)
           );
end Mult_FL_E2;

architecture Behavioral of Mult_FL_E2 is
    constant ZERO_VEC: STD_LOGIC_VECTOR (BITWIDTH-1 downto 0):= (others => '0');
    constant EXPONENT_WIDTH: INTEGER := 2;
    type PARTIAL_SUM_ARRAY_T is array (0 to 2**(EXPONENT_WIDTH+1)) of STD_LOGIC_VECTOR(2*MANTISSA_WIDTH-1 downto 0);
    signal partial_sum_array : PARTIAL_SUM_ARRAY_T := (others => (others => '0'));
    signal decoded_result_t : STD_LOGIC_VECTOR(2**(EXPONENT_WIDTH+1) + PARTIAL_PRODUCT_WIDTH - 3 downto 0);

    signal decoded_mult_res : STD_LOGIC_VECTOR (BITWIDTH-2 downto 0);
    signal a_mantissa : STD_LOGIC_VECTOR (MANTISSA_WIDTH-1 downto 0);
    signal a_mantissa_t : STD_LOGIC_VECTOR (MANTISSA_WIDTH-1 downto 0);
    signal a_exponent : STD_LOGIC_VECTOR (EXPONENT_WIDTH-1 downto 0);
    signal a_carry : STD_LOGIC;
    signal a_buf : STD_LOGIC_VECTOR (BITWIDTH-1 downto 0);
    signal b_mantissa : STD_LOGIC_VECTOR (MANTISSA_WIDTH-1 downto 0);
    signal b_mantissa_t : STD_LOGIC_VECTOR (MANTISSA_WIDTH-1 downto 0);
    signal b_exponent : STD_LOGIC_VECTOR (EXPONENT_WIDTH-1 downto 0);
    signal b_carry : STD_LOGIC;
    signal b_buf : STD_LOGIC_VECTOR (BITWIDTH-1 downto 0);
    signal exponent_sum : STD_LOGIC_VECTOR (EXPONENT_WIDTH downto 0);
    signal mantissa_product : STD_LOGIC_VECTOR (2*MANTISSA_WIDTH-1 downto 0);
    
begin

    decoded_mult_res <= decoded_result_t(2**(EXPONENT_WIDTH+1) + PARTIAL_PRODUCT_WIDTH - 3 downto 2**(EXPONENT_WIDTH+1) + PARTIAL_PRODUCT_WIDTH - BITWIDTH - 1);

    INOUT_BUFS: if INOUT_BUF_EN = True generate
    process(clk)
        begin
            if rising_edge(clk) then
                if rst = '1' then
                    result_o <= (others => '0');
                else
                    a_buf <= a_i;
                    b_buf <= b_i;
                    if (a_buf(7) xor b_buf(7)) = '0' then
                        result_o <= ZERO_VEC + (decoded_mult_res);
                    else
                        result_o <= ZERO_VEC - (decoded_mult_res);
                    end if;
    
                end if;
            end if;
        end process;
        end generate;
        
        NO_INOUT_BUFS: if INOUT_BUF_EN = False generate
        a_buf <= a_i;
        b_buf <= b_i;
        result_o <= ('0' & decoded_mult_res) when (a_buf(7) xor b_buf(7)) = '0' else ZERO_VEC - (decoded_mult_res);   
        end generate;
        
        -- Encoder (Fixed-to-Float convert)
        a_exponent <= "11" when a_buf(BITWIDTH-1 downto BITWIDTH-2)="01" or  a_buf(BITWIDTH-1 downto BITWIDTH-2)="10" else
                      "10" when a_buf(BITWIDTH-1 downto BITWIDTH-3)="001" or  a_buf(BITWIDTH-1 downto BITWIDTH-3)="110" else
                      "01" when a_buf(BITWIDTH-1 downto BITWIDTH-4)="0001" or  a_buf(BITWIDTH-1 downto BITWIDTH-4)="1110" else
                      "00";
                    
        a_mantissa_t <= a_buf(BITWIDTH-2 downto BITWIDTH-MANTISSA_WIDTH-1) when a_exponent = "11" else
                        a_buf(BITWIDTH-3 downto BITWIDTH-MANTISSA_WIDTH-2) when a_exponent = "10" else
                        a_buf(BITWIDTH-4 downto BITWIDTH-MANTISSA_WIDTH-3) when a_exponent = "01" else
                        a_buf(BITWIDTH-5 downto BITWIDTH-MANTISSA_WIDTH-4);

        a_mantissa <= a_mantissa_t when a_buf(7) = '0' else (not a_mantissa_t + a_carry);
        
        a_carry <= '0' when a_mantissa_t = ZERO_VEC(MANTISSA_WIDTH-1 downto 0) else '1';

        b_exponent <=   "11" when b_buf(BITWIDTH-1 downto BITWIDTH-2)="01" or  b_buf(BITWIDTH-1 downto BITWIDTH-2)="10" else
                        "10" when b_buf(BITWIDTH-1 downto BITWIDTH-3)="001" or  b_buf(BITWIDTH-1 downto BITWIDTH-3)="110" else
                        "01" when b_buf(BITWIDTH-1 downto BITWIDTH-4)="0001" or  b_buf(BITWIDTH-1 downto BITWIDTH-4)="1110" else
                        "00";
        
        b_mantissa_t <= b_buf(BITWIDTH-2 downto BITWIDTH-MANTISSA_WIDTH-1) when b_exponent = "11" else
                        b_buf(BITWIDTH-3 downto BITWIDTH-MANTISSA_WIDTH-2) when b_exponent = "10" else
                        b_buf(BITWIDTH-4 downto BITWIDTH-MANTISSA_WIDTH-3) when b_exponent = "01" else
                        b_buf(BITWIDTH-5 downto BITWIDTH-MANTISSA_WIDTH-4);

        b_mantissa <= b_mantissa_t when b_buf(7) = '0' else (not b_mantissa_t + b_carry);

        b_carry <= '0' when b_mantissa_t = ZERO_VEC(MANTISSA_WIDTH-1 downto 0) else '1';

        -- Mantissa Multiplication
        mantissa_product <= a_mantissa * b_mantissa;

        -- Add exponents
        exponent_sum <= ('0' & a_exponent) + ('0' & b_exponent);


        
        -- Decoder (Float-to-Fixed convert)
        process(mantissa_product, exponent_sum)
        begin
            decoded_result_t <= (others => '0');
            for ii in 0 to 2**(EXPONENT_WIDTH+1)-2 loop
                if ii = conv_integer(exponent_sum) then
                    decoded_result_t (ii + PARTIAL_PRODUCT_WIDTH -1 downto ii) <= mantissa_product(2*MANTISSA_WIDTH-1 downto 2*MANTISSA_WIDTH - PARTIAL_PRODUCT_WIDTH);
                end if;
            end loop;
        end process;

--        decoded_mult_res <= (     mantissa_product(2*MANTISSA_WIDTH-1 downto 3) & "0000000")   when exponent_sum = "110" else
--                            ('0' & mantissa_product(2*MANTISSA_WIDTH-1 downto 3) & "000000")   when exponent_sum = "101" else
--                            ("00" & mantissa_product(2*MANTISSA_WIDTH-1 downto 3) & "00000")   when exponent_sum = "100" else
--                            ("000" & mantissa_product(2*MANTISSA_WIDTH-1 downto 3) & "0000")   when exponent_sum = "011" else
--                            ("0000" & mantissa_product(2*MANTISSA_WIDTH-1 downto 3) & "000")   when exponent_sum = "010" else
--                            ("00000" & mantissa_product(2*MANTISSA_WIDTH-1 downto 3) & "00")   when exponent_sum = "001" else
--                            ("000000" & mantissa_product(2*MANTISSA_WIDTH-1 downto 3) & "0");
    
end Behavioral;
















--entity mult_int8_fl_1_2_3 is
--    generic(LENGTH : integer:= 8;
--            INOUT_BUF_EN : boolean:= True);
--    Port ( a_i : in STD_LOGIC_VECTOR(LENGTH-1 downto 0);  -- Mult input 1
--           b_i : in STD_LOGIC_VECTOR(LENGTH-1 downto 0);  -- Mult input 2
--           clk, rst : in STD_LOGIC;
--           result_o : out STD_LOGIC_VECTOR (10 downto 0)
--           );
--end mult_int8_fl_1_2_3;

--architecture Behavioral of mult_int8_fl_1_2_3 is
--    constant ZERO_VEC: STD_LOGIC_VECTOR (10 downto 0):= (others => '0');
--    signal mult_result : STD_LOGIC_VECTOR (4 downto 0);
--    signal mult_result_s : STD_LOGIC_VECTOR (4 downto 0);
--    signal mult_result_p : STD_LOGIC_VECTOR (4 downto 0);
--    signal decoded_mult_res : STD_LOGIC_VECTOR (9 downto 0);
--    signal wr_conf_s : STD_LOGIC;
--    signal wr_conf_p : STD_LOGIC;
--    signal c_sign : STD_LOGIC; -- sign bit of the coeficient
--    signal a_mantissa : STD_LOGIC_VECTOR (2 downto 0);
--    signal a_mantissa_t : STD_LOGIC_VECTOR (2 downto 0);
--    signal a_exponent : STD_LOGIC_VECTOR (1 downto 0);
--    signal a_carry : STD_LOGIC;
--    signal a_buf : STD_LOGIC_VECTOR (LENGTH-1 downto 0);
--    signal b_mantissa : STD_LOGIC_VECTOR (2 downto 0);
--    signal b_mantissa_t : STD_LOGIC_VECTOR (2 downto 0);
--    signal b_exponent : STD_LOGIC_VECTOR (1 downto 0);
--    signal b_carry : STD_LOGIC;
--    signal b_buf : STD_LOGIC_VECTOR (LENGTH-1 downto 0);
--    signal exponent_sum : STD_LOGIC_VECTOR (2 downto 0);
--    signal mantissa_product : STD_LOGIC_VECTOR (5 downto 0);
    
--begin

--    INOUT_BUFS: if INOUT_BUF_EN = True generate
--    process(clk)
--        begin
--            if rising_edge(clk) then
--                if rst = '1' then
--                    result_o <= (others => '0');
--                else
--                    a_buf <= a_i;
--                    b_buf <= b_i;
--                    if (a_buf(7) xor b_buf(7)) = '0' then
--                        result_o <= ZERO_VEC + (decoded_mult_res);
--                    else
--                        result_o <= ZERO_VEC - (decoded_mult_res);
--                    end if;
    
--                end if;
--            end if;
--        end process;
--        end generate;
        
--        NO_INOUT_BUFS: if INOUT_BUF_EN = False generate
--        a_buf <= a_i;
--        b_buf <= b_i;
--        result_o <= ('0' & decoded_mult_res) when (a_buf(7) xor b_buf(7)) = '0' else ZERO_VEC - (decoded_mult_res);   
--        end generate;
        
--        -- Encoder (Fixed-to-Float convert)
--        a_exponent <= "11" when a_buf(7 downto 6)="01" or  a_buf(7 downto 6)="10" else
--                      "10" when a_buf(7 downto 5)="001" or  a_buf(7 downto 5)="110" else
--                      "01" when a_buf(7 downto 4)="0001" or  a_buf(7 downto 5)="1110" else
--                      "00";
                    
--        a_mantissa_t <= a_buf(6 downto 4) when a_exponent = "11" else
--                        a_buf(5 downto 3) when a_exponent = "10" else
--                        a_buf(4 downto 2) when a_exponent = "01" else
--                        a_buf(3 downto 1);

--        a_mantissa <= a_mantissa_t when a_buf(7) = '0' else (not a_mantissa_t - a_carry);
        
--        a_carry <= '0' when a_mantissa_t="000" else '1';

--        b_exponent <=   "10" when b_buf(7 downto 6)="01" or  b_buf(7 downto 6)="10" else
--                        "10" when b_buf(7 downto 5)="001" or  b_buf(7 downto 5)="110" else
--                        "01" when b_buf(7 downto 4)="0001" or  b_buf(7 downto 5)="1110" else
--                        "00";
        
--        b_mantissa_t <= b_buf(6 downto 4) when b_exponent = "11" else
--                        b_buf(5 downto 3) when b_exponent = "10" else
--                        b_buf(4 downto 2) when b_exponent = "01" else
--                        b_buf(3 downto 1);

--        b_mantissa <= b_mantissa_t when b_buf(7) = '0' else (not b_mantissa_t - b_carry);

--        b_carry <= '0' when b_mantissa_t="000" else '1';

--        -- Mantissa Multiplication
--        mantissa_product <= a_mantissa * b_mantissa;

--        -- Add exponents
--        exponent_sum <= ('0'&a_exponent) + ('0'&b_exponent);
        
--        -- Decoder (Float-to-Fixed convert)
--        decoded_mult_res <= (     mantissa_product(5 downto 3) & "0000000")   when exponent_sum = "110" else
--                            ('0' & mantissa_product(5 downto 3) & "000000")   when exponent_sum = "101" else
--                            ("00" & mantissa_product(5 downto 3) & "00000")   when exponent_sum = "100" else
--                            ("000" & mantissa_product(5 downto 3) & "0000")   when exponent_sum = "011" else
--                            ("0000" & mantissa_product(5 downto 3) & "000")   when exponent_sum = "010" else
--                            ("00000" & mantissa_product(5 downto 3) & "00")   when exponent_sum = "001" else
--                            ("000000" & mantissa_product(5 downto 3) & "0");
    
--end Behavioral;

