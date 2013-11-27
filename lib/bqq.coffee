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

bqq.company company = {}

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

baseParams = (company_id) ->
  return unless company[company_id]
  access_token: company[company_id].access_token
  company_id: company_id
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
  fetch 'GET', 'oauth2/token',
    grant_type: "authorization_code"
    app_id: bqq.key
    app_secret: bqq.secret
    code: query.code
    state: query.state
    redirect_uri: bqq.handler[actor],
    (err, data) ->
      return res.end(err) if err
      data = data.data
      if actor == 'user' then res.setHeader('Set-Cookie',qs.stringify(data))
      else company[data.open_id] = data
      req.access = data
      next()


bqq.companyInfo = (company_id, cb) ->
  fetch 'GET', 'api/corporation/get', baseParams(company_id), cb

bqq.memberList = (company_id, cb) ->
  query = baseParams(company_id)
  query.timestamp = 0
  fetch 'GET', 'api/user/list', query, cb

bqq.tips = (company_id, params, receivers, cb) ->
  query = baseParams(company_id)
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
  fetch, 'POST', 'api/tips/send', query, cb
