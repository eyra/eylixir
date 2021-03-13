defmodule CoreWeb.SurveyTool.Index do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  alias Core.SurveyTools
  alias Core.SurveyTools.SurveyTool

  data(survey_tools, :any)
  data(study, :any)
  data(changeset, :any)
  data(saved, :boolean)
  data(path_provider, :any)

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> load_survey_tools}
  end

  def handle_event("delete", params, socket) do
    {:ok, _} =
      %SurveyTool{id: params["value"] |> String.to_integer()}
      |> SurveyTools.delete_survey_tool()

    {:noreply, socket |> load_survey_tools}
  end

  def render(assigns) do
    ~H"""
    <h1>Listing Survey tools</h1>

    <table>
    <thead>
    <tr>
      <th colspan="2">Title</th>
    </tr>
    </thead>
    <tbody>
    <tr :for={{survey_tool <- @survey_tools}}>
      <td>{{ survey_tool.title }}</td>
      <td>
        <span>{{ link "Show", to: @path_provider.live_path(@socket, __MODULE__) }}</span>
        <span fixme="can?(@socket, [survey_tool], CoreWeb.SurveyToolController, :edit)">
        {{ live_patch "Edit", to: @path_provider.live_path(@socket,  CoreWeb.SurveyTool.Edit, survey_tool.id), replace: true }}
        </span>
        <button phx-click="delete" value={{survey_tool.id}}>
          Delete
        </button>
      </td>
    </tr>
    </tbody>
    </table>

    <span>{{ live_patch "New Survey tool", to: @path_provider.live_path(@socket, CoreWeb.SurveyTool.New), replace: true }}</span>

    """
  end

  defp load_survey_tools(socket) do
    socket |> assign(survey_tools: SurveyTools.list_survey_tools())
  end
end
