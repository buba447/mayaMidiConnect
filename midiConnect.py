import maya.cmds as cmds
import maya.mel
import json

md_controlGroup = {}
md_controlMap = {}
returnLogs = True

def md_start():
	print("MD Scripts Started")

def updateControlGroup(groupJSON):
	global md_controlGroup
	global md_controlMap
	md_controlGroup = json.loads(groupJSON)
	newArray = md_controlGroup['controls']

	for control in newArray:
		channel = control['channel']
		md_controlMap[channel] = control
	return ("Updated map for" + md_controlGroup['name'])

def md_update(channel, value):
	dial = dialForChannel(channel)
	if dial == None:
		if returnLogs:
			return "No dial found"
		return
	dial['value'] = value
	if dialForChannel(dial['parentChannel']) != None:
		dial = dialForChannel(dial['parentChannel'])
	if dial['childChannel'] != None:
		if returnLogs:
			return md_updateLogDial(dial)
		md_updateLogDial(dial)
	else:
		if returnLogs:
			return md_updateDefaultDial(dial)
		md_updateDefaultDial(dial)

def dialForChannel(channel):
	global md_controlMap
	if channel in md_controlMap:
		return md_controlMap[channel]
	else:
		return None

def md_updateLogDial(dial):
	childDial = dialForChannel(dial['childChannel'])
	if childDial == None:
		return "No Child Dial Found"
	childValue = childDial['value'] 
	parentValue = dial['value']

	bottomValue = remap(parentValue, 0, 127, 0.0, 1.0)
	attributes = childDial['attributes']
	interval = float(1.0 - bottomValue) / len(attributes)
	bottomValue = 1.0
	for attribute in attributes:
		oMin = attribute['outMinValue']
		oMax = attribute['outMaxValue']
		iMin = attribute['inMinValue']
		iMax = attribute['inMaxValue']
		outSpread = (oMax - oMin) * 0.5
		modifiedSpread = outSpread * bottomValue
		midPoint = oMin + outSpread
		oMin = midPoint - modifiedSpread
		oMax = midPoint + modifiedSpread
		bottomValue = bottomValue - interval
		newValue = remap(childValue, iMin, iMax, oMin, oMax)
		if attribute['mayaCommand'] != None:
			md_evalDialButtonAttribute(attribute, newValue)
			continue
		mayaNode = attribute['mayaNode']
		mayaAttr = attribute['mayaAttribute']
		cmds.setAttr((mayaNode + "." + mayaAttr), newValue )
	return ("Updated child dial " + str(dial['childChannel']))


def md_updateDefaultDial(dial):
	if dial == None:
		return "No Dial Found"
	value = dial['value']
	attributes = dial['attributes']
	for attribute in attributes:
		newValue = newValueFromAttribute(attribute, value)
		if attribute['mayaCommand'] != None:
			md_evalDialButtonAttribute(attribute, newValue)
			continue
		mayaNode = attribute['mayaNode']
		mayaAttr = attribute['mayaAttribute']
		cmds.setAttr((mayaNode + "." + mayaAttr), newValue )
	return ("Updated " + str(len(attributes)) + " attributes")

def md_evalDialButtonAttribute(attribute, value):
	fromValue = attribute['outMinValue']
	toValue = attribute['outMaxValue']
	mCommand = attribute['mayaCommand']
	if fromValue == None or toValue == None:
		maya.mel.eval(mCommand)
		return ("Executed:" + mCommand)
	if value >= fromValue and value <= toValue:
		#execute button command while in range
		mCommand = attribute['mayaCommand']
		valuedCommand = mCommand.replace("$v", value)
		maya.mel.eval(valuedCommand)
		return ("Executed:" + valuedCommand)
	return ("Failed Executing" + mCommand)

def newValueFromAttribute(attribute, value):
	oMin = attribute['outMinValue']
	oMax = attribute['outMaxValue']
	iMin = attribute['inMinValue']
	iMax = attribute['inMaxValue']
	return remap(value, iMin, iMax, oMin, oMax)

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


