library IEEE;
library work;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_misc.all;
use ieee.numeric_std.all;
use work.util.all;
use work.ram_pkg.all;

entity top is
    port (
        clk : in std_logic;
        reset : in std_logic;

        cga_r : in std_logic;
        cga_g : in std_logic;
        cga_b : in std_logic;
        cga_i : in std_logic;

        cga_h_sync : in std_logic;
        cga_v_sync : in std_logic;

        vga_clk : in std_logic;
        vga_reset : in std_logic;

        vga_h_sync : out std_logic;
        vga_v_sync : out std_logic;
        vga_r : out std_logic_vector(1 downto 0);
        vga_g : out std_logic_vector(1 downto 0);
        vga_b : out std_logic_vector(1 downto 0)
    );
end top;

architecture rtl of top is
    constant CGA_H_VALID_SIZE : natural := 640;
    constant CGA_V_VALID_SIZE : natural := 200;

    constant VGA_H_VALID_SIZE : natural := 1280;
    constant VGA_V_VALID_SIZE : natural := 800;

    constant PIXEL_WIDTH : natural := 4;

    component video_decoder is
        generic (
            PIXEL_WIDTH : natural;

            INPUT_BUFFER_DEPTH : natural;
            H_SYNC_CAPTURE_DEPTH : natural;
            V_SYNC_CAPTURE_DEPTH : natural;
            PIXEL_DECODE_OFFSET : natural;
    
            CLOCK_MUL : natural;

            H_TOTAL_SIZE : natural;
            V_TOTAL_SIZE : natural;

            H_VALID_SIZE : natural;
            V_VALID_SIZE : natural;

            H_VALID_START : natural;
            V_VALID_START : natural);
        port (
            clk : in std_logic;
            reset : in std_logic;

            pixel : in std_logic_vector(PIXEL_WIDTH - 1 downto 0);

            h_sync : in std_logic;
            v_sync : in std_logic;

            address : out std_logic_vector(ceillog2(H_VALID_SIZE * V_VALID_SIZE) - 1 downto 0);
            address_valid : out std_logic;

            data : out std_logic_vector(PIXEL_WIDTH - 1 downto 0)
        );
    end component video_decoder;

    component video_encoder is
        generic (
            PIXEL_WIDTH : natural;

            V_ADDRESS_DIV : natural;
            H_ADDRESS_DIV : natural;

            H_TOTAL_SIZE : natural;
            V_TOTAL_SIZE : natural;

            H_SYNC_SIZE : natural;
            V_SYNC_SIZE : natural;

            H_VALID_SIZE : natural;
            V_VALID_SIZE : natural;

            H_VALID_START : natural;
            V_VALID_START : natural);
        port (
            clk : in std_logic;
            reset : in std_logic;

            pixel : out std_logic_vector(PIXEL_WIDTH - 1 downto 0);

            h_sync : out std_logic;
            v_sync : out std_logic;

            address : out std_logic_vector(ceillog2((H_VALID_SIZE / H_ADDRESS_DIV) * (V_VALID_SIZE / V_ADDRESS_DIV)) - 1 downto 0);
            address_valid : out std_logic;

            data : in std_logic_vector(PIXEL_WIDTH - 1 downto 0)
        );
    end component video_encoder;

    component xilinx_simple_dual_port_2_clock_ram is
        generic (
            RAM_WIDTH : integer := 64; -- Specify RAM data width
            RAM_DEPTH : integer := 512; -- Specify RAM depth (number of entries)
            RAM_PERFORMANCE : string := "LOW_LATENCY"; -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
            INIT_FILE : string := "RAM_INIT.dat" -- Specify name/location of RAM initialization file if using one (leave blank if not)
        );

        port (
            addra : in std_logic_vector((clogb2(RAM_DEPTH) - 1) downto 0); -- Write address bus, width determined from RAM_DEPTH
            addrb : in std_logic_vector((clogb2(RAM_DEPTH) - 1) downto 0); -- Read address bus, width determined from RAM_DEPTH
            dina : in std_logic_vector(RAM_WIDTH - 1 downto 0); -- RAM input data
            clka : in std_logic; -- Write Clock
            clkb : in std_logic; -- Read Clock
            wea : in std_logic; -- Write enable
            enb : in std_logic; -- RAM Enable, for additional power savings, disable port when not in use
            rstb : in std_logic; -- Output reset (does not affect memory contents)
            regceb : in std_logic; -- Output register enable
            doutb : out std_logic_vector(RAM_WIDTH - 1 downto 0) -- RAM output data
        );

    end component xilinx_simple_dual_port_2_clock_ram;

    signal cga_pixel : std_logic_vector(PIXEL_WIDTH - 1 downto 0);

    signal cga_address_valid : std_logic;
    signal cga_address : std_logic_vector(ceillog2(CGA_H_VALID_SIZE * CGA_V_VALID_SIZE) - 1 downto 0);
    signal cga_data : std_logic_vector(PIXEL_WIDTH - 1 downto 0);

    signal vga_address_valid : std_logic;
    signal vga_address : std_logic_vector(ceillog2(CGA_H_VALID_SIZE * CGA_V_VALID_SIZE) - 1 downto 0);
    signal vga_data : std_logic_vector(PIXEL_WIDTH - 1 downto 0);

    signal vga_pixel : std_logic_vector(PIXEL_WIDTH - 1 downto 0);

