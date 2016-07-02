import maya.cmds as cmds
import bw as bw
import json
import traceback

createPyWindow = 'midiPyWindow'
createInterpolatorWindow = 'midiInterpolatorWindow'
settingDrivenKeyWindow = 'midiSettingDrivenKeyWindow'
addingObjectsWindow = 'addingObjectsWindow'
removingObjectsWindow = 'removingObjectsWindow'
midiPyTextField = 'midiPyTextField'
midiIntCheckBox = 'midiIntCheckBox'
midiBaseName = 'midiNode_'

columnPadding = 20
innerItemPadding = 5
sectionSpacerPadding = 10

def md_start():
    md_buildMenu()
    #md_openCommandPort('4477')

def md_buildMenu():
	if cmds.menu('midiConnectRoot', exists=True):
	    cmds.deleteUI('midiConnectRoot')
	cmds.menu('midiConnectRoot', l="MidiConnect", p='MayaWindow', tearOff=True, allowOptionBoxes=True)
	cmds.menuItem('midiConnectCreateItem', l='Create Control',sm=True,p='midiConnectRoot')
	cmds.menuItem('midiConnectInterpolatorItem', l='Interpolator', ann='New Interpolation Driver', p='midiConnectCreateItem', c='import midiConnect as md; md.md_showCreateInterpolatorControl()')
	cmds.menuItem('midiConnectPythonItem', l='Python Command', ann='New Python Command', p='midiConnectCreateItem', c='import midiConnect as md; md.md_showCreatePyControl()')
	cmds.menuItem('midiConnectEditItem', l='Edit Control',sm=True,p='midiConnectRoot')
	cmds.menuItem('midiConnectSetDrivenKey', l='Set Driven Key', ann='Set Driven MIDI Key', p='midiConnectEditItem', c='import midiConnect as md; md.md_showAddDrivenKeyControl()')
	cmds.menuItem('midiConnectAddObjects', l='Add Objects', ann='Add selection and attributes to MIDI Channel', p='midiConnectEditItem', c='import midiConnect as md; md.md_showaddSelectedAttributesToNode()')
	cmds.menuItem('midiConnectRemoveObjects', l='Remove Objects', ann='Remove selection and attributes from MIDI Channel', p='midiConnectEditItem', c='import midiConnect as md; md.md_showRemoveSelectedAttributesToNode()')

def md_openCommandPort(port):
	name = "0.0.0.0:" + port
	cmds.commandPort(name=name, sourceType="python")

#TODO Remove window close buttons, hook into cancel button, and clean state
def md_showCreatePyControl():
	md_cleanupOpenWindows()
	cmds.window(createPyWindow, title="New Python Control" )
	cmds.columnLayout(co = ['both', columnPadding])
	cmds.separator( style='none', height=columnPadding )
	cmds.textField(midiPyTextField, width=400)
	cmds.separator( style='none', height=innerItemPadding )
	cmds.text(label='Enter Python command(s) and press MIDI control to set.\nTip: %S will be replaced with currently selected objects in command', width=400)
	cmds.separator( style='none', height=sectionSpacerPadding )
	cmds.button( label="Cancel", c='import midiConnect as md; md.md_cleanupOpenWindows()')
	cmds.separator( style='none', height=columnPadding )
	cmds.showWindow(createPyWindow)

def md_showCreateInterpolatorControl():
	md_cleanupOpenWindows()
	cmds.window(createInterpolatorWindow, title="New Interpolator Control" )
	cmds.columnLayout(co = ['both', columnPadding])
	cmds.separator( style='none', height=columnPadding )
	cmds.text(label='Select objects and attributes \nthen move desired MIDI control to set it.', align='left')
	cmds.separator( style='none', height=innerItemPadding )
	cmds.checkBox(midiIntCheckBox, label='Delete any existing connections from control' )
	cmds.separator(style='none', height=sectionSpacerPadding)
	cmds.button( label="Cancel", c='import midiConnect as md; md.md_cleanupOpenWindows()')
	cmds.separator( style='none', height=columnPadding )
	cmds.showWindow(createInterpolatorWindow)

