# This struct is similar to struct produced by 
# cv breakdown, so when we parse the PBP, 
# it forms each stat into this struct, so
# working with cv stats vs pbp stats

# TL;DR this is the big daddy stat
 

defmodule Stat do
  defstruct [
    :time,
    :title,
    :team,
    :player,
    :result,
    :stat_id,
    :parent_id,
    :film_time_start,
    :film_time_end,
    :tag_type,
    :type,
    :period,
    :required_period_review,
    :film_id
  ]
end


