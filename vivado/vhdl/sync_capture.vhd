library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_capture is
    generic (
        VALID_OFFSET: natural;
        VALID_LENGTH: natural;
        SYNC_POLARITY: bit
    );
    port (
        clk: in std_ulogic;
        resetn: in std_ulogic;
        enable: in std_ulogic;
        sync: in std_ulogic;
        valid: out std_ulogic;
        cascade_enable: out std_ulogic;
        address: out integer range 0 to VALID_LENGTH - 1
    );
end entity sync_capture;

architecture rtl of sync_capture is
    constant TOTAL_LENGTH: natural := VALID_OFFSET + VALID_LENGTH;
    
    signal counter: integer range 0 to TOTAL_LENGTH - 1;
    signal prev_sync: std_ulogic;
    signal at_edge: boolean;
begin
    at_edge <= sync = to_stdulogic(SYNC_POLARITY) and prev_sync = not sync;

    process(clk) begin
        if rising_edge(clk) then            
            if resetn = '0' then
                prev_sync <= '0';
                counter <= 0;
            else                
                if enable = '1' then
                    prev_sync <= sync;

                    if at_edge then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    cascade_enable <= '1' when at_edge else '0';
    valid <= '1' when counter >= VALID_OFFSET and counter < TOTAL_LENGTH
        else '0';
    address <= counter - VALID_OFFSET when valid = '1' else 0;
end architecture rtl;

