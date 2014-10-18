Uploader = require "../main"

describe "uploader", ->
  it "should upload some junk to S3", (done) ->
    policy = JSON.parse(localStorage.FSPolicy)
    uploader = Uploader policy

    uploader.upload(
      key: "test.wat"
      blob: new Blob ["hello"]
    ).then (url) ->
      assert.equal url, "https://s3.amazonaws.com/trinket/18894/test.wat"
      done()
    , (error) ->
      console.log error
    , (progress) ->
      console.log progress
    .done()
