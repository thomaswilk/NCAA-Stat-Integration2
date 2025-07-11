Mix.install([
  {:finch, "~> 0.16"},
  {:floki, "~> 0.34"},
  {:jason, "~> 1.4"}

])

Code.require_file("utils.exs", __DIR__)
Code.require_file("requests.exs", __DIR__)
Code.require_file("THEEBRAIN.exs", __DIR__)

{:ok, _} = Finch.start_link(name: StatsFinch)


defmodule Main do 
  # These functions take path for cv and pbp stats, rather than list of stats
  # Should take in list of stats instead
  # 

  
  def test_team_assigner(cv_stats, pbp_stats, period \\ 1) do 


    Team_Assigner.assign_cv_teams(cv_stats, pbp_stats)
    |> Statfitter.Utils.get_faceoffs()
    |> Statfitter.Utils.get_stat_by_period(period)
    |> Enum.with_index
    |> Enum.map(fn {fo, idx} ->
      IO.puts(" FO ##{idx}: #{fo.team}")
    end)


    IO.puts("\n\n")

    pbp_stats
    |> Statfitter.Utils.get_faceoffs
    |> Statfitter.Utils.get_stat_by_period(period)
    |> Enum.with_index
    |> Enum.map(fn {fo, idx} ->
      IO.puts(" FO ##{idx}: #{fo.team}")
    end)

  end



  def test_faceoff_difference(cv_stats, pbp_stats, period \\ 1) do

    IO.puts("pbp")
    pbp_fo_diff = 
    pbp_stats
    |> Statfitter.Utils.get_stat_by_period(period)
    |> Statfitter.Utils.get_faceoffs
    |> Statfitter.Utils.get_faceoff_difference_array_pbp

    pbp_fo_diff
    |> Enum.with_index()
    |> Enum.each(fn {val, idx} ->
          IO.puts("#{idx}: #{Statfitter.Utils.seconds_formatter(val)}")
            # IO.puts("#{idx}: #{val}")

        end)


    pbp_fo_diff
    |>Enum.sum()
    |> Statfitter.Utils.seconds_formatter()
    |> IO.inspect(label: "total time PBP")

    IO.puts("\n\n")
    IO.puts("cv")
    
    cv_fo_diff = 
    cv_stats
    |> Statfitter.Utils.get_faceoffs
    |> Statfitter.Utils.get_stat_by_period(period)
    |> Statfitter.Utils.get_faceoff_difference_array_cv

    cv_fo_diff
    |> Enum.with_index()
    |> Enum.each(fn {val, idx} ->
          IO.puts("#{idx}: #{Statfitter.Utils.seconds_formatter(val)}")
          # IO.puts("#{idx}: #{val}")
        end)

    cv_fo_diff
    |> Enum.sum()
    |> Statfitter.Utils.seconds_formatter()
    |> IO.inspect(label: "Total Time CV") 
  end

  # add output path
  def test_equal_faceoff_matching(cv_stats, pbp_stats, period) do 
    cv_period_stats =  cv_stats |> Statfitter.Utils.get_stat_by_period(period)
    pbp_period_stats =  pbp_stats |> Statfitter.Utils.get_stat_by_period(period)
    
    Statfitter.fo_equal(cv_period_stats, pbp_period_stats)
    |> IO.inspect()
  end 

  def test_match_whole_game_by_quarter(cv_stats, pbp_stats, _output_path \\ "output/default_dump.json") do 

     Statfitter.main(cv_stats, pbp_stats, "Cornell", "Maryland")
     |> Statfitter.Utils.get_faceoffs()
    # |> Utils.print_stats_json(output_path)
  end 

  def test_match_quarter(cv_stats, pbp_stats, period) do 
    cv_period_stats =  cv_stats |> Statfitter.Utils.get_stat_by_period(period)
    pbp_period_stats =  pbp_stats |> Statfitter.Utils.get_stat_by_period(period)

    Statfitter.match_quarter({cv_period_stats, pbp_period_stats})
  end



  # Seems redundant, but there is a good explaination         (i swear :())
  def test_match_whole_game(cv_stats, pbp_stats) do
    Statfitter.match_quarter({cv_stats, pbp_stats})
  end

end 

