if File.exists?("test_db") do
  File.rmdir!("test_db")
end

defmodule TestStructs do
  alias Nostrum.Struct.User
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.Guild.Role
  alias Nostrum.Struct.Message

  def user do
    %User{
      avatar: "XXXXXXXXXXXXXX",
      bot: false,
      discriminator: "XXXX",
      email: nil,
      id: 1234567736329846798,
      mfa_enabled: nil,
      username: "XXXXX",
      verified: nil
    }
  end

  def member do
    %Member{
      deaf: false,
      joined_at: "2019-05-20T16:16:12.363574+00:00",
      mute: false,
      nick: nil,
      roles: [],
      user: user()
    }
  end

  def role do
    %Role{
      color: 0,
      hoist: true,
      id: 234264626636234,
      managed: false,
      mentionable: true,
      name: "XXXXXXXXXX",
      permissions: 6432632,
      position: 232642364
    }
  end

  def message do
    %Message{
      activity: nil,
      application: nil,
      attachments: [],
      author: role(),
      channel_id: 123,
      content: "<MUST SET IN TESTS>",
      edited_timestamp: nil,
      embeds: [],
      guild_id: 12345,
      id: 1234512612,
      member: member(),
      mention_everyone: false,
      mention_roles: [],
      mentions: [],
      nonce: 582318674208096256,
      pinned: false,
      reactions: nil,
      timestamp: "2019-05-26T21:26:30.958000+00:00",
      tts: false,
      type: 0,
      webhook_id: nil
    }
  end
end

ExUnit.start()
