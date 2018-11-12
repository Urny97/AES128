library ieee;
use ieee.std_logic_1164.all;

entity AddRoundKey is
  port (  key_in : in std_logic_vector(127 downto 0);
	  text_in: in std_logic_vector(127 downto 0); -- Ook 32 bits maken?
	  ARK_out: out std_logic_vector(31 downto 0));
end entity;

architecture AddRoundKey_arch of AddRoundKey is
begin
  process(key_in, text_in)
  begin
    -- 1e kolom
    ARK_out <= key_in(127 downto 96) xor text_in(127 downto 96);
    -- 2e kolom
    ARK_out <= key_in(95 downto 64) xor text_in(95 downto 64);
    -- 3e kolom
    ARK_out <= key_in(63 downto 32) xor text_in(63 downto 32);
    -- 4e kolom
    ARK_out <= key_in(31 downto 0) xor text_in(31 downto 0);
  end process;

end;
