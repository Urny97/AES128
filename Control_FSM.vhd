library ieee;
use ieee.STD_LOGIC_1164.ALL;
use ieee.STD_LOGIC_ARITH.ALL;
use ieee.STD_LOGIC_UNSIGNED.ALL;

entity Control_FSM is
  port(
    clock, reset, ce: in STD_LOGIC;
    roundcounter: out STD_LOGIC_VECTOR(3 downto 0);
    which_column: out STD_LOGIC_VECTOR(2 downto 0);
    ARK_mux_sel: out STD_LOGIC_VECTOR(1 downto 0);
    DO_mux_sel, done, clear, hold_data_out,
    read_data_in, append: out STD_LOGIC
  );
end Control_FSM;

architecture Behavioural of Control_FSM is

  type tStates is (sIdle, sFirstRound, sLoopUntil10, sLastRound, sDone);
  -- Idle: de chip doet niets
  -- sFirstRound: Plain_text wordt een eerste ronde geëncodeerd
  -- LoopUntil9: data loopt negen keer door de verschillende codeerstappen
  -- LastLoop: in de 10e ronde wordt de MixColumn stap overgeslagen
  -- Done: de chip is klaar met de encryptie

  signal curState, nxtState: tStates;
  signal rcon_reg, clk_ctr_sign: STD_LOGIC_VECTOR(3 downto 0) := "0000";
  signal which_column_sign: STD_LOGIC_VECTOR(2 downto 0);
  signal done_sign, count_enable, clear_sign, hold_data_out_sign,
  read_data_in_sign, append_sign: STD_LOGIC;

  begin
    roundcounter <= rcon_reg;
    done <= done_sign;
    clear <= clear_sign;
    hold_data_out <= hold_data_out_sign;
    read_data_in <= read_data_in_sign;
    which_column <= which_column_sign;
    append <= append_sign;

-- Clock Counter
  clk_ctr: process(clock, reset)
  begin
    if reset = '1' then
      clk_ctr_sign <= "0000";
    elsif rising_edge(clock) then
      if ce = '1' and count_enable = '1' then
        case curState is
          when sFirstRound =>
            if clk_ctr_sign = "0001" then
              clk_ctr_sign <= "0000";
            else
              clk_ctr_sign <= clk_ctr_sign + 1;
            end if;
          when sLoopUntil10 => 
            if clk_ctr_sign = "1001" then
              clk_ctr_sign <= "0000";
            else
              clk_ctr_sign <= clk_ctr_sign + 1;
            end if;
          when sLastRound =>
            if clk_ctr_sign = "1101" then
              clk_ctr_sign <= "0000";
            else
              clk_ctr_sign <= clk_ctr_sign + 1;
            end if;
          when others => clk_ctr_sign <= clk_ctr_sign;
        end case;
      else
        clk_ctr_sign <= clk_ctr_sign;
      end if;
    end if;
  end process;

-- Roundcounter
  incr_ctr: process(clock, reset)
  begin
    if reset = '1' then
      rcon_reg <= "0000";
    elsif rising_edge(clock) then
      if ce = '1' and count_enable = '1' then
        case curState is
          when sFirstRound =>
            if clk_ctr_sign = "0001" then
              rcon_reg <= rcon_reg + 1;
            else
              rcon_reg <= rcon_reg;
            end if;
          when sLoopUntil10 =>
            if clk_ctr_sign = "1001" then
              rcon_reg <= rcon_reg + 1;
            else
              rcon_reg <= rcon_reg;
            end if;
          when sLastRound =>
           if clk_ctr_sign = "1101" then
              rcon_reg <= rcon_reg + 1;
            else
              rcon_reg <= rcon_reg;
            end if;
          when others => rcon_reg <= rcon_reg;
        end case;
      else
        rcon_reg <= rcon_reg;
      end if;
    end if;
  end process;

  -- Column counter
  Column_counter: process(clock, reset)
  begin
    if reset = '1' then
      which_column_sign <= "000";
    elsif rising_edge(clock) then
      if ce = '1' then
        if which_column_sign = "100" then
          which_column_sign <= "001";
          append_sign <= '1';
        else
          which_column_sign <= which_column_sign + 1;
          append_sign <= '0';
        end if;
      else
        which_column_sign <= which_column_sign;
      end if;
    end if;
  end process;

-- State Register
  FSM_switchstate : process(clock, reset)
  begin
    if reset = '1' then
      curState <= sIdle;
    elsif rising_edge(clock) then
      curState <= nxtState;
    end if;
  end process;

--Next State Register
  FSM_nxtState : process(curState, ce, rcon_reg, reset)
  begin
    case curState is
        when sIdle =>
          if reset = '1' then
            nxtState <= sIdle;
          else
            if ce = '1' then
              if rcon_reg = "0000" then
                nxtState <= sFirstRound;
              end if;
            else
              nxtState <= curState;
            end if;
          end if;

        when sFirstRound =>
          if reset = '1' then
            nxtState <= sIdle;
          else
            if ce = '1' then
              if rcon_reg = "0001" then
                nxtState <= sLoopUntil10;
              end if;
            else
              nxtState <= curState;
            end if;
          end if;

        when sLoopUntil10 =>
          if reset = '1' then
            nxtState <= sIdle;
          else
            if ce = '1' then
              if rcon_reg = "1010" then
                nxtState <= sLastRound;
              end if;
            else
              nxtState <= curState;
            end if;
          end if;

        when sLastRound =>
          if reset = '1' then
            nxtState <= sIdle;
          else
            if ce = '1' then
              nxtState <= sDone;
            else
              nxtState <= curState;
            end if;
          end if;

        when sDone =>
          if reset = '1' then
            nxtState <= sIdle;
          else
            if ce = '0' then
              nxtState <= sIdle;
            else
              nxtState <= curState;
            end if;
          end if;

        when others =>
          if reset = '1' then
            nxtState <= sIdle;
          else
            if ce = '1' then
              nxtState <= sIdle;
            else
              nxtState <= curState;
            end if;
          end if;
    end case;
  end process;

  -- Output Function
  Control_out: process(curState)
  begin
    case curState is
      when sIdle => DO_mux_sel <= '0'; ARK_mux_sel <= "00"; done_sign <= '0'; 
                    clear_sign <= '1'; count_enable <= '0';
                    hold_data_out_sign <= '0'; read_data_in_sign <= '0';

      when sFirstRound => DO_mux_sel <= '0'; ARK_mux_sel <= "00"; done_sign <= '0';
                          clear_sign <= '0'; count_enable <= '1'; 
                          hold_data_out_sign <= '0'; read_data_in_sign <= '1';

      when sLoopUntil10 => DO_mux_sel <= '0'; ARK_mux_sel <= "01"; done_sign <= '0';
                          clear_sign <= '0'; count_enable <= '1'; 
                          hold_data_out_sign <= '0'; read_data_in_sign <= '0';

      when sLastRound => DO_mux_sel <= '1'; ARK_mux_sel <= "11"; done_sign <= '0';
                         clear_sign <= '0'; count_enable <= '1'; 
                         hold_data_out_sign <= '1'; read_data_in_sign <= '0';

      when sDone => DO_mux_sel <= '1'; ARK_mux_sel <= "11"; done_sign <= '1';
                    clear_sign <= '0'; count_enable <= '0'; 
                    hold_data_out_sign <= '0'; read_data_in_sign <= '0';
    end case;
  end process;

end Behavioural;
