simple sdk for business qq
=========

useage

```javascript
var BQQ = require('bqq');
BQQ.init({
  name: 'your app name',
  key: 'app key',
  secret: 'secret key',
  ip: 'you server ip'
  start: 'http[s]://yourhost/callback/when/startUsingBQQ'
})

BQQ.getToken(codeFormBQQ, state, function(err, data){
  if(err) return;
  token = data.data.access_token;
  refreshToken = data.data.refresh_token;
});

var bqq = new BQQ({
  token: 'company_access_token'
  refreshToken: 'refresh_token'
  companyId: 'company_id'
});

bqq.memberList(function(err, data){
  //..
});
```
