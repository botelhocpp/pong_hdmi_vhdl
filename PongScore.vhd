LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 
LIBRARY WORK;
USE WORK.PongPkg.ALL;
USE WORK.HdmiPkg.ALL;
 
ENTITY PongScore IS
GENERIC ( g_SCORE_X : INTEGER );
PORT (
    i_Clk : IN STD_LOGIC;
    i_Video_Enable : IN STD_LOGIC;
    i_Col_Count : IN INTEGER RANGE 0 TO c_H_MAX;
    i_Row_Count : IN INTEGER RANGE 0 TO c_V_MAX;
    i_Score : IN INTEGER RANGE 0 TO c_SCORE_LIMIT;
    o_Draw_Score : OUT STD_LOGIC
);
END ENTITY;

ARCHITECTURE RTL OF PongScore IS
    -- Wires 
    SIGNAL w_Row_Select : INTEGER RANGE 0 TO c_SCORE_HEIGHT := 0;
    SIGNAL w_Char_Row : STD_LOGIC_VECTOR(c_SCORE_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    
    -- Registers
    SIGNAL r_Score : INTEGER RANGE 0 TO c_SCORE_LIMIT := 0;
    SIGNAL r_Draw_Score : STD_LOGIC := '0';
BEGIN
    e_CHARACTER_ROM: ENTITY WORK.CharacterRom
    PORT MAP (
        i_Clk => i_Clk,
        i_Char_Select => r_Score,
        i_Row_Select => w_Row_Select,
        o_Char_Row => w_Char_Row
    );
    
    p_LOAD_SCORE:
    PROCESS(i_Clk)
    BEGIN
        IF(RISING_EDGE(i_Clk)) THEN
            IF(w_Row_Select = 0) THEN
                r_Score <= i_Score;
            END IF;
        END IF;
    END PROCESS p_LOAD_SCORE;
    
    p_DRAW_SCORE:
    PROCESS(i_Clk)
        VARIABLE v_Col_Select : INTEGER RANGE 0 TO c_SCORE_WIDTH := 0;
        VARIABLE v_Previous_Row_Count : INTEGER RANGE 0 TO c_V_MAX := i_Row_Count;
    BEGIN
        IF(i_Video_Enable = '1') THEN
            v_Col_Select := i_Col_Count - g_SCORE_X;
            w_Row_Select <= i_Row_Count - c_SCORE_Y_POS;
        ELSE
            v_Col_Select := 0;
            w_Row_Select <= 0;
        END IF;
    
        IF(RISING_EDGE(i_Clk)) THEN
            IF(
                i_Video_Enable = '1' AND
                g_SCORE_X <= i_Col_Count AND 
                g_SCORE_X + c_SCORE_WIDTH > i_Col_Count AND
                c_SCORE_Y_POS <= i_Row_Count AND 
                c_SCORE_Y_POS + c_SCORE_HEIGHT > i_Row_Count AND
                w_Char_Row(c_SCORE_WIDTH - v_Col_Select - 1) = '1'
            ) THEN
                r_Draw_Score <= '1';
            ELSE
                r_Draw_Score <= '0';
            END IF;
        END IF;
    END PROCESS p_DRAW_SCORE;
    
    o_Draw_Score <= r_Draw_Score;
END ARCHITECTURE;
