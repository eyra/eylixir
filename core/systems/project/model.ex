defmodule Systems.Project.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Project
  }

  schema "projects" do
    field(:name, :string)
    belongs_to(:auth_node, Core.Authorization.Node)
    belongs_to(:root, Project.NodeModel)
    timestamps()
  end

  @required_fields ~w(name)a
  @fields @required_fields

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:full),
    do:
      preload_graph([
        :root,
        :auth_node
      ])

  def preload_graph(:root), do: [root: Project.NodeModel.preload_graph(:down)]
  def preload_graph(:auth_node), do: [auth_node: []]

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(project), do: project.auth_node_id
  end

  defimpl Frameworks.Utility.ViewModelBuilder do
    use CoreWeb, :verified_routes

    def view_model(%Project.Model{} = project, page, %{current_user: user}) do
      vm(project, page, user)
    end

    defp vm(
           %{
             id: id,
             name: name,
             root: %{
               id: root_node_id,
               items: items
             }
           },
           {Project.OverviewPage, :card},
           _user
         ) do
      path = ~p"/project/node/#{root_node_id}"

      share = %{
        action: %{type: :send, event: "share", item: id},
        face: %{type: :label, label: "Share", wrap: true}
      }

      edit = %{
        action: %{type: :send, event: "edit", item: id},
        face: %{type: :label, label: "Edit", wrap: true}
      }

      delete = %{
        action: %{type: :send, event: "delete", item: id},
        face: %{type: :icon, icon: :delete}
      }

      info = [info(items)]

      tags =
        items
        |> Enum.map(&tag/1)
        |> Enum.uniq()

      %{
        type: :secondary,
        id: id,
        path: path,
        label: nil,
        title: name,
        tags: tags,
        info: info,
        left_actions: [edit, share],
        right_actions: [delete]
      }
    end

    defp tag(%{tool_ref: %{data_donation_tool: %{id: _id}}}), do: "Data Donation"
    defp tag(%{tool_ref: %{benchmark_tool: %{id: _id}}}), do: "Benchmark"
    defp tag(_), do: nil

    defp info([_item]), do: "1 item"
    defp info(items) when is_list(items), do: "#{Enum.count(items)} items"
  end
end
