library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SubBytes is
  port(
    SB_in: in STD_LOGIC_VECTOR(31 downto 0);
    SB_out: out STD_LOGIC_VECTOR(31 downto 0) 
    -- blok nodig aan de uitgang die kolommen weer samenvoegt. Is dit de moeite?
  );
end SubBytes;

architecture Behavioural of SubBytes is

component bytesub is
  port(
    BS_in :in std_logic_vector( 7 downto 0 );
    BS_out :out std_logic_vector( 7 downto 0 )
  );
end component;

begin
--instantiatie van component
C1 : ByteSub port map (SB_in(31 downto 24), SB_out(31 downto 24));
C2 : ByteSub port map (SB_in(23 downto 16), SB_out(23 downto 16));
C3 : ByteSub port map (SB_in(15 downto 8), SB_out(15 downto 8));
C4 : ByteSub port map (SB_in(7 downto 0), SB_out(7 downto 0));

end Behavioural;
