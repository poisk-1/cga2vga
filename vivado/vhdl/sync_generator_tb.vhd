library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_generator_tb is
end entity sync_generator_tb;

architecture tb of sync_generator_tb is
    constant SYNC_LENGTH: natural := 1;
    constant BP_LENGTH: natural := 3;
    constant VALID_LENGTH: natural := 27;
    constant FP_LENGTH: natural := 5;
    constant TOTAL_LENGTH: natural := SYNC_LENGTH + BP_LENGTH + VALID_LENGTH + FP_LENGTH;
    constant SYNC_POLARITY: bit := '1';
    
    constant CYCLE_TIME: time := 1 ns;
    constant ENABLE_DIVIDER: natural := 4;
    constant ENABLE_CYCLE_TIME: time := CYCLE_TIME * ENABLE_DIVIDER;
    
    constant TEST_CYCLES: natural := 10;
    constant TEST_TIME: time := ENABLE_CYCLE_TIME * TOTAL_LENGTH * TEST_CYCLES;

    signal clk: std_ulogic := '0';
    signal resetn: std_ulogic := '0';
    signal enable: std_ulogic := '0';
    
    signal sync: std_ulogic;
    signal sync_prev: std_ulogic;
    
    signal valid: std_ulogic;
    signal valid_prev: std_ulogic;
    
    signal cascade_enable: std_ulogic;
    signal cascade_enable_prev: std_ulogic;

    signal address: integer;
    
    signal enable_counter: integer range 0 to (ENABLE_DIVIDER - 1) := 0;
    
    signal sync_count: natural := 0;
begin
    duv: entity work.sync_generator
        generic map (
            SYNC_LENGTH => SYNC_LENGTH,
            BP_LENGTH => BP_LENGTH,
            VALID_LENGTH => VALID_LENGTH,
            FP_LENGTH => FP_LENGTH,
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
    
    sync_prev <= sync;
    valid_prev <= valid;
    cascade_enable_prev <= cascade_enable;

    test_sync: process begin
        wait on sync;

        if sync = to_stdulogic(not SYNC_POLARITY) and sync_prev = to_stdulogic(SYNC_POLARITY) then
            sync_count <= sync_count + 1;
            
            assert sync_prev'stable(ENABLE_CYCLE_TIME * SYNC_LENGTH)
            report "bad sync"
            severity failure;            
        elsif sync = to_stdulogic(SYNC_POLARITY) and sync_prev = to_stdulogic(not SYNC_POLARITY) then
            assert sync_prev'stable(ENABLE_CYCLE_TIME * (BP_LENGTH + VALID_LENGTH + FP_LENGTH))
            report "bad not sync"
            severity failure;
            
            assert valid = '0' and valid_prev'stable(ENABLE_CYCLE_TIME * FP_LENGTH)
            report "bad front porch"
            severity failure;
            
            assert cascade_enable = '1' and cascade_enable_prev ='0'
            report "bad cascade_enable"
            severity failure;
        end if;
    end process test_sync;

    test_cascade_enable: process begin
        wait on cascade_enable;
        
        if cascade_enable = '0' and cascade_enable_prev ='1' then
            assert cascade_enable_prev'stable(CYCLE_TIME)
            report "bad not cascade_enable"
            severity failure;                                    
        end if;
    end process test_cascade_enable;

    test_valid: process begin
        wait on valid;

        if valid = '1' and valid_prev = '0' then
            assert valid_prev'stable(ENABLE_CYCLE_TIME * (SYNC_LENGTH + BP_LENGTH))
            report "bad not valid"
            severity failure;
            
            assert sync = to_stdulogic(not SYNC_POLARITY) and sync_prev'stable(ENABLE_CYCLE_TIME * BP_LENGTH)
            report "bad back porch"
            severity failure;            
        elsif valid = '0' and valid_prev = '1' then
            assert valid_prev'stable(ENABLE_CYCLE_TIME * VALID_LENGTH)
            report "bad valid"
            severity failure;
        end if;
    end process test_valid;

    test_address: process begin
        wait on valid;

        if valid = '1' and valid_prev = '0' then
            wait for ENABLE_CYCLE_TIME;
            
            for i in 0 to VALID_LENGTH - 1 loop
                assert address = i
                report "bad address"
                severity failure;
                
                wait for ENABLE_CYCLE_TIME;
            end loop;
        end if;
    end process test_address;

    test_sync_count: process begin
        wait for TEST_TIME;
        
        assert sync_count = TEST_CYCLES
        report "no sync"
        severity failure;

        wait;
    end process test_sync_count;
    
end architecture tb;