defmodule FinstaWeb.HomeLive do

  use FinstaWeb, :live_view
  alias Finsta.Posts
  alias Finsta.Posts.Post

  @impl true
  def render(%{loading: true}=assigns) do
    ~H"""
      Finsta is loading ...
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
      <h1 class="text-2x1">Finsta</h1>
      <.button type="button" phx-click={show_modal("new-post-modal")}>Create Post</.button>

      <div id="feed" phx-udpate="stream" class="flex flex-col gap-2">
        <div :for={{dom_id, post} <- @streams.posts} id={dom_id} class="w-1/2 mx-auto flex flex-col gap-2 p-4 border rounded">
          <img src={post.image_path}/>
          <p><%=post.user.email%></p>
          <p><%=post.caption%></p>
        </div>
      </div>

      <.modal id="new-post-modal">
        <.simple_form for={@form} phx-change="validate" phx-submit="save-post">
          <.live_file_input upload={@uploads.image} required />
          <.input field={@form[:caption]} type="textarea" label="Caption" required/>

          <.button type="submit" phx-disable-with="Saving...">Create Post</.button>
        </.simple_form>
      </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      form =
        %Post{}
        |> Post.changeset(%{})
        |> to_form(as: "post")

      socket=
        socket
        |> assign(form: form, loading: false)
        |> allow_upload(:image, accept: ~w{.png .jpg}, max_entries: 1) # enable file uploading
        |> stream(:posts, Posts.posts())

      {:ok, socket}
    else
      {:ok, assign(socket, loading: true)}
    end
  end


  @impl true
  def handle_event("validate", _param, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save-post", %{"post" => post_params}, socket) do
    %{current_user: user} = socket.assigns

    post_params
     |> Map.put("user_id", user.id)
     |> Map.put("image_path", List.first(consume_files(socket)))
     |> Posts.save()
     |> case do
       {:ok, _post} ->
          socket =
            socket
            |> put_flash(:info, "Post created successfully!")
            |> push_navigate(to: ~p"/home")

          {:noreply, socket}

       {:error, _changeset} ->
          {:noreply, socket}
     end
  end

  defp consume_files(socket) do
      # code from https://hexdocs.pm/phoenix_live_view/uploads.html
      consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
        dest = Path.join([:code.priv_dir(:finsta), "static", "uploads", Path.basename(path)])
        # The `static/uploads` directory must exist for `File.cp!/2`
        # and FinstaWeb.static_paths/0 should contain uploads to work,.
        File.cp!(path, dest)

        {:postpone, ~p"/uploads/#{Path.basename(dest)}"}
      end)
  end
end
