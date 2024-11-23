LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 
LIBRARY WORK;
USE WORK.PongPkg.ALL;
USE WORK.HdmiPkg.ALL;
 
ENTITY PongBall IS
PORT (
    i_Clk           : IN STD_LOGIC;
    i_Game_Active   : IN STD_LOGIC;
    i_Col_Count     : IN INTEGER RANGE 0 TO c_H_MAX;
    i_Row_Count     : IN INTEGER RANGE 0 TO c_V_MAX;
    --
    o_Draw_Ball     : OUT STD_LOGIC;
    o_Ball_X        : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    o_Ball_Y        : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
);
END ENTITY;
 
ARCHITECTURE RTL OF PongBall IS  
  SIGNAL r_Ball_Count : INTEGER RANGE 0 TO c_Ball_Speed := 0;
   
  -- X and Y location (Col, Row) for Pong Ball, also Previous Locations
  SIGNAL r_Ball_X      : INTEGER RANGE 0 TO c_H_MAX := 0;
  SIGNAL r_Ball_Y      : INTEGER RANGE 0 TO c_V_MAX := 0;
  SIGNAL r_Ball_X_Prev : INTEGER RANGE 0 TO c_H_MAX := 0;
  SIGNAL r_Ball_Y_Prev : INTEGER RANGE 0 TO c_V_MAX := 0;
 
  SIGNAL r_Draw_Ball : STD_LOGIC := '0';
   
BEGIN    
  p_Move_Ball : PROCESS (i_Clk) IS
  BEGIN
    IF RISING_EDGE(i_Clk) THEN
      -- If the game is not active, ball stays in the middle of the screen
      -- until the game starts.
      IF i_Game_Active = '0' THEN
        r_Ball_X      <= c_Game_Width/2;
        r_Ball_Y      <= c_Game_Height/2;
        r_Ball_X_Prev <= c_Game_Width/2 + 1; 
        r_Ball_Y_Prev <= c_Game_Height/2 - 1;
 
      ELSE
        -- Update the ball counter continuously.  Ball movement update rate is
        -- determined by a constant in the package file.
        IF r_Ball_Count = c_Ball_Speed THEN
          r_Ball_Count <= 0;
        ELSE
          r_Ball_Count <= r_Ball_Count + 1;
        END IF;
 
        -----------------------------------------------------------------------
        -- Control X Position (Col)
        -----------------------------------------------------------------------
        IF r_Ball_Count = c_Ball_Speed THEN
           
          -- Store Previous Location to keep track of ball movement
          r_Ball_X_Prev <= r_Ball_X;
           
          -- If ball is moving to the right, keep it moving right, but check
          -- that it's not at the wall (in which case it bounces back)
          IF r_Ball_X_Prev < r_Ball_X THEN
            IF r_Ball_X = c_Game_Width-2 THEN
              r_Ball_X <= r_Ball_X - 1;
            ELSE
              r_Ball_X <= r_Ball_X + 1;
            END IF;
          -- Ball is moving left, keep it moving left, check for wall impact
          ELSIF r_Ball_X_Prev > r_Ball_X THEN
            IF r_Ball_X = 1 THEN
              r_Ball_X <= r_Ball_X + 1;
            ELSE
              r_Ball_X <= r_Ball_X - 1;
            END IF;
          END IF;
        END IF;
 
         
        -----------------------------------------------------------------------
        -- Control Y Position (Row)
        -----------------------------------------------------------------------
        IF r_Ball_Count = c_Ball_Speed THEN
           
          -- Store Previous Location to keep track of ball movement
          r_Ball_Y_Prev <= r_Ball_Y;
           
          -- If ball is moving to the up, keep it moving up, but check
          -- that it's not at the wall (in which case it bounces back)
          IF r_Ball_Y_Prev < r_Ball_Y THEN
            IF r_Ball_Y = c_Game_Height-1 THEN
              r_Ball_Y <= r_Ball_Y - 1;
            ELSE
              r_Ball_Y <= r_Ball_Y + 1;
            END IF;
          -- Ball is moving down, keep it moving down, check for wall impact
          ELSIF r_Ball_Y_Prev > r_Ball_Y THEN
            IF r_Ball_Y = 1 THEN
              r_Ball_Y <= r_Ball_Y + 1;
            ELSE
              r_Ball_Y <= r_Ball_Y - 1;
            END IF;
          END IF;
        END IF;
      END IF;                           -- w_Game_Active = '1'
    END IF;                             -- RISING_EDGE(i_Clk)
  END PROCESS p_Move_Ball;
 
 
  -- Draws a ball at the location determined by X and Y indexes.
  p_Draw_Ball : PROCESS (i_Clk) IS
  BEGIN
    IF RISING_EDGE(i_Clk) THEN
      IF (i_Col_Count = r_Ball_X AND i_Row_Count = r_Ball_Y) THEN
        r_Draw_Ball <= '1';
      ELSE
        r_Draw_Ball <= '0';
      END IF;
    END IF;
  END PROCESS p_Draw_Ball;
 
  o_Draw_Ball <= r_Draw_Ball;
  o_Ball_X    <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Ball_X, o_Ball_X'LENGTH));
  o_Ball_Y    <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Ball_Y, o_Ball_Y'LENGTH));
   
   
END ARCHITECTURE;