def md_showAddDrivenKeyControl():
	md_cleanupOpenWindows()
	cmds.window(settingDrivenKeyWindow, title="Set Driven MIDI Key" )
	cmds.columnLayout(co = ['both', columnPadding])
	cmds.separator( style='none', height=columnPadding )
	cmds.text(label='Move MIDI Control To Set. \n Alternatively you can set from current selection and attributes', width=400)
	#TODO ^ Make this statementTrue
	cmds.separator( style='none', height=sectionSpacerPadding )
	cmds.button( label="Cancel", c='import midiConnect as md; md.md_cleanupOpenWindows()')
	cmds.separator( style='none', height=columnPadding )
	cmds.showWindow(settingDrivenKeyWindow)

def md_showaddSelectedAttributesToNode():
	md_cleanupOpenWindows()
	cmds.window(addingObjectsWindow, title="Add Selection to MIDI Channel" )
	cmds.columnLayout(co = ['both', columnPadding])
	cmds.separator( style='none', height=columnPadding )
	cmds.text(label='Select Objects and Attributes then move MIDI Control', width=400)
	cmds.separator( style='none', height=sectionSpacerPadding )
	cmds.button( label="Cancel", c='import midiConnect as md; md.md_cleanupOpenWindows()')
	cmds.separator( style='none', height=columnPadding )
	cmds.showWindow(addingObjectsWindow)

def md_showRemoveSelectedAttributesToNode():
	md_cleanupOpenWindows()
	cmds.window(removingObjectsWindow, title="Remove Selection from MIDI Channel" )
	cmds.columnLayout(co = ['both', columnPadding])
	cmds.separator( style='none', height=columnPadding )
	cmds.text(label='Select Objects (attributes optional) then move MIDI Control', width=400)
	cmds.separator( style='none', height=sectionSpacerPadding )
	cmds.button( label="Cancel", c='import midiConnect as md; md.md_cleanupOpenWindows()')
	cmds.separator( style='none', height=columnPadding )
	cmds.showWindow(removingObjectsWindow)

def md_cleanupOpenWindows():
	if cmds.window(removingObjectsWindow, exists=True):
		cmds.deleteUI(removingObjectsWindow)
	if cmds.window(addingObjectsWindow, exists=True):
		cmds.deleteUI(addingObjectsWindow)
	if cmds.window(settingDrivenKeyWindow, exists=True):
		cmds.deleteUI(settingDrivenKeyWindow)
	if cmds.window(createInterpolatorWindow, exists=True):
		cmds.deleteUI(createInterpolatorWindow)
	if cmds.textField(midiIntCheckBox, exists=True):
		cmds.deleteUI(midiIntCheckBox)
	if cmds.window(createPyWindow, exists=True):
		cmds.deleteUI(createPyWindow)
	if cmds.textField(midiPyTextField, exists=True):
		cmds.deleteUI(midiPyTextField)

def md_update(controller, channel, value):
	channelNode = md_nodeNameForMidiChannel(controller, channel)
	if cmds.window(createInterpolatorWindow, exists=True):
		md_createInterpolator(controller, channel, value)
		return "Update"
	if cmds.window(createPyWindow, exists=True):
		md_createPyCommand(controller, channel, value)
		return "Update"
	if cmds.window(settingDrivenKeyWindow, exists=True):
		md_setDrivenKeyForControl(channelNode)
		return "Update"
	if cmds.window(addingObjectsWindow, exists=True):
		md_addSelectedAttributesToNode(channelNode)
		md_cleanupOpenWindows()
		return "Update"
	if cmds.window(removingObjectsWindow, exists=True):
		md_removeSelectedObjectsFromNode(channelNode)
		md_cleanupOpenWindows()
		return "Update"
	cmds.setAttr((channelNode + '.input1'), value)
	if cmds.getAttr((channelNode + '.isPyCommand')):
		if value > 0:
			return "Update"
		pyCommand = cmds.getAttr((channelNode + '.pyCommand'))
		print 'Found Py Node, attempting to execute code:' + pyCommand
		exec pyCommand
		return "Update"
	childNodes = cmds.listConnections((channelNode + '.output'))
	for child in childNodes:
		node = cmds.getAttr( child + '.nodeName')
		attr = cmds.getAttr( child + '.attrName')
		setterName = cmds.getAttr( child + '.setterName')
		grandChildName = midiBaseName + node + '_' + attr
		output = cmds.getAttr( grandChildName + '.output1D')
		cmds.setAttr(setterName, output)
	return "Update"

