'use strict';

const express = require('express');
const request = require('request');
const util = require('util')

var PORT = process.env.PORT || 8080;
var HOST = process.env.HOST || '0.0.0.0';
var VERSION = process.env.VERSION || 'v1';
var SERVICE_NAME = process.env.SERVICE_NAME || 'Unknown';
var NAME_URL = process.env.NAME_URL || 'Unknown';
var PHONE_URL = process.env.PHONE_URL || 'Unknown';

var bodyParser = require('body-parser');

var app = express();
var router = express.Router();

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));



router.get("/", function(req, res) {
  res.status(200).send("Welcome to hello world service. I am running on version = "+VERSION);
});

router.get("/hello", function (req, res) {
  console.log('Request Headers = ' + getJaegerHeaders(req));
  var data = {
    'version': VERSION,
    'service_name': SERVICE_NAME,
    'name': '',
    'phone': ''
  };

  var pname = external(req, res, NAME_URL); 
  var pphone = external(req, res, PHONE_URL); 
  Promise.all([pname, pphone]).then(values => { 
      data.name = values[0];
      data.phone = values[1];
      console.log('Name service response ='+util.inspect(values[0], {showHidden: false, depth: null}));
      console.log('Phone service response ='+util.inspect(values[1], {showHidden: false, depth: null}));
      res.status(200).send(data);  
    }, 
    reason => {
      res.status(500).send(reason);
  }); 

});

function external(ireq, ires, url){
    if(url != 'Unknown') {
      return new Promise(function(resolve, reject){
          request({ url: url, headers: getJaegerHeaders(ireq) }, function (error, response, body) {
              if (error) return reject(error);
              try {
                  resolve(JSON.parse(body));
              } catch(e) {
                  reject(e);
              }
          });
      });
    }
}

function getJaegerHeaders(req) {
  var headers = { 
      'x-request-id': req.header('x-request-id'),
      'x-b3-traceid': req.header('x-b3-traceid'),
      'x-b3-spanid': req.header('x-b3-spanid'),
      'x-b3-parentspanid': req.header('x-b3-parentspanid'),
      'x-b3-sampled': req.header('x-b3-sampled'),
      'x-b3-flags': req.header('x-b3-flags'),
      'x-ot-span-context': req.header('x-ot-span-context')
  }
  return headers;
}

app.use('/', router);

console.log('HOST='+HOST);
console.log('PORT='+PORT);
console.log('SERVICE_NAME='+SERVICE_NAME);
console.log('VERSION='+VERSION);
console.log('NAME_URL='+NAME_URL);
console.log('PHONE_URL='+PHONE_URL);

app.listen(PORT, HOST);
