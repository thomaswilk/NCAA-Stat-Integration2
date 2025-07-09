
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

    def match_pbp_to_cv(cv_stats, pbp_stats, _home, _away) do
        renamed_cv_stats = cv_stats #Team_Assigner.assign_cv_teams(cv_stats, pbp_stats)

        #sorts ALL stats by quarter
        Enum.flat_map(["1", "2", "3", "4"], fn period ->
            cv = Statfitter.Utils.get_stat_by_period(renamed_cv_stats, period)
            pbp = Statfitter.Utils.get_stat_by_period(pbp_stats, period)

            {cv, pbp}
           # match_quarter({cv, pbp})
        end)
    end     

    
#   # def match_quarter(stats) do 
    #     {cv, pbp} = stats    

    #     num_cv_fo = Utils.get_faceoffs(cv_fo)
    #     |> length()

    #     num_pbp_fo = Utils.get_faceoffs(pbp_fo)
    #     |> length()
    #     # get number of face offs for each
        
    #     if num_cv_fo == num_pbp_fo do
    #     # cv_fo == pbp_fo
    #         # Line up accordingly


            
    #     else if num_cv_fo > num_pbp_fo do 
      
    #     else do 

    #     end 
# end

    # TODO: Implement matching branch 
    # will be easy

    def fo_equal(_cv_stats, _pbp_stats) do
        nil
    end

    # TODO: Implement parsing branch -----# 
     # FALSE DETECTIONS
        # Three ways to possibly detect  false detection

        # 1: how long since last face off
            # using the face off difference and some multiplier to account from game time to real time, if a length is too long then found it ! 

        # 2: how long the clip is 
            # many false detections are short snippets (10 seconds or less in length) and can be scanned that way

        # 3: From the result of the face off, we can see which team won and then use sliding window to see where it fucks up or something 
            # say cv = [left, right, right, left, left ]
            # and pbp= [left, right, right, left ]
            # then we can see that one of the last two must be incorrect 
    #-----------------------------------------#

    # Assumptions: . 

    def pbp_lt_cv_matching(cv_stats, pbp_stats) do 
       Statfitter.Utils.get_faceoffs(cv_stats)
        |> Enum.map(fn stat -> 
            stat.team
        end)

        Statfitter.Utils.get_faceoffs(pbp_stats)
        |> Enum.map(fn stat -> 
            stat.team
        end)
    end

    # TODO: Implement imputation branch----#
        # tbh no clue yet 
            # Use estimated realtime to predict where to impute extra faceoff?
            # [cv_stats[0] start time, cv_stats[-1] start time] is the time of the quarter?
            # 
    #-------------------------------------#
    def pbp_gt_cv_matching(_cv_stats, _pbp_stats) do 
        nil
    end 



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
            if stat.film_time_end and stat.film_time_start do
                Float.round((stat.film_time_end - stat.film_time_start) * 1.0, 2)
            else 
                nil
            end    
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

            replace_team_names({left_team, right_team}, cv_stats)
        end

        # TODO: Implement a method of matching teams properly 

        def backwards_check({cv_faceoffs, pbp_faceoffs}) do
            cv_fo = cv_faceoffs |> Statfitter.Utils.get_stat_by_period(1) |> List.last()
            pbp_fo = pbp_faceoffs |> Statfitter.Utils.get_stat_by_period(1) |> List.last()


            # who left who right?
            case cv_fo.team do
                "left" -> IO.inspect({pbp_fo.team, get_other_team(pbp_fo.team, pbp_faceoffs)})
                        {pbp_fo.team, get_other_team(pbp_fo.team, pbp_faceoffs)}
                "right" -> IO.inspect({get_other_team(pbp_fo.team, pbp_faceoffs), pbp_fo.team})
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
