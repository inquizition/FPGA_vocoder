--------------------------------------------------------------------------------
--
--   FileName:         i2s_playback.vhd
--   Dependencies:     i2s_transceiver.vhd, clk_wiz_0 (PLL)
--   Design Software:  Vivado v2017.2
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 04/19/2019 Scott Larson
--     Initial Public Release
-- 
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY i2s_playback IS
    GENERIC(
        d_width     : INTEGER := 24);                    --data width
    PORT(
        clock       : IN STD_LOGIC;                      --system clock (100 MHz on Basys board)
        reset_n     : IN STD_LOGIC;                      --active low asynchronous reset
        filter_on_n : IN STD_LOGIC;
        mclk        : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);  --master clock
        sclk        : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);  --serial clock (or bit clock)
        ws          : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);  --word select (or left-right clock)
        sd_rx       : IN STD_LOGIC;                      --serial data in
        sd_tx       : OUT STD_LOGIC);                    --serial data out
END i2s_playback;

ARCHITECTURE logic OF i2s_playback IS
    SIGNAL master_clk   : STD_LOGIC;                             --internal master clock signal
    SIGNAL serial_clk   : STD_LOGIC := '0';                      --internal serial clock signal
    SIGNAL word_select  : STD_LOGIC := '0';                      --internal word select signal
    SIGNAL l_data_rx    : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --left channel data received from I2S Transceiver component
    SIGNAL r_data_rx    : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --right channel data received from I2S Transceiver component
    SIGNAL l_data_tx    : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --left channel data to transmit using I2S Transceiver component
    SIGNAL r_data_tx    : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --right channel data to transmit using I2S Transceiver component

    -- Add buffers for left and right channels
    -- SIGNAL l_data_buffer :  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');
    -- SIGNAL r_data_buffer :  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');

    --declare PLL to create 11.29 MHz master clock from 100 MHz system clock
    COMPONENT clk_wiz_0
        PORT(
            clk_in1     : IN STD_LOGIC := '0';
            clk_out1    : OUT STD_LOGIC);
    END COMPONENT;

    --declare I2S Transceiver component
    COMPONENT i2s_transceiver IS
        GENERIC(
            mclk_sclk_ratio : INTEGER := 4;    --number of mclk periods per sclk period
            sclk_ws_ratio   : INTEGER := 64;   --number of sclk periods per word select period
            d_width         : INTEGER := 24);  --data width
        PORT(
            reset_n     : IN STD_LOGIC;                              --asynchronous active low reset
            mclk        : IN STD_LOGIC;                              --master clock
            sclk        : OUT STD_LOGIC;                             --serial clock (or bit clock)
            ws          : OUT STD_LOGIC;                             --word select (or left-right clock)
            sd_tx       : OUT STD_LOGIC;                             --serial data transmit
            sd_rx       : IN STD_LOGIC;                              --serial data receive
            l_data_tx   : IN STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);   --left channel data to transmit
            r_data_tx   : IN STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);   --right channel data to transmit
            l_data_rx   : OUT STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --left channel data received
            r_data_rx   : OUT STD_LOGIC_VECTOR(d_width-1 DOWNTO 0)); --right channel data received
    END COMPONENT;

    COMPONENT MovingAverageFilter
        GENERIC (
            d_width : INTEGER := 24;
            mclk_ws_ratio : INTEGER := 256    --number of mclk periods per ws period
        );
        PORT (
            reset_n   : IN STD_LOGIC;
            filter_on_n : IN STD_LOGIC;
            clk       : IN STD_LOGIC;
            data_in   : IN STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
            data_out  : OUT STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
            update    : IN STD_LOGIC
        );
    END COMPONENT;

    SIGNAL l_data_buffer : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL r_data_buffer : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');

BEGIN

    --instantiate PLL to create master clock
    i2s_clock: clk_wiz_0 
    PORT MAP(clk_in1 => clock, clk_out1 => master_clk);
  
    i2s_transceiver_0: i2s_transceiver GENERIC MAP(mclk_sclk_ratio => 4, sclk_ws_ratio => 64, d_width => 24)
                         PORT MAP(reset_n => reset_n, mclk => master_clk, sclk => serial_clk, ws => word_select,
                                  sd_tx => sd_tx, sd_rx => sd_rx, l_data_tx => l_data_buffer,
                                  r_data_tx => r_data_buffer, l_data_rx => l_data_rx, r_data_rx => r_data_rx);

    buffer_left: MovingAverageFilter GENERIC MAP(d_width => 24, mclk_ws_ratio => 256) PORT MAP(reset_n => reset_n, data_in => l_data_rx, clk => master_clk,
                                                            data_out => l_data_buffer, update => '1', filter_on_n => filter_on_n);

    buffer_right: MovingAverageFilter GENERIC MAP(d_width => 24, mclk_ws_ratio => 256) PORT MAP(reset_n => reset_n, data_in => r_data_rx, clk => master_clk,
                                                             data_out => r_data_buffer, update => '1', filter_on_n => filter_on_n);
  
    -- Connect buffers to transmit data
    r_data_tx <= r_data_buffer;  -- assign right channel buffered data to transmit (to playback out buffered data)
    l_data_tx <= l_data_buffer;  -- assign left channel buffered data to transmit (to playback out buffered data)

    -- Update buffers with received data
    --l_data_buffer <= l_data_rx;
    --r_data_buffer <= r_data_rx;
    
    mclk(0) <= master_clk;  --output master clock to ADC
    mclk(1) <= master_clk;  --output master clock to DAC
    sclk(0) <= serial_clk;  --output serial clock (from I2S Transceiver) to ADC
    sclk(1) <= serial_clk;  --output serial clock (from I2S Transceiver) to DAC
    ws(0) <= word_select;   --output word select (from I2S Transceiver) to ADC
    ws(1) <= word_select;   --output word select (from I2S Transceiver) to DAC

    -- sd_tx <= l_data_tx(0) OR r_data_tx(0); -- You may need to adjust this depending on your requirements

END logic;
