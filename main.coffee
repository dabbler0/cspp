#!/usr/bin/env coffee

fs = require 'fs'
interpreter = require './interpreter.coffee'

program = fs.readFileSync(process.argv[2]).toString()
parseTree = interpreter.parse program
interpreter.interpret parseTree
