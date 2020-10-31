defmodule BlogWeb.PostLive.New do
  use Phoenix.LiveView,
    layout: {BlogWeb.LayoutView, "wider.html"}

  import Phoenix.HTML, only: [raw: 1]

  @impl true

  def mount(_params, _session, socket) do
    md = """
    # You can use markdown
    ## It supports syntax highlighting too
    ```elixir
    def func do
    end
    ```
    """

    {:ok,
     assign(socket,
       preview: markdown_to_html(md),
       title: "",
       content: md
     )}
  end

  def render(assigns) do
    ~L"""
    <div class="row">
    <div class="column">
      <form phx-change="preview">
      <input name="post-title" value="<%= @title %>" type="text">
      <textarea name="post-content" id="new-post"><%= @content %></textarea>
      </form>
    </div>
    <div class="column">
      <%= raw @preview %>
    </div>
    </div>
    """
  end

  def handle_event("preview", %{"post-content" => content, "post-title" => title}, socket) do
    {:noreply,
     socket
     |> assign(
       preview: markdown_to_html(content),
       content: content,
       title: title
     )}
  end

  defp markdown_to_html(md) do
    {_, html, _errors} = Earmark.as_html(md)
    NimblePublisher.Highlighter.highlight(html)
  end
end
