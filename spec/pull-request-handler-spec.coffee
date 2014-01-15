PullRequestHandler = require '../src/pull-request-handler'

describe 'PullRequestHandler', ->

  beforeEach ->
    @username = 'testuser'
    @repoName = 'testrepo'
    @requestingUsername = 'ralphy'
    @handler = new PullRequestHandler
      username: @username
      repoName: @repoName
      requestingUsername: @requestingUsername

    @res =
      statusCode: 200

  describe 'sendBadgePullRequest', ->

    beforeEach ->
      @stub(@handler, 'makeFork').yields()
      @stub(@handler, 'waitForFork').yields()
      @stub(@handler, 'getReadme').yields()
      @stub(@handler, 'updateReadme').yields()
      @stub(@handler, 'createPullRequest').yields()

    it 'returns a promise when called', ->
      promise = @handler.sendBadgePullRequest()
      promise.should.be.a 'object'

    it 'calls success handler when finished', (done) ->
      @handler.sendBadgePullRequest().then ->
        done()

    it 'calls failure handler if an error occurs', (done) ->
      @handler.makeFork.restore()
      @stub @handler, 'makeFork', =>
        @handler.deferred.reject new Error('forcing failure')

      @handler.sendBadgePullRequest().fail (error) ->
        error.message.should.equal 'forcing failure'
        done()

  describe 'makeFork', ->
    beforeEach ->
      @stub(@handler.request, 'post').yields(null, @res)

    it 'should send a request', (done) ->

      @handler.makeFork =>
        @handler.request.post.callCount.should.equal 1
        @handler.request.post.getCall(0).args[0].uri.should.equal "https://api.github.com/repos/#{@username}/#{@repoName}/forks"
        @handler.request.post.getCall(0).args[0].qs.should.have.keys 'access_token'
        done()

    it 'should call the given callback', ->
      fn = @stub()
      @handler.makeFork fn
      fn.callCount.should.equal 1

    it 'should reject the deferred if the request fails', (done) ->
      fn = @stub()
      @handler.request.post.restore()
      @stub(@handler.request, 'post').yields(null, {statusCode: 404})
      @handler.makeFork fn

      fn.callCount.should.equal 0

      @handler.deferred.promise.fail ->
        done()
      .done()

  describe 'waitForFork', ->
    beforeEach ->
      @stub(@handler, 'setTimeout').yields()

    it 'should call callback if fork found', (done) ->
      @stub(@handler.request, 'get').yields(null, @res)
      @handler.waitForFork =>
        @handler.request.get.callCount.should.equal 1
        @handler.setTimeout.callCount.should.equal 0
        done()

    it 'should try again, after a delay', (done) ->
      @stub @handler.request, 'get', (options, fn) =>
        if @handler.request.get.callCount < 5
          fn null, {statusCode: 404}
        else
          fn null, @res

      @handler.waitForFork =>
        @handler.request.get.callCount.should.equal 5
        @handler.setTimeout.callCount.should.equal 4
        done()

    it 'should timeout after 10 tries', (done) ->
      fn = @stub()
      @stub(@handler.request, 'get').yields(null, {statusCode: 404})
      @handler.waitForFork fn

      @handler.deferred.promise.fail =>
        fn.callCount.should.equal 0
        @handler.request.get.callCount.should.equal 10
        @handler.setTimeout.callCount.should.equal 10
        done()
      .done()


    it 'should fail if we dont get the expected "not found" for the fork', (done) ->
      fn = @stub()
      @stub(@handler.request, 'get').yields(null, {statusCode: 422})
      @handler.waitForFork fn

      @handler.deferred.promise.fail =>
        fn.callCount.should.equal 0
        @handler.request.get.callCount.should.equal 1
        @handler.setTimeout.callCount.should.equal 0
        done()
      .done()

  describe 'getReadme', ->

    it 'should decode the readme and return the content and sha', (done) ->
      @stub(@handler.request, 'get').yields null, @res, JSON.stringify require('./fixtures/readme')

      @handler.getReadme (content, sha) =>
        content.should.equal 'test'
        sha.should.equal '5ee878578b97dbeccbc6eca518cd78adf3c0464e'
        done()


    it 'should fail cleanly when encountering an unexpected response', (done) ->
      fn = @stub()
      @stub(@handler.request, 'get').yields(null, {statusCode: 422})

      @handler.getReadme fn

      @handler.deferred.promise.fail =>
        fn.callCount.should.equal 0
        @handler.request.get.callCount.should.equal 1
        done()
      .done()

  describe 'updateReadme', ->

    it 'should attach the badge text to the readme content and base64 encode it', (done) ->
      @stub(@handler.request, 'put').yields(null, @res)

      @handler.updateReadme 'test', 'sha', =>
        body = JSON.parse @handler.request.put.getCall(0).args[0].body
        content = "[![Stories in Ready](https://badge.waffle.io/#{@username}/#{@repoName}.png?label=ready)](https://waffle.io/#{@username}/#{@repoName})\ntest"
        body.should.eql
          message: 'add waffle.io badge'
          content: new Buffer(content).toString('base64')
          sha: 'sha'

        done()

    it 'should fail cleanly when encountering an unexpected response', (done) ->
      fn = @stub()
      @stub(@handler.request, 'put').yields(null, {statusCode: 422})

      @handler.updateReadme 'test', 'sha', fn

      @handler.deferred.promise.fail =>
        fn.callCount.should.equal 0
        @handler.request.put.callCount.should.equal 1
        done()
      .done()

  describe 'createPullRequest', ->

    it 'should include the requestor in the message', (done) ->
      @stub(@handler.request, 'post').yields(null, @res)

      @handler.createPullRequest =>
        body = JSON.parse @handler.request.post.getCall(0).args[0].body
        body.body.should.contain 'ralphy'
        done()

    it 'should create a PR from waffle master to the requested master', (done) ->
      @stub(@handler.request, 'post').yields(null, @res)

      @handler.createPullRequest =>
        body = JSON.parse @handler.request.post.getCall(0).args[0].body
        body.head.should.equal 'waffleio:master'
        body.base.should.equal 'master'
        done()

    it 'should fail cleanly when encountering an unexpected response', (done) ->
      fn = @stub()
      @stub(@handler.request, 'post').yields(null, {statusCode: 422})

      @handler.createPullRequest fn

      @handler.deferred.promise.fail =>
        fn.callCount.should.equal 0
        @handler.request.post.callCount.should.equal 1
        done()
      .done()
