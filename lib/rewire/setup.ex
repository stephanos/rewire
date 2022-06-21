defmodule Rewire.Setup do
  @moduledoc false

  use Application

  def start(_, _) do
    Rewire.Cover.export_private_functions()
    Supervisor.start_link([], name: Rewire.Supervisor, strategy: :one_for_one)
  end
end
