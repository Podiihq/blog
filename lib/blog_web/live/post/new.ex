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
       valid_attrs: @default_attrs,
       attrs: @default_attrs
     )
     |> build()}
  end

  def render(assigns) do
    ~L"""
    <div class="row">
    <div class="column">
      <form phx-change="preview", phx-submit="save">
      <input name="post-title" value="<%= @post.title |> String.downcase() |> String.replace(" ", "-") %>"  type="text">
      <textarea name="post-content" id="new-post"><%= @content %></textarea>
      <button> Save </button>
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

  def handle_event("save", _, socket) do
    title = socket.assigns.post.title |> String.downcase()
    today = Date.utc_today()
    path = Path.join(Path.expand("."), ["posts", "/#{today.year}"])
    filename = "#{today.month}-" <> String.pad_leading("#{today.day}", 2, "0") <> "-#{title}"
    filename = String.replace(filename, " ", "-")

    {:ok, _res} =
      File.open(path <> "/" <> filename <> ".md", [:read, :write], fn file ->
        IO.write(file, socket.assigns.content)
      end)

    {:noreply, socket}
  end

  def handle_event("preview", %{"post-content" => content}, socket) do
    {:noreply, socket |> assign(content: content) |> build(content)}
  end

  defp markdown_to_html(md) do
    {_, html, _errors} = Earmark.as_html(md)
    NimblePublisher.Highlighter.highlight(html)
  end

  defp build(socket, content \\ @default_md) do
    [code, body] = :binary.split(content, ["\n---\n", "\r\n---\r\n"])
    body = markdown_to_html(body)

    socket =
      try do
        {%{} = attrs, _} = Code.eval_string(code, [])
        socket |> assign(valid_attrs: attrs, attrs: attrs)
      rescue
        _ ->
          {%{} = attrs, _} = Code.eval_string(@default_attrs, [])
          socket |> assign(valid_attrs: socket.assigns.valid_attrs, attrs: attrs)
      end

    filename = "posts/2020/04-17-hello-world.md"

    socket |> assign(post: Blog.Post.build(filename, socket.assigns.valid_attrs, body))
  end
end
