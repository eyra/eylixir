defmodule Systems.Support.HelpdeskPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :helpdesk

  alias Frameworks.Pixel.Spacing
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias Frameworks.Pixel.Text.{Title2, BodyLarge}

  alias Systems.Support.HelpdeskForm

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> update_menus()}
  end

  def handle_info({:claim_focus, :helpdesk_form}, socket) do
    # helpdesk_form is currently only form that can claim focus
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <Workspace
        menus={@menus}
    >
      <ContentArea>
        <FormArea>
          <MarginY id={:page_top} />
          <Title2>{dgettext("eyra-support", "form.title")}</Title2>
          <BodyLarge>{dgettext("eyra-support", "form.description")} </BodyLarge>
        </FormArea>
      </ContentArea>

      <Spacing value="XL" />

      <HelpdeskForm id={:helpdesk_form} user={@current_user}/>

    </Workspace>
    """
  end
end