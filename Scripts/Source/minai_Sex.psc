scriptname minai_Sex extends Quest

SexLabFramework slf


bool bHasOstim = False
GlobalVariable minai_UseOstim
int map 
int descriptionsMap
bool bHasAIFF

minai_AIFF aiff
minai_MainQuestController main
Actor PlayerRef

function Maintenance(minai_MainQuestController _main)
  playerRef = Game.GetPlayer()
  main = _main
  aiff = (Self as Quest) as minai_AIFF
  Debug.Trace("[minai] - Initializing Sex Module.")
  bHasAIFF = (Game.GetModByName("AIAgent.esp") != 255)
  
  RegisterForModEvent("HookStageStart", "OnStageStart")
  RegisterForModEvent("HookOrgasmStart", "PostSexScene")
  RegisterForModEvent("HookAnimationEnd", "EndSexScene")
  RegisterForModEvent("HookAnimationStart", "OnAnimationStart")
  
  ; RegisterForModEvent("ostim_event", "OnOstimEvent")
  RegisterForModEvent("ostim_thread_start", "OStimManager")
  RegisterForModEvent("ostim_thread_scenechanged", "OStimManager")
  RegisterForModEvent("ostim_thread_speedchanged", "OStimManager")
  RegisterForModEvent("ostim_actor_orgasm", "OStimManager")
  RegisterForModEvent("ostim_thread_end", "OStimManager")
    
  slf = Game.GetFormFromFile(0xD62, "SexLab.esm") as SexLabFramework
  if Game.GetModByName("OStim.esp") != 255
    Debug.Trace("[minai] Found OStim")
    bHasOstim = True
  EndIf

  minai_UseOStim = Game.GetFormFromFile(0x0906, "MinAI.esp") as GlobalVariable
  if !minai_UseOStim
    Debug.Trace("[minai] Could not find ostim toggle")
  EndIf
  
  ; Reset incase the player quit during a sex scene or this got stuck
  SetSexSceneState("off")
  InitializeSexDescriptions()
EndFunction



bool Function CanAnimate(actor akTarget, actor akSpeaker)
  if bHasOstim && minai_UseOStim.GetValue() == 1.0 && !OActor.IsInOStim(akTarget) && !OActor.IsInOStim(akSpeaker)
    return True
  EndIf
  return !slf.IsActorActive(akTarget) && !slf.IsActorActive(akSpeaker)
EndFunction

Function Start1pSex(actor akSpeaker)
  if bHasOstim && minai_UseOStim.GetValue() == 1.0
    OThread.QuickStart(OActorUtil.ToArray(akSpeaker))
  else
    slf.Quickstart(akSpeaker)
  EndIf
EndFunction


Function Start2pSex(actor akSpeaker, actor akTarget, actor Player, bool bPlayerInScene)
  if bHasOstim && minai_UseOStim.GetValue() == 1.0
    int ActiveOstimThreadID
    if bPlayerInScene
      ActiveOstimThreadID = OThread.QuickStart(OActorUtil.ToArray(Player, akSpeaker))
    else
      ActiveOstimThreadID = OThread.QuickStart(OActorUtil.ToArray(akTarget, akSpeaker))
    EndIf
    Utility.Wait(2)
    bool AutoMode = OThread.IsInAutoMode(ActiveOstimThreadID)
    if AutoMode == False
      OThreadBuilder.NoPlayerControl(ActiveOstimThreadID)
      OThread.StartAutoMode(ActiveOstimThreadID)
    EndIf
  Else
    slf.Quickstart(akTarget,akSpeaker)
  EndIf
EndFunction


