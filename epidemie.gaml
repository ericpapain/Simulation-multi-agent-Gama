/**
* Name: Automatic repair of roads
* Author:
* Description: 7th part of the tutorial: Road Traffic
* Tags: transport
*/

model tutorial_gis_city_traffic

global {
	file shape_file_buildings <- file("../includes/building.shp");
	file shape_file_roads <- file("../includes/road.shp");
	file shape_file_bounds <- file("../includes/bounds.shp");
	geometry shape <- envelope(shape_file_bounds);
	
	float step <- 10 #mn;
	int distance_infection <- 2;
	int nb_people <- rnd(50, 100);
	int current_hour update: (time / #hour) mod 24;
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16; 
	int max_work_end <- 20; 
	float min_speed <- 1.0 #km / #h;
	float max_speed <- 5.0 #km / #h; 
	float destroy <- 0.02;
	int repair_time <- 2 ;
	graph the_graph;
	int rayon_contamination <- 5;
	
	init {
		
		
		create building from: shape_file_buildings with: [type::string(read ("NATURE"))] {
			if type="Industrial" {
				color <- #yellow ;
				border <- #black;
			} else if type="Hospital" {
				color <- #green;
				border <- #black;
			} else {
				color <- #gray;
				border <- #black;
			}
		}
		create road from: shape_file_roads ;
		map<road,float> weights_map <- road as_map (each:: (each.destruction_coeff * each.shape.perimeter));
		the_graph <- as_edge_graph(road) with_weights weights_map;
		
		
		list<building> residential_buildings <- building where (each.type="Residential");
		list<building>  industrial_buildings <- building  where (each.type="Industrial") ;
		list<building>  hopital_buildings <- building  where (each.type="Hospital") ;
		
		create people number: nb_people {
			state <- rnd(1, 3);
			speed <- min_speed + rnd (max_speed - min_speed) ;
			start_work <- min_work_start + rnd (max_work_start - min_work_start) ;
			end_work <- min_work_end + rnd (max_work_end - min_work_end) ;
			living_place <- one_of(residential_buildings) ;
			working_place <- one_of(industrial_buildings) ;
			healing_place <- one_of(hopital_buildings);
			objective <- "resting";
			location <- any_location_in (living_place); 
		}
		
		
		create medecin number: 10 {
			color <- #pink;
			state <- rnd(1, 3);
			speed <- min_speed + rnd (max_speed - min_speed) ;
			start_work <- min_work_start + rnd (max_work_start - min_work_start) ;
			end_work <- min_work_end + rnd (max_work_end - min_work_end) ;
			living_place <- one_of(residential_buildings) ;
			working_place <- one_of(industrial_buildings) ;
			objective <- "resting";
			location <- any_location_in (living_place); 
		}
	}
	
	reflex update_graph{
		map<road,float> weights_map <- road as_map (each:: (each.destruction_coeff * each.shape.perimeter));
		the_graph <- the_graph with_weights weights_map;
	}
	reflex repair_road when: every(repair_time #hour ) {
		road the_road_to_repair <- road with_max_of (each.destruction_coeff) ;
		ask the_road_to_repair {
			destruction_coeff <- 1.0 ;
		}
	}
}

species building {
	string type; 
	rgb color <- #gray  ;
	rgb border <- #black;
	
	aspect base {
		draw shape color: color border: border;
	}
}


species hopital parent: building {
	
}

species road  {
	float destruction_coeff <- 1 + ((rnd(100))/ 100.0) max: 2.0;
	int colorValue <- int(255*(destruction_coeff - 1)) update: int(255*(destruction_coeff - 1));
	rgb color <- rgb(min([255, colorValue]),max ([0, 255 - colorValue]),0)  update: rgb(min([255, colorValue]),max ([0, 255 - colorValue]),0) ;
	
	aspect base {
		draw shape color: color ;
	}
}

species Human skills:[moving]  {
	rgb color;
	int state;
	building living_place <- nil ;
	building working_place <- nil ;
	building healing_place <- nil;
	int start_work ;
	int end_work  ;
	string objective ; 
	point the_target <- nil ;
		
	reflex time_to_work when: current_hour = start_work and objective = "resting"{
		objective <- "working" ;
		the_target <- any_location_in (working_place);
	}
		
	reflex time_to_go_home when: current_hour = end_work and objective = "working"{
		objective <- "resting" ;
		the_target <- any_location_in (living_place); 
	} 
	  
	reflex move when: the_target != nil {
		path path_followed <- goto(target:the_target, on:the_graph, return_path: true);
		list<geometry> segments <- path_followed.segments;
		loop line over: segments {
			float dist <- line.perimeter;
			ask road(path_followed agent_from_geometry line) { 
				destruction_coeff <- destruction_coeff + (destroy * dist / shape.perimeter);
			}
		}
		if the_target = location {
			the_target <- nil ;
		}
	}
	

}
species people parent: Human {
	
    list<people> targets;
	
	reflex infect {
		ask people at_distance(distance_infection){
			if self.state = 3 {
				myself.color <- #red;
				myself.state <- 3;
			}
		}
	}
	
	
	reflex contaminer_zone {
	
		if self.state = 3 {
			do create_zone_contamination();	
		} 
	}
	
	action create_zone_contamination {
		create virus number: 1 {
			age <- 1;
			rayon_contagion <- 1;
			position <- self.location;
		}
	}

	
	reflex verifier_etat {
		if state = 1 {
			color <- #blue;
		} else if state = 2 {
			color <- #green;
		} else {
			color <- #red;
		}
	}
	
	aspect base {
		if self.state = 3 {
			draw circle(10) color: color border: #black;
		} else if self.state = 2 {
			draw triangle(25) color: color border: #black;
		} else {
			draw square(20) color: color border: #black;
		}
	}
}

species virus {
	int age;
	int rayon_contagion;
	int max_age <- int(7);
	rgb color <- #purple;
	int speed_grow <- 1;
	point position;
	
	reflex mourir {
		if age >= max_age {
			do die;
		}
	}
	
	reflex grandir {
		if speed_grow >= 5 {
			rayon_contagion <- rayon_contagion + 1;
			speed_grow <- 1;
			age <- age + 1;
		}
		speed_grow <- speed_grow + 1;
	}
	
	
	reflex contaminer {
		list nearest_agents <- agents_at_distance(2) ;
//		list<people> targets;
		
//		ask targets as: people {
		
		if (length(nearest_agents) > 0) {
			loop i from:0 to: (length(nearest_agents) - 1) {
				people ag <- (people(nearest_agents at i));
				if (ag != nil){
					if ag.state = 1 or ag.state = 2 {
						ag.color <- #pink;
						ag.state <- 3;
							
					}	
				}
				
			}
		}
		
//			if self distance_to targets <= 2 {
//				if myself is people and myself.state = 1 or myself.state = 2 {
//					myself.color <- #red;
//					myself.state <- 3;
//				}
//			}
		}
	
//	}
	
	aspect base {
		draw circle(rayon_contagion) color: color;
	}
}

species medecin parent: Human {
	
//	reflect soigner {
//		if self distance_to people <= 2 {
//			people.state <- 2;
//			people.color <- #yellow;
//		}
//	}
	aspect base {
		draw circle(10) color: color border: #black;
	}
	
}

experiment epidemie_grippe type: gui {
	parameter "Shapefile for the buildings:" var: shape_file_buildings category: "GIS" ;
	parameter "Shapefile for the roads:" var: shape_file_roads category: "GIS" ;
	parameter "Shapefile for the bounds:" var: shape_file_bounds category: "GIS" ;
	parameter "Number of people agents" var: nb_people category: "People" ;
	parameter "Earliest hour to start work" var: min_work_start category: "People" min: 2 max: 8;
	parameter "Latest hour to start work" var: max_work_start category: "People" min: 8 max: 12;
	parameter "Earliest hour to end work" var: min_work_end category: "People" min: 12 max: 16;
	parameter "Latest hour to end work" var: max_work_end category: "People" min: 16 max: 23;
	parameter "minimal speed" var: min_speed category: "People" min: 0.1 #km/#h ;
	parameter "maximal speed" var: max_speed category: "People" max: 10 #km/#h;
	parameter "Value of destruction when a people agent takes a road" var: destroy category: "Road" ;
	parameter "Number of hours between two road repairs" var: repair_time category: "Road" ;
	
	output {
		display city_display type:opengl {
			species building aspect: base ;
			species road aspect: base ;
			species people aspect: base ;
			species virus aspect: base;
			species medecin aspect: base;
		}
//		display chart_display refresh: every(10#cycles) { 
//			chart "Road Status" type: series size: {1, 0.5} position: {0, 0} {
//				data "Mean road destruction" value: mean (road collect each.destruction_coeff) style: line color: #green ;
//				data "Max road destruction" value: road max_of each.destruction_coeff style: line color: #red ;
//			}
//			chart "People Objectif" type: pie style: exploded size: {1, 0.5} position: {0, 0.5}{
//				data "Working" value: people count (each.objective="working") color: #magenta ;
//				data "Resting" value: people count (each.objective="resting") color: #blue ;
//			}
//		}
	}
}