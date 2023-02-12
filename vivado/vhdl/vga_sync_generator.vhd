library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync_generator is
    generic (
        H_SYNC_LENGTH: natural;
        H_BP_LENGTH: natural;
        H_VALID_LENGTH: natural;
        H_FP_LENGTH: natural;
        H_SYNC_POLARITY: bit;
        
        V_SYNC_LENGTH: natural;
        V_BP_LENGTH: natural;
        V_VALID_LENGTH: natural;
        V_FP_LENGTH: natural;
        V_SYNC_POLARITY: bit
    );

    port (
        clk   : in std_ulogic;
        resetn : in std_ulogic;
        h_sync: out std_ulogic;
        v_sync: out std_ulogic
    );
end entity vga_sync_generator;

architecture rtl of vga_sync_generator is
    signal h_sync_0: std_ulogic;
        
    signal cascade_enable: std_ulogic;
begin
    h_sync_generator: entity work.sync_generator
        generic map (
            SYNC_LENGTH => H_SYNC_LENGTH,
            BP_LENGTH => H_BP_LENGTH,
            VALID_LENGTH => H_VALID_LENGTH,
            FP_LENGTH => H_FP_LENGTH,
            SYNC_POLARITY => H_SYNC_POLARITY
        )
        port map (
            clk => clk,
            resetn => resetn,
            cascade_enable => cascade_enable,
            enable => '1',
            sync => h_sync_0);
        
    v_sync_generator: entity work.sync_generator
        generic map (
            SYNC_LENGTH => V_SYNC_LENGTH,
            BP_LENGTH => V_BP_LENGTH,
            VALID_LENGTH => V_VALID_LENGTH,
            FP_LENGTH => V_FP_LENGTH,
            SYNC_POLARITY => V_SYNC_POLARITY
        )    
        port map (
            clk => clk,
            resetn => resetn,
            enable => cascade_enable,
            sync => v_sync);
            
    process (clk) begin
        if rising_edge(clk) then
            h_sync <= h_sync_0;
        end if;
    end process;
    
end architecture;