#------------Example of creating pbp stats and reading it-------------------#
  # Requests.get_play_by_play_by_teams("Cornell", "Maryland", "05/26/2025")
  # |> Utils.print_stats_json("output/pbpChip.json")

  # Utils.json_to_stats("output/pbpChip.json")
  # |> IO.inspect()
#---------------------------------------------------------------------#


    # This variables are to determine input for the testing commands
    # Do not remove/comment
    
    # Maryland vs Cornell 05/26/2025 (Championship game aka 'the chip')
    cv_path = "input/cvChip.json"
    pbp_path = "input/pbpChip.json"

    # Marist vs Siena 05/01/2025 
    # cv_path = "input/cvMaristSiena.json"
    # pbp_path = "input/pbpMaristSiena.json"


    cv_stats = Utils.json_to_stats(cv_path)
    pbp_stats = Utils.json_to_stats(pbp_path)
    



#------------ Testing functions from MAIN -----------------------#
  # # Period of game to test on

  period = 3 
  # Main.test_team_assigner(cv_stats, pbp_stats, period)

  Main.test_faceoff_difference(cv_stats, pbp_stats, period)


  Main.test_equal_faceoff_matching(cv_stats, pbp_stats, period)

  Main.test_match_quarter(cv_stats, pbp_stats, period)
  |> Statfitter.Utils.get_faceoffs()
#---------------------------------------------------------------------#


#------------Correct face off matching for the Championship------(ithink)-----# 
  # Main.test_match_whole_game("input/cvChip2.json", "input/pbpChip.json", "output/firstSuccessChip.json")
  # Main.test_match_whole_game("input/cvMaristSiena.json", "input/pbpMaristSiena.json")
  # |> Statfitter.Utils.get_faceoffs()
  # |> Enum.with_index()
  # |> Enum.map(fn {fo, idx} -> {idx, fo.team, Statfitter.Utils.seconds_formatter(fo.film_time_start)}
  #   end ) 
  # |> IO.inspect()
#---------------------------------------------------------------------#

#-------Tests for new pruning branch---(PBP faceoff < CV faceoff)-----#
  # # Code.require_file("stat.exs", __DIR__)


  cv_faceoffs = Statfitter.Utils.get_faceoffs(cv_stats)
  multiplier = 2
  # multiplier = Statfitter.prune2(cv_stats, pbp_stats)



  IO.inspect(multiplier, label: "Linear scaleer")

  # adjusted_pbp_faceoffs
   IO.puts("PBP")

  Statfitter.Utils.get_faceoffs(pbp_stats)
  |> Statfitter.Utils.update_time_multiplier(multiplier)
  |> Statfitter.Utils.get_faceoff_difference_array_pbp
  |> Enum.with_index()
  |> Enum.each(fn {val, idx} -> 
     IO.puts("#{idx}, #{Statfitter.Utils.seconds_formatter(val)}")
   end)
   IO.puts("\n\n CV")
  

  first_stat = hd(cv_faceoffs).film_time_end

  Statfitter.Utils.get_faceoff_difference_array_cv(cv_faceoffs, first_stat )  
  |> Enum.with_index()
  |> Enum.each(fn {val, idx} -> 
     IO.puts("#{idx}, #{Statfitter.Utils.seconds_formatter(val)}")
   end)

# ---------------------------------------------------------------------#


# -----------other testing stuff done with meeting with martin---------#
  # -------- not important ---- # 
# Utils.json_to_stats("output/firstSuccessChip.json")
# |> Statfitter.Utils.get_faceoffs
# |> Enum.map(fn stat -> 
#   stat.film_time_end
#   end
# )
# |> Enum.with_index()
# |> Enum.each(fn {val, idx} -> 
#   IO.puts("#{idx}, #{Statfitter.Utils.seconds_formatter(val)}")
# end)

# Main.test_match_whole_game(cv_stats, pbp_stats)
# |> Statfitter.Utils.get_faceoffs
# |> Enum.map(fn stat -> 
#   stat.film_time_end
#   end
# )
# |> Enum.with_index()
# |> Enum.each(fn {val, idx} -> 
#   IO.puts("#{idx}, #{Statfitter.Utils.seconds_formatter(val)}")
# end)