Uploader = require "../main"

policy = JSON.parse(localStorage.CCASPolicy)
uploader = Uploader policy

global.Q = require "q"

describe "uploader", ->
  it "should upload some junk to S3", (done) ->
    uploader.upload(
      key: "test.wat"
      blob: new Blob ["wat wat wat???"], type: "text/plain"
    ).then (url) ->
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
