defmodule MyAppWeb.LocaleHook do
  def on_mount(:default, _params, session, socket) do
    _ = Localize.Plug.put_locale_from_session(session, gettext: MyApp.Gettext)
    {:cont, socket}
  end

  def session(_conn, value), do: %{"extra" => value}
end

defmodule MyAppWeb.LocaleLive do
  use Phoenix.LiveView

  use Localize.VerifiedRoutes,
    router: MyApp.LiveRouter,
    endpoint: MyApp.LiveEndpoint,
    gettext: MyApp.Gettext

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       mount_locale: Localize.get_locale().cldr_locale_id,
       title: Gettext.dgettext(MyApp.Gettext, "routes", "video"),
       extra: session["extra"],
       pid: inspect(self())
     )}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply,
     assign(socket,
       params_locale: Localize.get_locale().cldr_locale_id,
       gettext: Gettext.get_locale(MyApp.Gettext)
     )}
  end

  def render(assigns) do
    ~H"""
    <p id="mount">{@mount_locale}</p>
    <p id="title">{@title}</p>
    <p id="params">{@params_locale}</p>
    <p id="gettext">{@gettext}</p>
    <p id="extra">{@extra}</p>
    <p id="pid">{@pid}</p>
    <a id="link" href={~q"/#{locale}/video"}>video</a>
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

  # No PutSession: the session keeps the locale it came with.
  pipeline :route_only do
    plug(:fetch_session)
    plug(Localize.Plug.PutLocale, from: [:route], gettext: MyApp.Gettext)
  end

  scope "/", MyAppWeb do
    pipe_through(:browser)

    # The shape of readme.app: a live_session around localize, with an
    # unlocalized live route and a localized get route next to it.
    live_session :localized,
      on_mount: MyAppWeb.LocaleHook,
      session: {MyAppWeb.LocaleHook, :session, ["mfa"]} do
      localize do
        live("/#{locale}/video", LocaleLive)
        live("/#{locale}/audio", LocaleLive)
        get("/#{locale}/pages/:page", PageController, :show, alias: false)
      end

      live("/live", LocaleLive)
    end

    localize [:en, :fr] do
      live("/#{locale}/outside", LocaleLive)
    end
  end

  scope "/stale", MyAppWeb do
    pipe_through(:route_only)

    live_session :stale, on_mount: MyAppWeb.LocaleHook do
      localize [:en, :fr] do
        live("/#{locale}/video", LocaleLive)
      end
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
