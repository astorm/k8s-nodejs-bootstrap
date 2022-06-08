'use strict';

const express = require('express');
const fs = require('fs')
const path = require('path')

function search(directory, result=[]) {
  const files = fs.readdirSync(directory)
  for(const [,file] of files.entries()) {
    const absolute = path.join(directory, file);
    let type = 'file'
    if(fs.existsSync(absolute) && fs.statSync(absolute).isDirectory()) {
      type = 'dir'
    }
    result.push({
      file:file,
      type:type
    })
  }
  return result
}

function getFileListingOutput(request) {
  const files = []

  const currentPath = request.query.path ? request.query.path : '.'
  const fullPath = [__dirname,currentPath].join('/')
  search(fullPath, files)
  let up = `[<a href="?path=${currentPath}/..">dir</a> ] ..\n`
  if('/' === path.resolve(fullPath)) {
    up = ``
  }

  const filesHtml = [
    `PATH: ${path.resolve(fullPath)}\n\n`,
    `[<a href="?path=.">dir</a> ] .\n`,
    up
  ]
  for(const [,file] of files.entries()) {
    let maybeLink = file.type.padEnd(4,' ')
    if(file.type === 'dir') {
      maybeLink = `<a href="?path=${currentPath}/${file.file}">${maybeLink}</a>`
    }
    filesHtml.push(`[${maybeLink}] ${file.file}\n`)
  }
  return `<html><body>
  <pre>${filesHtml.join('')}</pre>
  </body></html>`
}

// Constants
const PORT = 8080;
const HOST = '0.0.0.0';

const fastify = require('fastify')({
  logger: true
})

// Declare a route
fastify.get('/', function (request, reply) {

  reply.header('Content-Type','text/html')
  // request.query.param
  reply.send(getFileListingOutput(request))
})

// Run the server!
fastify.listen(PORT, HOST, function (err, address) {
  if (err) {
    fastify.log.error(err)
    process.exit(1)
  }
  console.log(`Server is now listening! on ${address}`)
})
// // App
// const app = express();
// app.get('/', (req, res) => {
//   // res.send('Hello World');
//   res.send(getFileListingOutput(req))
// });

// app.listen(PORT, HOST);
// console.log(`Running on http://${HOST}:${PORT}`);
