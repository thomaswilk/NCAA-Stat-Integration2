Code.require_file("parse.exs", __DIR__)
Code.require_file("utils.exs", __DIR__)


defmodule Requests do 

    # # for schedule grabber
    # def get_team_schedule_html(id) do
    #     url = "https://stats.ncaa.org/teams/#{id}"
    #     fetch(url)
    #     # |> Parser.get_team_schedule_html()
    # end 


    # Play by play request
    def get_play_by_play_by_teams(home, away, date, sport \\ "mlax" , division \\ "1") do
        Requests.get_contest_id_html(home, away, date, sport, division)
        |>Requests.get_play_by_play_by_id()
    end

    # Getting id for a game 
    def get_contest_id_html(home, away, date, sport, division) do 
        Utils.create_scoreboard_url(date, sport, division)
        |> Requests.fetch
        |> Parser.parse_scoreboard_html(home, away)
    end 

     # requesting actual play by play
    def get_play_by_play_by_id(id) do
        url ="https://stats.ncaa.org/contests/#{id}/play_by_play"
        fetch(url)
        |>Parser.parse_pbp_table_from_html
        # |>Utils.print_stats_json("output/championship2.json")
    end 

    
  
   
    # broken :( )
    # def get_cv_breakdown(film_id, auth) do
    #     fetch("http://localhost:4000/api/cv/films/#{film_id}/stats", auth)
    #     |> Utils.read_json
    # end 



    # fetch html
    def fetch(url, headers \\ []) do
        IO.puts(url)
        headers = [{"user-agent", "Mozilla/5.0"}] ++ headers
        request = Finch.build(:get, url, headers) #Creat connection using finch

        case Finch.request(request, StatsFinch) do # send request
        {:ok, %Finch.Response{status: 200, body: body}} -> # ok
            IO.puts("Successfully fetched") # success
            body
            
        {:ok, %Finch.Response{status: code}} -> # ok 
            IO.puts("HTTP status code: #{code}") # no body??
            nil

        {:error, reason} -> # 
            IO.puts("Request failed: #{inspect(reason)}")
            nil
      end
    end






end 