begin
    cga_pixel <= cga_i & cga_b & cga_g & cga_r;

    cga_decoder : video_decoder generic map(
        PIXEL_WIDTH => PIXEL_WIDTH,

        INPUT_BUFFER_DEPTH => 2,
        H_SYNC_CAPTURE_DEPTH => 4,
        V_SYNC_CAPTURE_DEPTH => 4,
        PIXEL_DECODE_OFFSET => 2,

        CLOCK_MUL => 8,

        H_TOTAL_SIZE => 960,
        V_TOTAL_SIZE => 316,

        H_VALID_SIZE => CGA_H_VALID_SIZE,
        V_VALID_SIZE => CGA_V_VALID_SIZE,

        H_VALID_START => 16#92#,
        V_VALID_START => 16#34#

        ) port map(
        clk => clk,
        reset => reset,
        pixel => cga_pixel,
        h_sync => cga_h_sync,
        v_sync => cga_v_sync,
        address => cga_address,
        address_valid => cga_address_valid,
        data => cga_data
    );

    vga_encoder : video_encoder generic map(
        PIXEL_WIDTH => PIXEL_WIDTH,

        H_ADDRESS_DIV => VGA_H_VALID_SIZE / CGA_H_VALID_SIZE,
        V_ADDRESS_DIV => VGA_V_VALID_SIZE / CGA_V_VALID_SIZE,

        H_TOTAL_SIZE => 1680,
        V_TOTAL_SIZE => 828,

        H_SYNC_SIZE => 136,
        V_SYNC_SIZE => 3,

        H_VALID_SIZE => VGA_H_VALID_SIZE,
        V_VALID_SIZE => VGA_V_VALID_SIZE,

        H_VALID_START => 136 + 200,
        V_VALID_START => 3 + 24

        ) port map(
        clk => vga_clk,
        reset => vga_reset,
        pixel => vga_pixel,
        h_sync => vga_h_sync,
        v_sync => vga_v_sync,
        address => vga_address,
        address_valid => vga_address_valid,
        data => vga_data
    );

    ram : xilinx_simple_dual_port_2_clock_ram generic map(
        RAM_WIDTH => PIXEL_WIDTH,
        RAM_DEPTH => 2 ** ceillog2(CGA_H_VALID_SIZE * CGA_V_VALID_SIZE),
        RAM_PERFORMANCE => "HIGH_PERFORMANCE",
        INIT_FILE => ""

        ) port map(
        enb => '1',

        clka => clk,
        addra => cga_address,
        dina => cga_data,
        wea => cga_address_valid,

        clkb => vga_clk,
        rstb => vga_reset,
        regceb => vga_address_valid,
        addrb => vga_address,
        doutb => vga_pixel

    );

    vga_r <= vga_pixel(3) & vga_pixel(0) when vga_pixel(0) = '1' else
        (others => '0');
    vga_g <= vga_pixel(3) & vga_pixel(1) when vga_pixel(1) = '1' else
        (others => '0');
    vga_b <= vga_pixel(3) & vga_pixel(2) when vga_pixel(2) = '1' else
        (others => '0');
end rtl;