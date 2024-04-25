defmodule Systems.Graphite.LeaderboardPage do
  use CoreWeb, :live_view_fabric
  use Fabric.LiveView, CoreWeb.Layouts
  use Systems.Observatory.Public
  use CoreWeb.UI.Responsive.Viewport
  use CoreWeb.Layouts.Stripped.Component, :leaderboard

  alias Core.ImageHelpers
  alias Frameworks.Pixel.Hero
  alias Frameworks.Pixel.Align

  alias Systems.Graphite

  @impl true
  def get_authorization_context(%{"id" => leaderboard_id}, _session, _socket) do
    Graphite.Public.get_leaderboard!(String.to_integer(leaderboard_id), [:auth_node])
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    model =
      Graphite.Public.get_leaderboard!(
        String.to_integer(id),
        Graphite.LeaderboardModel.preload_graph(:down)
      )

    {
      :ok,
      socket
      |> assign(
        id: id,
        model: model,
        image_info: nil
      )
      |> observe_view_model()
      |> update_image_info()
      |> compose_child(:leaderboard_table)
    }
  end

  @impl true
  def handle_resize(socket) do
    socket
    |> update_image_info()
    |> update_menus()
  end

  def handle_view_model_updated(socket) do
    socket
    |> update_image_info()
    |> compose_child(:leaderboard_table)
  end

  defp update_image_info(
         %{assigns: %{viewport: %{"width" => viewport_width}, vm: %{info: %{image_id: image_id}}}} =
           socket
       ) do
    image_width = viewport_width
    image_height = 360
    image_info = ImageHelpers.get_image_info(image_id, image_width, image_height)

    socket
    |> assign(image_info: image_info)
  end

  defp update_image_info(socket) do
    socket
  end

  @impl true
  def compose(:leaderboard_table, %{vm: %{leaderboard_table: leaderboard_table}}) do
    leaderboard_table
  end

  @impl true
  def handle_event(_, _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div id={:leaderboard_page} class="w-full h-full" phx-hook="ViewportResize">
        <.stripped menus={@menus}>
          <:header>
            <div class="h-[180px] bg-grey5">
            <%= if @image_info do %>
              <Hero.image title={@vm.info.title} subtitle={@vm.info.subtitle} logo_url={@vm.info.logo_url} image_info={@image_info} />
            <% end %>
            </div>
          </:header>
          <Area.content>
            <Margin.y id={:page_top} />
            <Align.horizontal_center>
              <Text.title2><%= @vm.title %></Text.title2>
            </Align.horizontal_center>
            <.spacing value="M" />
            <.stack fabric={@fabric} />
          </Area.content>
        </.stripped>
      </div>
    """
  end
end
