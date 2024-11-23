LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY UNISIM;
USE UNISIM.VComponents.all;

LIBRARY WORK;
USE WORK.HdmiPkg.ALL;

ENTITY HdmiOut IS
PORT (
    i_Channel_R : IN t_Byte;
    i_Channel_G : IN t_Byte;
    i_Channel_B : IN t_Byte;
    i_Clk : IN STD_LOGIC;
    i_Pixel_Clk : IN STD_LOGIC;
    i_H_Sync : IN STD_LOGIC;
    i_V_Sync : IN STD_LOGIC;
    i_Video_Enable : IN STD_LOGIC;
    o_Hdmi_Data_N : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    o_Hdmi_Data_P : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    o_Hdmi_Clk_N : OUT STD_LOGIC;
    o_Hdmi_Clk_P : OUT STD_LOGIC
);
END ENTITY;

ARCHITECTURE Structural OF HdmiOut IS
    SIGNAL w_Tmds_R_Shift, w_Tmds_G_Shift, w_Tmds_B_Shift : STD_LOGIC := '0';
    SIGNAL w_Tmds_R ,w_Tmds_G, w_Tmds_B : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
BEGIN
    -- TMDS Channel Encoders
    e_TMDS_ENCODER_R: ENTITY WORK.TdmsEncoder
    PORT MAP (  
        i_Data => i_Channel_R,
        i_Clk => i_Pixel_Clk,
        i_Video_Enable => i_Video_Enable,
        i_Control_1 => '0',
        i_Control_0 => '0',
        o_Encoded_Data => w_Tmds_R
    );
    e_TMDS_ENCODER_G: ENTITY WORK.TdmsEncoder
    PORT MAP (  
        i_Data => i_Channel_G,
        i_Clk => i_Pixel_Clk,
        i_Video_Enable => i_Video_Enable,
        i_Control_1 => '0',
        i_Control_0 => '0',
        o_Encoded_Data => w_Tmds_G
    );
    e_TMDS_ENCODER_B: ENTITY WORK.TdmsEncoder
    PORT MAP (  
        i_Data => i_Channel_B,
        i_Clk => i_Pixel_Clk,
        i_Video_Enable => i_Video_Enable,
        i_Control_1 => i_V_Sync,
        i_Control_0 => i_H_Sync,
        o_Encoded_Data => w_Tmds_B
    );
    
    -- Channel Shift Registers
    e_SHIFT_REGISTER_R: ENTITY WORK.shift_register
    GENERIC MAP (g_N => 10)
    PORT MAP (
        i_Data_In => w_Tmds_R,  
        i_Clk => i_Clk,  
        i_Data_Out => w_Tmds_R_Shift   
    );
    e_SHIFT_REGISTER_G: ENTITY WORK.shift_register
    GENERIC MAP (g_N => 10)
    PORT MAP (
        i_Data_In => w_Tmds_G,  
        i_Clk => i_Clk,  
        i_Data_Out => w_Tmds_G_Shift   
    );
    e_SHIFT_REGISTER_B: ENTITY WORK.shift_register
    GENERIC MAP (g_N => 10)
    PORT MAP (
        i_Data_In => w_Tmds_B,  
        i_Clk => i_Clk,  
        i_Data_Out => w_Tmds_B_Shift   
    );
 
    -- Create Differential Pairs (TMDS)
    e_DIFF_CLK : OBUFDS
    GENERIC MAP (IOSTANDARD => "TMDS_33")
    PORT MAP (
        I => i_Pixel_Clk,
        O => o_Hdmi_Clk_P,
        OB => o_Hdmi_Clk_N
    );
    e_DIFF_R : OBUFDS
    GENERIC MAP (IOSTANDARD => "TMDS_33")
    PORT MAP (
        I => w_Tmds_R_Shift,
        O => o_Hdmi_Data_P(2),
        OB => o_Hdmi_Data_N(2)
    );
    e_DIFF_G : OBUFDS
    GENERIC MAP (IOSTANDARD => "TMDS_33")
    PORT MAP (
        I => w_Tmds_G_Shift,
        O => o_Hdmi_Data_P(1),
        OB => o_Hdmi_Data_N(1)
    );
    e_DIFF_B : OBUFDS
    GENERIC MAP (IOSTANDARD => "TMDS_33")
    PORT MAP (
        I => w_Tmds_B_Shift,
        O => o_Hdmi_Data_P(0),
        OB => o_Hdmi_Data_N(0)
    );
END ARCHITECTURE;