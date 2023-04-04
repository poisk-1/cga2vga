library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package top_types is
    type cga_pixel_t is record
        i: std_ulogic;
        g: std_ulogic;
        b: std_ulogic;
        r: std_ulogic;
    end record cga_pixel_t;

    subtype vga_color_t is std_ulogic_vector(1 downto 0);
    type vga_pixel_t is record
        g: vga_color_t;
        b: vga_color_t;
        r: vga_color_t;
    end record vga_pixel_t;

    function vga_pixel_black return vga_pixel_t;

    function vga_color_test(
        v_address: integer;
        v_address_max: integer;
        h_address: integer;
        h_address_max: integer) return vga_pixel_t;
end top_types;

package body top_types is
    function vga_pixel_black return vga_pixel_t is
    begin
        return (r => "00", g => "00", b => "00");
    end function vga_pixel_black;

    function vga_color_test(
        v_address: integer;
        v_address_max: integer;
        h_address: integer;
        h_address_max: integer) return vga_pixel_t is

        constant H_COLOR_ADDRESS_BITS: natural := 10;
        constant V_COLOR_ADDRESS_BITS: natural := 9;

        constant H_COLOR_ADDRESS_MAX: natural := 2 ** H_COLOR_ADDRESS_BITS;
        constant V_COLOR_ADDRESS_MAX: natural := 2 ** V_COLOR_ADDRESS_BITS;

        constant H_COLOR_OFFSET: integer := (h_address_max - H_COLOR_ADDRESS_MAX) / 2;
        constant V_COLOR_OFFSET: integer := (v_address_max - V_COLOR_ADDRESS_MAX) / 2;

        variable h_color_address: std_ulogic_vector(H_COLOR_ADDRESS_BITS - 1 downto 0);
        variable v_color_address: std_ulogic_vector(V_COLOR_ADDRESS_BITS - 1 downto 0);    
    begin
        if
            v_address >= V_COLOR_OFFSET and
            v_address < (V_COLOR_OFFSET + V_COLOR_ADDRESS_MAX) and
            h_address >= H_COLOR_OFFSET and
            h_address < (H_COLOR_OFFSET + H_COLOR_ADDRESS_MAX) then

            h_color_address := std_ulogic_vector(to_unsigned(h_address - H_COLOR_OFFSET, h_color_address'length));
            v_color_address := std_ulogic_vector(to_unsigned(v_address - V_COLOR_OFFSET, v_color_address'length));
    
            return (
                r => h_color_address(H_COLOR_ADDRESS_BITS - 3 downto H_COLOR_ADDRESS_BITS - 4),
                g => h_color_address(H_COLOR_ADDRESS_BITS - 1 downto H_COLOR_ADDRESS_BITS - 2),
                b => v_color_address(V_COLOR_ADDRESS_BITS - 1 downto V_COLOR_ADDRESS_BITS - 2));
        else
            return vga_pixel_black;
        end if;
    end function vga_color_test;        
end package body;
