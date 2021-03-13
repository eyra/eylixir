defmodule CoreWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use CoreWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate
  import Plug.Conn

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import CoreWeb.ConnCase

      import Core.TestHelpers
      alias Core.Factories
      alias CoreWeb.Routes

      # The default endpoint for testing
      @endpoint CoreWeb.Support.Endpoint

      import Core.AuthTestHelpers
    end
  end

  def build_conn_with_dependencies() do
    Phoenix.ConnTest.build_conn()
    |> put_private(:path_provider, CoreWeb.Support.PathProvider)
    |> put_private(:endpoint, CoreWeb.Support.Endpoint)
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Core.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Core.Repo, {:shared, self()})
    end

    conn = build_conn_with_dependencies()

    {:ok, conn: conn}
  end
end
