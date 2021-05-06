defmodule Bot.WebSocketCLient do
  use GenServer

  require Logger

  defstruct [
    stream_ref: nil,
    gun_pid: nil
  ]

  def start_link(state \\ %__MODULE__{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__);
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:open_ws, conn_info}, state) do
    {:noreply, Map.merge(state, ws_upgrade(conn_info))}
  end

  @impl true
  def handle_cast({:send, message}, state) do
    :gun.ws_send(state.gun_pid, {:text, message})
    Logger.info("current state: " <> inspect(state))
    Logger.info("sending message: " <> inspect(message))
    {:noreply, state}
  end



  @impl true
  def handle_info({:gun_response, _conn_pid, _, _, _status, _header}, _state) do
    {:stop, :ws_upgrade_failed, :ws_upgrade_failed}
  end

  @impl true
  def handle_info({:gun_error, _conn_pid, _stream_ref, reason}, _state) do
    {:stop, :ws_upgrade_failed, reason}
  end

  @impl true
  def handle_info({:gun_upgrade, _connPid, _stream_ref, [<<"websocket">>], headers}, state) do
    Logger.info("Upgraded #{inspect(state.gun_pid)}. Success! \n Headers: \n #{inspect(headers)}")
    {:noreply, state}
  end


  @impl true
  def handle_info({:gun_ws, _conn_pid, _stream_pid, {:text, message}}, state) do
    Logger.info("Recieved message: #{message}")
    {:noreply, state}
  end


  @impl true
  def handle_info(message, state) do
    Logger.error "Unexpected message: #{inspect message, pretty: true} with state: #{inspect state, pretty: true}"
    {:noreply, state}
  end



  def ws_upgrade(conn_info) do
    %{ path: path, port: port, host: host } = conn_info

    {:ok, _} = :application.ensure_all_started(:gun)
    connect_opts = %{
      connect_timeout: :timer.minutes(1),
      retry: 10,
      retry_timeout: 300
    }


    {:ok, gun_pid} = :gun.open(host, port, connect_opts)
    {:ok, _protocol} = :gun.await_up(gun_pid)
    # Set custom header with cookie for device id
    stream_ref = :gun.ws_upgrade(gun_pid, path)
    # Return updated state
    %__MODULE__{stream_ref: stream_ref, gun_pid: gun_pid}
  end

end
