Mix.install([
  {:finch, "~> 0.16"},
  {:floki, "~> 0.34"},
  {:jason, "~> 1.4"}

])

Code.require_file("utils.exs",__DIR__)
Code.require_file("requests.exs",__DIR__)
Code.require_file("THEEBRAIN.exs",__DIR__)

{:ok, _} = Finch.start_link(name: StatsFinch)






# Requests.get_play_by_play_by_teams("Marist", "Siena", "05/01/2025")
# |> Utils.print_stats_json("input/pbpMaristSiena.json")

# Requests.get_play_by_play_by_teams("Cornell", "Maryland", "05/26/2025")
# |> Statfitter.Utils.update_time_continuous()
# |> Utils.print_stats_json("other/time_change.json")

# Utils.json_to_stats("input/cvMaristSiena.json")
# |> IO.inspect()

period = 4

IO.puts("pbp")
Utils.json_to_stats("input/pbpMaristSiena.json")
|> Statfitter.Utils.get_stat_by_period(period)
|> Statfitter.Utils.get_faceoffs
|> Statfitter.Utils.update_time_continuous
|> Statfitter.Utils.get_faceoff_difference_array_pbp
|> Enum.with_index()
|> Enum.each(fn {val, idx} ->
  IO.puts("#{idx}: #{Statfitter.Utils.seconds_formatter(val)}")
  end)

IO.puts("\n\n")
IO.puts("cv")
Utils.json_to_stats("input/cvMaristSiena.json")
|> Statfitter.Utils.get_stat_by_period(period)
|> Statfitter.Utils.get_faceoffs
|> Statfitter.Utils.get_faceoff_difference_array_cv
|> Enum.with_index()
|> Enum.each(fn {val, idx} ->
  IO.puts("#{idx}: #{Statfitter.Utils.seconds_formatter(val)}")
  end)
