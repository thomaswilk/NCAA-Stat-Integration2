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



  def test_loss(cv_fo_diff, pbp_fo_diff) do
    Enum.zip(cv_fo_diff, pbp_fo_diff)
    |> Enum.map(fn {cv, pbp} -> trunc(abs(cv - pbp)) end)
    |> Enum.sum()
  end

  #removes index from list
  def test_delete(stats, index) do
    {first, second} = Enum.split(stats, index)
    second_half = tl(second)
    first ++ second_half
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
    # cv_path = "input/cvChip.json"
    # pbp_path = "input/pbpChip.json"

    # Marist vs Siena 05/01/2025 
    cv_path = "input/cvMaristSiena.json"
    pbp_path = "input/pbpMaristSiena.json"


    cv_stats = Utils.json_to_stats(cv_path)
    pbp_stats = Utils.json_to_stats(pbp_path)
    



#------------ Testing functions from MAIN -----------------------#
  # # Period of game to test on

  # period = 3 
  # # Main.test_team_assigner(cv_stats, pbp_stats, period)

  # Main.test_faceoff_difference(cv_stats, pbp_stats, period)


  # Main.test_equal_faceoff_matching(cv_stats, pbp_stats, period)

  # Main.test_match_quarter(cv_stats, pbp_stats, period)
  # |> Statfitter.Utils.get_faceoffs()
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

  # marist vs siena false face offs: 14, 18,  32 



  # MARTIN
  # This might be the algorithm we choose to go with.
  # It iterates through each cv faceoff, deleting one at a time
  # Each time it removes a face off, It calculates "loss"
  # Searching for the difference in time pbp faceoffs and cv faceoffs 
  # After every index is tested, it will sum the loss 
  # Then we take the removal which generated lowest loss 

  # multiplier = 1
  # multiplier = 2
  # multiplier = 3
  # multiplier = 4
  # multiplier = 5
  multiplier = 0.8
  cv_fo = cv_stats |> Statfitter.Utils.get_faceoffs
  first_cv_fo_time = hd(cv_fo).film_time_end
  
  cv_diff = cv_fo |> Statfitter.Utils.get_faceoff_difference_array_cv(first_cv_fo_time)
  pbp_diff = pbp_stats |> Statfitter.Utils.get_faceoffs |> Statfitter.Utils.update_time_multiplier(multiplier) |> Statfitter.Utils.get_faceoff_difference_array_pbp


  

  loss= cv_diff
  |> Enum.with_index
  |> Enum.map(fn {_, index} ->
    cv_diff 
    |> Main.test_delete(index)
    |> Main.test_loss(pbp_diff)
    end
  )

  # loss
  # |> Enum.with_index
  # |> Enum.map(fn {loss, index} ->
  #   IO.puts("Removed FO #{index+1}: #{loss}")
  # end )

  min = Enum.min(loss)
  index = Enum.find_index(loss, fn x -> x == min end)


  IO.puts("------\nMultiplier: #{multiplier}\nFace off to remove: #{index+1}\nLoss: #{min}\n------- ")


# ---------------------------------------------------------------------#


 