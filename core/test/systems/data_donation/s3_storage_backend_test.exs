defmodule Systems.DataDonation.S3StorageBackendTest do
  use Core.DataCase, async: true

  alias Systems.DataDonation.S3StorageBackend

  describe "path/1" do
    test "generates a unique path" do
      assert S3StorageBackend.path("a-participant") != S3StorageBackend.path("a-participant")
    end
  end
end