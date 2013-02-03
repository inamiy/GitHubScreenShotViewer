class RedisKey

  # hash
  userInfoForId: (userId) ->
    "user:#{userId}:info"

  # stringified
  starredReposForUserId: (userId) ->
    "user:#{userId}:repos"

class RedisManager

  redis = require('redis')

  constructor: (@redisId) ->
    console.log "new RedisManager(#{@redisId})"

  openRedis : (callback) ->
    client = redis.createClient()
    client.select(@redisId, (err, res) ->
      callback(client)
    )

  starredReposForUserId : (userId, callback) ->
    @openRedis((client) ->
      client.get(RedisKey::starredReposForUserId(userId), (err, res) ->
        repos = JSON.parse(res)
        callback(err, repos)

        client.quit()
      )
    )

  setStarredReposForUserId: (userId, repos, callback) ->
    @openRedis((client) ->
      reposStr = JSON.stringify(repos)
      client.set(RedisKey::starredReposForUserId(userId), reposStr, (err, res) =>
        callback(err, res)

        client.quit()
      )
    )

  userInfoForId: (userId, callback) ->
    console.log("userInfoForId = " + userId);

    @openRedis((client) =>
      client.hgetall(RedisKey::userInfoForId(userId), (err, userInfo) =>
        if err?
          callback(err, null, null)
        else
          callback(null, userInfo.access_token, userInfo.userName)

        client.quit()
      )
    )

  setUserInfoForId: (userId, userName, token, callback) ->
    console.log "setUserInfoForId = #{userId} userName = #{userName} token = #{token}"

    @openRedis((client) =>
      client.hmset(RedisKey::userInfoForId(userId), "token", token, "userName", userName, (err) ->
        callback(err)

        client.quit()
      )
    )

module.exports = RedisManager