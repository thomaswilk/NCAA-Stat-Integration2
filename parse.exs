
Code.require_file("stat.exs", __DIR__)

defmodule Parser do 
  alias Stat

  




  #--------PLAY BY PLAY PARSING--------__#
   # Creating table of stats from html [time, away, score, home]
    def parse_pbp_table_from_html(html) do
        {:ok, doc} = Floki.parse_document(html)

        Floki.find(doc, "div.card.table-responsive")
        |> Enum.with_index()
        |> Enum.flat_map(fn {div, index} ->
            Floki.find(div, "tbody tr")
            |> Enum.map(fn row ->
            Floki.find(row, "td")
            |> Enum.map(&Floki.text/1)
            end)
            |> Enum.filter(fn cells -> length(cells) == 4 end)
            |> Enum.map(fn cells ->
            cells ++ [index + 1]
            end)
        end)
        |>parse_rows_table
    end


    # Creates list of parsed stats
    def parse_rows_table(table) do
        [first, second | rest ] = table
        home = parse_team_from_goalie_stat(first)
        away = parse_team_from_goalie_stat(second)

        rest
        |> Enum.flat_map(&parse_pbp_stat(&1, home, away))
        |> Enum.reject(&is_nil/1)
    end
    # Parses each play into a Stat structure
    def parse_pbp_stat([time, desc1, _, desc2, period], home, away) do

        {stat, source} =
        cond do
            desc1 != "" -> {desc1, :desc1}
            desc2 != "" -> {desc2, :desc2}
            true -> {"", :none}
        end


        cond do
        # clear - quite easy
        Regex.match?(~r/^Clear attempt by (\w+) (good|bad)\./, stat) ->
            case Regex.run(~r/^Clear attempt by (\w+) (good|bad)\./, stat) do
            [_, team, result] ->
                [
                %Stat{title: "Clear attempt", team: team, result: result, time: time, period: period}
                ]
            _ -> []
            end

        # gb - quite easy 
        Regex.match?(~r/^Ground ball pickup by (\w+) (.+)\./, stat) ->
            case Regex.run(~r/^Ground ball pickup by (\w+) (.+)\./, stat) do
            [_, team, player] ->
                [
                %Stat{title: "Ground ball pickup", team: team, player: player, time: time, period: period}
                ]
            _ -> []
            end


        # Foul
        Regex.match?(~r/^Foul on (\w+)\./, stat) ->
            case Regex.run(~r/^Foul on (\w+)\./, stat) do
            [_, team] ->
                [
                %Stat{title: "Foul", team: team, time: time, period: period}
                ]
            _ -> []
            end

        # Penalty
        Regex.match?(~r/^Penalty on (\w+) (.+) \((.+)\)/, stat) ->
            case Regex.run(~r/^Penalty on (\w+) (.+) \((.+)\)/, stat) do
            [_, team, player, result] ->
                [
                %Stat{title: "Penalty", team: team, player: player, result: result, time: time, period: period}
                ]
            _ -> []
            end

        # Faceoff win
        Regex.match?(~r/^Faceoff .+ vs .+ won by (\w+)/, stat) ->
            case Regex.run(~r/^Faceoff .+ vs .+ won by (\w+)/, stat) do
            [_, team] ->
                [
                %Stat{title: "Faceoff", team: team, time: time, period: period}
                ]
            _ -> []
            end

        # Shot clock violation
        Regex.match?(~r/^Shot clock violation by (\w+)\./, stat) ->
            case Regex.run(~r/^Shot clock violation by (\w+)\./, stat) do
            [_, team] ->
                [
                %Stat{title: "Shot clock violation", team: team, time: time, period: period}
                ]
            _ -> []
            end
        # Shot result types (WIDE, BLOCKED, HIGH, HIT POST)
        Regex.match?(~r/^Shot by (\w+) (.+) (WIDE|BLOCKED|HIGH|HIT POST)\./, stat) ->
            case Regex.run(~r/^Shot by (\w+) (.+) (WIDE|BLOCKED|HIGH|HIT POST)\./, stat) do
            [_, team, player, result] ->
               result =
                    cond do
                        result in ["WIDE", "HIGH"] -> "missed"
                        result == "HIT POST" -> "pipe"
                        true -> String.downcase(result)
                    end
                [
                %Stat{title: "Shot", team: team, player: player, result: result, time: time, period: period}
                ]
            _ -> []
            end

        # Shot saved  --- double check martin this makes sense ----
        Regex.match?(~r/^Shot by (\w+) (.+), SAVE (.+)\./, stat) ->
            case Regex.run(~r/^Shot by (\w+) (.+), SAVE (.+)\./, stat) do
            [_, team, shooter, goalie] ->
                goalie_team = if source == :desc1, do: away, else: home
                [
                %Stat{title: "Shot", team: team, player: shooter, result: "Saved", time: time, period: period},
                %Stat{title: "Save", team: goalie_team, player: goalie, time: time, period: period} #goalie team vairable i think makes sense
                ]
            _ -> []
            end


        # caused turnover: good 
        Regex.match?(~r/^Turnover by (\w+) (.+) \(caused by (.+)\)\./, stat) ->
            case Regex.run(~r/^Turnover by (\w+) (.+) \(caused by (.+)\)\./, stat) do
            [_, team, player, caused_by] ->
            [
                %Stat{title: "Turnover", team: team, player: player, time: time, period: period},
                %Stat{title: "Caused Turnover", player: caused_by, time: time, period: period}
            ]
            _ -> []
            end

       # goak with assist: good !!!!!!!!!MARTIN CHECK!!!!!!!!!!! -triple stat
        Regex.match?(~r/^GOAL by (\w+) (.+), goal number (\d+) for season\./, stat) ->
            case Regex.run(~r/^GOAL by (\w+) (.+), goal number (\d+) for season\./, stat) do
            [_, team, scorer, _] ->
                [
                %Stat{title: "Shot", team: team, player: scorer, result: "Goal", time: time, period: period},
                %Stat{title: "Goal", team: team, player: scorer, time: time, period: period}
                ]
            _ -> []
            end

      
      
        # goak with assist: good !!!!!!!!!MARTIN CHECK!!!!!!!!!!! -triple stat
        Regex.match?(~r/^GOAL by (\w+) (.+), Assist by (.+), goal number (\d+) for season\./, stat) ->
            case Regex.run(~r/^GOAL by (\w+) (.+), Assist by (.+), goal number (\d+) for season\./, stat) do
            [_, team, scorer, assister, _] ->
                [
                %Stat{title: "Shot", team: team, player: scorer, result: "Goal", time: time, period: period},
                %Stat{title: "Goal", team: team, player: scorer, time: time, period: period},
                %Stat{title: "Assist", team: team, player: assister, time: time, period: period}
                ]
            _ -> []
            end

        # GOAL without assist: good !!!!!!!!!MARTIN CHECK!!!!!!!!!!! -double stat
        Regex.match?(~r/^GOAL by (\w+) (.+) \(FIRST GOAL\), goal number (\d+) for season\./, stat) ->
            case Regex.run(~r/^GOAL by (\w+) (.+) \(FIRST GOAL\), goal number (\d+) for season\./, stat) do
            [_, team, scorer, _] ->
                [
                %Stat{title: "Shot", team: team, player: scorer, result: "Goal", time: time, period: period},
                %Stat{title: "Goal", team: team, player: scorer, time: time, period: period}
                ]
            _ -> []
            end

        true ->
            []
        end
    end
    # Gets the team's abbreviation from the first two (goalie) stats
    def parse_team_from_goalie_stat([_, desc1, _, desc2, _]) do 
        desc = if desc1 != "", do: desc1, else: desc2
        case Regex.run(~r/ at goalie for (\w+)/, desc) do
            [_, team] -> team
            _ -> nil     
        end
    end
   
   #--------------------------------------#



    #Getting the contest ID from scoreboard page
    # 
    #
    #    Gotta copy from type script file 
    #
    def parse_scoreboard_html(html, home, away) do
        {:ok, doc} = Floki.parse_document(html)

        game =   # for each table, get all cells, see if home and away are both present
        Floki.find(doc, "table")
        |> Enum.find(fn table ->
            cells =
            table
            |> Floki.find("td")
            |> Enum.map(&Floki.text/1)

            Enum.any?(cells, &String.contains?(&1, home)) &&
            Enum.any?(cells, &String.contains?(&1, away))
        end)
        if game == nil do # if no game with both teams found, gracefull y exit 
        IO.puts("No game found between #{home} and #{away}")
        IO.puts("Check team names.")
        else
        IO.puts("Game found")
        href = # find the a tag with text "Box Score", return that href
        game
        |> Floki.find("a")
        |> Enum.find(fn a ->
            Floki.text(a) |> String.trim() == "Box Score"
        end)
        |> case do
            {"a", attrs, _} ->
            Enum.find_value(attrs, fn
                {"href", url} -> url
                |>String.split("/")
                |> Enum.find(fn x -> Regex.match?(~r/^\d+$/, x) end)
                _ -> nil
            end)

            _ -> nil
        end
        href
        end
    end
    
    # Getting a teams schedule (to do later)




end 
