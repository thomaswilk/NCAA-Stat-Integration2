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

  def test_faceoff_difference(cv_path, pbp_path, period \\ 1) do

    IO.puts("pbp")
    x = Utils.json_to_stats(pbp_path)
    |> Statfitter.Utils.get_stat_by_period(period)
    |> Statfitter.Utils.get_faceoffs
    |> Statfitter.Utils.get_faceoff_difference_array_pbp

    
    x
    |> Enum.with_index()
    |> Enum.each(fn {val, idx} ->
          # IO.puts("#{idx}: #{Statfitter.Utils.seconds_formatter(val)}")
            IO.puts("#{idx}: #{val}")

        end)


    Enum.sum(x)
    |> Statfitter.Utils.seconds_formatter()
    |> IO.inspect(label: "total time PBP")

    IO.puts("\n\n")
    IO.puts("cv")
     y = Utils.json_to_stats(cv_path)
    |> Statfitter.Utils.get_faceoffs
    |> Statfitter.Utils.get_stat_by_period(period)
    |> Statfitter.Utils.get_faceoff_difference_array_cv
    
    y
    |> Enum.with_index()
    |> Enum.each(fn {val, idx} ->
          # IO.puts("#{idx}: #{Statfitter.Utils.seconds_formatter(val)}")
          IO.puts("#{idx}: #{val}")
        end)

      Enum.sum(y)
      |> Statfitter.Utils.seconds_formatter()
      |> IO.inspect(label: "Total Time CV") 
  end

  # add output path
  def test_equal_faceoff_matching(cv_path, pbp_path, period) do 
    cv_stats = Utils.json_to_stats(cv_path) |> Statfitter.Utils.get_stat_by_period(period)
    pbp_stats = Utils.json_to_stats(pbp_path) |> Statfitter.Utils.get_stat_by_period(period)
    
    Statfitter.fo_equal(cv_stats, pbp_stats)
    |> IO.inspect()
  end 

  def test_match_whole_game_by_quarter(cv_path, pbp_path, _output_path \\ "output/default_dump.json") do 
     cv_stats = Utils.json_to_stats(cv_path) 
     pbp_stats = Utils.json_to_stats(pbp_path) 

     Statfitter.main(cv_stats, pbp_stats, "Cornell", "Maryland")
     |> Statfitter.Utils.get_faceoffs()
    # |> Utils.print_stats_json(output_path)
  end 

  def test_match_quarter(cv_path, pbp_path, period) do 
    cv_stats = Utils.json_to_stats(cv_path) |> Statfitter.Utils.get_stat_by_period(period)
    pbp_stats = Utils.json_to_stats(pbp_path) |> Statfitter.Utils.get_stat_by_period(period)
    Statfitter.match_quarter({cv_stats, pbp_stats})
  end

    def test_match_whole_game(cv_path, pbp_path) do
    cv_stats = Utils.json_to_stats(cv_path)
    pbp_stats = Utils.json_to_stats(pbp_path)
    Statfitter.match_quarter({cv_stats, pbp_stats})
    end

end 
#------------Example of creating pbp and reading it-------------------#
  # Requests.get_play_by_play_by_teams("Cornell", "Maryland", "05/26/2025")
  # |> Utils.print_stats_json("output/pbpChip.json")

  # Utils.json_to_stats("output/pbpChip.json")
  # |> IO.inspect()
#---------------------------------------------------------------------#


#------------Other testing functions from MAIN -----------------------#
  # Main.test_team_assigner("input/cvChip.json", "input/pbpChip.json")
  # Main.test_team_assigner("input/cvMaristSiena.json", "input/pbpMaristSiena.json", 3)

  # Main.test_faceoff_difference("input/cvMaristSiena.json", "input/pbpMaristSiena.json", 1)
  # Main.test_faceoff_difference("input/cvChip.json", "input/pbpChip.json", 2)

  # Main.test_equal_faceoff_matching("input/cvChip.json", "input/pbpChip.json", 3)
  # Main.test_match_quarter("input/cvMaristSiena.json", "input/pbpMaristSiena.json", 4)
  # |> Statfitter.Utils.get_faceoffs()
#---------------------------------------------------------------------#


#------------Correct face off matching for the Championship-----------# 
  # Main.test_match_whole_game("input/cvChip2.json", "input/pbpChip.json", "output/firstSuccessChip.json")
  # Main.test_match_whole_game("input/cvMaristSiena.json", "input/pbpMaristSiena.json")
  # |> Statfitter.Utils.get_faceoffs()
  # |> Enum.with_index()
  # |> Enum.map(fn {fo, idx} -> {idx, fo.team, Statfitter.Utils.seconds_formatter(fo.film_time_start)}
  #   end ) 
  # |> IO.inspect()
#---------------------------------------------------------------------#

#----------------Tests for new pruning branch-------------------------#
  Code.require_file("stat.exs", __DIR__)

  # game = "chip"
  game = "MaristSiena"

  pbp_stats = Utils.json_to_stats("input/pbp#{game}.json")
  cv_stats = Utils.json_to_stats("input/cv#{game}.json")
  multiplier = Statfitter.prune2(cv_stats, pbp_stats)



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

  Statfitter.Utils.get_faceoffs(cv_stats)
  |> Statfitter.Utils.get_faceoff_difference_array_cv
  |> Enum.with_index()
  |> Enum.each(fn {val, idx} -> 
     IO.puts("#{idx}, #{Statfitter.Utils.seconds_formatter(val)}")
   end)





#---------------------------------------------------------------------#