def md_createInterpolator(controller, channel, value):
    removeCurrentConnections = cmds.checkBox(midiIntCheckBox, query=True, value=True)
    md_cleanupOpenWindows()
    channelNode = md_createBaseNodeForMidiChannel(controller, channel, removeCurrentConnections)
    md_addSelectedAttributesToNode(channelNode)
    cmds.setAttr((channelNode + '.input1'), value)

def md_createPyCommand(controller, channel, value):
	pythonCommand = cmds.textField(midiPyTextField, text=True, q=True)
	channelNode = md_createBaseNodeForMidiChannel(controller, channel, True)
	print cmds.setAttr((channelNode + '.isPyCommand'), True)
	print cmds.setAttr((channelNode + '.pyCommand'), pythonCommand, type = 'string')
	md_cleanupOpenWindows()

def md_setDrivenKeyForControl(channelNode):
	## TODO BASE OFF OF SELECTION IF PRESENT
	lastChannelValue = cmds.getAttr((channelNode + '.output'))
	childNodes = cmds.listConnections((channelNode + '.output'))
	for child in childNodes:
		setterName = cmds.getAttr(child + '.setterName')
		attrValue = cmds.getAttr(setterName)
		keyCount = cmds.getAttr((child + '.value'), size = True)
		keyIndex = keyCount
		for x in xrange(0,keyCount):
			keyPosition = cmds.getAttr((child + '.value['+str(x)+'].value_Position'))
			diff = abs(lastChannelValue - keyPosition)
			if diff < 5:
				keyIndex = x
				break
		cmds.setAttr( (child + '.value['+str(keyIndex)+'].value_Position'), lastChannelValue)
		cmds.setAttr( (child + '.value['+str(keyIndex)+'].value_Interp'), 3)
		cmds.setAttr( (child + '.value['+str(keyIndex)+'].value_FloatValue'), attrValue)
	md_cleanupOpenWindows()

def md_removeSelectedObjectsFromNode(channelNode):
	slObjects = cmds.ls(selection=True)
	slAttributes = cmds.channelBox('mainChannelBox',q=True,selectedMainAttributes=True)
	childNodes = cmds.listConnections((channelNode + '.output'))
	for node in slObjects:
		nodeName = midiBaseName + node + "_"
		if slAttributes is not None:
			for attr in slAttributes:
				checkedNode = nodeName + attr
				if checkedNode in childNodes:
					cmds.disconnectAttr((channelNode + '.output'), (checkedNode + '.inputValue'))
					cmds.delete(checkedNode)
		else:
			foundNodes = cmds.ls((nodeName + '*'))
			for foundNode in foundNodes:
				if foundNode in childNodes:
					cmds.disconnectAttr((channelNode + '.output'), (foundNode + '.inputValue'))
					cmds.delete(foundNode)

