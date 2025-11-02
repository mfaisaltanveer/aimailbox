defmodule Aimailbox.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :aimailbox

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def create do
    load_app()

    for repo <- repos() do
      :ok = ensure_repo_created(repo)
    end
  end

  defp ensure_repo_created(repo) do
    IO.puts("Creating database for #{inspect(repo)}")

    case repo.__adapter__().storage_up(repo.config) do
      :ok ->
        IO.puts("Database created successfully")
        :ok
      {:error, :already_up} ->
        IO.puts("Database already exists")
        :ok
      {:error, term} when is_binary(term) ->
        IO.puts("Error creating database: #{term}")
        :ok
      {:error, term} ->
        IO.puts("Error creating database: #{inspect(term)}")
        :ok
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
