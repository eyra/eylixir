defmodule SignInWithApple.CallbackPlug do
  import Plug.Conn
  import SignInWithApple.Helpers, only: [backend_module: 1, apply_defaults: 1]

  def init(options) when is_list(options), do: options |> apply_defaults()

  def call(conn, config) do
    session_params = get_session(conn, :sign_in_with_apple)
    config = Keyword.put(config, :session_params, session_params)
    {:ok, %{user: user_info}} = backend_module(config).callback(config, conn.body_params)

    user =
      if user = SignInWithApple.get_user_by_sub(user_info["sub"]) do
        user
      else
        {:ok, user_name_params} = conn.body_params["user"] |> Jason.decode!() |> Map.fetch("name")

        {:ok, signed_in_apple_user} =
          SignInWithApple.register_user(%{
            sub: user_info["sub"],
            email: user_info["email"],
            is_private_email: user_info["is_private_email"],
            first_name: user_name_params["firstName"],
            middle_name: user_name_params["middleName"],
            last_name: user_name_params["lastName"]
          })

        signed_in_apple_user.user
      end

    CoreWeb.UserAuth.log_in_user(conn, user)
  end
end
