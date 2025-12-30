library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_capture_tb is
end entity sync_capture_tb;

architecture tb of sync_capture_tb is
    constant CYCLE_TIME: time := 1 ns;
    constant ENABLE_DIVIDER: natural := 4;
    constant ENABLE_CYCLE_TIME: time := CYCLE_TIME * ENABLE_DIVIDER;
    
    constant SYNC_LENGTH: natural := 7;
    constant BP_LENGTH: natural := 3;
    constant VALID_LENGTH: natural := 27;
    constant FP_LENGTH: natural := 5;
    constant TOTAL_LENGTH: natural := SYNC_LENGTH + BP_LENGTH + VALID_LENGTH + FP_LENGTH;
    constant SYNC_POLARITY: bit := '1';
    
    constant TEST_CYCLES: natural := 10;
    constant TEST_TIME: time := ENABLE_CYCLE_TIME * TOTAL_LENGTH * TEST_CYCLES;

    signal clk: std_ulogic := '0';
    signal resetn: std_ulogic := '0';
    signal enable: std_ulogic := '0';
    
    signal sync: std_ulogic;
    
    signal valid: std_ulogic;
    signal valid_prev: std_ulogic;
    
    signal cascade_enable: std_ulogic;
    signal cascade_enable_prev: std_ulogic;

    signal address: integer;
    
    signal enable_counter: integer range 0 to (ENABLE_DIVIDER - 1) := 0;
    signal sync_counter: integer range 0 to (TOTAL_LENGTH * ENABLE_DIVIDER - 1) := 0;
begin
    duv: entity work.sync_capture
        generic map (
            SYNC_AND_BP_LENGTH => SYNC_LENGTH + BP_LENGTH,
            VALID_LENGTH => VALID_LENGTH,
            MAX_FP_LENGTH => FP_LENGTH,
            SYNC_POLARITY => SYNC_POLARITY)
            
        port map (
            clk => clk,
            resetn => resetn,
            enable => enable,
            sync => sync,
            valid => valid,
            address => address,
            cascade_enable => cascade_enable);

    clk <= not clk after (CYCLE_TIME / 2);
    resetn <= '1' after (CYCLE_TIME * 2);
    
    make_enable: process(clk) begin
        if rising_edge(clk) then
            enable <= '0'; 
            if enable_counter = (ENABLE_DIVIDER - 1) then
                enable <= '1'; 
                enable_counter <= 0;
            else
                enable_counter <= enable_counter + 1;
            end if;
        end if;
    end process make_enable;

    make_sync: process(clk) begin
        if rising_edge(clk) then
            sync <= to_stdulogic(not SYNC_POLARITY); 
            if sync_counter = TOTAL_LENGTH * ENABLE_DIVIDER - 1 then
                sync_counter <= 0;
            else
                if sync_counter < SYNC_LENGTH * ENABLE_DIVIDER then
                    sync <= to_stdulogic(SYNC_POLARITY);
                end if;
                sync_counter <= sync_counter + 1;
            end if;
        end if;
    end process make_sync;

    valid_prev <= valid;
    cascade_enable_prev <= cascade_enable;
    
end architecture tb;
