LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 
LIBRARY WORK;
USE WORK.PongPkg.ALL;
USE WORK.HdmiPkg.ALL;
 
ENTITY PongGame IS
PORT (
    i_Clk : IN STD_LOGIC;
    i_Video_Enable : IN STD_LOGIC;
    i_H_Sync : IN STD_LOGIC;
    i_V_Sync : IN STD_LOGIC;
    i_Pressed_Up : IN STD_LOGIC;
    i_Pressed_Down : IN STD_LOGIC;
    i_Pressed_Left : IN STD_LOGIC;
    i_Pressed_Right : IN STD_LOGIC;
    i_Pressed_A : IN STD_LOGIC;
    i_Pressed_B : IN STD_LOGIC;
    i_H_Pos : IN INTEGER RANGE 0 TO c_H_MAX;
    i_V_Pos : IN INTEGER RANGE 0 TO c_V_MAX;
    o_Video_Enable : OUT STD_LOGIC;
    o_H_Sync : OUT STD_LOGIC;
    o_V_Sync : OUT STD_LOGIC;
    o_Channel_R : OUT t_Byte;
    o_Channel_G : OUT t_Byte;
    o_Channel_B : OUT t_Byte
);
END ENTITY;
 
ARCHITECTURE RTL OF PongGame IS
  TYPE t_GameState IS (
    s_IDLE, 
    s_RUNNING, 
    s_P1_WINS, 
    s_P2_WINS, 
    s_CLEANUP
  );
  SIGNAL r_Current_State : t_GameState := s_IDLE;

  TYPE t_Level IS (
    s_COLORFUL,
    s_GRAYSCALE,
    s_BLACK_WHITE
  );
  SIGNAL r_Current_Level : t_Level := s_COLORFUL;
 
  SIGNAL w_Draw_Paddle_P1 : STD_LOGIC := '0';
  SIGNAL w_Draw_Paddle_P2 : STD_LOGIC := '0';
  SIGNAL w_Paddle_Y_P1    : INTEGER RANGE 0 TO c_V_MAX := 0;
  SIGNAL w_Paddle_Y_P2    : INTEGER RANGE 0 TO c_V_MAX := 0;
  SIGNAL w_Draw_Ball      : STD_LOGIC := '0';
  SIGNAL w_Draw_Score_P1  : STD_LOGIC := '0';
  SIGNAL w_Draw_Score_P2  : STD_LOGIC := '0';
  SIGNAL w_Ball_X         : INTEGER RANGE 0 TO c_H_MAX := 0;
  SIGNAL w_Ball_Y         : INTEGER RANGE 0 TO c_V_MAX := 0;
   
  SIGNAL w_Game_Active : STD_LOGIC := '0';
 
  SIGNAL w_Paddle_Y_P1_Top : INTEGER RANGE 0 TO c_V_MAX := 0;
  SIGNAL w_Paddle_Y_P1_Bot : INTEGER RANGE 0 TO c_V_MAX := 0;
  SIGNAL w_Paddle_Y_P2_Top : INTEGER RANGE 0 TO c_V_MAX := 0;
  SIGNAL w_Paddle_Y_P2_Bot : INTEGER RANGE 0 TO c_V_MAX := 0;
 
  SIGNAL r_P1_Score : INTEGER RANGE 0 TO c_Score_Limit + 1 := 0;
  SIGNAL r_P2_Score : INTEGER RANGE 0 TO c_Score_Limit + 1 := 0;
   
  SIGNAL w_H_Pos : INTEGER RANGE 0 TO c_H_MAX := 0;
  SIGNAL w_V_Pos : INTEGER RANGE 0 TO c_V_MAX := 0;
  
  SIGNAL r_P2_Paddle_Up, r_P2_Paddle_Dn, r_Pressed_B : STD_LOGIC := '0';
  
  SIGNAL r_Video_Enable_Aligned : STD_LOGIC := '0';
  SIGNAL r_H_Sync_Aligned : STD_LOGIC := '1';
  SIGNAL r_V_Sync_Aligned : STD_LOGIC := '1';

  SIGNAL w_Modifier : INTEGER RANGE 0 TO c_MAX_MODIFIER := 0;
  SIGNAL w_P2_Speed : INTEGER RANGE 0 TO c_PADDLE_REFRESH_RATE := 0;
