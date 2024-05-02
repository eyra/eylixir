defmodule Systems.Citizen.Pool.DetailPageBuilder do
  import CoreWeb.Gettext

  alias Systems.{
    Citizen,
    Pool,
    Advert
  }

  def view_model(pool, assigns) do
    %{
      title: Pool.Model.title(pool),
      tabs: create_tabs(assigns, pool)
    }
  end

  defp create_tabs(
         %{initial_tab: initial_tab},
         %{participants: participants} = pool
       ) do
    adverts = load_adverts(pool)

    [
      %{
        id: :citizens,
        title: dgettext("link-citizen", "tabbar.item.citizens"),
        live_component: Citizen.Overview,
        props: %{citizens: participants, pool: pool},
        type: :fullpage,
        active: initial_tab === :citizens
      },
      %{
        id: :adverts,
        title: dgettext("link-citizen", "tabbar.item.adverts"),
        live_component: Advert.ListView,
        props: %{adverts: adverts},
        type: :fullpage,
        active: initial_tab === :adverts
      }
    ]
  end

  defp load_adverts(pool) do
    preload = Advert.Model.preload_graph(:down)

    Advert.Public.list_submitted(pool, preload: preload)
    |> Enum.map(&Pool.Builders.AdvertItem.view_model(&1))
  end
end
