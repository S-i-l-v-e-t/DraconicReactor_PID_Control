component = require("component")
thread = require("thread")
event = require("event")
term = require("term")
curIn,curOut=0,0
setfield=0.05
setTemp=8000.4
fieldCoe={0.08,0.03,0.09}
tempCoe={0.05,0.09,0.1}
energyCoe={0.045,0.11,0.1}
intgTime=15
avgOut=0
fieldDeltaList={}
tempDeltaList={}
energyDeltaList={}
reactor = component.proxy(component.get("d35f832a-8b73-4c50-b996-e79fc76cac70"))
outGate = component.proxy(component.get("9a0c929b-e3e4-4e5b-9c77-a28681347305"))
inGate = component.proxy(component.get("9d6438bc-8a2f-4780-b4cc-6260585af537"))
Monitor="d5d4584e-6017-42fa-a900-f6a13a311aae"
gpuaddr="120"
gpu = component.proxy(component.get(gpuaddr))
gpu.bind(Monitor)
gpu.setResolution(40,12.5)
buttonStat="stop"

function FieldRate()
    return reactor.getReactorInfo()["fieldStrength"]/reactor.getReactorInfo()["maxFieldStrength"]
end
function FieldDrain()
    return reactor.getReactorInfo()["fieldDrainRate"]
end
function EnergyRate()
    return reactor.getReactorInfo()["energySaturation"]/reactor.getReactorInfo()["maxEnergySaturation"]
end
function Field()
    return reactor.getReactorInfo()["fieldStrength"]
end
function maxField()
    return reactor.getReactorInfo()["maxFieldStrength"]
end
function Energy()
    return reactor.getReactorInfo()["energySaturation"]
end
function eV()
    return reactor.getReactorInfo()["generationRate"]
end
function FuelRate()
    return reactor.getReactorInfo()["fuelConversion"]/reactor.getReactorInfo()["maxFuelConversion"]
end
function Temp()
    return reactor.getReactorInfo()["temperature"]
end
function status()
    return reactor.getReactorInfo()["status"]
end

function setIn(value)
    if value<0
    then
        inGate.setFlowOverride(0)
        curIn=0
    else
        if(value>64000000)
        then
            inGate.setFlowOverride(64000000)
        else
            inGate.setFlowOverride(value)
            curIn=value
        end
    end
end
function setOut(value)
    if value<0
    then
        outGate.setFlowOverride(0)
        curOut=0
    else
        outGate.setFlowOverride(value)
        curOut=value
    end
end
function sum(tb)
    local sumvar=0.0
    for k,v in pairs(tb)
    do
        sumvar=sumvar+v
    end
    return sumvar
end
function len(tb)
    local length=0
    for k,v in pairs(tb)
    do
        length=k
    end
    return length
end
function field_main()
    local it,eP,eI,eD,eT,fieldDelta=0,0.0,0.0,0.0,0.0,0.0
    while true
    do
        fieldDelta=maxField()*setfield-Field()
        eP=fieldDelta*fieldCoe[1]
        if eP+FieldDrain()>=0 
        then
            table.insert(fieldDeltaList,fieldDelta)
            if it>=3
            then
                eI=sum(fieldDeltaList)*fieldCoe[2]
                eD=(fieldDelta-fieldDeltaList[len(fieldDeltaList)-1])*fieldCoe[3]
            end
            if it<=intgTime
            then
                it=it+1
            else
                it=0
                fieldDeltaList={}
            end
        end
        eT=eP+eI+eD
        setIn(eT+FieldDrain())
        os.sleep(0.3)
    end
end

