/***
* Name: FestivalBasicQueens
* Author: Wilfredo Robinson + Jhorman Perez
* Description: N Queens Problem
***/

model FestivalBasicQueens


global {
    
    int NUMBER_OF_NEIGHBORS <- 8; //# of neighbors for each cell for this simulation. 8 corresponds to Moore type neighbors (includes diagonals)
    int NUMBER_OF_QUEENS <- 10; //Total # of queens to be used for this simulation
    int globalRow;
    
    list<GridCell> GRID_CELLS;
    list<Queen> ALL_QUEENS;
    bool pauseSimulation;
    list<Queen> listOfQueens;
    
    init{
        create Queen number: NUMBER_OF_QUEENS;
        
        // Color even grid cells black
        int start <- 0;
        int end <- NUMBER_OF_QUEENS - 1;
        bool even <- true;

        loop r from: 0 to: NUMBER_OF_QUEENS - 1 {
        	loop i from: start to: end {
        		int modCalc <- mod(i, 2);
        		if (even and modCalc = 0) {
        			GridCell[i].color <- #black;
        		}
        		else if (!even and modCalc != 0) {
    				GridCell[i].color <- #black;
        		}
        	}
        	even <- !even;
        	start <- end + 1;
        	end <- end + NUMBER_OF_QUEENS;
        }
        
        int i <- 0;
        
        ask Queen {
        	self.index <- i;
        	add self to: listOfQueens;
        	i <- i + 1;
        }
        
        listOfQueens[0].doMove <- true;
    }
    
    /*
     * It stops the simulation once a solution has been found.
     * Then, it locates FinishedAgents on the board's free cells.
     */
    reflex pauseSimulation when: pauseSimulation {
    	write 'Solution found for the N Queens problem!' color: #green;
    	
		list<point> emptyPositions <- [];
		ask GridCell {
    		if (self.queen = nil) {
    			add {self.location.x, self.location.y} to: emptyPositions;
    		}
    	}
    	
    	loop pos over: emptyPositions {
    		create FinishedAgent number: 1 { position <- pos; }
    	}
    	
    	do pause;
    }
    
}

