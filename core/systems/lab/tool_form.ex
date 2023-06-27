defmodule Systems.Lab.ToolForm do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Text

  alias Systems.{
    Lab
  }

  # Handle initial update
  @impl true
  def update(
        %{id: id, entity_id: entity_id, validate?: validate?},
        %{assigns: %{myself: myself}} = socket
      ) do
    add_day_button = %{
      action: %{type: :send, event: "add_day", target: myself},
      face: %{type: :primary, label: dgettext("link-lab", "add.day.button")}
    }

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity_id: entity_id,
        validate?: validate?,
        add_day_button: add_day_button
      )
      |> update_entity()
      |> update_day_list_items()
      |> update_byline()
    }
  end

  @impl true
  def update(
        %{day_view: :submit, og_day_model: og_day_model, day_model: day_model},
        %{assigns: %{entity: entity}} = socket
      ) do
    Lab.Public.submit_day_model(entity, og_day_model, day_model)
    send(self(), {:hide_popup})

    {
      :ok,
      socket
      |> update_entity()
      |> update_day_list_items()
      |> update_byline()
    }
  end

  @impl true
  def update(%{day_view: :hide}, socket) do
    send(self(), {:hide_popup})
    {:ok, socket}
  end

  defp update_entity(%{assigns: %{entity_id: entity_id}} = socket) do
    entity = Lab.Public.get(entity_id, [:time_slots])
    changeset = Lab.ToolModel.changeset(entity, :create, %{})

    socket
    |> assign(
      entity: entity,
      changeset: changeset
    )
  end

  defp update_day_list_items(%{assigns: %{entity: %{time_slots: time_slots}}} = socket) do
    day_list_items = Lab.DayListItemModel.parse(time_slots)
    socket |> assign(day_list_items: day_list_items)
  end

  defp update_byline(%{assigns: %{day_list_items: day_list_items}} = socket) do
    number_of_time_slots =
      day_list_items
      |> Enum.reduce(
        0,
        fn %{number_of_timeslots: number_of_timeslots}, acc ->
          acc + number_of_timeslots
        end
      )

    number_of_seats =
      Enum.reduce(day_list_items, 0, fn %{number_of_seats: number_of_seats}, acc ->
        acc + number_of_seats
      end)

    byline =
      dgettext("link-lab", "form.description",
        time_slots: number_of_time_slots,
        seats: number_of_seats
      )

    socket |> assign(byline: byline)
  end

  @impl true
  def handle_event("add_day", _params, %{assigns: %{entity: entity}} = socket) do
    day_model = Lab.Public.new_day_model(entity)
    props = popup_props(day_model, socket)

    send(self(), {:show_popup, %{module: Systems.Lab.DayView, props: props}})
    {:noreply, socket}
  end

  @impl true
  def handle_event("search_subject", _params, %{assigns: %{entity: _entity}} = socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("edit_day", %{"item" => index}, %{assigns: %{entity: entity}} = socket) do
    day = get_day(socket, index)
    day_model = Lab.Public.edit_day_model(entity, day)

    props = popup_props(day_model, socket)

    send(self(), {:show_popup, %{module: Systems.Lab.DayView, props: props}})
    {:noreply, socket}
  end

  @impl true
  def handle_event("duplicate_day", %{"item" => index}, %{assigns: %{entity: entity}} = socket) do
    day = get_day(socket, index)
    day_model = Lab.Public.duplicate_day_model(entity, day)

    props = popup_props(day_model, socket)

    send(self(), {:show_popup, %{module: Systems.Lab.DayView, props: props}})
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_day", %{"item" => index}, %{assigns: %{entity: entity}} = socket) do
    day = get_day(socket, index)
    Lab.Public.remove_day(entity, day)

    {
      :noreply,
      socket
      |> update_entity()
      |> update_day_list_items()
      |> update_byline()
    }
  end

  defp popup_props(day_model, %{assigns: %{id: id}}) do
    %{
      id: :day_popup,
      target: %{type: __MODULE__, id: id},
      day_model: day_model
    }
  end

  defp get_day(socket, index) when is_binary(index) do
    get_day(socket, index |> String.to_integer())
  end

  defp get_day(%{assigns: %{day_list_items: day_list_items}}, index) do
    day_list_items |> Enum.at(index)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title3><%= dgettext("link-lab", "form.title") %></Text.title3>
      <.spacing value="M" />
      <Text.body_large><%= @byline %></Text.body_large>
      <.spacing value="S" />
      <table class="table-auto">
        <%= for {day_list_item, index} <- Enum.with_index(@day_list_items) do %>
          <Lab.DayList.item id={index} target={@myself} {day_list_item} />
        <% end %>
      </table>
      <.spacing value="S" />
      <.wrap>
        <Button.dynamic {@add_day_button} />
      </.wrap>
    </div>
    """
  end
end