Function StartGroupSex(actor akSpeaker, actor akTarget, actor Player, bool bPlayerInScene, Actor[] actorsFromFormList)
  if bHasOstim && minai_UseOStim.GetValue() == 1.0
    int ActiveOstimThreadID
    ActiveOstimThreadID = OThread.QuickStart(OActorUtil.ToArray(actorsFromFormList[0],actorsFromFormList[1],actorsFromFormList[2],actorsFromFormList[3],actorsFromFormList[4],actorsFromFormList[5],actorsFromFormList[6],actorsFromFormList[7],actorsFromFormList[8],actorsFromFormList[9]))
    Utility.Wait(2)
    bool AutoMode = OThread.IsInAutoMode(ActiveOstimThreadID)
    if AutoMode == False
      OThreadBuilder.NoPlayerControl(ActiveOstimThreadID)
      OThread.StartAutoMode(ActiveOstimThreadID)
    EndIf
  Else
    int numMales = 0
    int numFemales = 0
    Actor[] sortedActors = new Actor[12]
    int i = 0
    ; If the player is a female actor and is in the scene, put them in slot 0
    if bPlayerInScene && player.GetActorBase().GetSex() != 0
      sortedActors[0] = Player
    EndIf
    while i < actorsFromFormList.Length
      if actorsFromFormList[i].GetActorBase().GetSex() == 0
        numMales += 1
      else
        numFemales += 1
        if sortedActors[0] == None
        ; If there's a female actor in the scene, put them in slot 0
          sortedActors[0] = actorsFromFormList[i]
        EndIf
      EndIf
      if i != 0
        sortedActors[i] = actorsFromFormList[i]
      EndIf
      i += 1
    EndWhile
    if sortedActors[0] == None
      ; No female actors in scene, just use the first one that we skipped before
      sortedActors[0] = actorsFromFormList[0]
    EndIf
    slf.StartSex(actorsFromFormList, slf.GetAnimationsByDefault(numMales, numFemales))
  EndIf
EndFunction


bool function UseSex()
  return slf != None || bHasOstim
EndFunction



Function ActionResponse(actor akTarget, actor akSpeaker, string sayLine, actor[] actorsFromFormList, bool bPlayerInScene)
  actor Player = game.GetPlayer()
    ; Mutually Exclusive keywords
    if CanAnimate(akTarget, akSpeaker)
      If stringutil.Find(sayLine, "-masturbate-") != -1
        Start1pSex(akSpeaker)
      elseif stringutil.Find(sayLine, "-startsex-") != -1 || stringUtil.Find(sayLine, "-have sex-") != -1 || stringUtil.Find(sayLine, "-sex-") != -1 || stringUtil.Find(sayLine, "-having sex-") != -1
        Start2pSex(akSpeaker, akTarget, Player, bPlayerInScene)
      elseIf stringutil.Find(sayLine, "-groupsex-") != -1 || stringUtil.Find(sayLine, "-orgy-") != -1 || stringUtil.Find(sayLine, "-threesome-") != -1 || stringUtil.Find(sayLine, "-fuck-") != -1
        StartGroupSex(akSpeaker, akTarget, Player, bPlayerInScene, actorsFromFormList)
      EndIf
    Else
      Debug.Trace("[minai] Not processing keywords for exclusive scene - Conflicting scene is running")
    EndIf
    
EndFunction



Event CommandDispatcher(String speakerName,String  command, String parameter)
  if !bHasAIFF
    return
  EndIf
  Actor akSpeaker=AIAgentFunctions.getAgentByName(speakerName)
  actor akTarget= AIAgentFunctions.getAgentByName(parameter)
  if !akTarget
    akTarget = PlayerRef
  EndIf

  bool bPlayerInScene = (akTarget == PlayerRef || akSpeaker == PlayerRef)

  string targetName = main.GetActorName(akTarget)
  if CanAnimate(akTarget, akSpeaker)
    If command == "ExtCmdMasturbate"
      Start1pSex(akSpeaker)
    elseif command == "ExtCmdStartSexScene"
      Start2pSex(akSpeaker, akTarget, PlayerRef, bPlayerInScene)
    elseIf command == "ExtCmdOrgy"
      Debug.Notification("Orgy is broken until I figure out how to get all AI actors")
      ; StartGroupSex(akSpeaker, akTarget, PlayerRef, bPlayerInScene, actorsFromFormList)
    EndIf
  Else
    Debug.Trace("[minai] Not processing keywords for exclusive scene - Conflicting scene is running")
  EndIf
EndEvent


Event OnOstimOrgasm(string eventName, string strArg, float numArg, Form sender)
    actor akActor = sender as actor
EndEvent



