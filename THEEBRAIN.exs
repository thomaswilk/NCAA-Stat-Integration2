




defmodule Statfitter do 

    def match_pbp_to_cv(cv_stats, pbp_stats, _home, _away) do
        renamed_cv_stats = cv_stats#Team_Assigner.assign_cv_teams(cv_stats, pbp_stats)

        #sorts ALL stats by quarter
        Enum.flat_map(["1", "2", "3", "4"], fn period ->
            cv = Statfitter.Utils.get_stat_by_period(renamed_cv_stats, period)
            pbp = Statfitter.Utils.get_stat_by_period(pbp_stats, period)

            {cv, pbp}
           # match_quarter({cv, pbp})
        end)
    end     

    
    # def match_quarter(stats) do 
    #     {cv, pbp} = stats    

    #     num_cv_fo = Utils.get_faceoffs(cv_fo)
    #     |> Utils.get_stats_length()

    #     num_pbp_fo = Utils.get_faceoffs(pbp_fo)
    #     |> Utils.get_stats_length()
    #     # get number of face offs for each
        
    #     if num_cv_fo == num_pbp_fo do
    #     # cv_fo == pbp_fo
    #         # Line up accordingly
    #     else if num_cv_fo > num_pbp_fo do 
    #     # cv_fo > pbp_fo
    #         # Use estimated realtime to predict which faceoff is fake
    #     else do 
    #     # cv_fo < pbp_fo
    #         # Use estimated realtime to predict where to impute extra faceoff
    #         # [cv_stats[0] start time, cv_stats[-1] start time] is the time of the quarter. 
    #         # 
    #     end 
    # end

    # def fo_equal(cv_stats, pbp_stats) do
        
    # end


    # def pbp_gt_matching(cv_stats, pbp_stats) do 

    # end

    # def pbp_lt_matching(cv_stats, pbp_stats) do 

    # end 



    # def create_faceoff_times(cv_stats, pbp_stats) do 

    #     # From the list of stats, will return an array of time since previous face off 

    #     # given cv stats [40, 100, 160, 200]
    #     # Will return [40, 60, 60, 40]

    #     # given pbp stats [15 10 7 4]
    #     # Will return [0, 5, 3, 3]

    # end 

    # def match_possesion 
    defmodule Utils do 

        def get_faceoffs(stats) do
            faceoffs = Enum.filter(stats, fn stat -> stat.title == "Faceoff" end)
            faceoffs
        end 

        # type checking 
        def get_stat_by_period(stats, period) do
            period_stats = Enum.filter(stats, fn stat -> stat["period"] == period end)
            period_stats
        end


        #--------------------Face Off Difference Array algo--------------------------#
        def get_faceoff_difference_array_pbp([], _last) do 
            []
        end

        def get_faceoff_difference_array_pbp(faceoffs, last \\ 0) do 
            [first_fo | rest ] = faceoffs
            current_fo_time = first_fo.time

            [current_fo_time-last] ++ get_faceoff_difference_array_pbp(rest, current_fo_time)        
        end 
        #----------------------------------------------------------------------------#


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

# defmodule Team_Assigner do 
        
#         # This module takes the last two face off stats, sees who wins, and then assigns cv left and right to actual team names
#         # Given full list of stats
#         def assign_cv_teams(cv_stats, pbp_stats) do
#             adjusted = Statfitter.Utils.get_faceoffs(cv_stats, pbp_stats)
#             |> backwards_check
#             |> replace_team_names(cv_stats)

#             adjusted
#         end


#         ### TODO THE ACTUALL CHECKING 
#         def backwards_check(faceoffs) do 
#             cv_fo, pbp_fo = faceoffs 
#             cv_fo_r = Enum.reverse(cv_fo)
#             pbp_fo_r = Enum.reverse(pbp_fo)
#         end 


# # this thing replaces team names left and right from the cv stats with the actual team names
#         def replace_team_names(team_names, cv_stats) do 
#             {left, right} = team_names
#             converted_stats = 
#             Enum.map(cv_stats, fn stat -> 
#                 case stat["team"] do 
#                     "right" -> Map.put(stat, "team", right)
#                     "left" -> Map.put(stat, "team", left)
#                     _ -> stat
#                 end 
#             end)

#             converted_stats
#         end 
# end  # end assign team
