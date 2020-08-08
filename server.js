const express = require("express")
const app = express()
const R = require('ramda')
const logger = require('morgan')
const log = console.log
const dotenv = require("dotenv")
app.use(logger())
app.use(express.json())
app.use(express.static('static'))
dotenv.config()
const PORT = process.env.ENV == "prod" ? 80 : 3000
const HOST = process.env.ENV == "prod" ? '0.0.0.0' : '127.0.0.1'


/*------------------------
  👇 JEXIA configuration
-------------------------*/

const jexiaSDK = require("jexia-sdk-js/node")
const dataModule = jexiaSDK.dataOperations()
const field = jexiaSDK.field
const credentials = {
    projectID: process.env.PROJECT_ID,
    key: process.env.API_KEY,
    secret: process.env.API_SECRET,
}
jexiaSDK.jexiaClient().init(credentials, dataModule)
// Users' dataset
const users = dataModule.dataset("users") 


/*------------------------
  👇 HANDLERS
-------------------------*/

// Simple error handler
const handleError = (err, res) => { 
  log(err); res.status(err.httpStatus.code).json({msg: `Error: ${err.httpStatus.status}`})
}

// Simple ok handler
const handleOk = (records, action, status, res) => {
  log(`${action} USER ok`); records === null 
                            ? res.sendStatus(status)
                            : res.status(status).json(records)
}


/*------------------------
  👇 API
-------------------------*/

// Seed the dataset
app.get('/api/seed', (req, res) => {
  let usersSeed = [
    { name: "Joseph K", verified: false },
    { name: "Blacksad", verified: false }
  ]

  let insertIfNone = selectedRecords => {
    (R.isEmpty(selectedRecords)) 
      ? users.insert(usersSeed).subscribe( r=>res.status(201).json(r), e=>handleError(e, res) )
      : res.sendStatus(204)
  }

  // Delete all users from the dataset
  users.delete().where(field("name").isNotNull()).subscribe( r=>log("USER DELETE ok"), e=> handleError(e, res) )

  // If no users in the dataset, create new users
  users.select().subscribe(insertIfNone, e=>handleError(e, res))
})

// Return all users
app.get('/api/users', (req, res) => {
    users
    .select()
    .fields(["id", "name", "verified"])
    .subscribe( r => handleOk(r, 'GET ALL', 200, res), e => handleError(e, res) )
})


// Create a new user
app.post('/api/users/create', (req, res) => {
  users
  .insert(req.body)
  .subscribe( r => handleOk(r[0], 'CREATE', 201, res), e => handleError(e, res) )
})

// Update a user
app.put('/api/users/:id/update', (req, res) => {
  users
  .update([{id: req.params.id, ...req.body}])
  .subscribe( r => handleOk(r[0], 'UPDATE', 200, res), e => handleError(e, res) )
})

// Delete a user by id
app.delete('/api/users/:id/delete', (req, res) => {
  users
  .delete()
  .where(field => field("id").isEqualTo(req.params.id))
  .subscribe( r => handleOk(r[0].id, 'DELETE', 200, res), e => handleError(e, res) )
})

// Verify a user by id
app.get('/api/users/:id/verify', (req, res) => {
  users
  .update([{id: req.params.id, verified: true}])
  .subscribe( r => handleOk(r[0].id, 'VERIFY', 200, res), e => handleError(e, res) )
})


/*------------------------
  👇 HTML file
-------------------------*/

app.get('*', (req, res) => res.sendFile('index.html'))


/*------------------------
  👇 SERVER
-------------------------*/
app.listen(PORT,HOST)
log(`App running on http://${HOST}:${PORT}`)