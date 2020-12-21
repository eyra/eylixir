defmodule Link.StudiesTest do
  use Link.DataCase

  alias Link.Studies

  describe "studies" do
    alias Link.Studies.Study
    alias Link.{Users, Factories}

    @researcher %{
      email: Faker.Internet.email(),
      password: "S4p3rS3cr3t",
      password_confirmation: "S4p3rS3cr3t"
    }
    @valid_attrs %{description: "some description", title: "some title"}
    @update_attrs %{description: "some updated description", title: "some updated title"}
    @invalid_attrs %{description: nil, title: nil}

    def researcher_fixture(attrs \\ %{}) do
      {:ok, user} = attrs |> Enum.into(@researcher) |> Users.create()
      user
    end

    def study_fixture(attrs \\ %{}) do
      researcher = researcher_fixture()

      {:ok, study} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Studies.create_study(researcher)

      study
    end

    test "list_studies/1 returns all studies" do
      study = study_fixture()
      assert Studies.list_studies() == [study]
    end

    test "list_studies/1 allows excluding a list of ids" do
      studies = 0..3 |> Enum.map(fn _ -> Factories.create_study() end)
      {excluded_study, expected_result} = List.pop_at(studies, 1)
      assert Studies.list_studies(exclude: [excluded_study.id]) == expected_result
    end

    test "list_owned_studies/1 returns only studies that are owned by the user" do
      _not_owned = Factories.create_study()
      researcher = Factories.get_or_create_researcher(email: "someone@example.com")
      owned = Factories.create_study(owner: researcher)
      assert Studies.list_owned_studies(researcher) == [owned]
    end

    test "get_study!/1 returns the study with given id" do
      study = study_fixture()
      assert Studies.get_study!(study.id).title == study.title
    end

    test "create_study/1 with valid data creates a study" do
      assert {:ok, %Study{} = study} = Studies.create_study(@valid_attrs, researcher_fixture())
      assert study.description == "some description"
      assert study.title == "some title"
    end

    test "create_study/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Studies.create_study(@invalid_attrs, researcher_fixture())
    end

    test "update_study/2 with valid data updates the study" do
      study = study_fixture()
      assert {:ok, %Study{} = study} = Studies.update_study(study, @update_attrs)
      assert study.description == "some updated description"
      assert study.title == "some updated title"
    end

    test "update_study/2 with invalid data returns error changeset" do
      study = study_fixture()
      assert {:error, %Ecto.Changeset{}} = Studies.update_study(study, @invalid_attrs)
    end

    test "delete_study/1 deletes the study" do
      study = study_fixture()
      assert {:ok, %Study{}} = Studies.delete_study(study)
      assert_raise Ecto.NoResultsError, fn -> Studies.get_study!(study.id) end
    end

    test "change_study/1 returns a study changeset" do
      study = study_fixture()
      assert %Ecto.Changeset{} = Studies.change_study(study)
    end

    test "apply_participant/2 creates application" do
      study = study_fixture()
      member = researcher_fixture(email: Faker.Internet.email())
      assert {:ok, _} = Studies.apply_participant(study, member)
    end

    test "application_status/2 informs if a member has applied to a study" do
      study = study_fixture()
      member = researcher_fixture(email: Faker.Internet.email())
      assert Studies.application_status(study, member) |> is_nil
      Studies.apply_participant(study, member)
      assert Studies.application_status(study, member) == :applied
    end

    test "update_participant_status/3 alters the status of a participant" do
      study = study_fixture()
      member = researcher_fixture(email: Faker.Internet.email())
      Studies.apply_participant(study, member)
      assert :ok = Studies.update_participant_status(study, member, "entered")
      assert Studies.application_status(study, member) == :entered
    end

    test "list_participants/1 lists all participants" do
      study = study_fixture()
      _non_particpant = researcher_fixture(email: Faker.Internet.email())
      applied_participant = researcher_fixture(email: Faker.Internet.email())
      Studies.apply_participant(study, applied_participant)
      accepted_participant = researcher_fixture(email: Faker.Internet.email())
      Studies.apply_participant(study, accepted_participant)
      Studies.update_participant_status(study, accepted_participant, "entered")
      rejected_participant = researcher_fixture(email: Faker.Internet.email())
      Studies.apply_participant(study, rejected_participant)
      Studies.update_participant_status(study, rejected_participant, "rejected")
      # Both members that applied should be listed with their corresponding status.
      assert Studies.list_participants(study) == [
               %{status: :applied, user_id: applied_participant.id},
               %{status: :entered, user_id: accepted_participant.id},
               %{status: :rejected, user_id: rejected_participant.id}
             ]
    end

    test "list_participations/1 list all studies a user is a part of" do
      study = Factories.create_study()
      member = Factories.get_or_create_user()
      # Listing without any participation should return an empty list
      assert Studies.list_participations(member) == []
      # The listing should contain the study after an application has been made
      Studies.apply_participant(study, member)
      assert Studies.list_participations(member) == [study]
    end

    test "add_owner!/2 grants a user ownership over a study" do
      researcher_1 = Factories.get_or_create_researcher()
      researcher_2 = Factories.get_or_create_researcher()
      study = Factories.create_study(owner: researcher_1)
      # The second researcher is not the owner of the study
      assert Studies.list_owned_studies(researcher_2) == []
      Studies.add_owner!(study, researcher_2)
      # The second researcher is now an owner of the study
      assert Studies.list_owned_studies(researcher_2) == [study]
    end

    test "assign_owners/2 adds or removes a users ownership of a study" do
      researcher_1 = Factories.get_or_create_researcher()
      researcher_2 = Factories.get_or_create_researcher()
      study = Factories.create_study(owner: researcher_1)
      # The second researcher is not the owner of the study
      assert Studies.list_owned_studies(researcher_2) == []
      Studies.assign_owners(study, [researcher_2])
      # The second researcher is now an owner of the study
      assert Studies.list_owned_studies(researcher_2) == [study]
      # The original owner can no longer claim ownership
      assert Studies.list_owned_studies(researcher_1) == []
    end

    test "list_owners/1 returns all users with ownership permission on the study" do
      researcher_1 = Factories.get_or_create_researcher()
      researcher_2 = Factories.get_or_create_researcher()
      study = Factories.create_study(owner: researcher_1)
      assert Studies.list_owners(study) == [researcher_1]
      Studies.assign_owners(study, [researcher_2])
      assert Studies.list_owners(study) == [researcher_2]
    end
  end
end
