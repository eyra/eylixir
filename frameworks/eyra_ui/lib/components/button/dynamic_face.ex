defmodule EyraUI.Button.DynamicFace do
  use EyraUI.Component

  alias EyraUI.Dynamic
  alias EyraUI.Button.Face.{Primary, Secondary, PrimaryIcon, Forward}

  prop(vm, :map, required: true)

  defviewmodel(
    type: nil,
    icon: nil
  )

  defp face(%{type: :primary, icon: _icon}), do: PrimaryIcon
  defp face(%{type: :secondary}), do: Secondary
  defp face(%{type: :forward}), do: Forward
  defp face(_), do: Primary

  def render(assigns) do
    ~H"""
      <Dynamic component={{ face(@vm) }} props={{ %{vm: @vm } }} />
    """
  end
end
