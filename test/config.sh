#!/bin/bash
set -e

testAlias+=(
	[digibyted:trusty]='digibyted'
)

imageTests+=(
	[digibyted]='
		rpcpassword
	'
)
