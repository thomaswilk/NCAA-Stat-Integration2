Mix.install([
  {:finch, "~> 0.16"},
  {:floki, "~> 0.34"},
  {:jason, "~> 1.4"}

])

Code.require_file("utils.exs",__DIR__)
Code.require_file("requests.exs",__DIR__)
Code.require_file("THEEBRAIN.exs",__DIR__)

{:ok, _} = Finch.start_link(name: StatsFinch)


defmodule Main do 

  def test_team_assigner(cv_path, pbp_path, period \\ 1) do 
    cv = Utils.json_to_stats(cv_path)
    pbp = Utils.json_to_stats(pbp_path)

    Team_Assigner.assign_cv_teams(cv, pbp)
    |> Statfitter.Utils.get_faceoffs()
    |> Statfitter.Utils.get_stat_by_period(period)
    |> Enum.with_index
    |> Enum.map(fn {fo, idx} ->
      IO.puts(" FO ##{idx}: #{fo.team}")
    end)


    IO.puts("\n\n")

    pbp
    |> Statfitter.Utils.get_faceoffs
    |> Statfitter.Utils.get_stat_by_period(period)
    |> Enum.with_index
    |> Enum.map(fn {fo, idx} ->
      IO.puts(" FO ##{idx}: #{fo.team}")
    end)

  end

  def test_faceoff_difference(cv_path, pbp_path, period \\ 2 ) do

    IO.puts("pbp")
    Utils.json_to_stats(pbp_path)
    |> Statfitter.Utils.get_stat_by_period(period)
    |> Statfitter.Utils.get_faceoffs
    #|> Statfitter.Utils.update_time_continuous      # pbp dont have continuous time unless we make it 
    |> Statfitter.Utils.get_faceoff_difference_array_pbp
    |> Enum.with_index()
    |> Enum.each(fn {val, idx} ->
          IO.puts("#{idx}: #{Statfitter.Utils.seconds_formatter(val)}")
        end)

    IO.puts("\n\n")
    IO.puts("cv")
    Utils.json_to_stats(cv_path)
    |> Statfitter.Utils.get_stat_by_period(period)
    |> Statfitter.Utils.get_faceoffs
    |> Statfitter.Utils.get_faceoff_difference_array_cv
    |> Enum.with_index()
    |> Enum.each(fn {val, idx} ->
          IO.puts("#{idx}: #{Statfitter.Utils.seconds_formatter(val)}")
        end)
  end

  # add output path
  def test_equal_faceoff_matching(cv_path, pbp_path, period) do 
    cv_stats = Utils.json_to_stats(cv_path) |> Statfitter.Utils.get_stat_by_period(period)
    pbp_stats = Utils.json_to_stats(pbp_path) |> Statfitter.Utils.get_stat_by_period(period)
    
    Statfitter.fo_equal(cv_stats, pbp_stats)
    |> IO.inspect()
  end 

  def test_match_whole_game(cv_path, pbp_path, output_path \\ "output/default_dump.json") do 
    IO.puts("1")
     cv_stats = Utils.json_to_stats(cv_path) 
     pbp_stats = Utils.json_to_stats(pbp_path) 
    IO.puts("2")
     Statfitter.main(cv_stats, pbp_stats, "Cornell", "Maryland")
     |> Utils.print_stats_json(output_path)
  end 


end 
#------------Example of creating pbp and reading it------------------#
  # Requests.get_play_by_play_by_teams("Cornell", "Maryland", "05/26/2025")
  # |> Utils.print_stats_json("output/pbpChip.json")

  # Utils.json_to_stats("output/pbpChip.json")
  # |> IO.inspect()
#---------------------------------------------------#





# Main.test_faceoff_difference("input/cvChip.json", "input/pbpChip.json", 3)

# Main.test_team_assigner("input/cvChip.json", "input/pbpChip.json")
Main.test_team_assigner("input/cvMaristSiena.json", "input/pbpMaristSiena.json", 3)
# Main.test_faceoff_difference("input/cvMaristSiena.json", "input/pbpMaristSiena.json", 3)

# Main.test_equal_faceoff_matching("input/cvChip.json", "input/pbpChip.json", 3)


# Main.test_match_whole_game("input/cvChip.json", "input/pbpChip.json")
# Main.test_match_whole_game("input/cvMaristSiena.json", "input/pbpMaristSiena.json")
