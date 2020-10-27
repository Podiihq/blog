%{
  author: "Sigu Magwa",
  title: "Elixir endpoint for USSD",
  description: "Creating a simple elixir server for USSD applications",
  tags: [
      "elixir",
      "ussd",
      "africastalking",
      "offline",
  ]
}
---



Sometimes you want to quickly setup a server in elixir to serve as a microservice. In this case we are going to spin up
an elixir server to serve and respond to USSD requests from our client


## Objective of the blog
This blog aims to teach you how to setup an elixir server (without any framework, infact we have only one library installed for this) that you can use to
create a USSD endpoint
## Initialize a new supervised elixir app
```elixir
mix new sample_ussd --sup
```
This will create a new supervised elixir application called sample_ussd. I wish I could start explaining supervision right now but I will skip just to make this blog shorter 😃

## Install a web server
Since we are going to be receiving http requests and responding to the requests
we need to install a web server on our application. The webserver I will use which also
happens to be the most used in elixir world is [cowboy](https://github.com/ninenines/cowboy)
```elixir
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"}
    ]
  end
```

We then install this via `mix deps.get`

### Configure the server
We can start up the server when our application is started. To do this we add a configuration
under `lib/ussd_sample/application.ex`. Add the following content

```elixir
defmodule UssdSample.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: UssdSample.Router, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: UssdSample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Our routes is usually considered as a plug so in our configuration above you will
realise that we point to our route as the plug to be used. The port is also set here, you can
change it to a number of your liking.

Should I explain what a plug is at this point? 🤔. Yes I guess I should because its an amazing concept that if we understand then routing in elixir will be simpler (hopefully)

## Lets talk plug
First off, I will assume you have a basic understanding of a http request and how much information is contained in a single request. How can we represent
all these information in a friendly elixir way?
Secondly, data in elixir is immutable so we cannot change the data. What if we wanted to add more information to our request? Let's pause for a moment and re-read these
questions, if you still confused let me know so I can try restructure the questions.

Anyway, the concept of plug was introduced to help manipulate http information. All the information contained in http request is packaged into what is known as a `conn` I guess
the core team shortened to word `connection`. Conn contains all the information, we can then pass this conn into several stages so as to add information to it or extract relevant information. Think of a plug as a stage that either add information to the `conn` or extracts some information from the `conn`

After manipulating the conn, the plug then passes the manipulated conn to the next stage.

The exact definition of a plug is
> A function that takes in a conn and returns a conn


### Create the router file
Our router will be where we define the route of our application. For now let's always respond with `hello world`
for whatever the route we visit. Create the file `lib/router.ex`, note that the name doesnt have to be `router.ex`

```elixir
defmodule UssdSample.Router do
  use Plug.Router
  plug(:match)

  plug(:dispatch)

  match _ do
    send_resp(conn, 200, "hello world")
  end
end

```
The router file has a couple of plugs too. Each plug takes in our request, transforms it then passes it to the next plug


To read more on [Plug.Router](https://hexdocs.pm/plug/Plug.Router.html#content), you will find more examples on how to write routes and how to handle errors

> I personally don't like how much magic there exists in the router file but I guess it is a necessary devil we have to live with to make our routes more readable

### Start your server
If you remember well, we told our application to start our server whenever we run the application. To run the application
```elixir
iex -S mix
```
Lets go over and visit [localhost:4000](http://localhost:4000)


## Relating to africastalking
Our application will sit in as the last receiver of a user request. When the user makes a request via ussd, it goes to africastalking. Africastalking
will then package this request and send it to us as a normal http request with the body of the request being what the user has responded with.

Have a look at [this docs by africastalking](https://build.at-labs.io/docs/ussd%2Foverview) to understand more on the request

![request flow from client to africastalking to our application](images/elixir-ussd/at-ussd.png)


### Create our endpoint
On our router we can add that endpoint that africastalking will be sending their requests to.

The requests come in as POST requests so on our router;
1. change the `match __` to return `404` and make sure it is the last function. This is so that if any of our routes are not matched it will return a 404 response
2. add the `/ussd` route with the contents below

```elixir
defmodule UssdSample.Router do
  use Plug.Router
  plug(:match)

  plug(:dispatch)

  post "/ussd" do
    {:ok, body, conn} = read_body(conn)
    send_resp(conn, 200, "I got #{body} from Africastalking")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end

```

### Setup from africastalking end
1. Go to https://account.africastalking.com/ and create an account
1. Go to sandbox app
1. Under USSD go to service codes and create a channel, dont worry about callback url we will input it in the next step

![ussd dashboard on africastalking](/images/elixir-ussd/at-dashboard.png)

### Enter ngrok and simulator
We can allow our application to be accessible via the internet using a tunneling software. We can have a look at ngrok in this case.


1. [ Install ngrok ](https://ngrok.com/download) then start it up by `ngrok http 4000`
1. copy the link generated by ngrok (the link is under the section written `Forwarding`, check on the output below in this case it is `https://ed5b1db8.ngrok.io`)
1. paste this link on your ussd application on AT dashboard as a callback URL. Refer to the diagram above ☝️ its written `ngrok`

```shell
ngrok by @inconshreveable                                                   (Ctrl+C to quit)

Session Status                online
Account                       Sigu Magwa (Plan: Free)
Version                       2.3.35
Region                        United States (us)
Web Interface                 http://127.0.0.1:4040
Forwarding                    http://ed5b1db8.ngrok.io -> http://localhost:4000
Forwarding                    https://ed5b1db8.ngrok.io -> http://localhost:4000

Connections                   ttl     opn     rt1     rt5     p50     p90
                              0       0       0.00    0.00    0.00    0.00
```

There is a simulator we can use to test our ussd code, launch the simulator from the AT dashboard (that is the second last menu item on the sandbox dashboard). The USSD code was generated for us when we registered the channel a few steps ago and it looks more like this

![simulator and ussd channel](/images/elixir-ussd/launch-simulator.png)

On the simulator we use our USSD code and make the first request.


AT sends us the data as url encoded data that looks like this.
```shell
"phoneNumber=%2B254712345679&serviceCode=%2A384%2A28682%23&text=&sessionId=ATUid_7f9d288441e2b060e249651230cb5c9a&networkCode=99999"
```


We will need to add a parser that can convert this into an elixir map. Remember what plugs are? They take in a `conn` and returns a modified `conn`. That looks like what we need at this point. Luckily, `plug` comes with a parser to do just this.

On our routes before call the dispatch plug, lets add the body parser plug which converts the URL encoded response into an elixir map and adds it to the conn as `body_params` . Lets inspect the `body_params`
```elixir
defmodule UssdSample.Router do
  use Plug.Router
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:urlencoded],
    pass: ["*/*"]
  )

  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Welcome Human!!")
  end

  post "/ussd" do
    IO.inspect(conn.body_params, label: "Body Params: ")
    send_resp(conn, 200, "CON I got #{inspect(conn.body_params)} from Africastalking")
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
```
When we make another ussd request this is what is printed out on the the terminal
```elixir
Body Params: : %{
  "networkCode" => "99999",
  "phoneNumber" => "+254712345677",
  "serviceCode" => "*384*28682#",
  "sessionId" => "ATUid_3b5bcc28808f8197af196d45ab6106d7",
  "text" => ""
}
```

On our simulator the map is also returned

![simulator first response](/images/elixir-ussd/simulator-response-one.png)



## Asking for user input
Lets now start asking the user for an input and respond depending on how they answer our questions
In this case we will assume our user always inputs the correct response so we dont handle any wrong answers. I will do another blog on
how to handle errors on USSD sessions

Lets hav a look at the final implementation then break it down bit by bit
```elixir
defmodule UssdSample.USSD do
  @moduledoc """
  Processes and responds to the USSD requests.
  """

  def process_body(%{"text" => "", "sessionId" => session_id}) do
    "CON Welcome to Podii.\nEnter your first name"
  end

  def process_body(%{"text" => text, "sessionId" => session_id}) do
    text |> String.split("*") |> IO.inspect() |> process_text()
  end

  def process_text([name]) do
    "CON Jambo #{name}, what year were you born?"
  end

  def process_text([name, dob]) do
    "CON Great! Where do you live at the moment?"
  end

  def process_text([name, dob, location]) do
    "END Thank you so much #{name}\nYou will receive SMS confirmation of your registration shortly"
  end
end
```

### First request
Our first request always has the text as an empty string so we can pattern match this and send back a response asking the user for their name.
If we expect a response from a user we respond with a string that has the word `CON` prepended to it. Our function will therefore look like this

```elixir
  def process_body(%{"text" => "", "sessionId" => session_id}) do
    "CON Welcome to Podii.\nEnter your first name"
  end
```

### When user responds
When the user responds with their name, this will be the first response from them so it will be a single string, any subsequent responses are separated by `*`

Let me explain this further:
When a user responds for the first time, the input will look like this
```elixir
"first"
```

When we ask a question and they respond again, here is how our text will look like
```elixir
"first*1970"
```
Meaning that the user first entered `first` then they entered `1970`. This is done for all the inputs the user gives until the end of the session

We can deal with such a string by [splitting](https://hexdocs.pm/elixir/String.html#split/3) it at the `*` so it produces a list of each response. We use this list to pattern match and create appropriate responses
to the user

```elixir

  def process_body(%{"text" => text, "sessionId" => session_id}) do
    text |> String.split("*") |> process_text()
  end

  def process_text([name]) do
    "CON Jambo #{name}, what year were you born?"
  end

  def process_text([name, dob]) do
    "CON Great! Where do you live at the moment?"
  end
```

### Final response
When we get to the final step, we will no longer need input from the user. Our string is now prepended by `END` to end the current session
```elixir
  def process_text([name, dob, location]) do
    "END Thank you so much #{name}\nYou will receive SMS confirmation of your registration shortly"
  end
```
![ending our session](/images/elixir-ussd/session-end.jpg)



## We are moving away from medium blog.
Check out our other blogs on [medium](https://medium.com/podiihq)
