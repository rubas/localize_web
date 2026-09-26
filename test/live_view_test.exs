defmodule Localize.LiveViewTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint MyApp.LiveEndpoint

  test "live navigation from /en/video to /fr/vidéo renders the page in fr" do
    {:ok, view, html} = live(build_conn(), "/en/video")
    assert html =~ ~s(<p id="locale">en</p>)

    {:ok, _view, html} = live_redirect(view, to: "/fr/vid%C3%A9o")
    assert html =~ ~s(<p id="locale">fr</p>)
    assert html =~ ~s(<p id="gettext">fr</p>)
  end

  test "live navigation from /fr/vidéo to the unlocalized /live keeps the session locale fr" do
    {:ok, view, _html} = live(build_conn(), "/fr/vid%C3%A9o")

    {:ok, _view, html} = live_redirect(view, to: "/live")
    assert html =~ ~s(<p id="locale">fr</p>)
  end

  test "a live patch from /fr/vidéo to the unlocalized /live restores the session locale en" do
    {:ok, view, _html} = live(build_conn(), "/en/video")

    assert render_patch(view, "/fr/vid%C3%A9o") =~ ~s(<p id="locale">fr</p>)
    assert render_patch(view, "/live") =~ ~s(<p id="locale">en</p>)
  end

  test "a live route with metadata: @audio_metadata keeps it next to its locale" do
    assert %{kind: :audio, localize_locale: %{cldr_locale_id: :fr}} =
             Phoenix.Router.route_info(MyApp.LiveRouter, "GET", "/fr/audio", nil)
  end
end
