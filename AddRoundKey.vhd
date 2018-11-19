library ieee;
use IEEE.STD_LOGIC_1164.ALL;

entity AddRoundKey is
  port (  key_in : in std_logic_vector(127 downto 0);
	  data_in: in std_logic_vector(127 downto 0); -- Ook 32 bits maken?
	  ARK_out: out std_logic_vector(31 downto 0)
  );
end entity;

architecture AddRoundKey_arch of AddRoundKey is
begin
  process(key_in, data_in)
  begin
    -- 1e kolom
    ARK_out <= key_in(127 downto 96) xor data_in(127 downto 96);
    -- 2e kolom
    ARK_out <= key_in(95 downto 64) xor data_in(95 downto 64);
    -- 3e kolom
    ARK_out <= key_in(63 downto 32) xor data_in(63 downto 32);
    -- 4e kolom
    ARK_out <= key_in(31 downto 0) xor data_in(31 downto 0);
  end process;

end;
