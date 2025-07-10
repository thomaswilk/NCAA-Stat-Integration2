
# Some things to consider while building 
#
# Overtime games:
#   Period 4 contains those stats?
#
# Misdrawn period boundaries:
#   The input will not be perfect and cannot assume that 
#   every stat is perfectly parsed into periods 1234 
#
# Real time vs game clock:
#   At any moment the real time can jump for minutes 
#   due to injuries, timeouts, or TV scheduling
#
# Doesnt have to be perfect:
#   Dont set the bar too high, sometimes shit 
#   happens and there's no way to fix it



defmodule Statfitter do 
    defmodule Utils do 

        def seconds_formatter(seconds) do 
            min = trunc(seconds / 60) 
            sec = rem(trunc(seconds), 60)
            "#{min}:#{String.pad_leading(Integer.to_string(sec), 2, "0")}"
        end 

        def get_faceoffs(stats) do
            faceoffs = Enum.filter(stats, fn stat -> stat.title == "Faceoff" end)
            faceoffs
        end 

        def get_faceoffs(stats1, stats2) do
            {get_faceoffs(stats1), get_faceoffs(stats2)}
        end 

        # type checking 
        def get_stat_by_period(stats, period) do
            period_stats = Enum.filter(stats, fn stat -> stat.period == period end)
            period_stats
        end

      #--------------------Face Off Difference Array algo--------------------------#

        # TODO Update this so that first face off of each period is not 15:00 
        # Create offset based off of period number basically 
        # Mabye it should be called with the full stats rather than just list of faceoffs
        # Would make sense 

        #pbp
        def get_faceoff_difference_array_pbp(faceoffs, last \\ 0)

        def get_faceoff_difference_array_pbp([], _last) do 
            []
        end

        def get_faceoff_difference_array_pbp(faceoffs, last) do 
            [first_fo | rest ] = faceoffs
            current_fo_time = first_fo.time

            #gets time of current stat, subtracts time from last stat.
            # Recursive pattern matchin' bb 
            [Float.round((current_fo_time - last) * 1.0, 2) | get_faceoff_difference_array_pbp(rest, current_fo_time)]
        end 

        #cv
        def get_faceoff_difference_array_cv(faceoffs, last \\ 0)

        def get_faceoff_difference_array_cv([], _last) do 
            []
        end

        def get_faceoff_difference_array_cv(faceoffs, last) do 
            [first_fo | rest ] = faceoffs
            current_fo_time = first_fo.film_time_end

            #gets time of current stat, subtracts time from last stat.
            # Recursive pattern matchin' bb 
            [Float.round((current_fo_time - last) * 1.0, 2) | get_faceoff_difference_array_cv(rest, current_fo_time)]
        end 
      #----------------------------------------------------------------------------#
        def get_length_of_stat(stat) do 
            if is_number(stat.film_time_end) and is_number(stat.film_time_start) do
                trunc(stat.film_time_end - stat.film_time_start)
            else 
                nil
            end    
        end 

        def update_time_multiplier(stats, multiplier) do 
            Enum.map(stats, fn stat -> 
                new_time = stat.time * multiplier
                %Stat{  stat | time: new_time }
            end )
        end 


        def update_time_continuous(stats) do
            # Turnovers cause issues due to sometimes missing time
            Enum.filter(stats, 
                fn stat -> stat.time != "" 
            end)
            |> 
            Enum.map(fn stat ->
                [min, sec] = String.split(stat.time, ":")
                 |> Enum.map(&String.to_integer/1)
                total_seconds = (stat.period* 15*60) - (min * 60 + sec)  
                %Stat{stat | time: total_seconds}
            end )
        end
    end # End of utils 

    def main(cv_stats, pbp_stats, _home, _away) do
        renamed_cv_stats = Team_Assigner.assign_cv_teams(cv_stats, pbp_stats)
        #sorts ALL stats by quarter

        Enum.flat_map([1, 2, 3, 4], fn period ->
            cv = Statfitter.Utils.get_stat_by_period(renamed_cv_stats, period)


            pbp = Statfitter.Utils.get_stat_by_period(pbp_stats, period)

           match_quarter({cv, pbp})
        end)
    end     

    
     def match_quarter(stats) do 
        {cv, pbp} = stats    

        
        num_cv_fo = Utils.get_faceoffs(cv)
        |> length()

        
        num_pbp_fo = Utils.get_faceoffs(pbp)
        |> length()
        # get number of face offs for each
        # IO.puts("Num cv:#{num_cv_fo}, Num PBP: #{num_pbp_fo}")
        cond do
            num_cv_fo == num_pbp_fo -> 
                fo_equal(cv, pbp)
                

            num_cv_fo < num_pbp_fo -> 
                pbp_gt_cv_matching(cv, pbp)

            true -> 
                pbp_lt_cv_matching(cv, pbp, num_pbp_fo - num_cv_fo)
        end
    end


    #Done?
    def fo_equal(cv_stats, pbp_stats) do

        #Index cv faceoffs so you can transfer film times to pbp stats in order
        cv_fo = Utils.get_faceoffs(cv_stats)
        cv_fo_map = Enum.with_index(cv_fo) |> Enum.into(%{}, fn {stat, idx} -> {idx, stat} end)

        Utils.get_faceoffs(pbp_stats)
        |> Enum.with_index()
        |> Enum.map(fn {stat, idx} ->
            if stat.title == "Faceoff" do
            case Map.fetch(cv_fo_map, idx) do
                {:ok, cv_fo} ->
                    %Stat{stat |
                        film_time_end: cv_fo.film_time_end,
                        film_time_start: cv_fo.film_time_end - 12
                    }

                :error -> 
                    IO.puts("Erorrrrrr")
                    stat
            end
            else
            stat
            end
        end)
    end


