github-pull-request
===================

waffle.io's way of sending automagical pull requests for our badges. Please don't use this to send spam pull requests, no one likes that!

For more details, read the [accompaning blog post](https://waffle.io/blog/2014/01/15/automagical-pull-requests/).

### Getting started
`npm install`

This project isn't consumable as is (as an npm module, for example). It's also very specific to [waffle.io](waffle.io), this constructs a Pull Request to embed the waffle badge into someone's readme.

### Environment dependencies

This code assumes there are two environment varibles set:

`APPLICATION_PUBLIC_REPO_ACCESS_TOKEN`: this is a GitHub access token that has permissions to interact with the waffle.io public repo. These permissions are required to create a fork of someone's repo.

`APPLICATION_ACCESS_TOKEN`: this is a GitHub access token with no permissions. It's used to make requests to public repos to fetch their readme file. You can reuse `APPLICATION_PUBLIC_REPO_ACCESS_TOKEN`, although it's more permissions than you need for this action.

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

The `RouteHelpers.checkAuthForPullRequest` middleware checks if waffle's logged in user is a collaborator of the project we're sending a pull request for, to protect our users from pull request spam.

### Running tests
`grunt` to compile coffeescript

`grunt test` to run tests
