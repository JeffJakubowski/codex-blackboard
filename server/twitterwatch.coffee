# Watch twitter and announce new tweets to general/0 chat.
#_
# The account login details are given in settings.json, like so:
# {
#   "twitter": {
#     "consumer_key": "xxxxxxxxx",
#     "consumer_secret": "yyyyyyyyyyyy",
#     "access_token_key": "zzzzzzzzzzzzzzzzzzzzzz",
#     "access_token_secret": "wwwwwwwwwwwwwwwwwwwwww"
#   }
# }
settings = Meteor.settings?.twitter ? {}

return unless settings.consumer_key and settings.consumer_secret
return unless settings.access_token_key and settings.access_token_secret
twit = new Twitter
  consumer_key: settings.consumer_key
  consumer_secret: settings.consumer_secret
  access_token_key: settings.access_token_key
  access_token_secret: settings.access_token_secret

hashtag = '#mysteryhunt'
twit.stream 'statuses/filter', {track: hashtag}, (stream) ->
  console.log "Listening to #{hashtag} on twitter"
  stream.on 'data', (data) ->
    return if data.retweeted_status? # don't report retweets
    unless data.user? # weird bug we saw
      console.log 'WEIRD TWIT!', data
      return
    console.log "Twitter! @#{data.user.screen_name} #{data.text}"
        #linkify hashtags
    text = data.text.replace /(^|\s)\#(\w+)\b/g, \
      '$1<a href="https://twitter.com/search?q=%23$2" target="_blank">#$2</a>'
    #linkify URLs
    text = data.text.replace /(^|\s)(http?:\/\/[\da-z\.-]+\.[a-z\.]{2,6}[\/\w\.-]*)/g, \
      '$1<a href="$2" target="_blank">$2</a>'
    #linkify usernames
    text = data.text.replace  /(^|\s)@([A-Za-z0-9_]{1,15})(?![.A-Za-z])/g, \
      '$1<a href="https://twitter.com/$2" target="_blank">@$2</a>'
    Meteor.call 'newMessage',
      nick: 'via twitter'
      action: 'true'
      body: "<a href='https://twitter.com/#{data.user.screen_name}'>@#{data.user.screen_name}</a> <a href='https://twitter.com/#{data.user.screen_name}/status/#{data.id_str}' target='_blank'>says:</a> #{text}"
      bodyIsHtml: true