Event OStimManager(string eventName, string strArg, float numArg, Form sender)
  int ostimTid = numArg as int
  Debug.Trace("[minai] oStim eventName: "+eventName+", strArg: "+strArg);
  if (eventName=="ostim_thread_start")
    string sceneName=OThread.GetScene(ostimTid);
    bool isRunning=OThread.IsRunning(ostimTid);
    Actor[] actors =  OThread.GetActors(ostimTid);
    string actorString;
    int i = actors.Length
    bool playerInvolved=false
    while(i > 0)
        i -= 1
        actorString=actorString+actors[i].GetDisplayName()+",";
        if (actors[i] == playerRef) 
          playerInvolved=true;
        endif
    endwhile
    
    if (playerInvolved)
      AIFF.ChillOut()
    endif
    SetSexSceneState("on")
    if bHasAIFF
      AIAgentFunctions.logMessage("ostim@"+sceneName+" "+isRunning+" "+actorString,"setconf")
    EndIf
    Debug.Trace("[minai] Started intimate scene")
  
  elseif (eventName=="ostim_thread_scenechanged")
    string sceneId = strArg 
    string sceneName=OThread.GetScene(ostimTid);
    bool isRunning=OThread.IsRunning(ostimTid);
    Actor[] actors =  OThread.GetActors(ostimTid);
    string actorString;
    int i = actors.Length
    bool playerInvolved=false
    while(i > 0)
        i -= 1
        actorString=actorString+actors[i].GetDisplayName()+",";
        if (actors[i] == playerRef)
          playerInvolved=true;
        endif
    endwhile
    
    if (playerInvolved)
      AIFF.ChillOut()
    endif
    main.RegisterEvent(""+sceneName+" id:"+sceneId+" isRunning:"+isRunning+" Actors:"+actorString,"info_sexscene")
    Debug.Trace("[minai] Ostim Scene changed")

  elseif (eventName=="ostim_actor_orgasm")    
    Actor OrgasmedActor = Sender as Actor
    main.RegisterEvent(OrgasmedActor.GetDisplayName() + " had an Orgasm")
    DirtyTalk("ohh... yes.","chatnf_sl_2",OrgasmedActor.GetDisplayName())
    Debug.Trace("[minai] Ostim Actor orgasm")

  elseif (eventName=="ostim_thread_end")    
    string sceneName=OThread.GetScene(ostimTid);
    bool isRunning=OThread.IsRunning(ostimTid);
    Actor[] actors =  OThread.GetActors(ostimTid);
    string actorString;
    int i = actors.Length
    bool playerInvolved=false
    while(i > 0)
      i -= 1
      actorString=actorString+actors[i].GetDisplayName()+",";
      if (actors[i] == playerRef) 
        playerInvolved=true;
      endif
    endwhile
    
    if (playerInvolved)
      AIFF.ChillOut()
    endif
    SetSexSceneState("off")
    Debug.Trace("[minai] Ended intimate scene")
  endif
EndEvent





Function LoadSexlabDescriptions()
  if (descriptionsMap==0)
    Debug.Trace("[minai] Loading Sexlab Descriptions")
    descriptionsMap=JValue.readFromFile( "Data/Data/minai/sexlab_descriptions.json");
    JValue.retain(descriptionsMap)
    Debug.Trace("[minai] Descriptions set: "+JMap.count(descriptionsMap)+" using map: "+descriptionsMap+ " Data/Data/minai/sexlab_descriptions.json")
  endif
EndFunction


Function SetSexSceneState(string sexState)
  if bHasAIFF
    AIAgentFunctions.logMessage("sexscene@" + sexState,"setconf")
  EndIf
EndFunction


Event OnAnimationStart(int tid, bool HasPlayer)
  LoadSexlabDescriptions()
  Actor[] actorList = slf.GetController(tid).Positions
  Actor[] sortedActorList = slf.SortActors(actorList,true)
  int i = sortedActorList.Length
  bool bPlayerInScene=false
  while(i > 0)
    i -= 1
    if (sortedActorList[i]==playerRef) 
      bPlayerInScene=true;
    EndIf
  EndWhile
  
  if (bPlayerInScene)
    AIFF.ChillOut()
  endif
  SetSexSceneState("on")
  Debug.Trace("[minai] Started Sex Scene")
EndEvent


