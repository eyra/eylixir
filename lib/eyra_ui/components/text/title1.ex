defmodule EyraUI.Text.Title1 do
  use Surface.Component

  slot default, required: true

  def render(assigns) do
    ~H"""
    <div class="text-title3 font-title3 lg:text-title1 lg:font-title1 mb-7 lg:mb-9">
      <slot />
    </div>
    """
  end
end
