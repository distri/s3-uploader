S3
====

Upload data directly to S3 from the client.

Usage
-----

>     uploader = S3.uploader(JSON.parse(localStorage.S3Policy))
>     uploader.upload
>       key: "myfile.text"
>       blob: new Blob ["radical"]
>       cacheControl: 60 # default 31536000

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

      upload: ({key, blob, cacheControl}) ->
        bucketUrl = "https://s3.amazonaws.com/#{bucket}"
        namespacedKey = "#{namespace}#{key}"
        url = "#{bucketUrl}/#{namespacedKey}"

        sendForm bucketUrl, objectToForm
          key: namespacedKey
          "Content-Type": blob.type
          "Cache-Control": "max-age=#{cacheControl or 31536000}"
          AWSAccessKeyId: accessKey
          acl: acl
          policy: policy
          signature: signature
          file: blob
        .then ->
          url

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

    # TODO: Figure out how to get this to work
    sendForm = (url, formData) ->
      deferred = Q.defer()

      request = new XMLHttpRequest()

      request.open("POST", url, true)
      request.send(formData)

      request.onreadystatechange = (e) ->
        if request.readyState is 4
          if isSuccess(request)
            deferred.resolve(true)
          else
            deferred.reject request.responseText

      return deferred.promise

    objectToForm = (data) ->
      formData = Object.keys(data).reduce (formData, key) ->
        formData.append(key, data[key])

        return formData
      , new FormData

