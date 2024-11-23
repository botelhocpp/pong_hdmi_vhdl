LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY shift_register IS
GENERIC ( g_N : INTEGER := 10 );
PORT (
    i_Data_In : IN STD_LOGIC_VECTOR(g_N - 1 DOWNTO 0);
    i_Clk : IN STD_LOGIC;
    i_Data_Out : OUT STD_LOGIC
);
END shift_register;

ARCHITECTURE behav OF shift_register IS
    SIGNAL r_Data_Bits : STD_LOGIC_VECTOR(g_N - 1 DOWNTO 0);
BEGIN
    PROCESS (i_Clk)
        VARIABLE v_Iterator : INTEGER RANGE 0 TO g_N := 0;
    BEGIN
        IF (RISING_EDGE(i_Clk)) THEN
            v_Iterator := v_Iterator + 1;
            
            IF (v_Iterator = (g_N - 1)) THEN
                r_Data_Bits <= i_Data_In;
            ELSIF (v_Iterator = g_N) THEN
                v_Iterator := 0;
            END IF;
            
            i_Data_Out <= r_Data_Bits(v_Iterator);
        END IF;
    END PROCESS;
END behav;