function temp_main()
    local it1,it2,eP1,eI1,eD1,eT1,eP2,eI2,eD2,eT2,tgtE,tDelta,eDelta=0,0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
    while true
    do
        tDelta=setTemp-Temp()
        eP1=tDelta*tempCoe[1]
        table.insert(tempDeltaList,tDelta)
        if it1>=3
        then
            eI1=sum(tempDeltaList)*tempCoe[2]
            eD1=(tDelta-tempDeltaList[len(tempDeltaList)-1])*tempCoe[3]
        else
            it1=it1+1
        end
        if it1<=intgTime
        then
            it1=it1+1
        else
            it1=0
            tempDeltaList={}
        end
        eT1=eP1+eI1+eD1
        eDelta=eT1*100
        eP2=eDelta*energyCoe[1]
        if eP2+eV()>=0
        then
            table.insert(energyDeltaList,eDelta)
            if it2>=3
            then
                eI2=sum(energyDeltaList)*energyCoe[2]
                eD2=(eDelta-energyDeltaList[len(energyDeltaList)-1])*energyCoe[3]
            else
                it2=it2+1
            end
            if it2<=intgTime
            then
                it2=it2+1
            else
                it2=0
                energyDeltaList={}
            end
        end
        eT2=eP2+eI2+eD2
        setOut(eV()+eT2)
        avgOut=curOut-curIn
        os.sleep(0.8)
    end
end
function initialize()
  inGate.setOverrideEnabled(true)
  outGate.setOverrideEnabled(true)
  reactor.chargeReactor()
  setOut(0)
  setIn(64000000)
  while(true)
  do
    if(Temp()>=2000 and Field()>=0.49 and Energy()>=0.49)
    then
      reactor.activateReactor()
      if(status()=="running")
      then
        break
      end
    end
  end
end

function drawFrame()
  term.clear()
  gpu.setResolution(40,12.5)
  term.setCursorBlink(false)
  gpu.setBackground(0x393939)
  term.setCursor(15,1)
  term.write("ReactorInfo")
  term.setCursor(3,3)
  term.write("ENEG:")
  term.setCursor(3,4)
  term.write("FUEL:")
  term.setCursor(3,6)
  term.write("FILD:")
  term.setCursor(3,7)
  term.write("TEMP:")
  term.setCursor(3,9)
  term.write("COUT:")
end
function drawButton()
  gpu.setBackground(0x20FF20)
  gpu.setForeground(0xFF2020)
  gpu.fill(1,10,40,2.5," ")
  term.setCursor(15,11)
  if buttonStat == "stop" then
    term.write("StopReactor")
    buttonStat="start"
  else
    term.write("StartReactor")
    buttonStat="stop"
  end
  gpu.setBackground(0x393939)
  gpu.setForeground(0xFFFFFF)
end
function termWrite(x,y,string)
  term.setCursor(x,y)
  term.write(string)
end
         
function startReactor()
  initialize()
  fieldThread = thread.create(
    function()
      field_main()
    end
)
  reactorThread = thread.create(
    function()
      temp_main()
    end
)
end    
function stopReactor()
  avgOut = 0
  reactorThread:kill()
  reactor.stopReactor()
  while true do
  if(status()~="stopping") then
    fieldThread:kill()
    break
  end
  os.sleep(0)
  end
end
drawFrame()
drawButton()
startReactor()
graphicUpdate = thread.create(
  function()
    while true do
        gpu.setBackground(0x000000)
        gpu.fill(9,3,40,7," ")
        gpu.setBackground(0x393939)
        termWrite(9,3,string.format("%.2f", EnergyRate()*100) .. "%")
        termWrite(9,4,string.format("%.2f", (1-FuelRate())*100) .. "%")
        termWrite(9,6,string.format("%.2f", FieldRate()*100) .. "%")
        termWrite(9,7,Temp() .. "°C")
        termWrite(9,9,string.format("%.2f", avgOut) .. "RF/t")
      os.sleep(0)
    end
  end
)
touchDriver = thread.create(
  function()
    while true do
      local k,a,x,y,b,p=event.pull("touch")
      if(y>=10) then
        if(buttonStat=="start") then
          stopReactor()
          drawButton()
        else
          drawButton()
          startReactor()
        end
      end
      os.sleep(0)
    end
  end
)
emergency_supervise = thread.create(
    function()
        while true do
            if status()=="running" and (Temp()>=8300 or FieldRate()<=0.02) then
                fieldThread:kill()
                reactorThread:kill()
                setOut(0)
                setIn(64000000)
                reactor.stopReactor()
                os.exit()
            end
            os.sleep(0)
        end     
    end
)