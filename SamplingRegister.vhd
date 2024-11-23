LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY SamplingRegister IS
GENERIC (g_NUM_CYCLES : INTEGER := 1250000);
PORT (
    i_Signal : IN STD_LOGIC;
    i_Clk : IN  STD_LOGIC;
    o_Output : OUT STD_LOGIC
);
END ENTITY;

ARCHITECTURE RTL OF SamplingRegister IS      
    CONSTANT c_TOTAL_CYCLES : INTEGER := 25000000;          
    SIGNAL r_Output : STD_LOGIC := '0'; 
BEGIN
    o_Output <= r_Output;
    
    p_SAMPLE_INPUT:
    PROCESS(i_Clk)   
        VARIABLE v_Counter : INTEGER RANGE 0 TO c_TOTAL_CYCLES := 0;              
        VARIABLE v_Enable_Read : STD_LOGIC := '1';
    BEGIN
        IF(RISING_EDGE(i_Clk)) THEN
            IF (v_Enable_Read = '1') THEN
                IF (i_Signal = '1') THEN
                    v_Enable_Read := '0';
                    v_Counter := 0;
                    r_Output <= '1';
                ELSE
                    r_Output <= '0';
                END IF;
            ELSE
                r_Output <= '0';
                IF (v_Counter < g_NUM_CYCLES) THEN
                    v_Counter := v_Counter + 1;
                ELSE
                    v_Enable_Read := '1';
                END IF;
            END IF;
        END IF;
    END PROCESS p_SAMPLE_INPUT;
END ARCHITECTURE;