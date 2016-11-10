defmodule Metex do
  def temperatures_of(cities) do
    coordinator_pid = spawn(Metex.Coordinator, :loop, [[], Enum.count(cities)])   #1
    cities |> Enum.each fn city ->                   #2
      worker_pid = spawn(Metex.Worker, :loop, [])    #3
      send worker_pid, {coordinator_pid, city}       #4
    end
  end
end
