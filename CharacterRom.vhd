LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
USE WORK.PongPkg.ALL;

ENTITY CharacterRom IS
PORT (
    i_Clk : IN STD_LOGIC;
    i_Char_Select : IN INTEGER RANGE 0 TO c_SCORE_LIMIT; 
    i_Row_Select : IN INTEGER RANGE 0 TO c_SCORE_HEIGHT - 1;
    o_Char_Row : OUT STD_LOGIC_VECTOR(c_SCORE_WIDTH - 1 DOWNTO 0)
);
END ENTITY;

ARCHITECTURE RTL OF CharacterRom IS
    TYPE t_Rom IS ARRAY (0 TO c_SCORE_LIMIT, 0 TO c_SCORE_HEIGHT - 1) OF STD_LOGIC_VECTOR(c_SCORE_WIDTH - 1 DOWNTO 0);
        
    CONSTANT c_CHAR_ROM : t_Rom := (
        -- Number 0
        ( "111", 
          "101", 
          "101", 
          "101", 
          "111"
        ),
        -- Number 1
        ( "010",
          "110",
          "010",
          "010",
          "111"
        ),
        -- Number 2
        ( "111",
          "001",
          "111",
          "100",
          "111"
        ),
        -- Number 3
        ( "111",
          "001",
          "111",
          "001",
          "111"
        ),
        -- Number 4
        ( "101",
          "101",
          "111",
          "001",
          "001"
        ),
        -- Number 5
        ( "111",
          "100",
          "111",
          "001",
          "111"
        ),
        -- Number 6
        ( "111",
          "100",
          "111",
          "101",
          "111"
        ),
        -- Number 7
        ( "111",
          "001",
          "001",
          "001",
          "001"
        ),
        -- Number 8
        ( "111",
          "101",
          "111",
          "101",
          "111"
        ),
        -- Number 9
        ( "111",
          "101",
          "111",
          "001",
          "111"
        )
    );
BEGIN
    PROCESS(i_Clk)
    BEGIN
        IF (RISING_EDGE(i_Clk)) THEN
            o_Char_Row <= c_CHAR_ROM(i_Char_Select, i_Row_Select);
        END IF;
    END PROCESS;
END ARCHITECTURE;