species Queen {
	
	int index;
	int currentColumn;
	bool hasBeenMoved;
	bool doMove <- false;
	Queen child <- nil;
    GridCell queenCell;
    list<list<int>> occupancyGrid;
    
    init {
    	
    	// Each Queen is assigned a different row on the board
    	loop cell over: GridCell {
    		if (cell.grid_y = globalRow){
    			queenCell <- cell;
    			globalRow <- globalRow + 1;
    			break;
    		}
    	}

        location <- queenCell.location;
        queenCell.queen <- self;
        
        // Once the Queen has been moved to a new cell, it will add itself to the ALL_QUEENS list
        add self to: ALL_QUEENS;
        
        // Calls the action clearOccupancyGrid
        do clearOccupancyGrid;
        
        // Start the search 
        write 'Initial position of ' + name + ' defined!' color: #blue;
    }
    
    aspect base {
        draw sphere(2.0) color: #blue ;
    }

    
    /* ACTIONS */
    
    action clearOccupancyGrid {
    	// Generates a matrix that represents the physical grid map. 
    	// Fills all the cells with zeroes (0)
        self.occupancyGrid <- [];
        list<int> cells;
        
        loop row from: 0 to: NUMBER_OF_QUEENS - 1 {
        	cells <- [];
            loop col from: 0 to: NUMBER_OF_QUEENS - 1 {
                add 0 to: cells;
            }
            add cells to: occupancyGrid;
        }
        
        if (index = 0){
    		ask Queen {
    			self.hasBeenMoved <- false;
    		}
    	}
    }
    
    /*
     * Identifies where all queens are in the physical grid map.
     */
    action calculateOccupancyGrid {
        // First fills all cells with zeroes to correctly update all cell values
        do clearOccupancyGrid;
        
        // Identifies which cells of the grid map currently include Queens
        loop cell over: GRID_CELLS {
            if cell.queen != nil and cell.queen != self and cell.queen.hasBeenMoved {
                self.occupancyGrid[cell.grid_x][cell.grid_y] <- 1000;
            }
        }
        
        // Once the queen locations have been updated, analizes each one of these cells
        loop cell over: GRID_CELLS {
            int m <- cell.grid_x;
            int n <- cell.grid_y;
            // If a queen is found, every cell in all directions from this queen 
            // is added a +1 to its current value. 
            if self.occupancyGrid[int(m)][int(n)] = 1000 {
                loop i from: 1 to: NUMBER_OF_QUEENS {
                    
                    // Marking path to the right of current Queen position
                    int mi <- int(m) + i;
                    if mi < NUMBER_OF_QUEENS {
                        self.occupancyGrid[mi][n] <- self.occupancyGrid[mi][n] + 1;
                    }
                    
                    // Marking path to the left of current Queen position
                    int n_mi <- int(m) - i;
                    if n_mi > -1 {
                        self.occupancyGrid[n_mi][n] <- self.occupancyGrid[n_mi][n] + 1;
                    }
                    
                    // Marking path below current Queen position
                    int ni <- int(n) + i;
                    if ni < NUMBER_OF_QUEENS {
                        self.occupancyGrid[m][ni] <- self.occupancyGrid[m][ni] + 1;
                    }
                    
                    // Marking path above current Queen position
                    int n_ni <- int(n) - i;
                    if n_ni > -1 {
                        self.occupancyGrid[m][n_ni] <- self.occupancyGrid[m][n_ni] + 1;
                    }
                    
                    // Marking path top right current Queen position
                    if mi < NUMBER_OF_QUEENS and ni < NUMBER_OF_QUEENS {
                        self.occupancyGrid[mi][ni] <- self.occupancyGrid[mi][ni] + 1;
                    }
                    
                    // Marking path bottom right current Queen position
                    if n_mi > -1 and ni < NUMBER_OF_QUEENS {
                        self.occupancyGrid[n_mi][ni] <- self.occupancyGrid[n_mi][ni] + 1;
                    }
                    
                    // Marking path top left current Queen position
                    if mi < NUMBER_OF_QUEENS and n_ni > -1 {
                        self.occupancyGrid[mi][n_ni] <- self.occupancyGrid[mi][n_ni] + 1;
                    }
                    
                    // Marking path bottom left current Queen position
                    if n_mi > -1 and n_ni > -1 {
                        self.occupancyGrid[n_mi][n_ni] <- self.occupancyGrid[n_mi][n_ni] + 1;
                    }
                }
            }
        }
    }
     
    /*
     * Function that checks every cell in the physical grid map and adds it to a list 
     * if it is unoccupied. This function returns a list of all unoccupied cells (value 0 by default).
     */
    list<point> getAvailableCells(int cellValue <- 0) {
        list<point> availableCells;
        
        loop cell over: GRID_CELLS {
            int m <- cell.grid_x;
            int n <- cell.grid_y;
            if (n = queenCell.grid_y and (m > queenCell.grid_x or !hasBeenMoved) and 
            	self.occupancyGrid[int(m)][int(n)] = cellValue){
            	add {int(m), int(n)} to: availableCells;
            }
        }
        write 'I am ' + name + ' and my availableCells are ' + availableCells;
        return availableCells;
    }
    
    /*
     * Gets the predecessor Queen, the one in the previous row (up).
     */
    Queen identifyPredecessor(int x) {
    	
    	list<Queen> predecessor;
    	
    	loop cell over: GRID_CELLS {
            int m <- cell.grid_x;
            int n <- cell.grid_y;
            
            if self.occupancyGrid[m][n] > 999 {
            	if n = self.queenCell.grid_y - 1 {
            		add cell.queen to: predecessor;
            	}
            }
        }
    	
    	if length(predecessor) > 0 {
    		return predecessor[rnd(0, length(predecessor)-1)];
    	}
		return nil;
    }
    
    /*
     * Places the Queen in an available cell if there is at least one.
     * Otherwise, it asks the Queen's predecessor to move.
     */
    action moveQueen {
    	do calculateOccupancyGrid();
    	list<point> availableCells <- getAvailableCells();
    	
    	// If there are available cells, move to next one (the next possible column)
    	if (length(availableCells) > 0) {
    		write 'I am ' + name + ' (' + queenCell.grid_x + ', ' + queenCell.grid_y 
    		+ ") and I can move to: " + availableCells color: #violet;

    		point availablePosition <- availableCells[rnd(length(availableCells) - 1)];
    		//point availablePosition <- availableCells[0];
    		currentColumn <- currentColumn + 1;
    		
    		loop cell over: GRID_CELLS {
    			if (cell.grid_x = availablePosition.x and cell.grid_y = availablePosition.y 
    				and cell.queen = nil
    			) {
    				queenCell.queen <- nil;
    				queenCell <- cell;
    				location <- cell.location;
    				queenCell.queen <- self;
    				write 'I am ' + name + ' and I moved to (' + queenCell.grid_x + ', ' 
    				+ queenCell.grid_y + ')' color: #violet;
    				break;
    			}
    		}
    		doMove <- false;
    		hasBeenMoved <- true;
    		
    		if (child = nil) {
    			if (index + 1 < NUMBER_OF_QUEENS){
					write 'Letting the next Queen place itself (' + listOfQueens[index + 1] + ')';
					listOfQueens[index + 1].doMove <- true;
				}
    		}
    		
			else {
				write 'Letting the child Queen place itself ' + child;
				child.doMove <- true;
			}
    	}
    	else {
    		currentColumn <- 0;
    		hasBeenMoved <- false;
    		 write 'I am ' + name + ' (' + self.queenCell.grid_x + ', ' 
    		 + self.queenCell.grid_y + ') , and I am unable to move from: (' + self.queenCell.grid_x + ", " + self.queenCell.grid_y + ')';
    		
    		// If there are no available cells, tell your predecessor to move!
    		Queen queenInPath <- identifyPredecessor(0);
    		
    		if queenInPath != nil {
    			GridCell queenInPathCell;
    			GridCell target;
    			float distance <- 1000.0;
    			ask queenInPath {
    				write 'I am ' + myself.name + ' (' + myself.queenCell.grid_x + ', ' 
    				+ myself.queenCell.grid_y + ') and I need help!' color: #red;
					write 'Hey ' + self.name + ' (' + self.queenCell.grid_x + ' ,' 
					+ self.queenCell.grid_y + '), could you please move?';
    				queenInPathCell <- self.queenCell;
    				self.doMove <- true;
    				self.child <- myself;
    			}
    		}
    	}
    	self.doMove <- false;
		listOfQueens[index].doMove <- false;
	}
    
    /*
     * Makes moveQueen happen in a controlled state.
     */
    reflex runQueenMoves when: !pauseSimulation and doMove {
    	
    	do moveQueen;
    	
    	bool allQueensPlaced <- true;
	    ask Queen {
	    	if (!self.hasBeenMoved) {
	    		allQueensPlaced <- false;
	    		break;
	    	}
	    }
	    pauseSimulation <- allQueensPlaced;
    }
    
}

species FinishedAgent {
	
	point position;
	
	aspect {
		draw sphere(1.0) color: #red at: position;
	}
	
}

grid GridCell width: NUMBER_OF_QUEENS height: NUMBER_OF_QUEENS neighbors: NUMBER_OF_NEIGHBORS {
    list<GridCell> neighbours  <- (self neighbors_at 2);
    Queen queen <- nil;
    
    init{
        add self to: GRID_CELLS;
    }
}

experiment main type: gui {
    output {
        display main_display {
            grid GridCell lines: #black;
            species Queen aspect: base;
            species FinishedAgent;
        }
    }
}
