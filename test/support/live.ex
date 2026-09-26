defmodule MyAppWeb.LocaleLive do
  use Phoenix.LiveView

  def handle_params(_params, _uri, socket) do
    {:noreply,
     assign(socket,
       locale: Localize.get_locale().cldr_locale_id,
       gettext: Gettext.get_locale(MyApp.Gettext)
     )}
  end

  def render(assigns) do
    ~H"""
    <p id="locale">{@locale}</p>
    <p id="gettext">{@gettext}</p>
    """
  end
end

defmodule MyApp.LiveRouter do
  use Phoenix.Router
  use Localize.Routes, gettext: MyApp.Gettext, helpers: false
  import Phoenix.LiveView.Router

  @audio_metadata %{kind: :audio}

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
        live("/#{locale}/audio", LocaleLive, metadata: @audio_metadata)
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
