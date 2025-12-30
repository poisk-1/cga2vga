library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_generator is
    generic (
        SYNC_LENGTH: natural;
        BP_LENGTH: natural;
        VALID_LENGTH: natural;
        FP_LENGTH: natural;
        SYNC_POLARITY: bit
    );
    port (
        clk: in std_ulogic;
        resetn: in std_ulogic;
        enable: in std_ulogic;
        sync: out std_ulogic;
        valid: out std_ulogic;
        cascade_enable: out std_ulogic;
        address: out integer range 0 to VALID_LENGTH - 1
    );
end entity sync_generator;

architecture rtl of sync_generator is
    constant TOTAL_LENGTH: natural := SYNC_LENGTH + FP_LENGTH + VALID_LENGTH + BP_LENGTH;
    constant VALID_START: natural := SYNC_LENGTH + BP_LENGTH;
    constant VALID_END: natural := SYNC_LENGTH + BP_LENGTH + VALID_LENGTH;
    
    signal counter: integer range 0 to TOTAL_LENGTH - 1;
begin
    process(clk) begin
        if rising_edge(clk) then
            cascade_enable <= '0';
            
            if resetn = '0' then
                sync <= to_stdulogic(SYNC_POLARITY);
                valid <= '0';
                counter <= 0;
            else                
                if enable = '1' then
                    if counter = TOTAL_LENGTH - 1 then
                        cascade_enable <= '1';
                        counter <= 0;
                        sync <= to_stdulogic(SYNC_POLARITY);
                    else
                        counter <= counter + 1;

                        if counter = SYNC_LENGTH - 1 then
                            sync <= to_stdulogic(not SYNC_POLARITY);
                        elsif counter = VALID_START - 1 then
                            valid <= '1';
                        elsif counter = VALID_END - 1 then
                            valid <= '0';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    address <= counter - VALID_START
        when counter >= VALID_START and counter < VALID_END
        else 0;

end architecture rtl;

