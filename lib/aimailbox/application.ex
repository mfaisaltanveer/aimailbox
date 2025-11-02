defmodule Aimailbox.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AimailboxWeb.Telemetry,
      Aimailbox.Repo,
      # Start Cloak vault for encryption
      Aimailbox.Encrypted,
      {DNSCluster, query: Application.get_env(:aimailbox, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Aimailbox.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Aimailbox.Finch},
      # Start Oban for background jobs
      {Oban, Application.fetch_env!(:aimailbox, Oban)},
      # Start a worker by calling: Aimailbox.Worker.start_link(arg)
      # {Aimailbox.Worker, arg},
      # Start to serve requests, typically the last entry
      AimailboxWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Aimailbox.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AimailboxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
