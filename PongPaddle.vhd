LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 
LIBRARY WORK;
USE WORK.PongPkg.ALL;
USE WORK.HdmiPkg.ALL;
 
ENTITY PongPaddle IS
GENERIC ( g_Player_Paddle_X : INTEGER );
PORT (
    i_Clk : IN STD_LOGIC;
    i_Paddle_Speed : IN INTEGER RANGE 0 TO c_PADDLE_REFRESH_RATE;
    i_Col_Count : IN INTEGER RANGE 0 TO c_H_MAX;
    i_Row_Count : IN INTEGER RANGE 0 TO c_V_MAX;
    i_Paddle_Up : IN STD_LOGIC;
    i_Paddle_Dn : IN STD_LOGIC;
    o_Draw_Paddle : OUT STD_LOGIC;
    o_Paddle_Y    : OUT INTEGER RANGE 0 TO c_V_MAX
);
END ENTITY;
 
ARCHITECTURE RTL OF PongPaddle IS
  SIGNAL w_Paddle_Count_En : STD_LOGIC;
   
  -- Start Location (Top Left) of Paddles
  SIGNAL r_Paddle_Y : INTEGER RANGE 0 TO c_GAME_HEIGHT - c_PADDLE_HEIGHT - 1 := c_GAME_HEIGHT/2 - c_PADDLE_HEIGHT/2;
 
  SIGNAL r_Draw_Paddle : STD_LOGIC := '0';
   
  SIGNAL r_Paddle_Up, r_Paddle_Dn : STD_LOGIC := '0';
BEGIN
    e_SAMPLE_PADDLE_UP: ENTITY WORK.SamplingRegister
    PORT MAP (
        i_Signal  => i_Paddle_Up,
        i_Clk => i_Clk,
        i_Number_Cycles => i_Paddle_Speed,
        o_Output => r_Paddle_Up
    );
    
    e_SAMPLE_PADDLE_DN: ENTITY WORK.SamplingRegister
    PORT MAP (
        i_Signal  => i_Paddle_Dn,
        i_Clk => i_Clk,
        i_Number_Cycles => i_Paddle_Speed,
        o_Output => r_Paddle_Dn
    );
    
  w_Paddle_Count_En <= r_Paddle_Up XOR r_Paddle_Dn;
 
  p_MOVE_PADDLE: 
  PROCESS (i_Clk) IS
  BEGIN
    IF RISING_EDGE(i_Clk) THEN
      IF (i_Paddle_Up = '1' AND w_Paddle_Count_En = '1') THEN
  
        -- If Paddle is already at the top, do not update it
        IF (r_Paddle_Y /= 0) THEN
          r_Paddle_Y <= r_Paddle_Y - 1;
        END IF;
  
      ELSIF (i_Paddle_Dn = '1' AND w_Paddle_Count_En = '1') THEN
  
        -- If Paddle is already at the bottom, do not update it
        IF (r_Paddle_Y /= c_GAME_HEIGHT - c_PADDLE_HEIGHT - 1) THEN
          r_Paddle_Y <= r_Paddle_Y + 1;
        END IF; 
      END IF;
    END IF;
  END PROCESS p_MOVE_PADDLE;
   
  p_DRAW_PADDLE:
  PROCESS (i_Clk) IS
  BEGIN
    IF RISING_EDGE(i_Clk) THEN
      IF (
        i_Col_Count = g_Player_Paddle_X AND
        i_Row_Count >= r_Paddle_Y AND
        i_Row_Count <= r_Paddle_Y + c_PADDLE_HEIGHT
      ) THEN
        r_Draw_Paddle <= '1';
      ELSE
        r_Draw_Paddle <= '0';
      END IF;
    END IF;
  END PROCESS p_DRAW_PADDLE;
 
  o_Draw_Paddle <= r_Draw_Paddle;
  o_Paddle_Y    <= r_Paddle_Y;
   
END ARCHITECTURE;
