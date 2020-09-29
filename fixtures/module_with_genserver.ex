defmodule Rewire.ModuleWithGenServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    {:ok, []}
  end

  def hello(pid) do
    GenServer.call(pid, :hello)
  end

  def handle_call(:hello, _from, state) do
    {:reply, Rewire.Hello.hello(), state}
  end
end
