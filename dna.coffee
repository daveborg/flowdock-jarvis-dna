# Description:
#   Collates DNA tagged notes in the current flow. Sales process helper.
#
# Dependencies:
#   "flowdock": ""
#	"q": "~1.0.0",
#   "nodemailer": "^1.1.1"
#
# Configuration:
#   None
#
# Commands:
#   hubot dna opportunityTag
#
# Author:
#   Dave Borgeest dborgeest@rallydev.com
q = require 'q'
flowdock = require 'flowdock'
util = require 'util'
child_process = require 'child_process'
mailer = require('nodemailer').createTransport
  host: process.env.HUBOT_SMTP_HOST || 'localhost'
  port: process.env.HUBOT_SMTP_PORT || 25
  connectionTimeout: 1000

token = process.env.HUBOT_FLOWDOCK_API_TOKEN

module.exports = (robot) ->
	flowdock_session = new flowdock.Session(token)
	encodedApiKey = "Basic " + new Buffer(token).toString('base64')
	tta = []
	cpp = []
	qbo = []
	cgo = []
	cpa = []

	robot.hear /dna (.+)/i, (res) ->
		opp = res.match[1]
		msg_data = res.message.user
		allFlows = robot.adapter.flows
		
		for thisFlow in allFlows when thisFlow.id is msg_data.flow
			flowEmail = thisFlow.email
			flowApiBase = thisFlow.url
		
		fullApiUrl = "#{thisFlow.url}/messages?tags=#{opp}"
		
		data = robot.http(fullApiUrl)
			.headers('Authorization': encodedApiKey, 'Accept', 'application/json')
			.get() (err, resp, body) ->
				data = JSON.parse(body)
				
				if (data.length == 0)
					res.send "Sorry, we don't know anything about this opportunity \'#{opp}\' \nLet's go ask!"
				else
					for thisMessage in data
						currentNote = thisMessage.content.replace("\##{opp}", "")
						currentNote = currentNote.replace("\##{opp}".toLowerCase(), "")
						
						#=======================================================
						# Sort the messages according to DNA
						if ("tta" in thisMessage.tags)
							tta.push utility.stripTags(currentNote)
						if ("cpp" in thisMessage.tags)
							cpp.push utility.stripTags(currentNote)
						if ("qbo" in thisMessage.tags)
							qbo.push utility.stripTags(currentNote)
						if ("cgo" in thisMessage.tags)
							cgo.push utility.stripTags(currentNote)
						if ("cpa" in thisMessage.tags)
							cpa.push utility.stripTags(currentNote)
					
					returnHTML = "<html><head><style>body {font-family: Verdana, Helvetica, Arial, sans-serif}.msgDiv {font-size: 11px; margin-bottom:10px;}th {font-size: 14px; margin-bottom:6px; background-color: \#eeeeee}td {vertical-align: top; padding: 2px}\#oppHeader {font-size: 20px; background-color: #cccccc; padding: 4px}</style></head><body>"
					
					returnHTML = "#{returnHTML}<div id=\"oppHeader\">#{opp}</div>\n"
					
					returnHTML = "#{returnHTML}<table><tr><th width=\"20%\">TTA</th><th width=\"20%\">CPP</th><th width=\"20%\">QBO</th><th width=\"20%\">CGO</th><th width=\"20%\">CPA</th></tr>"
					returnHTML = "#{returnHTML}<tr>"
					
					returnHTML = "#{returnHTML}<td>"
					for thisMsg in tta
						returnHTML = "#{returnHTML}<div class=\"msgDiv\">#{thisMsg}</div>"
					returnHTML = "#{returnHTML}</td>"
					
					returnHTML = "#{returnHTML}<td>"
					for thisMsg in cpp
						returnHTML = "#{returnHTML}<div class=\"msgDiv\">#{thisMsg}</div>"
					returnHTML = "#{returnHTML}</td>"
					
					returnHTML = "#{returnHTML}<td>"
					for thisMsg in qbo
						returnHTML = "#{returnHTML}<div class=\"msgDiv\">#{thisMsg}</div>"
					returnHTML = "#{returnHTML}</td>"
					
					returnHTML = "#{returnHTML}<td>"
					for thisMsg in cgo
						returnHTML = "#{returnHTML}<div class=\"msgDiv\">#{thisMsg}</div>"
					returnHTML = "#{returnHTML}</td>"
					
					returnHTML = "#{returnHTML}<td>"
					for thisMsg in cpa
						returnHTML = "#{returnHTML}<div class=\"msgDiv\">#{thisMsg}</div>"
					returnHTML = "#{returnHTML}</td>"
					
					returnHTML = "#{returnHTML}</tr></table></body></html>"
					
					#==============
					#Send the Email
					utility.sendEmail "DNA: #{opp}", flowEmail, returnHTML
					

utility =
	sendEmail: (subject, emailTo, htmlBody) ->
		deferred = q.defer()
		options =
			to: emailTo
			from: 'jarvis-flowdock@rallydev.com'
			subject: subject
			html: htmlBody
		mailer.sendMail options, (error, info) ->
			if error
				deferred.reject(new Error(error))
			else
				console.log info
		deferred.promise
	
	stripTags: (str) ->
		str.replace(/(\#TTA|\#CPP|\#QBO|\#CGO|\#CPA)/i, '').replace(/^\s+/g, '')
