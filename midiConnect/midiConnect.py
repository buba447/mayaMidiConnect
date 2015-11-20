import maya.cmds as cmds
import maya.mel
import json

md_controlGroup = {}
md_controlMap = {}

def md_start():
	print("MD Scripts test")

def updateControlGroup(groupJSON):
	global md_controlGroup
	global md_controlMap
	md_controlGroup = json.loads(groupJSON)
	newArray = md_controlGroup['controls']
	print ("Switching to " + md_controlGroup['name'] + " group")
	#Mapping all controls to a dictionary where KEY is the channel of the control
	for control in newArray:
		channel = control['channel']
		md_controlMap[channel] = control

def md_update(channel, value):
	dial = dialForChannel(channel)
	if dial == None:
		return
	md_updateDefaultDial(dial, value)
	# if dial['logDial'] == 1:
	# 	# Log Dial, Update
	# 	md_updateLogDial(dial, value)
	# else:
	# 	# Normal Dial, Update
		
	# attributes = dial['attributes']
	# for attribute in attributes:

def dialForChannel(channel):
	global md_controlMap
	if channel in md_controlMap:
		return md_controlMap[channel]
	else:
		return None

def md_updateDefaultDial(dial, value):
	attributes = dial['attributes']
	for attribute in attributes:
		if "mayaCommand" in dial:
			md_evalDialButtonAttribute(attribute, value)
			continue
		mayaNode = attribute['mayaNode']
		mayaAttr = attribute['mayaAttribute']
		newValue = newValueFromAttribute(attribute, value)
		cmds.setAttr((mayaNode + "." + mayaAttr), newValue )

def md_evalDialButtonAttribute(attribute, value):
	newValue = newValueFromAttribute(attribute, value)
	fromValue = attribute['outMinValue']
	toValue = attribute['outMaxValue']
	if value >= fromValue and value <= toValue:
		#execute button command while in range
		mCommand = attribute['mayaCommand']
		valuedCommand = str.replace("$v", newValue)
		maya.mel.eval(valuedCommand)

def newValueFromAttribute(attribute, value):
	oMin = attribute['outMinValue']
	oMax = attribute['outMaxValue']
	iMin = attribute['inMinValue']
	iMax = attribute['inMaxValue']
	return remap(value, oMin, oMax, iMin, iMax)

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
    oldMin = min( oMin, oMax )
    oldMax = max( oMin, oMax )
    if not oldMin == oMin:
        reverseInput = True

    #check reversed output range
    reverseOutput = False   
    newMin = min( nMin, nMax )
    newMax = max( nMin, nMax )
    if not newMin == nMin :
        reverseOutput = True

    portion = (x-oldMin)*(newMax-newMin)/(oldMax-oldMin)
    if reverseInput:
        portion = (oldMax-x)*(newMax-newMin)/(oldMax-oldMin)

    result = portion + newMin
    if reverseOutput:
        result = newMax - portion

    return result