# TODO: Implement pruning branch -----# 
     # FALSE DETECTIONS
        # Three ways to possibly detect  false detection

        # 1: how long since last face off
            # using the face off difference and some multiplier to account from game time to real time, if a length is too long then found it ! 


        # THIS IS THE CURRENT IMPLEMENTATION
        # Occam's razor: simplest solution usually best (or something like that)
        # 2: how long the clip is 
            # many false detections are short snippets (10 seconds or less in length) and can be scanned that way
            # gets the n shortest clips and removes them 


        # 3: From the result of the face off, we can see which team won and then use sliding window to see where it fucks up or something 
            # say cv = [left, right, right, left, left ]
            # and pbp= [left, right, right, left ]
            # then we can see that one of the last two must be incorrect 
#-----------------------------------------#
    def pbp_lt_cv_matching(cv_stats, pbp_stats, difference) do 
        cv_fo = Utils.get_faceoffs(cv_stats)

        shortest_n = 
            Enum.map(cv_fo,  fn fo -> 
                length = Utils.get_length_of_stat(fo)
                {fo, length} 
            end)
            |> Enum.sort(fn {_fo1, length1}, {_fo2, length2} -> length1 >= length2 end)
            |> Enum.take(difference)
            |> Enum.map(fn {stat, _length} -> stat end)

        # IO.inspect(shortest_n, label: "Face offs removed:")
        Enum.filter(cv_stats, fn stat -> stat not in shortest_n end)
        |> fo_equal(pbp_stats)
    end


    def prune2(cv_stats, pbp_stats) do 
            cv_fo_diff = Utils.get_faceoffs(cv_stats)
            |> Utils.get_faceoff_difference_array_cv
            |> Enum.sum()

            pbp_fo_diff = Utils.get_faceoffs(pbp_stats)
            |> Utils.get_faceoff_difference_array_pbp
            |> Enum.sum()
            
            (cv_fo_diff-20)/pbp_fo_diff
        end 






# TODO: Implement imputation branch----#
        # tbh no clue yet 
            # Use estimated realtime to predict where to impute extra faceoff?
            # [cv_stats[0] start time, cv_stats[-1] start time] is the time of the quarter?
            # 
#-------------------------------------#
    def pbp_gt_cv_matching(_cv_stats, _pbp_stats) do 
        IO.puts("Quarter PBP > CV")
        [%Stat{}]
    end
end


#Move this module inside of statfitter?
defmodule Team_Assigner do 
        # This module determines which team is "left" and which team is "right" in cv stats
        # Main function is assign_cv_teams
        # Pass the two list of stats and then it will return cv_stats with the team name
        # matching the team name abbreviation in the pbp stats


        # Given full list of stats
       def assign_cv_teams(cv_stats, pbp_stats) do
            {cv_faceoffs, pbp_faceoffs} = Statfitter.Utils.get_faceoffs(cv_stats, pbp_stats)

            {left_team, right_team} =
            {cv_faceoffs, pbp_faceoffs}
            |> backwards_check()

            adjusted = replace_team_names({left_team, right_team}, cv_stats)
            adjusted 
        end

        # TODO: Implement a method of matching teams properly 

        def backwards_check({cv_faceoffs, pbp_faceoffs}) do
            cv_fo = cv_faceoffs |> Statfitter.Utils.get_stat_by_period(1) |> List.last()
            pbp_fo = pbp_faceoffs |> Statfitter.Utils.get_stat_by_period(1) |> List.last()


            # who left who right?
            case cv_fo.team do
                "left" -> 
                        #IO.inspect({pbp_fo.team, get_other_team(pbp_fo.team, pbp_faceoffs)})
                        {pbp_fo.team, get_other_team(pbp_fo.team, pbp_faceoffs)}
                "right" -> 
                        #IO.inspect({get_other_team(pbp_fo.team, pbp_faceoffs), pbp_fo.team})
                        {get_other_team(pbp_fo.team, pbp_faceoffs), pbp_fo.team}
                _ -> {"Unknown", "Unknown"}
            end
        end


        # this thing replaces team names left and right from the cv stats with the actual team names
        def replace_team_names({left, right}, cv_stats) do
            Enum.map(cv_stats, fn stat ->
                case stat.team do
                    "left" -> %Stat{stat | team: left}
                    "right" -> %Stat{stat | team: right}
                    _ -> stat
                end
            end)
        end

        # 
        defp get_other_team(team, pbp_faceoffs) do
            Enum.find_value(pbp_faceoffs, fn stat ->
                other = stat.team
                if other != team, do: other, else: nil
            end)
        end

end 
