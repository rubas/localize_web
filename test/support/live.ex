defmodule MyAppWeb.LocaleLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <p id="locale">{Localize.get_locale().cldr_locale_id}</p>
    <p id="gettext">{Gettext.get_locale(MyApp.Gettext)}</p>
    """
  end
end

defmodule MyApp.LiveRouter do
  use Phoenix.Router
  use Localize.Routes, gettext: MyApp.Gettext, helpers: false
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:fetch_session)
    plug(Localize.Plug.PutLocale, from: [:route, :session], gettext: MyApp.Gettext)
    plug(Localize.Plug.PutSession)
  end

  scope "/", MyAppWeb do
    pipe_through(:browser)

    live_session :localized, on_mount: {Localize.LiveView, gettext: MyApp.Gettext} do
      localize [:en, :fr] do
        live("/#{locale}/video", LocaleLive)
      end

      live("/live", LocaleLive)
    end
  end
end

defmodule MyApp.LiveEndpoint do
  use Phoenix.Endpoint, otp_app: :localize_web

  @session_options [store: :cookie, key: "_live", signing_salt: "localize_live"]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  plug(Plug.Session, @session_options)
  plug(MyApp.LiveRouter)
end
