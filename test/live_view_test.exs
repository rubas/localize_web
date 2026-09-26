defmodule Localize.LiveViewTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint MyApp.LiveEndpoint

  defp text(html, id),
    do: html |> LazyHTML.from_fragment() |> LazyHTML.query("##{id}") |> LazyHTML.text()

  defp href(html),
    do:
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("#link")
      |> LazyHTML.attribute("href")
      |> hd()

  defp assert_fr(html) do
    assert text(html, "mount") == "fr"
    assert text(html, "title") == "vidéo"
    assert text(html, "params") == "fr"
    assert text(html, "gettext") == "fr"
    assert href(html) == "/fr/vid%C3%A9o"
  end

  test "a live navigation from /en/video to /fr/vidéo is a full page load that renders fr from mount on" do
    conn = build_conn()
    {:ok, view, html} = live(conn, "/en/video")
    assert text(html, "mount") == "en"
    assert text(html, "title") == "video"

    assert {:error, {:redirect, %{to: "http://www.example.com/fr/vid%C3%A9o"}}} =
             live_redirect(view, to: "/fr/vid%C3%A9o")

    {:ok, _view, html} = live(conn, "/fr/vid%C3%A9o")
    assert_fr(html)
  end

  test "a live navigation from /fr/vidéo to /fr/audio stays live and renders fr from mount on" do
    {:ok, view, _html} = live(build_conn(), "/fr/vid%C3%A9o")
    {:ok, _view, html} = live_redirect(view, to: "/fr/audio")
    assert_fr(html)
  end

  test "a live patch from /fr/vidéo to /fr/audio stays in the same LiveView process" do
    {:ok, view, html} = live(build_conn(), "/fr/vid%C3%A9o")
    pid = text(html, "pid")

    html = render_patch(view, "/fr/audio")
    assert text(html, "pid") == pid
    assert_fr(html)
  end

  test "a live navigation from /fr/vidéo to the unlocalized /live is a full page load that keeps the session locale fr" do
    conn = get(build_conn(), "/fr/vid%C3%A9o")
    {:ok, view, _html} = live(conn)

    assert {:error, {:redirect, %{to: "http://www.example.com/live"}}} =
             live_redirect(view, to: "/live")

    {:ok, _view, html} = live(recycle(conn), "/live")
    assert text(html, "mount") == "fr"
  end

  test "the connected mount of /stale/fr/vidéo renders fr while the cookie session holds en" do
    conn = Plug.Test.init_test_session(build_conn(), %{"localize_locale" => "en"})
    {:ok, _view, html} = live(conn, "/stale/fr/vid%C3%A9o")
    assert text(html, "mount") == "fr"
    assert text(html, "params") == "fr"
  end

  test "the session of the user's live_session MFA reaches mount next to the route locale" do
    {:ok, _view, html} = live(build_conn(), "/fr/vid%C3%A9o")
    assert text(html, "extra") == "mfa"
  end

  test "localized live routes outside a live_session get a live session per locale" do
    {:ok, view, html} = live(build_conn(), "/en/outside")
    assert text(html, "mount") == "en"

    assert {:error, {:redirect, %{to: "http://www.example.com/fr/outside"}}} =
             live_redirect(view, to: "/fr/outside")
  end

  test "each locale of a localized live route has its own live session" do
    names =
      for path <- ["/en/video", "/fr/vid%C3%A9o", "/de/video", "/live"] do
        %{phoenix_live_view: {_view, _action, _opts, %{name: name}}} =
          Phoenix.Router.route_info(MyApp.LiveRouter, "GET", URI.decode(path), nil)

        name
      end

    assert names == [{:localized, :en}, {:localized, :fr}, {:localized, :de}, :localized]
  end
end
