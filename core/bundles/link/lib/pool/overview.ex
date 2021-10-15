defmodule Link.Pool.Overview do
  @moduledoc """
   The student overview screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :studentpool

  import CoreWeb.Gettext

  alias Link.Pool.Form.{Students, Campaigns}

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.UI.Navigation.{ActionBar, TabbarArea, Tabbar, TabbarContent}

  data(tabs, :any)
  data(initial_tab, :any)

  @impl true
  def mount(%{"tab" => initial_tab}, _session, socket) do
    tabs = create_tabs(initial_tab)

    {
      :ok,
      socket
      |> assign(tabs: tabs)
      |> assign(initial_tab: initial_tab)
      |> update_menus()
    }
  end

  @impl true
  def mount(_params, session, socket) do
    mount(%{"tab" => nil}, session, socket)
  end

  defp create_tabs(initial_tab) do
    [
      %{
        id: :students,
        title: dgettext("link-studentpool", "tabbar.item.students"),
        component: Students,
        props: nil,
        type: :fullpage,
        active: initial_tab === :students
      },
      %{
        id: :campaigns,
        title: dgettext("link-studentpool", "tabbar.item.campaigns"),
        component: Campaigns,
        props: nil,
        type: :fullpage,
        active: initial_tab === :campaigns
      }
    ]
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("link-studentpool", "title") }}
        menus={{ @menus }}
      >
        <TabbarArea tabs={{@tabs}}>
          <ActionBar>
            <Tabbar vm={{ %{initial_tab: @initial_tab, size: :wide, type: :segmented} }} />
          </ActionBar>
          <TabbarContent/>
        </TabbarArea>
      </Workspace>
    """
  end
end
