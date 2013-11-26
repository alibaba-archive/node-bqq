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

company = {}

fetch = (cmd, query, callback) ->
  source = request("https://#{path.join bqq.url, cmd}?#{qs.stringify query}")
  data = ""
  source.on 'data', (chunk) -> data += chunk
  source.on 'end', ->
    try
      data = JSON.parse(data)
    catch e
      return callback e
    callback null, data

push = (cmd, query, callback) ->
  dest = request
    method: 'POST'
    url: "https://#{path.join bqq.url, cmd}"
    json: query,
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
  app_id: key
  client_ip: ip
  oauth_version: 2

bqq.authURL = -> "https://" + bqq.url + "/oauth2/authorize?" + qs.stringify
    response_type: 'code'
    app_id: bqq.key
    redirect_uri: bqq.handler.user
    state: 1

bqq.codeHandler = (actor) -> (req, res, next) ->
  {query} = url.parse req.url, true
  fetch 'oauth2/token',
    grant_type: "authorization_code"
    app_id: bqq.key
    app_secret: bqq.secret
    code: query.code
    state: query.state
    redirect_uri: bqq.handler[actor],
    (err, data) ->
      return res.end(err) if err
      if actor == 'user' then res.setHeader('Set-Cookie',qs.stringify(data))
      else company[data.open_id] = data
      req.access = data
      next()

bqq.companyInfo = (company_id, cb) ->
  fetch 'api/corporation/get', baseParams(company_id), cb

bqq.memberList = (company_id, cb) ->
  query = baseParams(company_id)
  query.timestamp = 0
  fetch 'api/user/list', query, cb

bqq.tips = (company_id, title, content, cb) ->
  query = baseParams(company_id)
  query.to_all = 1
  query.window_title = bqq.appName
  query.tips_title = title
  query.tips_content = content
  push 'api/tips/send', query, cb

bqq.broadcast = (company_id, title, content) ->
  query = baseParams(company_id)
  query.title = title
  query.content = content
  query.is_online = 1
  query.recv_dept_ids = company_id
  push 'api/broadcast/send', query, cb
