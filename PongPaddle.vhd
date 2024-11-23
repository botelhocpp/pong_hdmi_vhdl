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
    
    i_Col_Count : IN INTEGER RANGE 0 TO c_H_MAX;
    i_Row_Count : IN INTEGER RANGE 0 TO c_V_MAX;
 
    -- Player Paddle Control
    i_Paddle_Up : IN STD_LOGIC;
    i_Paddle_Dn : IN STD_LOGIC;
 
    o_Draw_Paddle : OUT STD_LOGIC;
    o_Paddle_Y    : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
);
END ENTITY;
 
ARCHITECTURE RTL OF PongPaddle IS
  SIGNAL w_Paddle_Count_En : STD_LOGIC;
   
  -- Start Location (Top Left) of Paddles
  SIGNAL r_Paddle_Y : INTEGER RANGE 0 TO c_Game_Height-c_Paddle_Height-1 := c_GAME_HEIGHT/2 - c_PADDLE_HEIGHT/2;
 
  SIGNAL r_Draw_Paddle : STD_LOGIC := '0';
   
  SIGNAL r_Paddle_Up, r_Paddle_Dn : STD_LOGIC := '0';
BEGIN
    e_SAMPLE_PADDLE_UP: ENTITY WORK.SamplingRegister
    PORT MAP (
        i_Signal  => i_Paddle_Up,
        i_Clk => i_Clk,
        o_Output => r_Paddle_Up
    );
    
    e_SAMPLE_PADDLE_DN: ENTITY WORK.SamplingRegister
    PORT MAP (
        i_Signal  => i_Paddle_Dn,
        i_Clk => i_Clk,
        o_Output => r_Paddle_Dn
    );
    
  -- Only allow paddles to move if only one button is pushed.
  w_Paddle_Count_En <= r_Paddle_Up XOR r_Paddle_Dn;
 
  -- Controls how the paddles are moved.  Sets r_Paddle_Y.
  -- Can change the movement speed by changing the constant in Package file.
  p_Move_Paddles : PROCESS (i_Clk) IS
  BEGIN
    IF RISING_EDGE(i_Clk) THEN
 
      -- Update the Paddle Location Slowly, only allowed when the Paddle Count
      -- reaches its limit
      IF (i_Paddle_Up = '1' AND w_Paddle_Count_En = '1') THEN
 
        -- If Paddle is already at the top, do not update it
        IF r_Paddle_Y /= 1 THEN
          r_Paddle_Y <= r_Paddle_Y - 1;
        END IF;
 
      ELSIF (i_Paddle_Dn = '1' AND w_Paddle_Count_En = '1') THEN
 
        -- If Paddle is already at the bottom, do not update it
        IF r_Paddle_Y /= c_Game_Height - c_Paddle_Height - 1 THEN
          r_Paddle_Y <= r_Paddle_Y + 1;
        END IF; 
      END IF;
    END IF;
  END PROCESS p_Move_Paddles;
   
  p_DRAW_PADDLE:
  PROCESS (i_Clk) IS
  BEGIN
    IF RISING_EDGE(i_Clk) THEN
      IF (
        i_Col_Count = g_Player_Paddle_X AND
        i_Row_Count >= r_Paddle_Y AND
        i_Row_Count < r_Paddle_Y + c_Paddle_Height
      ) THEN
        r_Draw_Paddle <= '1';
      ELSE
        r_Draw_Paddle <= '0';
      END IF;
    END IF;
  END PROCESS p_DRAW_PADDLE;
 
  o_Draw_Paddle <= r_Draw_Paddle;
  o_Paddle_Y <= STD_LOGIC_VECTOR(TO_UNSIGNED(r_Paddle_Y, o_Paddle_Y'LENGTH));
   
END ARCHITECTURE;
