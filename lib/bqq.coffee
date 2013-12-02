qs = require 'querystring'
url = require 'url'
path = require 'path'
request = require 'request'

module.exports = bqq =
  appName: 'Teambition'
  url: 'openapi.b.qq.com'
  key: 'appkey'
  secret: 'appsecret'
  ip: '127.0.0.1'
  handler:
    user: 'usercallback'
    company: 'companycallback'


fetch = (method, cmd, query, callback) ->
  request
    method: method
    url: "https://#{path.join bqq.url, cmd}?#{qs.stringify query}",
    (err, res, body) ->
      try
        data = JSON.parse(body)
      catch e
        return callback e
      callback null, data

baseParams = ->
  access_token: @access_token
  company_id: @company_id
  app_id: bqq.key
  client_ip: bqq.ip
  oauth_version: 2

bqq.authURL = -> "https://" + bqq.url + "/oauth2/authorize?" + qs.stringify
    response_type: 'code'
    app_id: bqq.key
    redirect_uri: bqq.handler.user
    state: 1

bqq.codeHandler = (actor) -> (req, res, next) ->
  {query} = url.parse req.url, true
  bqq.getToken actor, query.code, query.state, (err, data) ->
    return res.end(err) if err
    data = data.data
    if actor == 'user' then res.setHeader('Set-Cookie',qs.stringify(data))
    req.access = data
    next()

bqq.getToken = (actor, code, state, cb) ->
  fetch 'GET', 'oauth2/token',
    grant_type: "authorization_code"
    app_id: bqq.key
    app_secret: bqq.secret
    code: code
    state: state
    redirect_uri: bqq.handler[actor],
    cb


bqq.companyInfo = (cb) ->
  fetch 'GET', 'api/corporation/get', baseParams(), cb

bqq.memberList = (cb) ->
  query = baseParams()
  query.timestamp = 0
  fetch 'GET', 'api/user/list', query, cb

bqq.face = (open_id, cb) ->
  query = baseParams()
  query.open_ids = open_id
  query.type_id = 5
  fetch 'GET', 'api/user/face', query, cb

bqq.email = (open_id, cb) ->
  query = baseParams()
  query.open_ids = open_id
  fetch 'GET', 'api/user/email', query, cb

bqq.qq = (open_id, cb) ->
  query = baseParams()
  query.open_ids = open_id
  fetch 'GET', 'api/user/qq', query, cb

bqq.tips = (params, receivers, cb) ->
  query = baseParams()
  if receivers instanceof Function
    query.to_all = 1
    cb = receivers
  else
    query.to_all = 0
    query.receivers = receivers
  query.window_title = bqq.appName
  query.tips_title = params.title
  query.tips_content = params.content
  if params.url then query.tips_url = params.url
  fetch 'POST', 'api/tips/send', query, cb

bqq.verifyhashskey = (options, cb) ->
  params = baseParams()
  params.open_id = options.open_id
  params.hashskey = options.hashskey
  fetch 'GET', 'api/login/verifyhashskey', params, cb

