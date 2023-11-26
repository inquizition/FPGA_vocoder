----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/25/2023 10:49:16 PM
-- Design Name: 
-- Module Name: filter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.numeric_std.all;


ENTITY MovingAverageFilter IS
    GENERIC (
        d_width : INTEGER := 24;
        window_size : INTEGER := 4  -- Set your desired window size
    );
    PORT (
        reset_n      : IN STD_LOGIC;
        data_in      : IN STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
        data_out     : OUT STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
        clk          : IN STD_LOGIC;
        update       : IN STD_LOGIC;
        filter_on_n  : IN STD_LOGIC
    );
END ENTITY MovingAverageFilter;

ARCHITECTURE Behavior OF MovingAverageFilter IS
    CONSTANT N : INTEGER := 20;
    SIGNAL buffer_data : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL buffer_sum  : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL buffer_count : INTEGER := 0;
    SIGNAL data_window : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');
    TYPE ShiftRegisterType IS ARRAY(0 to N-1) OF STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
    SIGNAL shiftRegister : ShiftRegisterType := (others => (others => '0'));
    signal average : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (others => '0');
BEGIN
    PROCESS (clk, reset_n, data_in, update)
        VARIABLE ws_cnt    :  INTEGER := 0;
    BEGIN
        IF reset_n = '0' THEN
            shiftRegister <= (others => (others => '0'));
            ws_cnt := 0;
            buffer_data <= (OTHERS => '0');
            buffer_sum  <= (OTHERS => '0');
            buffer_count <= 0;
            data_window <= (OTHERS => '0');
        ELSIF(clk'EVENT AND clk = '1') THEN
            IF(ws_cnt < window_size-1) THEN
                ws_cnt := ws_cnt + 1;
            ELSIF update = '1' THEN
                for i in N-1 downto 1 loop
                    shiftRegister(i) <= shiftRegister(i-1);
                end loop;
                
                shiftRegister(0) <= data_in;
                
                buffer_sum <= (others => '0');
                for i in 0 to N-1 loop
                    buffer_sum <= STD_LOGIC_VECTOR(unsigned(buffer_sum) + unsigned(shiftRegister(i)));
                end loop;
                
                average <= STD_LOGIC_VECTOR(unsigned(buffer_sum) / N);
                
                
                --buffer_data <= data_in;
                --buffer_sum  <= buffer_sum + signed(data_in) - signed(data_window(buffer_count));
                --data_window(buffer_count) <= data_in;
                --buffer_count <= buffer_count + 1;
                ws_cnt := 0;
            END IF;
        END IF;
    END PROCESS;

    -- Assign data_out based on intermediate_data
    --data_out <= average;
    data_out <= shiftRegister(N-1) WHEN filter_on_n = '0' ELSE average;
END ARCHITECTURE Behavior;

--LIBRARY ieee;
--USE ieee.std_logic_1164.ALL;
--USE ieee.numeric_std.ALL; -- Add this line

--ENTITY Filter IS
--    GENERIC (
--        d_width : INTEGER := 24;
--        mclk_ws_ratio : INTEGER := 256
--    );
--    PORT (
--        reset_n      : IN STD_LOGIC;
--        data_in      : IN STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
--        data_out     : OUT STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
--        clk          : IN STD_LOGIC;
--        update       : IN STD_LOGIC;
--        filter_on_n  : IN STD_LOGIC
--    );
--END ENTITY Filter;

--ARCHITECTURE Behavior OF Filter IS
--    SIGNAL buffer_data : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');
--    SIGNAL buffer_sum  : SIGNED(d_width DOWNTO 0) := (OTHERS => '0');
--    SIGNAL buffer_count : INTEGER := 0;
--    SIGNAL average_out : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0); -- Intermediate signal
--BEGIN
--    PROCESS (clk, reset_n, data_in, update)
--        VARIABLE ws_cnt    :  INTEGER := 0;  --counter of serial clock toggles during half period of word select
--    BEGIN
--        IF reset_n = '0' THEN
--            -- Synchronous reset
--            ws_cnt := 0;
--            buffer_data <= (OTHERS => '0');
--            buffer_sum  <= (OTHERS => '0');
--            buffer_count <= 0;
--        ELSIF(clk'EVENT AND clk = '1') THEN                            --master clock rising edge
        
--            IF(ws_cnt < mclk_ws_ratio-1) THEN                          --less than half period of ws
--                ws_cnt := ws_cnt + 1;                                  --increment sclk/ws counter
--            ELSIF update = '1' THEN                                    -- Synchronous update on rising edge of the clock
--                    buffer_data <= data_in;
--                    buffer_sum  <= buffer_sum + signed(data_in);
--                    buffer_count <= buffer_count + 1;
--                    ws_cnt := 0;
--            END IF;
--        END IF;
--END PROCESS;

--    -- Assign data_out based on intermediate_data
--    average_out <= std_logic_vector(resize(buffer_sum, d_width) / to_signed(buffer_count, d_width + 1));
--    data_out <= buffer_data WHEN filter_on_n = '0' ELSE average_out;
--    --data_out <= average_out;
--END ARCHITECTURE Behavior;