Uploader = require "../main"

policy = JSON.parse(localStorage.FSPolicy)
uploader = Uploader policy

global.Q = require "q"

describe "uploader", ->
  it "should upload some junk to S3", (done) ->
    uploader.upload(
      key: "test.wat"
      blob: new Blob ["wat wat wat???"], type: "text/plain"
    ).then (url) ->
      assert.equal url, "https://s3.amazonaws.com/trinket/18894/test.wat"
      done()
    , (error) ->
      console.log error
    , (progress) ->
      console.log progress
    .done()

  it "should be able to get files", (done) ->
    uploader.get "test.wat"
    .then (blob) ->
      console.log blob
      done()
    , (error) ->
      console.log error
    , (progress) ->
      console.log progress
    .done()
