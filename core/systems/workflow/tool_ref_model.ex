defmodule Systems.Workflow.ToolRefModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  require Logger

  import Ecto.Changeset
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept
  alias Frameworks.Utility

  alias Systems.Workflow
  alias Systems.Document
  alias Systems.Alliance
  alias Systems.Lab
  alias Systems.Feldspar
  alias Systems.Graphite
  alias Systems.Instruction
  alias Systems.Onyx

  @tools [
    :alliance_tool,
    :document_tool,
    :feldspar_tool,
    :graphite_tool,
    :instruction_tool,
    :lab_tool,
    :onyx_tool
  ]

  schema "tool_refs" do
    field(:special, Ecto.Atom)

    belongs_to(:alliance_tool, Alliance.ToolModel)
    belongs_to(:document_tool, Document.ToolModel)
    belongs_to(:feldspar_tool, Feldspar.ToolModel)
    belongs_to(:graphite_tool, Graphite.ToolModel)
    belongs_to(:instruction_tool, Instruction.ToolModel)
    belongs_to(:lab_tool, Lab.ToolModel)
    belongs_to(:onyx_tool, Onyx.ToolModel)

    has_one(:workflow_item, Workflow.ItemModel, foreign_key: :tool_ref_id)

    timestamps()
  end

  @required_fields ~w(special)a
  @fields @required_fields

  @doc false
  def changeset(tool_ref, attrs) do
    tool_ref
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:down),
    do: preload_graph(@tools)

  def preload_graph(tool_id_field) when is_atom(tool_id_field) do
    if Enum.member?(@tools, tool_id_field) do
      tool_model =
        tool_id_field
        |> get_tool_key()
        |> get_tool_model()

      [{tool_id_field, apply(tool_model, :preload_graph, [:down])}]
    else
      raise ArgumentError, "Unsupported tool_id_field: #{inspect(tool_id_field)}"
    end
  end

  defp get_tool_key(tool_id_field) when is_atom(tool_id_field) do
    get_tool_key(Atom.to_string(tool_id_field))
  end

  defp get_tool_key(tool_id_field) when is_binary(tool_id_field) do
    String.split(tool_id_field, "_") |> List.first()
  end

  defp get_tool_model(tool_key) do
    # The tool_key is equal to the system name for now. Systems only have one tool model.
    # If this changes, we need to update this function.
    Utility.Module.get(tool_key, "ToolModel")
  end

  def auth_tree(%Workflow.ToolRefModel{} = tool_ref) do
    Concept.ToolModel.auth_tree(tool(tool_ref))
  end

  def flatten(tool_ref), do: tool(tool_ref)

  def form(%{special: special} = tool_ref), do: Concept.ToolModel.form(tool(tool_ref), special)

  def external_path(%{alliance_tool: alliance_tool}, next_id) do
    Alliance.ToolModel.external_path(alliance_tool, next_id)
  end

  def external_path(_, _), do: nil

  def tool_field(tool), do: String.to_existing_atom("#{Concept.ToolModel.key(tool)}_tool")
  def tool_id_field(tool), do: String.to_existing_atom("#{Concept.ToolModel.key(tool)}_tool_id")

  def tool(tool_ref) do
    @tools
    |> Enum.reduce(nil, fn tool, acc ->
      tool = Map.get(tool_ref, tool)

      case tool do
        %{id: _id} -> tool
        _ -> acc
      end
    end)
  end

  def tag(%Workflow.ToolRefModel{special: :questionnaire}),
    do: dgettext("eyra-project", "tool_ref.tag.questionnaire")

  def tag(%Workflow.ToolRefModel{special: :graphite}),
    do: dgettext("eyra-project", "tool_ref.tag.graphite")

  def tag(%Workflow.ToolRefModel{special: _special}) do
    dgettext("eyra-project", "tool_ref.tag.default")
  end
end
