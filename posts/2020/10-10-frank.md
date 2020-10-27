%{
  author: "Frank Midigo",
  title: "Notifications on live view",
  description: "Showing notification messages in Phoenix LiveView ",
  tags: [
      "elixir",
      "ussd",
      "africastalking",
      "offline",
  ]
}
---



Showing notification messages in Phoenix LiveView
=================================================


After handling some event in live view, you might want to show a notification message to the client to give them an update that something has happened. The quickest way to do this is to simply `put_flash` and `redirect` but doing a `redirect` might not be an option especially if it is a multi-step process because you might lose state.

**Solution 1: Using Hooks**

[Hooks](https://hexdocs.pm/phoenix_live_view/js-interop.html) provide a means of reacting to some event from the server or client. For our case, we would like the browser to react by showing notifications when something happens in the server.

[**live\_view v1.40**](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#push_event/3) comes with a `push_event/3` function that we can use to push an event to the client side. We can utilize this to push a notification event and receive that event using `Hooks` .

```
def handle\_event("something happened", params, socket) do{:noreply, push\_event(socket, "notify", %{type: "success", message: "done successfully"})}end
```

Then in our `app.js` let’s define a Hook to receive the notification event. Once we receive the event, we can now target the preferred element to hold the message in the DOM.

```javascript
let Hooks = {};Hooks.Notify = {
mounted(){
_this_.handleEvent("notify", (_payload_) =>{
if(payload.type == "success"){
document.getElementById("notify-success").innerHTML = _payload_.message
else{
document.getElementById("notify-error").innerHTML = _payload_.message
}
})
}}
```

We can reuse the the `flash`s’ containing elements to display our notifications. Let’s add the `phx-hook` attribute to our target elements so that they can be patched with the new contents

```
<main _role_\="main" _class_\="container"><p _class_\="alert alert-info" _role_\="alert" _phx-click_\="lv:clear-flash" _phx-value-key_\="info" _id_\="notify-success" _phx-hook_\="Notify"><%= live\_flash(@flash, :info) %></p><p _class_\="alert alert-danger" _role_\="alert" _phx-click_\="lv:clear-flash" _phx-value-key_\="error" id="notifiy-error" phx-hook="Notify><%= live\_flash(@flash, :error) %></p><%= @inner\_content %></main>
```

Voila !! That’s it

**Solution 2: Using assigns**

Assigns refers to a `map` holding all the data that is needed in the templates. Because `assigns` are specific to each individual socket, we need to find a way to work with it without breaking our code.

Let’s borrow some code from the implementation of `flash` messages, we can define them as helper functions for working with the notifications.

```elixir
def put_notification(socket, type, msg) do
socket
|> assign(:notification, %{type: type, msg: msg}
enddef live_notification(socket, type) do
socket.assigns
|> Map.get(:notification, %{})
|> notification_by_type(type)
enddefp notification_by_type(%{msg: msg, type: type}, type), do: msgdefp notification\_by\_type(\_, \_), do: nil
```

The `live_notification/2` function is designed in such a way that if the notification is not available in the assigns, it returns `nil` instead of raising. This makes it handy for general usage.

Now let’s handle some event that will trigger the notifications.

```
def handle\_event("something happened", params, socket) do{:noreply, put\_notification(socket, :info, "something happened")}end
```

We now go ahead and add the markups for displaying the notifications in our `live.html.leex` file.

```
<main _role_\="main" _class_\="container"><p _class_\="alert alert-info" _role_\="alert" _phx-click_\="lv:clear-flash" _phx-value-key_\="info" ><%= live\_flash(@flash, :info) %></p><p _class_\="alert alert-danger" _role_\="alert" _phx-click_\="lv:clear-flash" _phx-value-key_\="error"><%= live\_flash(@flash, :error) %></p><p _class_\="alert alert-info" _role_\="alert" ><%= live\_notification(@socket, :info) %></p><p _class_\="alert alert-danger" _role_\="alert" ><%= live\_notification(@socket, :error) %></p><%= @inner\_content %></main>
```
