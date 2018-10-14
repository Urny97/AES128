library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity AES128 is
  port(
    reset: in std_logic;
    clock: in std_logic;
    ce: in std_logic;
    data_in: in std_logic_vector(127 downto 0);
    key: in std_logic_vector(127 downto 0);
    data_out: out std_logic_vector(127 downto 0);
    done: out std_logic
  );
end AES128;

architecture Behavioural of AES128 is

  -- signalen om componenten aan elkaar te hangen
  signal key_out_ARK_in, ARK_out_SB_in, SB_out_shiftrow_in,
         shiftrow_out_MC_in, MC_out_ARK_mux_in,
         reg_out_ARK_in, ARK_mux_out_reg_in, DO_mux_out_reg_in,
         final_data_out: STD_LOGIC_VECTOR(127 downto 0);

  signal rcon_contr_rcon_keys: STD_LOGIC_VECTOR(3 downto 0);
  signal contr_out_ARK_mux_sel, contr_out_DO_mux_sel: STD_LOGIC;
  signal done_sign: STD_LOGIC;

  component Control_FSM is
    port(
    clock, reset, ce: in STD_LOGIC;
    roundcounter: out STD_LOGIC_VECTOR(3 downto 0);
    ARK_mux_sel, DO_mux_sel: out STD_LOGIC;
    done: out STD_LOGIC
    );
  end component;

  component KeyScheduler is
    port(
      roundcounter: in STD_LOGIC_VECTOR(3 downto 0);
		  clock: in std_logic;
			reset: in std_logic;
			ce: in std_logic;
			key: in std_logic_vector(127 downto 0);
			key_out: out std_logic_vector(127 downto 0)
    );
  end component;

  component AddRoundKey is
    port(
      key_in: in std_logic_vector(127 downto 0);
      text_in: in std_logic_vector(127 downto 0);
      ARK_out: out std_logic_vector(127 downto 0)
    );
  end component;

  component SubBytes is
    port(
      SB_in: in std_logic_vector( 127 downto 0 );
      SB_out: out std_logic_vector( 127 downto 0 )
    );
  end component;

  component ShiftRow is
    port(
      shiftrow_in: in std_logic_vector(127 downto 0);
      shiftrow_out: out std_logic_vector(127 downto 0)
    );
  end component;

  component MixColumn is
    port(
      MC_in: in std_logic_vector (127 downto 0);
		  MC_out: out std_logic_vector(127 downto 0)
    );
  end component;

begin

  -- instantiaties van componenten
  KeyS: KeyScheduler port map(rcon_contr_rcon_keys, clock, reset, ce, key,
                            key_out_ARK_in);
  Ctl_FSM: Control_FSM port map(clock, reset, ce, rcon_contr_rcon_keys,
                           contr_out_ARK_mux_sel, contr_out_DO_mux_sel,
                           done_sign);
  ARK: AddRoundKey port map(key_out_ARK_in, reg_out_ARK_in, ARK_out_SB_in);
  SB: SubBytes port map(ARK_out_SB_in, SB_out_shiftrow_in);
  SR: ShiftRow port map(SB_out_shiftrow_in, shiftrow_out_MC_in);
  MC: MixColumn port map(shiftrow_out_MC_in, MC_out_ARK_mux_in);

  data_out <= final_data_out;
  done <= done_sign;

  -- ARK mux
  ARK_mux: process(contr_out_ARK_mux_sel, reg_out_ARK_in, MC_out_ARK_mux_in, data_in)
  begin
    case contr_out_ARK_mux_sel is
      when '0' => ARK_mux_out_reg_in <= reg_out_ARK_in;
      when '1' => ARK_mux_out_reg_in <= data_in;
      when others => ARK_mux_out_reg_in <= MC_out_ARK_mux_in;
    end case;
  end process;

  -- DataOut mux
  DO_mux: process(contr_out_DO_mux_sel, final_data_out, shiftrow_out_MC_in)
  begin
    case contr_out_DO_mux_sel is
      when '0' => DO_mux_out_reg_in <= (others => '0');
      when '1' => DO_mux_out_reg_in <= shiftrow_out_MC_in;
      when others => DO_mux_out_reg_in <= (others => '0');
    end case;
  end process;

  -- ARK_reg
  ARK_reg: process(clock, reset)
  begin
    if reset = '1' then
      reg_out_ARK_in <= (others => '0');
    elsif rising_edge(clock) then
      if ce = '1' then
        reg_out_ARK_in <= ARK_mux_out_reg_in;
      end if;
    end if;
  end process;

  -- DO_reg
  DO_reg: process(clock, reset)
  begin
    if reset = '1' then
      final_data_out <= (others => '0');
    elsif rising_edge(clock) then
      if ce = '1' then
        final_data_out <= DO_mux_out_reg_in;
      end if;
    end if;
  end process;

end Behavioural;
