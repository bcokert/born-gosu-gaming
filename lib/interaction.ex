defmodule Interaction do
  @enforce_keys [:name, :mid, :mstate, :reducer]
  defstruct [:name, :mid, :mstate, :reducer, on_remove: nil]

  @type mstate :: tuple()

  @type context :: %{
    emoji: String.t(),
    sender: Nostrum.Snowflake.t(),
    is_add: boolean,
  }

  @type t :: %Interaction{
    name: String.t(),
    mid: Nostrum.Snowlake.t(),
    mstate: mstate(),
    reducer: (mstate(), context() -> mstate()),
    on_remove: (mstate() -> any()) | nil,
  }

  @type response :: :ok | {:error, String.t()}

  @server Interaction.Server

  def start_link() do
    GenServer.start_link(@server, nil, name: @server)
  end

  @spec create(Interaction.t()) :: response()
  def create(interaction) do
    GenServer.call(@server, {:create, interaction})
  end

  @spec interact(Nostrum.Snowflake.t(), context()) :: response()
  def interact(mid, context) do
    GenServer.call(@server, {:interact, mid, context})
  end

  @spec remove(Nostrum.Snowflake.t()) :: response()
  def remove(mid) do
    GenServer.call(@server, {:remove, mid})
  end
end
