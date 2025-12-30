library IEEE;
use ieee.math_real.all;

package util is
    function ceillog2 (depth: in positive) return natural;
end util;

package body util is

function ceillog2(depth : positive) return natural is
begin
    return integer(ceil(log2(real(depth))));
end function;

end package body util;
