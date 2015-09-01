S3 Uploader
===========

Upload data directly to S3 from the client.

Usage
-----

>     uploader = S3.uploader(JSON.parse(localStorage.S3Policy))
>     uploader.upload
>       key: "myfile.text"
>       blob: new Blob ["radical"]
>       cacheControl: 60 # default 0


The uploader automatically prefixes the key with the namespace specified in the
policy.

A promise is returned that is fulfilled with the url of the uploaded resource.

>     .then (url) -> # "https://s3.amazonaws.com/trinket/18894/myfile.txt"

The promise is rejected with an error if the upload fails.

A progress event is fired with the percentage of the upload that has completed.

The policy is a JSON object with the following keys:

- `accessKey`
- `policy`
- `signature`

Since these are all needed to create and sign the policy we keep them all
together.

Giving this object to the uploader method creates an uploader capable of
asynchronously uploading files to the bucket specified in the policy.

Notes
-----

The policy must specify a `Cache-Control` header because we always try to set it.

Implementation
--------------

    Q = require "q"

    module.exports = (credentials) ->
      {policy, signature, accessKey} = credentials
      {acl, bucket, namespace} = extractPolicyData(policy)

      bucketUrl = "https://s3.amazonaws.com/#{bucket}"

      urlFor = (key) ->
        namespacedKey = "#{namespace}#{key}"

        "#{bucketUrl}/#{namespacedKey}"

      upload: ({key, blob, cacheControl}) ->
        namespacedKey = "#{namespace}#{key}"
        url = urlFor(key)

        sendForm bucketUrl, objectToForm
          key: namespacedKey
          "Content-Type": blob.type
          "Cache-Control": "max-age=#{cacheControl or 0}"
          AWSAccessKeyId: accessKey
          acl: acl
          policy: policy
          signature: signature
          file: blob
        .then ->
          url

      get: (key) ->
        url = urlFor(key) + "?origin=#{document.domain}"

        deferred = Q.defer()

        request = new XMLHttpRequest
        request.open "GET", url, true
        request.responseType = "arraybuffer"

        request.onprogress = deferred.notify

        request.onreadystatechange = ->
          if request.readyState is 4
            if isSuccess(request)
              blob = new Blob [request.response],
                type: request.getResponseHeader('content-type')

              deferred.resolve blob
            else
              deferred.reject "#{request.status} - #{request.statusText}"

        request.send()

        return deferred.promise

Helpers
-------

    getKey = (conditions, key) ->
      results = conditions.filter (condition) ->
        typeof condition is "object"
      .map (object) ->
        object[key]
      .filter (value) ->
        value

      results[0]

    getNamespaceFromPolicyConditions = (conditions) ->
      (conditions.filter ([a, b, c]) ->
        a is "starts-with" and b is "$key"
      )[0][2]

    extractPolicyData = (policy) ->
      policyObject = JSON.parse(atob(policy))

      conditions = policyObject.conditions

      acl: getKey(conditions, "acl")
      bucket: getKey(conditions, "bucket")
      namespace: getNamespaceFromPolicyConditions(conditions)

    isSuccess = (request) ->
      request.status.toString()[0] is "2"

    sendForm = (url, formData) ->
      deferred = Q.defer()

      request = new XMLHttpRequest()

      request.open("POST", url, true)

      request.upload.onprogress = deferred.notify

      request.onreadystatechange = (e) ->
        if request.readyState is 4
          if isSuccess(request)
            deferred.resolve(true)
          else
            deferred.reject request.responseText

      request.send(formData)

      return deferred.promise

    objectToForm = (data) ->
      formData = Object.keys(data).reduce (formData, key) ->
        formData.append(key, data[key])

        return formData
      , new FormData
