defmodule BlogWeb.PostLive.New do
  use Phoenix.LiveView,
    layout: {BlogWeb.LayoutView, "wider.html"}

  import Phoenix.HTML, only: [raw: 1]

  @default_attrs """
  %{
  title: "Blog Title",
  author: "Your Name",
  tags: ["tag one"],
  description: "Short Description of your Blog",
  draft: true
  }
  """

  @default_md """
  #{@default_attrs}
  ---
  Hello world!

  # You can use markdown
  ## It supports syntax highlighting too
  ```elixir
  def func do
  end
  ```
  """

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       title: "",
       content: @default_md,
       post: build()
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
      <%= if @post do %>
      <h1> <%= @post.title %> </h1>
      <p> Author: <%= @post.author %> </p>
      <b> <%= Enum.join(@post.tags, ", ") %> </b>
      <p> <%= raw @post.body %> </p>
      <% end %>
    </div>
    </div>
    """
  end

  def handle_event("preview", %{"_target" => ["post-title"], "post-title" => title}, socket) do
    today = Date.utc_today()
    path = Path.join(Path.expand("."), ["posts", "/#{today.year}"])
    filename = "#{today.month}-" <> String.pad_leading(today.day, 2, "0") <> "-#{title}"

    {:ok, _res} =
      File.open(path <> "/" <> filename <> ".md", [:append], fn file ->
        IO.write(file, socket.assigns.content)
      end)

    {:noreply, socket}
  end

  def handle_event("preview", %{"post-content" => content, "post-title" => title}, socket) do
    {:noreply,
     socket
     |> assign(
       content: content,
       title: title,
       post: build(content)
     )}
  end

  defp markdown_to_html(md) do
    {_, html, _errors} = Earmark.as_html(md)
    NimblePublisher.Highlighter.highlight(html)
  end

  defp build(content \\ @default_md) do
    [code, body] = :binary.split(content, ["\n---\n", "\r\n---\r\n"])
    body = markdown_to_html(body)

    {%{} = attrs, _} =
      try do
        Code.eval_string(code, [])
      rescue
        _ ->
          Code.eval_string(@default_attrs, [])
      end

    filename = "posts/2020/04-17-hello-world.md"

    Blog.Post.build(filename, attrs, body)
  end
end
