github-pull-request
===================

waffle.io's way of sending automagical pull requests for our badges. Please don't use this to send spam pull requests, no one likes that!

For more details, read the [accompaning blog post](https://waffle.io/blog/2014/01/15/automagical-pull-requests/).

### Getting started
`npm install`

This project isn't consumable as is (as an npm module, for example). It's also very specific to [waffle.io](waffle.io), this constructs a Pull Request to embed the waffle badge into someone's readme.

### Example

You would use this like so:

```coffeescript
app.get '/:username/:repoName/pull', RouteHelpers.checkAuthForPullRequest, (req, res) ->
  pullRequestHandler = new PullRequestHandler
    username: req.params.username
    repoName: req.params.repoName
    requestingUsername: req.session.username
 
  pullRequestHandler.sendBadgePullRequest()
    .then =>
      res.json
        success: true
    .fail (error) =>
      res.json
        success: false
 
    .done()
```

### Running tests

`grunt test`
