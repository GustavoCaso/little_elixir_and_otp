defmodule Metex.Worker do
  use GenServer

  # Client

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def get_temperature(location) do
    GenServer.call(__MODULE__, {:location, location})
  end

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  def reset_stats do
    GenServer.call(__MODULE__, :reset_stats)
  end

  def stop do
    GenServer.cast(__MODULE__, :stop)
  end

  # Server

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call(:get_stats, _from, state) do
    {:ok, state, state}
  end

  def handle_call({:location, location}, _from, state) do
    case temperature_of(location) do
      {:ok, temp} ->
        new_state = update_stats(state, location)
        {:reply, "#{temp}˚C", new_state}
      _ ->
        {:reply, :error, state}
    end
  end

  def handle_cast(:reset_stats, _from, state) do
    {:noreply, %{}}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state }
  end

  def terminate(reason, state) do
    IO.puts "server terminated because of #{inspect reason}"
    inspect state
    :ok
  end

  def temperature_of(location) do
    url_for(location)
    |> HTTPoison.get
    |> parse_response
  end

  defp url_for(location) do
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}"
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body
    |> JSON.decode!
    |> compute_temperature
  end

  defp parse_response(_) do
    :error
  end

  defp compute_temperature(json) do
    try do
      temp = (json["main"]["temp"] - 273.15 |> Float.round(1))
      {:ok, temp}
    rescue
      _ -> :error
    end
  end

  defp update_stats(old_state, location) do
    case Map.has_key?(old_state, location) do
      true ->
        Map.update!(old_state, location, &(&1 + 1))
      false ->
        Map.put_new(old_state, location, 1)
    end
  end
end
