defmodule CoreWeb.User.Profile do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  alias Surface.Components.Form
  alias Core.Accounts
  alias EyraUI.Form.{TextInput, Checkbox}
  use EyraUI.AutoSave, :profile
  alias EyraUI.Text.Title2
  alias EyraUI.Container.{ContentArea, FormArea}
  alias EyraUI.Button.DeleteButton

  data(path_provider, :any)

  def load(_params, _session, %{assigns: %{current_user: user}}) do
    Accounts.get_profile(user)
  end

  defdelegate get_changeset(profile, attrs \\ %{}), to: Accounts, as: :change_profile
  defdelegate save(changeset), to: Accounts, as: :update_profile

  def render(assigns) do
    ~H"""
    <ContentArea>
      <FormArea>
        <Title2>{{dgettext "eyra-account", "profile.title"}}</Title2>
        <Form for={{ @changeset }} change="save">
          <Checkbox field={{:researcher}} label_text={{dgettext("eyra-account", "researcher.label")}}/>
          <TextInput field={{:fullname}} label_text={{dgettext("eyra-account", "fullname.label")}} />
          <TextInput field={{:displayname}} label_text={{dgettext("eyra-account", "displayname.label")}} />
        </Form>
        <DeleteButton label={{ dgettext("eyra-account", "signout.button") }} path={{ @path_provider.path(@socket, CoreWeb.UserSessionController, :delete) }} />
      </FormArea>
    </ContentArea>
    """
  end
end
