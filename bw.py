import maya.cmds as cmds
import json

bw_selectionChanged = 0

def start():
  print("BW Scripts Starting")
  print("Opening Command Port")
  cmds.commandPort(name="0.0.0.0:4477", sourceType="python")

def helloWorld():
  print("MC Client Connected")
  return "MC Client Connected"

# Mark - Selection Polling
def startSelectionPolling():
  global bw_selectionChanged
  bw_selectionChanged = 0
  cmds.scriptJob( e= ["SelectionChanged","bw.selectionChangedLocalCallback()"], protected=True)

def selectionChangedLocalCallback():
  global bw_selectionChanged
  bw_selectionChanged = 1

def slPoll(asJSON=True):
  global bw_selectionChanged
  if bw_selectionChanged == 0:
    return 0
  bw_selectionChanged = 0
  return lsSelected(asJSON)

# Mark - Listing Objects and Attributes

def lsSelectedAndAttributes(asJSON=True):
  slObjects = lsSelected(False)
  slAttributes = cmds.channelBox('mainChannelBox',q=True,selectedMainAttributes=True)
  returnData = {}
  returnData['objects'] = slObjects
  returnData['attributes'] = slAttributes
  if asJSON == True:
    return json.dumps(returnData)
  return returnData

def lsSelected(asJSON=True):
  slObjects = cmds.ls(selection=True)
  returnObjects = []
  for node in slObjects:
    returnNode = {}
    attrs = lsKeyableAttr(node, asJSON=False)
    returnNode[node] = attrs
    returnObjects.append(returnNode)
  if asJSON == True:
    return json.dumps(returnObjects)
  return returnObjects

def lsChildren(node):
  cO = cmds.listRelatives(node, c=True, type='transform', pa=True)
  if cO == None:
      return node
  rO = []
  for cNode in cO:
      rO.append(lsChildren(cNode))
  return {node : rO}

def lsSceneTree(asJSON=True):
  tlObjects = cmds.ls(assemblies=True)
  dagObjects = []
  for node in tlObjects:
      if node != None:
          dagObjects.append(lsChildren(node))
  if asJSON == True:
    return json.dumps(dagObjects)
  return dagObjects

def lsSets(asJSON=True):
  allSets = cmds.ls(et='objectSet')
  sets = []
  for node in allSets:
    str = cmds.sets(node, q=True, text=True)
    if str == 'gCharacterSet':
      sets.append(node)
  if asJSON == True:
    return json.dumps(sets)
  return sets

def lsSetChildren(set, asJSON=True):
  setChildren = cmds.sets(set , q=True)
  if asJSON == True:
    return json.dumps(setChildren)
  return setChildren

def lsKeyableAttr(object, asJSON=True):
  attrs = cmds.listAttr(object, k=True, s=True)
  fullAttrs = {}
  for attr in attrs:
    str = object + "." + attr
    value = cmds.getAttr(str)
    fullAttrs[attr] = value
  if asJSON == True:
    return json.dumps(fullAttrs)
  return fullAttrs

def lsOutlinerChildren(outlinerObject, asJSON=True):
  cO = cmds.listRelatives(outlinerObject, c=True, type='transform', pa=True)
  if cO == None:
    return None
  returnObjects = []
  for node in cO:
    dagOb = {}
    gC = cmds.listRelatives(node, c=True, type='transform', pa=True)
    dagOb['title'] = node;
    childCount = 0
    if gC != None:
      childCount = len(gC)
    dagOb['childCount'] = childCount
    returnObjects.append(dagOb)
  if asJSON == True:
    return json.dumps(returnObjects)
  return returnObjects

def lsOutlinerObjects(asJSON=True):
  # First Lets get all top level DAG Objects
  # 
  tlObjects = cmds.ls(assemblies=True)
  returnObjects = []
  for node in tlObjects:
    dagOb = {}
    cO = cmds.listRelatives(node, c=True, type='transform', pa=True)
    dagOb['title'] = node;
    childCount = 0
    if cO != None:
      childCount = len(cO)
    dagOb['childCount'] = childCount
    returnObjects.append(dagOb)
  # Now lets get all QSS
  # 
  allSets = cmds.ls(et='objectSet')
  for node in allSets:
    str = cmds.sets(node, q=True, text=True)
    if str == 'gCharacterSet':
      dagOb = {}
      cO = cmds.listRelatives(node, c=True, type='transform', pa=True)
      dagOb['title'] = node;
      childCount = 0
      if cO != None:
        childCount = len(cO)
      dagOb['childCount'] = childCount
      returnObjects.append(dagOb)
  if asJSON == True:
    return json.dumps(returnObjects)
  return returnObjects

# Mark - Setter Methods

def setValueRel(attr, value):
  oValue = cmds.getAttr(attr)
  nValue = oValue + value
  cmds.setAttr(attr, nValue)

def resetAttrs(node=None):
  if node == None:
    selected = cmds.ls(selection=True)
    for node in selected:
      resetAttrs(node)
    return
  attrs = cmds.listAttr(node, k=True, s=True)
  for attr in attrs:
    defaultValue = cmds.attributeQuery(attr, node=node, ld=True)
    str = node + "." + attr
    cmds.setAttr(str, defaultValue[0])

# Mark - Experimental

def getMeshVertexData( mesh ):
  returnData = []
  exportObject = 'bwExportObject'
  cmds.duplicate( mesh, n=exportObject )
  cmds.polyTriangulate(exportObject)
  numOfFaces = cmds.polyEvaluate(exportObject,  f=True )
  for i in xrange(0, numOfFaces):
    faceSelect = exportObject + '.f[' + str(i) + ']'
    fVertices = [] 
    fVertices = cmds.polyListComponentConversion(faceSelect, ff = True, tvf = True)
    fVertices = cmds.filterExpand(fVertices, sm = 70, ex = True)
    print fVertices
    for vertex in fVertices:
      faceDict = {}
      vName = cmds.polyListComponentConversion(vertex, fvf = True, tv = True)
      xyz = []
      xyz = cmds.xform(vName, q = True, os = True, t = True)
      faceDict['x'] = round(xyz[0], 2)
      faceDict['y'] = round(xyz[1], 2)
      faceDict['z'] = round(xyz[2], 2)
      normal = []
      normal = cmds.polyNormalPerVertex(vertex, q = True, xyz = True)
      faceDict['xN'] = round(normal[0], 2)
      faceDict['yN'] = round(normal[1], 2)
      faceDict['zN'] = round(normal[2], 2)
      # vuv = []
      # vuv = cmds.polyListComponentConversion(vertex, fvf = True, tuv = True)
      # uvCoords = []
      # uvCoords = cmds.polyEditUV(vuv[0], q = True, u = True, v = True)
      # faceDict['u'] = round(uvCoords[0], 2)
      # faceDict['v'] = round(uvCoords[0], 2)
      returnData.append(faceDict)
  cmds.delete(exportObject)
  return json.dumps(returnData)