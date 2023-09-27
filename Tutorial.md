# Build a real-time Instagram Clone with Phoenix LiveView

Demonstrates how to build a real-time Instagram clone using Phoenix LiveView. We cover various aspects of the application, including setting up the project, implementing user authentication and login, managing file uploads, creating posts, displaying uploaded images, and adding real-time functionality. We showcase the power of LiveView by building the application without the need for JavaScript, all while explaining the steps involved and providing code examples. This tutorial is a great resource for developers looking to build real-time web applications using Phoenix LiveView.

Based on [John Elm youtube channel]( https://www.youtube.com/watch?v=4cnmyQJToKM)

## Create the project
First, let’s create a new Phoenix Liveview project.

        $ mix phx.new finsta

When it finished 

        $ cd finsta

## Create the Database
Configure your database (by default PostgreSQL) in the file config/dev.exs optionally config/test.exs if you want to run the test cases. You will need to have a database installed or use a Docker container with PostgreSQL.
Create the database with the command mix ecto.create
Your will see a message like this
The database for Finsta.Repo has been created

Run the test to check that everything is ok

    $ mix test
	
Start your Phoenix app with:

    $ mix phx.server

You can also run your app inside IEx (Interactive Elixir) as:

    $ iex -S mix phx.server

Generates authentication logic for a resource

     $ mix phx.gen.auth Accounts User users

The mix phx.gen.auth Accounts User users command generates a flexible, pre-built authentication system into your Phoenix app. This generator allows you to quickly move past the task of adding authentication to your codebase and stay focused on the real-world problem your application is trying to solve. The first argument is the context module, followed by the schema module and its plural name (used as the schema table name). See the doc for more info.

When you run the command you will see something like this

- Using Phoenix.LiveView (default)
- Using Phoenix.Controller only
Do you want to create a LiveView-based authentication system? [Yn] Y

Enter Y

Finally update your dependencies with the following command:

    $ mix deps.get

Remember to update your repository by running migrations:

    $ mix ecto.migrate

Alternative you can run one command
     $ mix do deps.get, ecto.migrate
Launch the App and register
    $ iex -S mix phx.server

In the current app we can see that once a user has logged in, it is redirected to the home page. The goal is to redirect logged in users to the actual feed. So we will redirect logged in users to a new LiveView page

Go to the `route.ex` file and copy the default route `get "/", PageController, :home`  defined in the scope `scope "/", FinstaWeb do` and move it to the scope `redirect if user is authenticated`

```
scope "/", FinstaWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/", PageController, :home

    live_session :redirect_if_user_is_authenticated,
     ...  
    end

    post "/users/log_in", UserSessionController, :create
  end
```

Then in the authenticated routes redirect users to the `/home`  page that we are going to create.

```
 scope "/", FinstaWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{FinstaWeb.UserAuth, :ensure_authenticated}] do
      live "home", HomeLive, :index
      ....
    end
  end
 ```

After that update the `signed_in_path` function in `user_auth.ex` module

`defp signed_in_path(_conn), do: ~p"/home"`

Now if you are logged in int the app you will be redirected to the `/home` path
and will see the text `Finsta`

# How to Create Posts

First we need to create the Schem

`mix phx.gen.schema Posts.Post posts caption:text image_path:string user_id:references:users`


# Migrate the changes to the Repository

`mix ecto.migrate`

Now that we have our `Post` Schema created we are going to update it

Replace `field :user_id, :id` by `belongs_to :user, User`


The main difference between using `field :user_id, :id` and `belongs_to :user, User` in the Ecto schema for posts is that the former is just a simple field declaration, while the latter is an association declaration. This has some implications for how Ecto handles the relationship between `posts` and `users`.

- Using  `field :user_id, :id` is simpler and more explicit, but it does not declare a relationship and may lead to data inconsistency or duplication.

- Using `belongs_to :user`, User declares a relationship and may reduce data inconsistency or duplication, but it is more complex and less explicit.


```
def changeset(post, attrs) do
  post
  |> cast(attrs, [:title, :body, :user_id])
  |> validate_required([:title, :body, :user_id])
end
```

This will cast the `user_id` field from the given attributes, validate that it is present, and check that it references a valid user record in the database.


###  Create a Form in the HomeLive View

Create a file `home_live.ex` in the directory  `lib/finsta_web/live`

Use the following template

```
defmodule FinstaWeb.HomeLive do
  
  @impl true
  def render(assigns) do
    ~H"""
    <!-- Your HTML code here -->
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # Your mount logic here
    {:ok, socket}
  end

  @impl true
  def handle_event("event", %{"value" => value}, socket) do
    # Your event handling logic here
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "info"}, socket) do
    # Your info handling logic here
    {:noreply, socket}
  end
end
```


Before to create the LiveView, here are the basic that every module should implement.
[According to the official documentation](https://hexdocs.pm/phoenix_live_view/js-interop.html), the Phoenix.LiveView behaviour defines the following callbacks that every LiveView module must implement:

`mount/3`
 - invoked when the LiveView is first rendered or connected. It takes the params, the session, and the socket as arguments and returns a tuple of {:ok, socket} or {:error, socket}. It is responsible for setting up the initial state and assigns of the LiveView.
  
`render/1`
- invoked whenever the LiveView needs to render its HTML template. It takes the assigns as an argument and returns a string of HTML code. It uses the ~H"""...""" sigil to write HTML templates with embedded Elixir expressions.

`handle_event/3`
 - invoked when an event is triggered from the client or the server. It takes the event name, the event payload, and the socket as arguments and returns a tuple of {:noreply, socket}, {:reply, reply, socket}, or {:stop, reason, socket}. It is responsible for handling user interactions, updating the state and assigns of the LiveView, and sending replies or stopping the LiveView if necessary.

There are also some optional callbacks that can be implemented by LiveView modules, such as:

`handle_info/2` 
- invoked when a regular Elixir message is sent to the LiveView process. It takes the message and the socket as arguments and returns a tuple of {:noreply, socket}, {:reply, reply, socket}, or {:stop, reason, socket}. It is useful for handling internal application messages or PubSub broadcasts.

`handle_params/3`
 - invoked when the URL params change on the client. It takes the params, the url, and the socket as arguments and returns a tuple of {:noreply, socket}, {:reply, reply, socket}, or {:stop, reason, socket}. It is useful for handling live navigation events or query params.

`handle_error/2`
 - invoked when an error occurs during rendering or event handling. It takes the error and the socket as arguments and returns a tuple of {:noreply, socket} or {:stop, reason, socket}. It is useful for logging errors or displaying error messages to the user.

```
  use FinstaWeb, :live_view
  alias Finsta.Posts
  alias Finsta.Posts.Post

```

Update the LiveView module for the Finsta app that imports some modules, aliases some modules, and implements the Phoenix.LiveView behaviour.

#### Update the render funtion


```
  @impl true
  def render(assigns) do
    ~H"""
      <h1 class="text-2x1">Finsta</h1>
      <.button type="button" phx-click={show_modal("new-post-modal")}>Create Post</.button>

      <.modal id="new-post-modal">
        <.simple_form for={@form} phx-change="validate" phx-submit="save-post">
          <.live_file_input upload={@uploads.image} required />
          <.input field={@form[:caption]} type="textarea" label="Caption" required/>

          <.button type="submit" phx-disable-with="Saving...">Create Post</.button>
        </.simple_form>
      </.modal>
    """
  end
```

- The `render/1` function, takes a map of assigns (variables passed from the socket) and returns a string of HTML code that will be rendered on the browser. The HTML code is written using the `~H"""..."""` sigil, which is a special syntax for writing HTML templates with embedded Elixir expressions. The HTML code uses some LiveComponents, which are reusable UI components that can be invoked with the `<.component>` syntax. The LiveComponents can take some attributes, such as `type`, `phx-click`, `phx-change`, etc., that define their behaviour and appearance. The HTML code also uses some helper functions, such as `show_modal/1`, shows a modal dialog with a given id.

- The HTML code consists of three parts: a heading with the app name, a button to create a new post, and a modal dialog to display a form for creating a new post. The button has a `phx-click` attribute that triggers an event named `"show_modal"` with a payload of `"new-post-modal"`. The modal dialog has an id of `"new-post-modal"` and contains a simple form with two inputs: one for uploading an image and one for writing a caption. The form has a `phx-change` attribute that triggers an event named `"validate"` with no payload and a `phx-submit` attribute that triggers an event named `"save-post"` with the form data as payload. The form also has a button to submit the form with a `phx-disable-with` attribute that disables the button and shows a text of `"Saving..."` while the form is being submitted.

- Be sure to double check the event names and their corresponding hanlders match to avoid unexpected errors.



```
  @impl true
  def mount(_params, _session, socket) do
    form =
      %Post{}
      |> Post.changeset(%{})
      |> to_form(as: "post")

    socket=
      socket
       |> assign(form: form)
       |> allow_upload(:image, accept: ~w{.png .jpg}, max_entries: 1) # enable file uploading

    {:ok, socket}
  end
```

- The `mount/3` function is invoked when a LiveView is first rendered, either as a regular HTTP request or as a stateful view on client connect.
- We create a `form` variable that holds a changeset for a `Post` struct. A `changeset` is a way of validating and tracking changes to data before persisting it to a database. 
- The `to_form/2` function converts the changeset into a form data structure that can be used by [`Phoenix.HTML.Form`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html) functions.
- We update the `socket` variable by assigning the `form` variable to its `assigns`. `assigns` are stateful values kept on the server side that can be accessed in the LiveView template. 
- We also call the `allow_upload/4` function to enable file uploading for the image field of the form. The `allow_upload/4` function takes four arguments: the socket, the name of the field, a list of accepted file extensions, and the maximum number of files allowed.
- We return `{:ok, socket}` as the result of the `mount/3` function. This indicates that the LiveView was successfully mounted and renders its template with the updated socket `assigns`.
 

 ### Handle Events validate and save-post

```  @impl true
  def handle_event("validate", _param, socket) do
    {:noreply, socket}
  end
```

-The `handle_event/3` function, is invoked when an event is triggered from the client. It takes three arguments: the name of the event, which is `"validate"` in this case; the payload of the event, which is ignored in this case; and the socket, which is the same data structure as before. The function returns a tuple of `{:noreply, socket}`, which indicates that the LiveView does not need to reply to the client and passes an updated socket to be used for rendering.```


```
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
```

- The `handle_event/3` function, is invoked when an event is triggered from the client. It takes three arguments: the name of the event, which is `"save-post"` in this case; the payload of the event, which is a map of form data with a key of `"post"` in this case; and the socket, which is the same data structure as before. The function returns a tuple of `{:noreply, socket}`, which indicates that the LiveView does not need to reply to the client and passes an updated socket to be used for rendering.

- We match on the event name `save-post` and the params that contain the post data. 
- We extract the current_user assign from the socket, which contains the information of the logged-in user.
- We update the `post_params` by adding the `user_id` and the `image_path` fields. The `user_id` is obtained from the `current_user` assign, while the `image_path` is obtained by calling the `consume_files/1` function. The consume_files/1 function takes a socket and returns a list of uploaded file paths that were allowed by the `allow_upload/4` function in the `mount/3` function.
- We call the `Posts.save/1` function to save the post_params to the database. The `Posts.save/1` function returns either `{:ok, post}` or `{:error, changeset}`, depending on whether the operation was successful or not.
- We use a `case expression` to handle the result of the `Posts.save/1` function. If it returns `{:ok, post}`, we update the socket by adding a `flash` message, which is a temporary message that can be displayed to the user, and pushing a navigation to redirect the user to another page. If it returns {:error, changeset}, we do nothing and return the socket as it is.


Note: The code is using `push_nativate` instead of `push_patch`, because the latest one will not close the modal, it'll just invoke
handle params and keep it on the same process, instead `push_navigate` we create a new process and it'll close the modal for us. See below to learn more.

#### When to use push_navigate instead of push_patch in LiveView. 

- `push_navigate` is used when you want to dismount the current LiveView and mount a new one. This means that the new LiveView will have its own `mount/3` and `render/1` functions invoked, and the current layout will be kept.
- `push_patch` is used when you want to update the current LiveView without re-mounting it. This means that only the `handle_params/3` function will be invoked, and the minimal set of changes will be sent to the client.
- You should use `push_navigate` when you want to switch between different LiveViews in the same session, and use `push_patch` when you want to change the URL and parameters of the current LiveView (for example, if you want to change the sorting of a table).

To learn more
  - [Improve UX with LiveView page transitions](https://alembic.com.au/blog/improve-ux-with-liveview-page-transitions)
  - [Live navigation](https://hexdocs.pm/phoenix_live_view/live-navigation.html)
  
```
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

```

- The function uses the `consume_uploaded_entries/4` function from the [`Phoenix.LiveView.Upload`]() module to process the uploaded files that were allowed by the `allow_upload/4` function in the `mount/3` function. The `consume_uploaded_entries/4` function takes four arguments: the socket, the name of the upload, a function to handle each uploaded entry, and an optional list of options.
- We create a `dest` variable that holds the destination path for the uploaded file. The destination path is composed of the `priv/static/uploads` directory of the application, and the basename of the uploaded file path. The `priv/static/uploads` directory must exist for the `File.cp!/2` function to work, and it should be included in the `FinstaWeb.static_paths/0` function to be served as static assets.
- Then we copy the uploaded file from its original path to the destination path using the `File.cp!/2` function from the Elixir File module. This function raises an exception if it fails to copy the file.
- Finally returns a tuple of `{:postpone, url}` where url is a string that represents the relative path of the uploaded file in the uploads directory. This indicates that the uploaded file should be postponed until it is explicitly consumed by calling `allow_upload/4` again with :auto_upload option set to true.


## Display the Post on the Front End
At this point we can create a Post, but we don't see anything on the front end.

### Loading Data from the Database using LiveView Streams.
We are going to load the post from the database using liveview streams, but only when the user is connected.

We need to update the `mount/3` function


```
  @impl true 
  def mount(_params, _session, socket) do
    if connected?(socket) do
      ...
        |> assign(form: form, loading: false)
      ... 
      {:ok, socket}
    else
      {:ok, assign(socket, loading: true)}
    end
  end
```

To communicate if we are connected `loading: false` or not `loading: true` we modifies the state of the LiveView socket by adding a key-value pair to the assigns map. The assigns map is a data structure that stores data that can be accessed in the `render/1` function or in the template if any.

So now we add a new render function before the existing one, so we handle the case the user is not connected.

```
 @impl true
  def render(%{loading: true}=assigns) do
    ~H"""
      Finsta is loading ...
    """
  end
```

Now we can update the original render function.

```
@impl true
  def render(assigns) do
    ~H"""
      ...
      <.button type="button" phx-click={show_modal("new-post-modal")}>Create Post</.button>

      <div id="feed" phx-udpate="stream" class="flex flex-col gap-2">
        <div :for={{dom_id, post} <- @streams.posts} id={dom_id} class="w-1/2 mx-auto flex flex-col gap-2 p-4 border rounded">
          <img src={post.image_path}/>
          <p><%=post.user.email%></p>
          <p><%=post.caption%></p>
        </div>
      </div>

      <.modal id="new-post-modal">
       ...     
       </.modal>
    """
  end
```

We creates a <div> element with the id of `feed` and the attribute of `phx-update="stream"`. This attribute tells LiveView to use the streaming update mode, which means that new elements will be appended to the existing ones without re-rendering the whole container.

It uses a <div> element with the `:for` attribute to loop over the `@streams.posts` assign, which is a list of tuples containing a `dom_id` and a `post` struct. The `dom_id` is a unique identifier for each `post` element, and the post struct contains the data of the post, such as the image path, the user email, and the caption.

Then create a nested <div> element for each post with the id of `{dom_id}` and some classes for styling. The classes are from Tailwind CSS, which is a utility-first CSS framework that allows you to create responsive designs using predefined classes.

It creates an <img> element with the src attribute set to `{post.image_path}`, which displays the image of the post.
It creates two <p> elements with the text of `{post.user.email}` and `{post.caption}`, which display the email of the user who posted the image and the caption of the image.

### Update the mount/3 function
Now we need to update our mount/3 funtion to load the data from the actual database we will use the LiveView `stream/3` function.
The `stream/3` function is a LiveView helper that allows you to stream data from a source to the client and render it as HTML elements. 
The function takes three arguments: socket, name, and source. The socket argument is the current state of the LiveView socket that needs to be updated. 
The name argument is an atom that identifies the stream. The source argument is an enumerable that provides the data to be streamed.


```
  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      ...

      socket=
        ...
        |> stream(:posts, Posts.posts())  
      ...
    else
      ...
    end
  end

```

In our case the source is the Database and we do a query in the Posts context, `lib/finsta/posts.ex`
Finally we need to add the function `posts/0` to the Posts context module to get the list of posts.

```
  def posts() do
    query =
       from p in Post,
       select: p,
       order_by: [desc: :inserted_at],
       preload: [:user]

    Repo.all(query)
  end

```

## Broadcast New Posts and Notify a user when somebody posts.
Now we are going to add the ability to broadcast new post to all users in the system and also notify
the user when someone add a post.

```
  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to the posts topic when connected
      Phoenix.PubSub.subscribe(Finsta.PubSub, "posts")
      ...
    else
      ...
    end
  end
```
Here we subscribte to the posts topic when connected using the `Phoenix.PubSub` module,
so we will be notified when someone adds a post to the system.



```
  @impl true
  def handle_event("save-post", %{"post" => post_params}, socket) do
    ...

    post_params
     ...
     |> case do
       {:ok, post} ->
          socket =
            socket
            |> put_flash(:info, "Post created successfully!")
            |> push_navigate(to: ~p"/home")

          # Broadcast a message when we create a post
          Phoenix.PubSub.broadcast(Finsta.PubSub, "posts", {:new, Map.put(post, :user, user)})

          {:noreply, socket}

       {:error, _changeset} ->
         ...
     end
  end
```

Here we sends a message to all the processes that are subscribed to the `posts` topic using the `Phoenix.PubSub` module. 
The `{:new, Map.put(post, :user, user)}` argument is the message itself, which is a tuple containing an atom and a map.
we need to add it, because the user association won't be loaded when it comes back from the database, so then we can
display the email from this broadcast user

To handle this message we just need to implement the `handle_info` callback

```
 @impl true
  def handle_info({:new, post}, socket) do
    socket =
      socket
      |> put_flash(:info, "#{post.user.email} just posted!")
      |> stream_insert(:posts, post, at: 0)

    {:noreply, socket}
  end
```

## Improve Finsta Web 
Some possible steps to improve the Phoenix LiveView projects are:

- Add pagination or infinite scrolling to the feed of posts, so that the user can see more posts without loading them all at once. This can be done by using the Phoenix.LiveView.Helpers.live_paginate/2 function or the Phoenix.LiveView.InfiniteScroll module. See [this tutorial](https://blog.appsignal.com/2022/01/11/build-interactive-phoenix-liveview-uis-with-components.html) or [this article](https://www.youtube.com/watch?v=1YzAztAMgP4.) for more details.
- Add comments and likes to the posts, so that the user can interact with other users and express their opinions. This can be done by creating new schemas and contexts for comments and likes, and adding LiveComponents and events to handle them. See [this article](https://github.com/beam-community/awesome-phoenix-liveview) or [this article](https://blog.logrocket.com/write-reusable-components-phoenix-liveview/) for more examples.nents-phoenix-liveview/.
