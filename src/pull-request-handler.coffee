Q = require 'q'
request = require 'request'

class PullRequestHandler

  baseUrl: 'https://api.github.com/repos/'
  request: request
  setTimeout: setTimeout

  constructor: ({@username, @repoName, @requestingUsername}) ->
    @deferred = Q.defer()

  sendBadgePullRequest: ->

    @makeFork =>
      @waitForFork =>
        @getReadme (content, sha) =>
          @updateReadme content, sha, =>
            @createPullRequest =>
              @deferred.resolve()

    @deferred.promise

  makeFork: (fn) ->

    @request.post
      uri: "#{@baseUrl}#{@username}/#{@repoName}/forks"
      qs:
        access_token: process.env.APPLICATION_PUBLIC_REPO_ACCESS_TOKEN
      headers: @_getHeaders()
    , (err, response, body) =>
      return @deferred.reject new Error('Repo already forked') if err or response.statusCode >= 400
      fn()

  waitForFork: (fn, timesCalled = 0) ->

    return @deferred.reject(new Error('Timed out waiting for fork')) if timesCalled is 10

    timesCalled++
    @request.get
      uri: "#{@baseUrl}waffleio/#{@repoName}/readme"
      qs:
        access_token: process.env.APPLICATION_ACCESS_TOKEN
      headers: @_getHeaders()
    , (err, response, body) =>
      if err or (response.statusCode >= 400 and response.statusCode isnt 404)
        @deferred.reject new Error('Errored while checking if fork was created')
      else if response.statusCode is 404
        checkAgain = => @waitForFork fn, timesCalled
        @setTimeout checkAgain, 1000
      else
        fn()

  getReadme: (fn) ->

    @request.get
      uri: "#{@baseUrl}waffleio/#{@repoName}/contents/README.md"
      qs:
        access_token: process.env.APPLICATION_ACCESS_TOKEN
      headers: @_getHeaders()
    , (err, response, body) =>
      return @deferred.reject new Error('Unable to get readme') if err or response.statusCode >= 400

      parsedBody = JSON.parse(body)

      base64Content = parsedBody.content || ''
      originalContent = new Buffer(base64Content, 'base64').toString()

      fn originalContent, parsedBody.sha

  updateReadme: (content, sha, fn) ->

    badgeContent = "[![Stories in Ready](https://badge.waffle.io/#{@username}/#{@repoName}.png?label=ready)](https://waffle.io/#{@username}/#{@repoName})\n"

    newContent = new Buffer(badgeContent + content).toString('base64')

    body = JSON.stringify
      message: 'add waffle.io badge'
      content: newContent
      sha: sha

    @request.put
      uri: "#{@baseUrl}waffleio/#{@repoName}/contents/README.md"
      qs:
        access_token: process.env.APPLICATION_PUBLIC_REPO_ACCESS_TOKEN
      body: body
      headers: @_getHeaders()
    , (err, response, body) =>
      return @deferred.reject new Error('Unable to update readme') if err or response.statusCode >= 400
      fn()

  createPullRequest: (fn) ->

    body = JSON.stringify
      title: "waffle.io Badge"
      body: """
          Merge this to receive a badge indicating the number of issues in the ready column on your waffle.io board at https://waffle.io/#{@username}/#{@repoName}

          This was requested by a real person (user #{@requestingUsername}) on waffle.io, we're not trying to spam you.
          """
      head: "waffleio:master"
      base: "master"

    @request.post
      uri: "#{@baseUrl}#{@username}/#{@repoName}/pulls"
      body: body
      qs:
        access_token: process.env.APPLICATION_PUBLIC_REPO_ACCESS_TOKEN
      headers: @_getHeaders()
    , (err, response, body) =>
      return @deferred.reject new Error('Unable to create pull request') if err or response.statusCode >= 400
      fn()

  _getHeaders: ->
    'User-Agent': 'waffle.io'

module.exports = PullRequestHandler
