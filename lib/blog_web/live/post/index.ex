defmodule BlogWeb.PageLive do
  use BlogWeb, :live_view

  @impl true
  def mount(%{"id" => id}, session, socket) do
    {:ok, assign(socket, query: "", results: %{}, posts: nil, post: Blog.get_post_by_id!(id))}
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, query: "", results: %{}, posts: Blog.all_posts())}
  end

  def render(%{posts: nil} = assigns) do
    ~L"""
    <h1> <%= @post.title %> </h1>
    <p> Author: <%= @post.author %> </p>
    <b> <%= Enum.join(@post.tags, ", ") %> </b>
    <p> <%= raw @post.body %> </p>
    """
  end

  def render(assigns) do
    ~L"""
      <%= for post <- @posts do %>
      <h1> <%= post.title %> </h1>
      <p> Author: <%= post.author %> </p>
      <b> <%= Enum.join(post.tags, ", ") %> </b>
      <p> <%= raw post.description %> </p>
      <%= live_redirect "Read", to: Routes.page_path(@socket, :show, post.id), class: "button" %>
      <% end %>
    """
  end
end