Event OnStageStart(int tid, bool HasPlayer)
  sslThreadController controller = slf.GetController(tid)
  
  if (controller.Stage==1) 
    LoadSexlabDescriptions()
  endif
  
  Actor[] actorList = slf.GetController(tid).Positions
  Actor[] targetactorList = actorList

  If (actorList.length < 1)
    return
  EndIf
  
  String pleasure=""
  Actor[] sortedActorList = slf.SortActors(actorList,true)
  
  int i = sortedActorList.Length
  while(i > 0)
    i -= 1
    pleasure=pleasure+sortedActorList[i].GetDisplayName()+" pleasure score "+slf.GetEnjoyment(tid,sortedActorList[i])+","
  endwhile
  String sceneTags="'. Scene tags: "+controller.Animation.GetRawTags()+"."
    if (controller.Animation.GetRawTags()=="")
      sceneTags="";
    EndIf
    
    ;Animations[StageIndex(Position, Stage)]
    String sexPos="#SEX_SCENARIO: Position '" +controller.Animation.Name+"'. ";
    String pleasureFull=pleasure

    String stageDesc1 = GetSexStageDescription(controller.Animation.FetchStage(controller.Stage)[0])
    string stageDesc2 = GetSexStageDescription(controller.Animation.FetchStage(controller.Stage)[1])
    
    String description=sortedActorList[0].GetDisplayName()+" is "+ stageDesc1
    String description2=sortedActorList[1].GetDisplayName()+" is "+ stageDesc2

    if (stageDesc1 == "")
      description="";
    EndIf
    
    if (stageDesc2 == "")
      description2="";
    EndIf
      

    ; Select an actor that's not the player, and have them talk.
    actor otherActor = sortedActorList[0]
    if otherActor == playerRef && sortedActorList.Length > 1
      otherActor = sortedActorList[1]
    EndIf

    string[] Tags = controller.Animation.GetRawTags()
    ; Send event, AI can be aware SEX is happening here
    if (Tags.Find("forced")!= -1)
      main.RegisterEvent(sexPos+sceneTags+actorList[0].GetDisplayName()+ " is being raped by  "+actorList[1].GetDisplayName()+ ", ("+actorList[0].GetDisplayName()+" feels a mix of pain and pleasure) ."+description+description2+"("+pleasureFull+")","info_sexscene")
    else
      main.RegisterEvent(sexPos+sceneTags+actorList[0].GetDisplayName()+ " and "+actorList[1].GetDisplayName()+ " are having sex. "+description+description2+"("+pleasureFull+")","info_sexscene")
    endif

    ; main.RegisterEvent(controller.Animation.FetchStage(controller.Stage)[0]+"@"+sceneTags,"info_sexscenelog")

    aiff.setAnimationBusy(1,otherActor.GetDisplayName())
    if (!slf.isMouthOpen(otherActor) && otherActor != playerRef)
      if (controller.Stage < (controller.Animation.StageCount()))
        DirtyTalk("ohh... yes.","chatnf_sl",sortedActorList[1].GetDisplayName())
      endif
    else
      main.RegisterEvent(otherActor.GetDisplayName()+ " is now using mouth with "+actorList[1].GetDisplayName(),"info_sexscene")
    endif
EndEvent

Function DirtyTalk(string lineToSay, string lineType, string name)
  if !bHasAIFF
    return
  EndIf
  AIAgentFunctions.requestMessageForActor(lineToSay, lineType, name)
EndFunction



Event PostSexScene(int tid, bool HasPlayer)
  sslThreadController controller = slf.GetController(tid)
  Actor[] actorList = slf.HookActors(tid)
  Actor[] targetactorList = actorList
  If (actorList.length < 1)
    return
  EndIf
  
  String pleasure=""
   int i = actorList.Length
  while(i > 0)
    i -= 1
    pleasure=pleasure+actorList[i].GetDisplayName()+" is reaching orgasm,"
  EndWhile
  String pleasureFull="Pleasure:"+pleasure
  ; Send event, AI can be aware SEX is happening here
  main.RegisterEvent(pleasureFull,"info_sexscene")
  
  Actor[] sortedActorList = slf.SortActors(actorList,true)
  ; Select an actor that's not the player, and have them talk.
  actor otherActor = sortedActorList[0]
  if otherActor == playerRef && sortedActorList.Length > 1
    otherActor = sortedActorList[1]
  EndIf
  
   main.RegisterEvent(otherActor.GetDisplayName()+ ": Oh yeah! I'm having an orgasm!.","chat")
   if (!slf.isMouthOpen(otherActor))
    DirtyTalk("I'm cumming!","chatnf_sl_2",otherActor.GetDisplayName())
  EndIf
