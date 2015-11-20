import maya.cmds as cmds
import json

def updateControlGroup(groupJSON):
	global controlGroup = json.loads(sceneJSON)
	global controlMap = {}
	controlsArray = controlGroup['controls']
	for control in controlsArray:
		channel = control['channel']
		controlMap[channel] = control

def update(channel, value):
	dial = dialForChannel(channel)
	attributes = dial['attributes']
	# if dial['logDial'] == 0
	# for attribute in attributes:


def dialForChannel(channel):
	return controlMap[channel]