BEGIN 
  WITH r_Current_Level SELECT 
    w_Modifier <= c_COLORFUL_MODIFIER * r_P1_Score     WHEN s_COLORFUL,
                  c_GRAYSCALE_MODIFIER * r_P1_Score    WHEN s_GRAYSCALE,
                  c_BLACK_WHITE_MODIFIER * r_P1_Score  WHEN s_BLACK_WHITE;

    w_H_Pos <= i_H_Pos/c_GAME_SCALE;
    w_V_Pos <= i_V_Pos/c_GAME_SCALE;
    w_P2_Speed <= c_PADDLE_REFRESH_RATE - w_Modifier;
 
    e_SAMPLE_B_BUTTON: ENTITY WORK.SamplingRegister
    PORT MAP (
        i_Signal  => i_Pressed_B,
        i_Clk     => i_Clk,
        i_Number_Cycles => c_PIXEL_CLK_FREQ/2,
        o_Output  => r_Pressed_B
    );
 
    e_PLAYER_1_PADDLE: ENTITY WORK.PongPaddle
    GENERIC MAP ( g_Player_Paddle_X => c_P1_PADDLE_COL )
    PORT MAP (
        i_Clk           => i_Clk,
        i_Paddle_Speed  => c_PADDLE_REFRESH_RATE,
        i_Col_Count     => w_H_Pos,
        i_Row_Count     => w_V_Pos,
        i_Paddle_Up     => i_Pressed_Up,
        i_Paddle_Dn     => i_Pressed_Down,
        o_Draw_Paddle   => w_Draw_Paddle_P1,
        o_Paddle_Y      => w_Paddle_Y_P1
    );
    e_PLAYER_2_PADDLE: ENTITY WORK.PongPaddle
    GENERIC MAP ( g_Player_Paddle_X => c_P2_PADDLE_COL )
    PORT MAP (
        i_Clk           => i_Clk,
        i_Paddle_Speed  => w_P2_Speed,
        i_Col_Count     => w_H_Pos,
        i_Row_Count     => w_V_Pos,
        i_Paddle_Up     => r_P2_Paddle_Up,
        i_Paddle_Dn     => r_P2_Paddle_Dn,
        o_Draw_Paddle   => w_Draw_Paddle_P2,
        o_Paddle_Y      => w_Paddle_Y_P2
    );
    e_PONG_BALL: ENTITY WORK.PongBall
    PORT MAP (
        i_Clk           => i_Clk,
        i_Game_Active   => w_Game_Active,
        i_Col_Count     => w_H_Pos,
        i_Row_Count     => w_V_Pos,
        i_Modifier      => w_Modifier,
        o_Draw_Ball     => w_Draw_Ball,
        o_Ball_X        => w_Ball_X,
        o_Ball_Y        => w_Ball_Y
    );
    e_PLAYER_1_SCORE: ENTITY WORK.PongScore
    GENERIC MAP ( g_SCORE_X => c_P1_SCORE_COL )
    PORT MAP (
        i_Clk => i_Clk,
        i_Video_Enable  => i_Video_Enable,
        i_Col_Count     => w_H_Pos,
        i_Row_Count     => w_V_Pos,
        i_Score         => r_P1_Score,
        o_Draw_Score    => w_Draw_Score_P1
    );
    e_PLAYER_2_SCORE: ENTITY WORK.PongScore
    GENERIC MAP ( g_SCORE_X => c_P2_SCORE_COL )
    PORT MAP (
        i_Clk => i_Clk,
        i_Video_Enable  => i_Video_Enable,
        i_Col_Count     => w_H_Pos,
        i_Row_Count     => w_V_Pos,
        i_Score         => r_P2_Score,
        o_Draw_Score    => w_Draw_Score_P2
    );
 
  w_Paddle_Y_P1_Top <= w_Paddle_Y_P1;
  w_Paddle_Y_P1_Bot <= w_Paddle_Y_P1 + c_PADDLE_HEIGHT;
  w_Paddle_Y_P2_Top <= w_Paddle_Y_P2;
  w_Paddle_Y_P2_Bot <= w_Paddle_Y_P2 + c_PADDLE_HEIGHT;

  p_GAME_FSM:
  PROCESS (i_Clk) IS
  BEGIN
    IF RISING_EDGE(i_Clk) THEN
      CASE r_Current_State IS
        WHEN s_IDLE =>
          IF i_Pressed_A = '1' THEN
            r_Current_State <= s_RUNNING;
          END IF;

          IF r_Pressed_B = '1' THEN
            CASE r_Current_Level IS
              WHEN s_COLORFUL =>
                r_Current_Level <= s_GRAYSCALE;
              WHEN s_GRAYSCALE =>
                r_Current_Level <= s_BLACK_WHITE;
              WHEN s_BLACK_WHITE =>
                r_Current_Level <= s_COLORFUL;
            END CASE;
          END IF;
         
        -- Stay in this state until either player misses the ball 
        -- Can only occur when the Ball is at 0 or c_GAME_WIDTH-1 
        WHEN s_RUNNING =>
 
          -- Player 1's Side:
          IF (w_Ball_X = c_P1_PADDLE_COL) THEN
            IF (w_Ball_Y > w_Paddle_Y_P1_Bot OR w_Ball_Y < w_Paddle_Y_P1_Top) THEN
              r_Current_State <= s_P2_WINS;
            END IF;
 
          -- Player 2's Side:
          ELSIF (w_Ball_X = c_P2_PADDLE_COL) THEN
            IF (w_Ball_Y > w_Paddle_Y_P2_Bot OR w_Ball_Y < w_Paddle_Y_P2_Top) THEN
              r_Current_State <= s_P1_WINS; 
            END IF; 
          END IF;
          
        WHEN s_P1_WINS =>
          r_P1_Score <= r_P1_Score + 1;
          r_Current_State  <= s_CLEANUP;
         
        WHEN s_P2_WINS =>
          r_P2_Score <= r_P2_Score + 1;
          r_Current_State <= s_CLEANUP;
         
        WHEN s_CLEANUP =>
          IF r_P1_Score > c_Score_Limit OR r_P2_Score > c_Score_Limit THEN
            r_P1_Score <= 0;
            r_P2_Score <= 0;
          END IF;
          
          r_Current_State <= s_IDLE;
        END CASE;
    END IF;
  END PROCESS p_GAME_FSM;
 
  -- Conditional Assignment of Game Active based on State Machine
  w_Game_Active <= '1' WHEN (r_Current_State = s_RUNNING) ELSE '0';
 
  p_DRAW_OBJECTS:
  PROCESS(i_Clk)
  BEGIN
    IF(RISING_EDGE(i_Clk)) THEN
        -- Draw Players (Cyan)
        IF(w_Draw_Paddle_P1 = '1' OR w_Draw_Paddle_P2 = '1') THEN
          CASE r_Current_Level IS
            WHEN s_COLORFUL =>
              o_Channel_R <= (OTHERS => '0');
              o_Channel_G <= (OTHERS => '1');
              o_Channel_B <= (OTHERS => '1');
            WHEN s_GRAYSCALE =>
              o_Channel_R <= t_Byte(TO_UNSIGNED(179, 8));
              o_Channel_G <= t_Byte(TO_UNSIGNED(179, 8));
              o_Channel_B <= t_Byte(TO_UNSIGNED(179, 8));
            WHEN s_BLACK_WHITE =>
              o_Channel_R <= (OTHERS => '1');
              o_Channel_G <= (OTHERS => '1');
              o_Channel_B <= (OTHERS => '1');
          END CASE;   
          
        -- Draw Ball (Green)
        ELSIF(w_Draw_Ball = '1') THEN 
          CASE r_Current_Level IS
            WHEN s_COLORFUL =>
              o_Channel_R <= (OTHERS => '0');
              o_Channel_G <= (OTHERS => '1');
              o_Channel_B <= (OTHERS => '0');
            WHEN s_GRAYSCALE =>
              o_Channel_R <= t_Byte(TO_UNSIGNED(150, 8));
              o_Channel_G <= t_Byte(TO_UNSIGNED(150, 8));
              o_Channel_B <= t_Byte(TO_UNSIGNED(150, 8));
            WHEN s_BLACK_WHITE =>
              o_Channel_R <= (OTHERS => '1');
              o_Channel_G <= (OTHERS => '1');
              o_Channel_B <= (OTHERS => '1');
          END CASE;     

        -- Draw Score (Yellow)
        ELSIF(w_Draw_Score_P1 = '1' OR w_Draw_Score_P2 = '1') THEN 
          CASE r_Current_Level IS
            WHEN s_COLORFUL =>
              o_Channel_R <= (OTHERS => '1');
              o_Channel_G <= (OTHERS => '1');
              o_Channel_B <= (OTHERS => '0');
            WHEN s_GRAYSCALE =>
              o_Channel_R <= t_Byte(TO_UNSIGNED(227, 8));
              o_Channel_G <= t_Byte(TO_UNSIGNED(227, 8));
              o_Channel_B <= t_Byte(TO_UNSIGNED(227, 8));
            WHEN s_BLACK_WHITE =>
              o_Channel_R <= (OTHERS => '1');
              o_Channel_G <= (OTHERS => '1');
              o_Channel_B <= (OTHERS => '1');
          END CASE;      

        -- Draw Net (White)
        ELSIF(
            i_H_Pos >= c_FRAME_WIDTH/2 + c_GAME_SCALE/2 AND 
            i_H_Pos < c_FRAME_WIDTH/2 + c_GAME_SCALE/2 + 2 AND 
            (i_V_Pos MOD 8 = 0)
        ) THEN 
            o_Channel_R <= (OTHERS => '1');
            o_Channel_G <= (OTHERS => '1');
            o_Channel_B <= (OTHERS => '1');
        
        -- Draw Background (Blue)
        ELSE         
          CASE r_Current_Level IS
            WHEN s_COLORFUL =>
              o_Channel_R <= (OTHERS => '0');
              o_Channel_G <= (OTHERS => '0');
              o_Channel_B <= (OTHERS => '1');
            WHEN s_GRAYSCALE =>
              o_Channel_R <= t_Byte(TO_UNSIGNED(29, 8));
              o_Channel_G <= t_Byte(TO_UNSIGNED(29, 8));
              o_Channel_B <= t_Byte(TO_UNSIGNED(29, 8));
            WHEN s_BLACK_WHITE =>
              o_Channel_R <= (OTHERS => '0');
              o_Channel_G <= (OTHERS => '0');
              o_Channel_B <= (OTHERS => '0');
          END CASE;
        END IF;
    END IF;
  END PROCESS p_DRAW_OBJECTS;
  
  p_UPDATE_P2_PADDLE: 
  PROCESS(i_Clk)
    VARIABLE v_Counter : INTEGER RANGE 0 TO c_PADDLE_REFRESH_RATE := 0;
    VARIABLE v_Move_Down : STD_LOGIC := '1';
  BEGIN
    IF(RISING_EDGE(i_Clk)) THEN
        IF(w_Game_Active = '1') THEN
            IF(v_Counter = w_P2_Speed) THEN
                v_Counter := 0;
                    
                IF(v_Move_Down = '1' AND w_Paddle_Y_P2 = c_GAME_HEIGHT - c_PADDLE_HEIGHT - 1) THEN
                    v_Move_Down := '0';
                ELSIF(v_Move_Down = '0' AND w_Paddle_Y_P2 = 0) THEN
                    v_Move_Down := '1';
                END IF;
            ELSE
                IF(v_Move_Down = '1') THEN
                    r_P2_Paddle_Dn <= '1';
                    r_P2_Paddle_Up <= '0';
                ELSE
                    r_P2_Paddle_Dn <= '0';
                    r_P2_Paddle_Up <= '1';
                END IF;
                v_Counter := v_Counter + 1;
            END IF;
        ELSE
            r_P2_Paddle_Up <= '0';
            r_P2_Paddle_Dn <= '0';
        END IF;
    END IF;
  END PROCESS;

  -- Sync 
  p_SYNC_PULSES:
  PROCESS(i_Clk)
  BEGIN
    IF(RISING_EDGE(i_Clk)) THEN
      r_Video_Enable_Aligned <= i_Video_Enable;
      r_H_Sync_Aligned <= i_H_Sync;
      r_V_Sync_Aligned <= i_V_Sync;
      
      o_Video_Enable <= r_Video_Enable_Aligned;
      o_H_Sync <= r_H_Sync_Aligned;
      o_V_Sync <= r_V_Sync_Aligned;
    END IF;
  END PROCESS p_SYNC_PULSES;
END ARCHITECTURE;
