import maya.cmds as cmds
import maya.mel
import json
import math as math

md_controlGroup = {}
md_controlMap = {}
returnLogs = True

def md_start():
	print("Midi Scripts Started")

def updateControlGroup(groupJSON):
	global md_controlGroup
	global md_controlMap
	md_controlMap.clear()
	md_controlGroup = json.loads(groupJSON)
	newArray = md_controlGroup['controls']

	for control in newArray:
		control['value'] = None
		channel = control['channel']
		md_controlMap[channel] = control
	return ("Updated map for" + md_controlGroup['name'])

def md_update(channel, value):
	dial = dialForChannel(channel)
	if dial == None:
		if returnLogs:
			return "No dial found"
		return
	if dial['value'] == None:
		# this should only happen the first time the dial is moved in a session
		dial['previousValue'] = value
	else:
		dial['previousValue'] = dial['value']

	dial['value'] = value

	if returnLogs:
		return md_updateDefaultDial(dial)
	md_updateDefaultDial(dial)

def dialForChannel(channel):
	global md_controlMap
	if channel in md_controlMap:
		return md_controlMap[channel]
	else:
		return None

def md_unMuteDial(channel):
	dial = dialForChannel(channel)
	dial['value'] = None

def md_updateDefaultDial(dial):
	if dial == None:
		return "No Dial Found"
	value = dial['value']
	previousValue = dial['previousValue']
	attributes = dial['attributes']
	isRealtive = dial['isRelative']
	isAutoCatch = dial['isAutoCatch']
	for attribute in attributes:
		newValue = newValueFromAttribute(attribute, value)
		if attribute['mayaCommand'] != None:
			md_evalDialButtonAttribute(attribute, newValue)
			continue
		mayaNode = attribute['mayaNode']
		mayaAttr = attribute['mayaAttribute']
		attrString = (mayaNode + "." + mayaAttr)
		if isRealtive == 1:
			prevDialValue = dial['previousValue']
			previousValue = newValueFromAttribute(attribute, prevDialValue)
			diff = newValue - previousValue
			prevAttrValue = cmds.getAttr(attrString)
			newValue = prevAttrValue + diff
		if isAutoCatch == 1:
			inRange = attribute['inRange']
			outRange = attribute['outRange']
			# Get Current value of attribute to be set
			currentAttrValue = cmds.getAttr(attrString)
			# Get previous output value
			prevOutputAttr = remapRange(previousValue, inRange, outRange)
			# Convert current value into input value
			currentInputValue = remapRange(currentAttrValue, outRange, inRange)
			if abs(value - currentInputValue) > 20 and round(prevOutputAttr) != round(currentAttrValue):
				continue
		cmds.setAttr(attrString, newValue )
	return ("Updated " + str(len(attributes)) + " attributes")

def md_evalDialButtonAttribute(attribute, value):
	mCommand = attribute['mayaCommand']
	valuedCommand = mCommand.replace("$v", str(value))
	return maya.mel.eval(valuedCommand)

def newValueFromAttribute(attribute, value):
	inRange = attribute['inRange']
	outRange = attribute['outRange']
	if inRange == None or outRange == None:
		return value
	return remapRange(value, inRange, outRange)

def remapRange(x, inRange, outRange):
	rangeLen = len(inRange)
	if rangeLen < 2:
		return x

	idx = 0
	for i in xrange(0,rangeLen):
		iValue = inRange[i]
		if x <= iValue:
			idx = i - 1
			break
	if idx == (rangeLen - 1):
		idx = idx - 1

	inMin = inRange[idx]
	inMax = inRange[idx + 1]
	outMin = outRange[idx]
	outMax = outRange[idx + 1]
	return remap(x, inMin, inMax, outMin, outMax)

def remap( x, oMin, oMax, nMin, nMax ):
    #range check
    if oMin == oMax:
        print "Warning: Zero input range"
        return nMin

    if nMin == nMax:
        print "Warning: Zero output range"
        return nMin

    #check reversed input range
    reverseInput = False
    oldMin = float(min( oMin, oMax ))
    oldMax = float(max( oMin, oMax ))
    if not oldMin == oMin:
        reverseInput = True

    #check reversed output range
    reverseOutput = False   
    newMin = float(min( nMin, nMax ))
    newMax = float(max( nMin, nMax ))
    if not newMin == nMin :
        reverseOutput = True

    portion = (x-oldMin)*(newMax-newMin)/(oldMax-oldMin)
    if reverseInput:
        portion = (oldMax-x)*(newMax-newMin)/(oldMax-oldMin)

    result = portion + newMin
    if reverseOutput:
        result = newMax - portion

    return result
