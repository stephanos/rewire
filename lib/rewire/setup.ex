defmodule Rewire.Setup do
  @moduledoc false

  use Application

  def start(_, _) do
    Application.ensure_all_started(:ex_unit)
    Supervisor.start_link([Rewire.Cover], name: Rewire.Supervisor, strategy: :one_for_one)
  end
end
