library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package top_types is
    subtype vga_color is std_ulogic_vector(1 downto 0);
    type vga_pixel is record
        g: vga_color;
        b: vga_color;
        r: vga_color;
    end record vga_pixel;
end top_types;
