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

    constant VGA_H_SYNC_LENGTH: natural := 136;
    constant VGA_H_BP_LENGTH: natural := 200;
    constant VGA_H_VALID_LENGTH: natural := 1280;
    constant VGA_H_FP_LENGTH: natural := 64;
    constant VGA_H_SYNC_POLARITY: bit := '0';

    constant VGA_V_SYNC_LENGTH: natural := 3;
    constant VGA_V_BP_LENGTH: natural := 24;
    constant VGA_V_VALID_LENGTH: natural := 800;
    constant VGA_V_FP_LENGTH: natural := 1;
    constant VGA_V_SYNC_POLARITY: bit := '0';

begin
    vga_sync_generator: entity work.vga_sync_generator
        generic map(
            H_SYNC_LENGTH => VGA_H_SYNC_LENGTH,
            H_BP_LENGTH => VGA_H_BP_LENGTH,
            H_VALID_LENGTH => VGA_H_VALID_LENGTH,
            H_FP_LENGTH => VGA_H_FP_LENGTH,
            H_SYNC_POLARITY => VGA_H_SYNC_POLARITY,

            V_SYNC_LENGTH => VGA_V_SYNC_LENGTH,
            V_BP_LENGTH => VGA_V_BP_LENGTH,
            V_VALID_LENGTH => VGA_V_VALID_LENGTH,
            V_FP_LENGTH => VGA_V_FP_LENGTH,
            V_SYNC_POLARITY => VGA_V_SYNC_POLARITY
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

    vga_pixel <=
        work.top_types.vga_color_test(vga_v_address, VGA_V_VALID_LENGTH, vga_h_address, VGA_H_VALID_LENGTH)
            when vga_h_valid = '1' and vga_v_valid = '1' else
        work.top_types.vga_pixel_black;

    vga_r <= vga_pixel.r;
    vga_g <= vga_pixel.g;
    vga_b <= vga_pixel.b;

end architecture rtl;