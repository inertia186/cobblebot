json.(message, :body, :recipient_term, :read_at, :created_at)

json.author_nick message.author.nick
json.recipient_nick message.recipient.nick
