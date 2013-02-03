class SessionManager

  GitHubService = require("./github-service")

  constructor: (@session) ->
    console.log "new SessionManager()"
    @sharedRedisManager = null

  isAuthed: ->
    authed = @session and @session.oauth? and @session.oauth.token? and @session.oauth.userInfo?
    console.log "isAuthed = #{authed}"
    authed

  getAccessTokenAndUserInfo: (code, callback) =>
    console.log "getAccessTokenAndUserInfo code=#{code}"

    GitHubService::getAccessToken(code, (err, token) =>
      console.log "did getAccessToken"

      if err?
        callback(err)
        return

      GitHubService::getUserInfo(token, (err, userInfo) =>
        console.log "did getUserInfo"

        if err?
          callback(err)
          return

        # set session
        @session.oauth = {
          token: token,
          userInfo: userInfo
        }

        # save userId & userName & token for future use (e.g. crawling)
        # (this should be separated from sess:* key)
        @sharedRedisManager.setUserInfoForId(userInfo.id, userInfo.login, token, (err) ->
          callback(err)
        )

      )

    )

  clearAuth: ->
    @session.destroy()

  userInfo: ->
    if @isAuthed()
      return @session.oauth.userInfo
    else
      return null

module.exports = SessionManager