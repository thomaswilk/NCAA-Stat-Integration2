Code.require_file("stat.exs", __DIR__)

defmodule Utils do

  def json_to_stats(path) do
    case File.read(path) do
      {:ok, json_string} ->
        parse_json_to_stats(json_string)

      {:error, reason} ->
        IO.puts("Failed to read file: #{inspect(reason)}")
        []
    end
  end

  def parse_json_to_stats(json_string) do
    case Jason.decode(json_string) do
      {:ok, %{"stats" => raw_stats}} ->
        Enum.map(raw_stats, fn stat_map ->
          map = for {k, v} <- stat_map, into: %{}, do: {String.to_atom(k), v}
          struct(Stat, map)
        end)

      {:error, reason} ->
        IO.puts("Failed to decode JSON: #{inspect(reason)}")
        []
    end
  end

  def save_cv_json(data, path) do
    cleaned =
      data
      |> Enum.reject(&is_nil/1)
      |> Enum.filter(&is_map/1)

    json = Jason.encode!(cleaned, pretty: true)
    File.write!(path, json)
  end

  def print_stats_json(final, path) do
  stats =
    final
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&Map.from_struct/1)

  json = Jason.encode!(%{"stats" => stats}, pretty: true)
  File.write!(path, json)
end



  def create_scoreboard_url(date, sport \\ "mlax", division \\ "1") do
    [month_str, day_str, year_str] = String.split(date, "/")

    year_label =
      case year_str do
        "2025" -> "24-25"
        "2024" -> "23-24"
      end

    gender =
      case sport do
        "mlax" -> "M"
        "wlax" -> "F"
      end

    season_id =
      case {year_label, division, gender} do
        {"24-25", "1", "M"} -> 18484
        {"24-25", "2", "M"} -> 18485
        {"24-25", "3", "M"} -> 18487
        {"24-25", "1", "F"} -> 18483
        {"24-25", "2", "F"} -> 18486
        {"24-25", "3", "F"} -> 18488
        {"23-24", "1", "M"} -> 18240
        {"23-24", "2", "M"} -> 18241
        {"23-24", "3", "M"} -> 18242
        {"23-24", "1", "F"} -> 18260
        {"23-24", "2", "F"} -> 18262
        {"23-24", "3", "F"} -> 18263
      end

      "https://stats.ncaa.org/contests/livestream_scoreboards?utf8=%E2%9C%93&season_division_id=#{season_id}&game_date=#{month_str}%2F#{day_str}%2F#{year_str}&conference_id=0&tournament_id=&commit=Submit"
  end

  


end
