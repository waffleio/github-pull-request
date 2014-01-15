sinon = require 'sinon'
chai = require 'chai'

before ->
  # give the test object stub() and spy() functions from sinon
  @[key] = value for key, value of sinon.sandbox.create()
  chai.should()

afterEach ->
  @restore()
