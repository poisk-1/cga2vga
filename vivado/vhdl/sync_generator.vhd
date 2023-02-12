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
    
    signal address_r: integer range 0 to TOTAL_LENGTH - 1;
begin
    process(clk) begin
        if rising_edge(clk) then
            cascade_enable <= '0';
            
            if resetn = '0' then
                sync <= to_stdulogic(SYNC_POLARITY);
                valid <= '0';
                address_r <= 0;
            else                
                if enable = '1' then
                    if address_r = TOTAL_LENGTH - 1 then
                        cascade_enable <= '1';
                        address_r <= 0;
                        sync <= to_stdulogic(SYNC_POLARITY);
                    else
                        address_r <= address_r + 1;
                        case address_r is
                            when SYNC_LENGTH - 1 =>
                                sync <= to_stdulogic(not SYNC_POLARITY);
                                
                            when VALID_START - 1 =>
                                valid <= '1';
                                
                            when VALID_END - 1 =>
                                valid <= '0';
                                
                            when others =>
                                null;
                                
                        end case;
                    end if;
                end if;
            end if;
        end if;
    end process;

    address <= address_r - VALID_START
        when address_r >= VALID_START and address_r < VALID_END
        else 0;

end architecture rtl;