def md_addSelectedAttributesToNode(channelNode):
    slObjects = cmds.ls(selection=True)
    slAttributes = cmds.channelBox('mainChannelBox',q=True,selectedMainAttributes=True)
    childNodes = cmds.listConnections((channelNode + '.output'))
    # TODO Assert and Warn if nothing selected
    for node in slObjects:
    	for attr in slAttributes:
			grandChildName = midiBaseName + node + '_' + attr
			childNodeName = channelNode + '_' + node + '_' + attr
			setterName = node + '.' + attr
			channelOutput = channelNode + '.output'
			childInput = childNodeName + '.inputValue'
			childOutput = childNodeName + '.outValue'
			grandchildInput = grandChildName + '.input1D'

			if childNodes is not None and childNodeName in childNodes:
				#This is already a child node of the channel
				continue
			if not cmds.objExists(grandChildName):
				cmds.createNode('plusMinusAverage', name=grandChildName, ss=True)
				cmds.addAttr(grandChildName, longName='setterName', dataType='string' )
				cmds.addAttr(grandChildName, longName='nodeName', dataType='string' )
				cmds.addAttr(grandChildName, longName='attrName', dataType='string' )
				cmds.setAttr((grandChildName + '.setterName'), setterName, type='string')
				cmds.setAttr((grandChildName + '.nodeName'), node, type='string')
				cmds.setAttr((grandChildName + '.attrName'), attr, type='string')
			inputIndex = cmds.getAttr(grandchildInput, size = True)
			grandchildInput = grandchildInput + '[' + str(inputIndex) + ']'
			cmds.createNode('remapValue', name=childNodeName, ss=True)
			cmds.connectAttr(channelOutput, childInput)
			cmds.connectAttr(childOutput, grandchildInput)
			attrValue = cmds.getAttr(setterName)
			cmds.removeMultiInstance((childNodeName + '.value[1]'), b=True)
			cmds.setAttr((childNodeName + '.value[0].value_FloatValue'), attrValue)
			cmds.addAttr(childNodeName, longName='setterName', dataType='string' )
			cmds.addAttr(childNodeName, longName='nodeName', dataType='string' )
			cmds.addAttr(childNodeName, longName='attrName', dataType='string' )
			cmds.setAttr((childNodeName + '.setterName'), setterName, type='string')
			cmds.setAttr((childNodeName + '.nodeName'), node, type='string')
			cmds.setAttr((childNodeName + '.attrName'), attr, type='string')

def md_mirrorNode(channelNode, newController, newChannel, value, findString, replaceString):
	newChannelNode = md_createBaseNodeForMidiChannel(newController, newChannel, True)
	childNodes = cmds.listConnections((channelNode + '.output'))
	if childNodes is None:
		return
	for child in childNodes:
		oldNodeName = cmds.getAttr(child + '.nodeName')
		node = oldNodeName.replace(findString, replaceString)
		attr = cmds.getAttr(child + '.attrName')
		grandChildName = midiBaseName + node + '_' + attr
		newChildName = child.replace(channelNode, newNodeName)
		newChildName = newChildName.replace(findString, replaceString)
		setterName = node + '.' + attr
		channelOutput = newChannelNode + '.output'
		childInput = newChildName + '.inputValue'
		childOutput = newChildName + '.outValue'
		grandchildInput = grandChildName + '.input1D'
###YOU LEFT OFF HERE
		newChildNode = cmds.duplicate(child, n=newChildName)
		newNodeName = nodeName.replace(findString, replaceString)
		cmds.setAttr((newChildName + '.nodeName'), newNodeName)
		attrName = cmds.getAttr(newChildName + '.attrName')
		
		cmds.setAttr((newChildName + '.setterName'), setterName)


		pass


def md_createBaseNodeForMidiChannel(controller, channel, replaceExisting):
	#Todo Deleting children
	node = md_nodeNameForMidiChannel(controller, channel)
	if replaceExisting and cmds.objExists(node):
		print 'DELETING BASE NODE ' + node
		md_deleteChannelNode(node)
	if cmds.objExists(node):
		return node
	returnNode = cmds.createNode('addDoubleLinear', name=node, ss=True)
	cmds.addAttr(returnNode, longName='isPyCommand', at= 'bool' )
	cmds.addAttr(returnNode, longName='pyCommand', dataType='string' )
	return returnNode

def md_deleteChannelNode(node):
	#TODO Delete Child Nodes too
	cmds.delete(node)

def md_nodeNameForMidiChannel(controller, channel):
	nodeName = midiBaseName + str(controller) + '_' + str(channel)
	return nodeName

