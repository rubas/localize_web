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
end
