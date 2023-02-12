library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    port (
        vga_clk: in std_ulogic;
        vga_resetn: in std_ulogic;
        vga_v_sync: out std_ulogic;
        vga_h_sync: out std_ulogic;
        vga_r: out std_ulogic_vector(1 downto 0);
        vga_g: out std_ulogic_vector(1 downto 0);
        vga_b: out std_ulogic_vector(1 downto 0)
    );
end entity top;

architecture rtl of top is
    signal vga_h_valid: std_ulogic;
    signal vga_h_address: integer;

    signal vga_v_valid: std_ulogic;
    signal vga_v_address: integer;

    signal vga_pixel: work.top_types.vga_pixel;
    signal vga_h_address_v: std_ulogic_vector(10 downto 0);
    signal vga_v_address_v: std_ulogic_vector(9 downto 0);
begin
    vga_sync_generator: entity work.vga_sync_generator
        generic map(
            H_SYNC_LENGTH => 136,
            H_BP_LENGTH => 200,
            H_VALID_LENGTH => 1280,
            H_FP_LENGTH => 64,
            H_SYNC_POLARITY => '0',

            V_SYNC_LENGTH => 3,
            V_BP_LENGTH => 24,
            V_VALID_LENGTH => 800,
            V_FP_LENGTH => 1,
            V_SYNC_POLARITY => '0'            
        )
        port map (
            clk => vga_clk,
            resetn => vga_resetn,
            v_sync => vga_v_sync,
            v_valid => vga_v_valid,
            v_address => vga_v_address,
            h_sync => vga_h_sync,
            h_valid => vga_h_valid,
            h_address => vga_h_address);

    vga_h_address_v <= std_ulogic_vector(to_unsigned(vga_h_address, 11));
    vga_v_address_v <= std_ulogic_vector(to_unsigned(vga_v_address, 10));

    vga_pixel <= 
        (
            r => vga_h_address_v(7 downto 6),
            g => vga_h_address_v(9 downto 8),
            b => vga_v_address_v(8 downto 7))
            when vga_h_valid = '1' and vga_v_valid = '1' else
        (r => "00", g => "00", b => "00");

    vga_r <= vga_pixel.r;
    vga_g <= vga_pixel.g;
    vga_b <= vga_pixel.b;

end architecture rtl;