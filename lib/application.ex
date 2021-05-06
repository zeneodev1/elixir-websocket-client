defmodule Bot.Application do
  use Application

  require Logger


  def start(_type, _args) do
    children = [
      {Bot.WebSocketCLient, %Bot.WebSocketCLient{}}
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: Bot.WebSocketCLient.Supervisor)
  end


  def start_ws() do
    GenServer.cast(Bot.WebSocketCLient, {:open_ws, %{path: "/", port: 80, host: 'echo.websocket.org'}})
  end

  def send(message) do
    GenServer.cast(Bot.WebSocketCLient, {:send, message})
  end




end
