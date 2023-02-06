library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_generator is
    generic (
        SYNC_LENGTH: natural := 4;
        BP_LENGTH: natural := 2;
        VALID_LENGTH: natural := 10;
        FP_LENGTH: natural := 2;
        SYNC_POLARITY: bit := '0'
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
    signal sync_r: std_ulogic;
    signal valid_r: std_ulogic;
    signal address_r: integer range 0 to (SYNC_LENGTH + FP_LENGTH + VALID_LENGTH + BP_LENGTH) - 1;
begin
    proc_name: process(clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                sync_r <= to_stdulogic(SYNC_POLARITY);
                valid_r <= '0';
                address_r <= 0;
            else
                if enable = '1' then
                    if address_r = SYNC_LENGTH - 1 then
                        sync_r <= to_stdulogic(not SYNC_POLARITY);
                    end if;

                    if address_r = SYNC_LENGTH + BP_LENGTH - 1 then
                        valid_r <= '1';
                    end if;

                    if address_r = SYNC_LENGTH + BP_LENGTH + VALID_LENGTH - 1 then
                        valid_r <= '0';
                    end if;

                    if address_r = SYNC_LENGTH + BP_LENGTH + VALID_LENGTH + FP_LENGTH - 1 then
                        address_r <= 0;
                        sync_r <= to_stdulogic(SYNC_POLARITY);
                    else
                        address_r <= address_r + 1;
                    end if;
                end if;
            end if;
        end if;
    end process proc_name;

    sync <= sync_r;
    valid <= valid_r;
    address <= address_r - (SYNC_LENGTH + BP_LENGTH);
    cascade_enable <= '1' when address_r = SYNC_LENGTH + BP_LENGTH + VALID_LENGTH + FP_LENGTH - 1 else '0';

end architecture rtl;

