/***
* Name: Festival_Challenge
* Author: Wilfredo Robinson and Jhorman Perez
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Festival_Challenge

/* Insert your model definition here */

global {
	
	int numberOfStages <- 4;
	int numberOfAspects <- 7;
	int numberOfAgents <- 20;
	bool pauseSimulation;
	bool resetSimulation;
	bool concertInSession;
	int globalRound;
	int numberOfRounds <- 2;
	list<stageAgent> cfpsSentList;
	list<guestAgent> agentsWithStageSelected;
	int globalUtility1;
	int globalUtility2;
	bool callingStage;
	list<guestAgent> agentsAtStage;
	point centerLocation <- {50, 50};
	
	init {
		create stageAgent number: numberOfStages {}
		create guestAgent number: numberOfAgents {} 
		create ticketCenter number: 1 {}
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
	rgb agentColor;
	bool cfpsSent;
	int initCycleCounter <- 0;
	int initCycle <- 0;
	int numberOfProposes;
	int round;
	list<guestAgent> agentsComing;
	//list<string> agentsComing;
	list<message> agentInfo;

	
	aspect default {
		draw square(7) at: location color: agentColor;
	}
	
	init {
		//////
	}	
	
	reflex cycleCounter when: !cfpsSent {
		if initCycleCounter < 1{
			initCycle <- cycle;
			initCycleCounter <- initCycleCounter + 1;
			if round = 0 {
				aspectQuality <- [rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(15, 30)];
			}
		}
		else if cycle - initCycle = 10000 {
			agentColor <- rgb(rnd(0,255), rnd(0, 255), rnd(0, 255));
			concertInSession <- true;
		} 
	}
	
	reflex announceAspects when: !cfpsSent and concertInSession and round <= 2 {
			round <- round + 1;
			write 'Round: ' + (globalRound + 1) + ' starts now! ------------------------------------------------------------------------------------' color: #orange;
			if round = 2{
				//write 'my name is ' + name + ' and my Crowd mass before modification is ' + aspectQuality[6] color: agentColor;
				write 'my name is ' + name + ' and ' + length(agentsComing) + ' VIP guests will be coming to my concert!' color: agentColor;
				if length(agentsComing) > 0 {
					aspectQuality[6] <- aspectQuality[6] * length(agentsComing);	
				}
				//write 'my name is ' + name + ' and my Crowd mass after modification is ' + aspectQuality[6] color: agentColor;
			}
			
			do start_conversation with: [ to :: list(guestAgent), protocol :: 'fipa-contract-net', 
				performative :: 'cfp', contents :: [stageAspects, aspectQuality, agentColor] ];
			cfpsSent <- true;
			add self to: cfpsSentList;
			write 'My name is ' + name + ' and my concert has begun at cycle ' + cycle + ' !' color: agentColor;
			write 'My aspects and qualities are: ' color: agentColor; 
			write '\t'+ stageAspects color: agentColor;
			write '\t'+ aspectQuality color: agentColor;
			if length(cfpsSentList) = numberOfStages{
				globalRound <- globalRound + 1;
			}
		}
	
//	reflex receiveCall when: callingStage {
//		agentInfo <- cfps;
//		if length(agentInfo) != 0 {
//			loop message over: agentInfo {
//				add message.sender to: agentsComing;
//			}
//		}
//		callingStage <- false;
//	}
	
	}


species guestAgent skills: [moving, fipa] {
	
	list<int> guestPreferences <- [rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(0, 10), rnd(0, 10), (int(flip(0.5)) * 2 - 1)];
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
	int ticketValue;
	int budget <- rnd(100, 600);
	
	
	aspect default {
		draw sphere(1.5) at: location color: agentColor;
	}
	init {
		write 'My name is ' + name + ' and my preferences are:';
		write '\t' + stageAspects;
		write '\t' + guestPreferences;
		if guestPreferences[6] = 1{
			agentColor <- #green;
			write '\t' + 'I like crowds!' color: agentColor;
		}
		else {
			agentColor <- #red;
			write '\t' + 'I dislike crowds!' color: agentColor;
		}
	}	
	
	reflex receiveStageInfo when: !cfpsReceived and length(utilityList) <= numberOfStages and concertInSession and globalRound <= numberOfRounds {
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
	
	reflex calculateUtilities when: length(utilityList) <= numberOfStages - 1 and concertInSession and globalRound <= numberOfRounds {
		loop stageNumber from: 0 to: numberOfStages - 1{
			int individualUtility;
			individualUtility <- int(calculateUtility(stageAgent(stageNumber)));
			add individualUtility to: utilityList;
			write 'The utility of ' + stageAgentList[stageNumber] + ' is ' + utilityList[stageNumber] color: rgb(nil);   
		}
		maxUtilityIndex <- utilityList index_of max(utilityList);
//		ask stageAgentList[maxUtilityIndex] {
//			myself.agentColor <- self.agentColor;
//		}
		write 'I am ' + name + ' and the max utility is ' + max(utilityList) color: agentColor;
		write 'I am ' + name + ' and I choose ' + stageAgentList[maxUtilityIndex] color: agentColor;
		if globalRound = 1 {
				globalUtility1 <- globalUtility1 + max(utilityList);
			}
			else if globalRound = 2{
				globalUtility2 <- globalUtility2 + max(utilityList);
				}
		stageSelected <- true;
		add self to: agentsWithStageSelected;
		if globalRound = 1 {
			ask stageAgent[maxUtilityIndex] {
				add myself to: self.agentsComing;
			}
//			do callStage (stageAgentList[maxUtilityIndex]);
		}
		if globalRound = 2 {
			targetPoint <-  {stageAgentList[maxUtilityIndex].location.x, stageAgentList[maxUtilityIndex].location.y};
		}
	}
	
	reflex moveToTarget when: stageSelected and concertInSession and globalRound = 2 and distance_to (location, targetPoint) != 0 {
		do goto target:targetPoint speed: 0.01;
		if distance_to (self, targetPoint) = 0 {
			add self to: agentsAtStage;
			ticketValue <- ticketValue - 1;
		}
	}
	
	reflex allAgentsSelected when: numberOfAgents = length(agentsWithStageSelected) and concertInSession and globalRound = 1 {
		do announceGlobalUtility();
		resetSimulation <- true;
	}
	
	reflex allAgentsArrived when: numberOfAgents = length(agentsAtStage) and concertInSession and globalRound <= numberOfRounds {
		do announceGlobalUtility();
		resetSimulation <- true;
	}
	
	reflex beIdle when: !stageSelected and !concertInSession and globalRound <= numberOfRounds and ticketValue != 0 {
		//agentColor <- rgb(nil);
		do wander speed: 0.25;
	}
	
	action announceGlobalUtility {
		if globalRound = 1 {
			write 'The global utility before crowd mass consideration is: ' + globalUtility1 color: #red;
		}	 
		else if globalRound = 2{
			write 'Global Utility before crowd mass modification is: ' + globalUtility1 color: #red;
			write 'Global Utility AFTER crowd mass modification is: ' + globalUtility2 color: #red;
			write 'Current number of agents in Festival is ' + numberOfAgents color: #red;
		}
	}
	
	reflex buyTicket when: !concertInSession and ticketValue = 0 {
		do goto target:centerLocation speed: 0.01;
		agentColor <- #black;
	}
	
//	action callStage (stageAgent stage) {
//		list<stageAgent> stageList;
//		add stage to: stageList;
//		do start_conversation with: [ to :: stageList, protocol :: 'fipa-contract-net', 
//		performative :: 'cfp', contents :: ['I am going to your concert!']];
//		callingStage <- true;
//	}
	
	reflex resetSimulation when: resetSimulation and globalRound <= numberOfRounds{
		ask stageAgent {
			self.initCycle <- 0;
			self.cfpsSent <- false;
			//agentColor <- nil;	
		}
		ask guestAgent {
			cfpsSentList <- [];
			stageSelected <- false;
			pauseSimulation <- true;
			cfpsReceived <- false;
			utilityList <- [];
			stageAgentList <- [];
			agentsAtStage <- [];
			//agentColor <- nil;
			agentsWithStageSelected <- [];
			if globalRound = 2 {
				concertInSession <- false;
				globalUtility1 <- 0;
				globalUtility2 <- 0;
				write 'Round: ' + globalRound + ' is now over ------------------------------------------------------------------------------------' color: #red;
				globalRound <- 0;
				ask stageAgent {
					self.initCycleCounter <- 0;
					self.round <- 0;
					self.agentsComing <- [];
					self.agentColor <- nil;
				}
			}
		}
	}
}

species ticketCenter {
	
	reflex generateTicket {
		ask guestAgent at_distance 0{
			if self.ticketValue = 0 {
				int ticketType <- rnd(1, 5);
				loop type from: ticketType to: 1 {
					write 'For your budget, the ticket I can offer you is type: ' + type color: #orange;
					if self.budget >= type * 50 {
						self.ticketValue <- ticketType;
						self.budget <- self.budget - self.ticketValue * 50;
						write '\t' + 'My name is ' + self.name + ' and I bought a ticket for ' + self.ticketValue + ' concerts!' color: #black;
						if self.guestPreferences[6] = 1{
							self.agentColor <- #green;
						}
						else {
							self.agentColor <- #red;
						}
						break;
					}
				}
				if self.agentColor = #black {
					write 'My name is ' + name + ' and I have no money left! I will leave this festival!' color: #violet;
					numberOfAgents <- numberOfAgents - 1;
					do die;
				}
			}	
		}
	}
	
	aspect default {
		draw square(7) at: centerLocation color: #black;
	}
	
	init {
		location <- centerLocation;
	}	
}

experiment Creative type: gui {
	output {
		display map type: opengl {
			species stageAgent;
			species ticketCenter;
			species guestAgent;
		}
	}
}


