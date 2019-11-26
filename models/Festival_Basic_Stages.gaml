/***
* Name: Festival_Basic_Stages
* Author: Wilfredo Robinson and Jhorman Perez
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Festival_Basic_Stages

/* Insert your model definition here */

global {
	
	int numberOfStages <- 5;
	int numberOfAspects <- 6;
	int numberOfAgents <- 10;
	bool pauseSimulation;
	bool resetSimulation;
	bool concertInSession;
	
	
	init {
		create stageAgent number: numberOfStages {}
		create guestAgent number: numberOfAgents {} 
	}
	
	reflex pauseSimulation when: pauseSimulation {
		pauseSimulation <- false;
		resetSimulation <- false;
		do pause;
	}
	
	
}


species stageAgent skills: [fipa] {
	
	list<string> stageAspects <- ['music genre', 'music volume', 'music quality', 'stage size', 'stage quality', 'ticket price', 'crowd mass'];
	list<int> aspectQuality;
	rgb agentColor <- rgb(rnd(0,255), rnd(0, 255), rnd(0, 255));
	bool cfpsSent;
	int initCycleCounter <- 0;
	int initCycle <- 0;

	
	aspect default {
		draw square(7) at: location color: agentColor;
	}
	
	init {
		//////
	}	
	
	reflex cycleCounter when: !cfpsSent {
		if initCycleCounter < 1{
			aspectQuality <- [rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(0, 10)];
			initCycle <- cycle;
			initCycleCounter <- initCycleCounter + 1;
			}
		else if cycle - initCycle = 1000 {
			agentColor <- rgb(rnd(0,255), rnd(0, 255), rnd(0, 255));
			concertInSession <- true;
			} 
		}
	
	reflex announceAspects when: !cfpsSent and concertInSession {
			agentColor <- rgb(rnd(0,255), rnd(0, 255), rnd(0, 255));
			do start_conversation with: [ to :: list(guestAgent), protocol :: 'fipa-contract-net', 
				performative :: 'cfp', contents :: [stageAspects, aspectQuality, agentColor] ];
			cfpsSent <- true;
			write 'My name is ' + name + ' and my concert has begun at cycle ' + cycle + ' !' color: agentColor;
			write 'My aspects and qualities are: ' color: agentColor; 
			write '\t'+ stageAspects color: agentColor;
			write '\t'+ aspectQuality color: agentColor;
		}
	}


species guestAgent skills: [moving, fipa] {
	
	list<int> guestPreferences <- [rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(0, 10)];
	int stageUtility;
	bool cfpsReceived;
	list<message> stageInfo;
	list<string> stageAspects <- ['music genre', 'music volume', 'music quality', 'stage size', 'stage quality', 'ticket price', 'crowd mass'];
	list<int> utilityList;
	list<stageAgent> stageAgentList;
	int maxUtilityIndex;
	point targetPoint;
	bool stageSelected;
	rgb agentColor;
	list<guestAgent> agentsAtStage;
	
	
	aspect default {
		draw sphere(1.5) at: location color: agentColor;
	}
	init {
		write 'My name is ' + name + ' and my preferences are:';
		write '\t' + stageAspects;
		write '\t' + guestPreferences;
	}	
	
	reflex receiveStageInfo when: !cfpsReceived and length(utilityList) <= numberOfStages and concertInSession {
		stageInfo <- cfps;
		cfpsReceived <- true;
		//agentColor <- nil;
		loop stageIndex from: 0 to: numberOfStages - 1 {
			add stageAgent(stageInfo[stageIndex].sender) to: stageAgentList;
		}
	}
	
	action calculateUtility (stageAgent stage) {
			stageUtility <- 0;
			loop stageIndex from: 0 to: numberOfStages - 1 {
				if (stageAgent(stageInfo[stageIndex].sender).name = stage.name)	{
					loop aspectIndex from: 0 to: numberOfAspects - 1 {
						int aspectToConsider <- int(stageInfo[stageIndex].contents[1][aspectIndex]);
						stageUtility <- stageUtility + guestPreferences[aspectIndex]*aspectToConsider;
					}
				}
			}
		return stageUtility;
	}
	
	reflex calculateUtilities when: length(utilityList) <= numberOfStages - 1 and concertInSession {
		loop stageNumber from: 0 to: numberOfStages - 1{
			add int(calculateUtility(stageAgent(stageNumber))) to: utilityList;
			write 'The utility of ' + stageAgentList[stageNumber] + ' is ' + utilityList[stageNumber] color: rgb(nil);   
		}
		maxUtilityIndex <- utilityList index_of max(utilityList);
		ask stageAgentList[maxUtilityIndex] {
			myself.agentColor <- self.agentColor;
		}
		write 'I am ' + name + ' and the max utility is ' + max(utilityList) color: agentColor;
		write 'I am ' + name + ' and I will go to  ' + stageAgentList[maxUtilityIndex] color: agentColor;
		stageSelected <- true;
		targetPoint <-  {stageAgentList[maxUtilityIndex].location.x, stageAgentList[maxUtilityIndex].location.y};
	}
	
	reflex moveToTarget when: stageSelected and concertInSession{
		do goto target:targetPoint speed: 500.0;
		ask stageAgentList[maxUtilityIndex] {
			if distance_to (myself, self) < 0.5 {
				add myself to: myself.agentsAtStage;
			}
		}
	}
	
	reflex allAgentsArrived when: numberOfAgents = length(agentsAtStage) and concertInSession{
		resetSimulation <- true;
	}
	
	reflex beIdle when: !stageSelected and !concertInSession{
		//agentColor <- rgb(nil);
		do wander speed: 0.25;
	}
	
	reflex resetSimulation when: resetSimulation {
		ask stageAgent {
			self.initCycleCounter <- 0;
			self.initCycle <- 0;
			cfpsSent <- false;
			//agentColor <- nil;	
		}
		stageSelected <- nil;
		concertInSession <- false;
		pauseSimulation <- true;
		cfpsReceived <- false;
		utilityList <- [];
		stageAgentList <- [];
		agentsAtStage <- [];
		//agentColor <- nil;
	}
}


experiment Stages type: gui {
	output {
		display map type: opengl {
			species stageAgent;
			species guestAgent;
		}
	}
}

