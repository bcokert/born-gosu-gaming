defmodule Command.Butler do
  require Logger

  @type reply :: {:reply, {String.t(), [integer]}}
  @type noreply :: {:noreply}

  def make_reply(str, bytes \\ [])

  @spec make_reply(String.t(), []) :: noreply
  def make_reply("", []) do
    {:noreply}
  end

  @spec make_reply(String.t(), [integer]) :: reply
  def make_reply(str, bytes) do
    {:reply, {str, bytes}}
  end

  def talk(str, discord_msg) do
    cond do
      str =~ "you sexy beast" ->
        [
          "Thank you #{discord_msg.author}!",
          "Good heavens #{discord_msg.author}, what a compliment",
          "No doubt half as sexy as you, #{discord_msg.author}",
        ]
          |> Enum.random()
          |> make_reply()
      str =~ "hello" ->
        [
          "Good day #{discord_msg.author}",
          "How are you this fine day #{discord_msg.author}",
          "#{discord_msg.author}! What a pleasant surprise.",
        ]
          |> Enum.random()
          |> make_reply()
      str =~ "tell me a joke" ->
        [
          "There are 10 kinds of people in this world. Those who understand binary, and 9 who don't.\nI can't remember why I laughed at this.",
          "What's my favourite thing about Switzerland?\nWell the flag is a big plus.",
          "My dog ate all my scrabble tiles, and ever since he's been leaving me little messages around the house.",
          "As a child I asked my father for money when I aced my math tests. I tried to go for the pre-pay angle, but he wouldn't cosine.",
          "I find it hard to explain puns to kleptomaniacs because they always take things literally.",
          "My father surived the mustard gas of the war and the pepper spray of the nam riots. I guess he's a seasoned veteran now.",
          "Russian dolls are quite full of themselves.",
          "It takes a lot of balls to golf like me.",
          "Where can you find a cow with no legs? Right where you left it.",
          "I have a terminal disease wherein I can't stop telling airport jokes.",
          "Two clowns are eating a cannibal. One turns to the other and says \"I think we got this joke wrong\".",
          "I have an EpiPen. My friend gave it to me when he was dying, it seemed very important to him that I have it.",
          "I always figured children who fell in wells couldn't see that well.",
          "Communism jokes aren't funny unless everyone gets them.",
          "I've been told I can be condescending. That means I talk down to people.",
          "What's the difference between a dirty old bus stop and a lobster with breast implants? One is a crusty bus station, the other one is a busty crustacean.",
          "Did you know that in the Canary Islands there are no Canaries? Same with the Virgin Islands, there are no canaries there either.",
        ]
          |> Enum.random()
          |> make_reply()
      str =~ "i need some inspiration" ->
        with {:ok, {_, _, img_url}} <- :httpc.request('https://inspirobot.me/api?generate=true') do
          [
            "Hope this helps #{img_url}",
            "Here you go #{img_url}",
            "Be inspired! #{img_url}",
            "This is a good one #{img_url}",
            "I've been saving this one #{img_url}",
          ]
            |> Enum.random()
            |> make_reply()
        else
          e ->
            Logger.info("Failed to grab a url from inspirobot: #{e}")
            [
              "Oops, something went wrong",
              "Unfortunately I can't help right now",
              "Would you take a rain check?",
            ]
              |> Enum.random()
              |> make_reply()
        end
      true ->
        ""
        |> make_reply()
    end
  end
end
