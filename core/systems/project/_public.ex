defmodule Systems.Project.Public do
  import Ecto.Query, warn: false
  alias Core.Repo

  alias Core.Accounts.User
  alias Core.Authorization

  alias Systems.{
    Project,
    Assignment
  }

  def get!(id, preload \\ []) do
    from(project in Project.Model,
      where: project.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def get_node!(id, preload \\ []) do
    from(node in Project.NodeModel,
      where: node.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def get_item!(id, preload \\ []) do
    from(item in Project.ItemModel,
      where: item.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def get_item_by_tool_ref(tool_ref, preload \\ [])

  def get_item_by_tool_ref(%Project.ToolRefModel{id: tool_ref_id}, preload) do
    get_item_by_tool_ref(tool_ref_id, preload)
  end

  def get_item_by_tool_ref(tool_ref_id, preload) when is_integer(tool_ref_id) do
    from(item in Project.ItemModel,
      where: item.tool_ref_id == ^tool_ref_id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_item_by_assignment(assignment, preload \\ [])

  def get_item_by_assignment(%Assignment.Model{id: assignment_id}, preload) do
    get_item_by_assignment(assignment_id, preload)
  end

  def get_item_by_assignment(assignment_id, preload) do
    from(item in Project.ItemModel,
      where: item.assignment_id in ^assignment_id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_tool_refs_by_tool(%{id: id} = tool, preload \\ []) do
    field = Project.ToolRefModel.tool_id_field(tool)

    query_tool_refs_by_tool(id, field, preload)
    |> Repo.all()
  end

  def query_tool_refs_by_tool(tool_id, field, preload \\ [])
      when is_integer(tool_id) and is_atom(field) do
    from(tool_ref in Project.ToolRefModel,
      where: field(tool_ref, ^field) == ^tool_id,
      preload: ^preload
    )
  end

  @doc """
  Returns the list of projects that are owned by the user.
  """
  def list_owned_projects(user, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    node_ids =
      Authorization.query_node_ids(
        role: :owner,
        principal: user
      )

    from(s in Project.Model,
      where: s.auth_node_id in subquery(node_ids),
      order_by: [desc: s.updated_at],
      preload: ^preload
    )
    |> Repo.all()
  end

  def delete(id) when is_number(id) do
    get!(id, Project.Model.preload_graph(:down))
    |> Project.Assembly.delete()
  end

  def delete_item(id) when is_number(id) do
    get_item!(id, Project.ItemModel.preload_graph(:down))
    |> Project.Assembly.delete()
  end

  def prepare(
        %{name: _name} = attrs,
        items
      )
      when is_list(items) do
    {:ok, root} =
      prepare_node(%{name: "Project", project_path: []}, items)
      |> Ecto.Changeset.apply_action(:prepare)

    prepare(attrs, root)
  end

  def prepare(
        %{name: _name} = attrs,
        %Project.NodeModel{} = root,
        %Authorization.Node{} = auth_node \\ Authorization.make_node()
      ) do
    %Project.Model{}
    |> Project.Model.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:root, root)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def prepare_node(
        %{name: _, project_path: _} = attrs,
        items,
        auth_node \\ Authorization.make_node()
      )
      when is_list(items) do
    %Project.NodeModel{}
    |> Project.NodeModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:items, items)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def prepare_item(attrs, %Project.ToolRefModel{} = tool_ref) do
    prepare_item(attrs, :tool_ref, tool_ref)
  end

  def prepare_item(attrs, %Assignment.Model{} = assignment) do
    prepare_item(attrs, :assignment, assignment)
  end

  def prepare_item(
        %{name: _name, project_path: _} = attrs,
        field_name,
        concrete
      ) do
    %Project.ItemModel{}
    |> Project.ItemModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(field_name, concrete)
  end

  def prepare_tool_ref(special, tool_key, tool) do
    %Project.ToolRefModel{}
    |> Project.ToolRefModel.changeset(%{special: special})
    |> Ecto.Changeset.put_assoc(tool_key, tool)
  end

  def add_item(%Project.ItemModel{} = item, %Project.NodeModel{} = node) do
    item
    |> Project.ItemModel.changeset(%{})
    |> Ecto.Changeset.put_assoc(:node, node)
    |> Repo.update()
  end

  def add_node(%Project.NodeModel{} = child, %Project.NodeModel{} = parent) do
    child
    |> Project.NodeModel.changeset(%{})
    |> Ecto.Changeset.put_assoc(:parent, parent)
    |> Repo.update()
  end

  def add_owner!(%Project.Model{} = project, user) do
    :ok = Authorization.assign_role(user, project, :owner)
  end

  def remove_owner!(%Project.Model{} = project, user) do
    Authorization.remove_role!(user, project, :owner)
  end

  def list_owners(%Project.Model{} = project, preload \\ []) do
    owner_ids =
      project
      |> Authorization.list_principals()
      |> Enum.filter(fn %{roles: roles} -> MapSet.member?(roles, :owner) end)
      |> Enum.map(fn %{id: id} -> id end)

    from(u in User, where: u.id in ^owner_ids, preload: ^preload, order_by: u.id) |> Repo.all()
  end
end