EndEvent

Event EndSexScene(int tid, bool HasPlayer)
    JValue.release(descriptionsMap)
    Debug.Trace("[minai] Ended Sex scene")
    sslThreadController controller = slf.GetController(tid)

    Actor[] actorList = slf.HookActors(tid)
    Actor[] targetactorList = actorList

    ; Send event, AI can be aware SEX is happening here
    Actor[] sortedActorList = slf.SortActors(actorList,true)
    
    ; Select an actor that's not the player, and have them talk.
    actor otherActor = sortedActorList[0]
    if otherActor == playerRef && sortedActorList.Length > 1
      otherActor = sortedActorList[1]
    EndIf

    main.RegisterEvent(sortedActorList[0].GetDisplayName()+ " and "+sortedActorList[1].GetDisplayName()+ " ended the intimate moment","info_sexscene")
    if bHasAIFF
      DirtyTalk("That was awesome, what do you think?","inputtext",otherActor.GetDisplayName())
      AIFF.SetAnimationBusy(0, otherActor.GetDisplayName())
    EndIf
    SetSexSceneState("off")
EndEvent


String function GetSexStageDescription(String animationStageName) 
    Debug.Trace("[minai] Obtaining description for: <"+animationStageName+"> using map: "+descriptionsMap)
  return JMap.getStr(descriptionsMap,animationStageName)
endFunction


function InitializeSexDescriptions()
  if (JMap.count(descriptionsMap) != 0 || descriptionsMap != 0)
    Debug.Trace("[minai] Not reinitializing sexlab descriptions - data already exists.")
    return
  EndIf
  descriptionsMap = JMap.object()
  LoadSexlabDescriptions()

  if (JMap.count(descriptionsMap) != 0 || descriptionsMap != 0)
    Debug.Trace("[minai] Not reinitializing sexlab descriptions - data already exists.")
    return
  EndIf
  
  Debug.Trace("[minai] Initializing sex descriptions");
  JMap.clear(descriptionsMap)
  JMap.setStr(descriptionsMap,"Mitos_Laplove_A1_S1","Stands over partner.")
  JMap.setStr(descriptionsMap,"Leito_Cowgirl_A1_S1","staying atop partner with gentle movements.")
  JMap.setStr(descriptionsMap,"Leito_Cowgirl_A2_S1","lying down in a passive stance.")
  JMap.setStr(descriptionsMap,"Leito_Cowgirl_A1_S2","still staying atop partner, sitting on, moving with gentle movements.")
  JMap.setStr(descriptionsMap,"Leito_Cowgirl_A2_S2","lying down in a passive stance.")
  JMap.setStr(descriptionsMap,"Leito_Cowgirl_A1_S3","still staying atop partner, sitting over, moving now with stronger movements.")
  JMap.setStr(descriptionsMap,"Leito_Cowgirl_A2_S3","lying down in a passive stance.")
  JMap.setStr(descriptionsMap,"Leito_Cowgirl_A1_S4","still staying atop partner, almost hugging, moving now with quick movements.")
  JMap.setStr(descriptionsMap,"Leito_Cowgirl_A2_S4","lying down in a passive stance.")
  JMap.setStr(descriptionsMap,"Leito_Cowgirl_A1_S5","still staying atop partner, almost hugging, moving now slowly. Trembling with Pleasure.")
  JMap.setStr(descriptionsMap,"Leito_Cowgirl_A2_S5","lying down in a passive stance. Trembling with Pleasure.")
  Debug.Trace("[minai] Descriptions set: "+JMap.count(descriptionsMap)+" using map: "+descriptionsMap)
  JValue.writeToFile(descriptionsMap, "Data/Data/minai/sexlab_descriptions.json")
endFunction

