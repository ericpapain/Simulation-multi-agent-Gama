

model danger_mapping

global {
	int point_dangereux <-10;
	
	init{
		create Centre number:1{
			// disposition de la position initial de notre centre
			location<-point(3,3);
		}
		create Point_Danger number:point_dangereux;
	}
	reflex term{
		list center <- list(Centre);
		if(center[0].fin_parcours){
			do pause;
		}
	}
	
}

species Robot skills:[moving]{
		
	float speed <-2.0;
	float rayon_observation <- 2.0;
	float rayon_communication <- 2.0;
	geometry region_deja_visiter <-nil;
	geometry region_non_encore_visiter <- copy(world.shape);
	geometry region_courante<-nil;
	list detected <-[];
	
	
	aspect basic{
		draw square(3) color:#blue;
		
		if(region_deja_visiter !=nil){draw region_deja_visiter color:#brown;}
	}
	
		// configuration des voisin visiter et des voisins non encore visiter
	reflex visiter{
		
		//mise a jour des voisins visiter pour le robot
		region_deja_visiter <- region_deja_visiter + (region_non_encore_visiter intersection circle(rayon_observation));
		
		//suppression de la voisin deja visiter des voisins deja visiter
		region_non_encore_visiter <- region_non_encore_visiter - circle(rayon_observation);
		
		list cible <- square(rayon_observation) closest_points_with(region_non_encore_visiter);
		do goto target: cible[1] speed:speed;
		do wander;
		
		
	}
	reflex rencontre_robot{
		
		//liste des robots dans un rayon d'observation et ajout dans les liste de voisins
		list<Robot> voisins <-  list(Robot) where ((each distance_to self)<=rayon_communication);
		
		list somme_total_des_voisin_geometry <-[];
		
		//variable de representation des voisins deja visiter
		geometry somme_region_deja_visiter<-nil;
		
		//variable de representation des voisins encore non visiter
		geometry somme_region_non_visiter <-nil;
		
		//variable de verification si la voisin est visiter ou pas
		bool state<-false;
		
		loop voisin over:voisins{
			if(voisin.detected!=detected){
				somme_total_des_voisin_geometry<-somme_total_des_voisin_geometry+voisin.detected;
				state<-true;
			}
			
			// mise a jour de la liste des zone deja visiter apres la rnecontre de 2 robots
			if(region_deja_visiter!=voisin.region_deja_visiter){
				somme_region_deja_visiter<-somme_region_deja_visiter + voisin.region_deja_visiter;
				state<-true;
			}
			
			//mise a niveau des region deja et non pas encore visiter par les robots
			if(region_non_encore_visiter!=voisin.region_non_encore_visiter){
				somme_region_non_visiter<-somme_region_non_visiter+ voisin.region_non_encore_visiter;
				state<-true;
			}
		}
		// verification d'une zone non pas encore visiter
		if(state){
			detected<-detected+somme_total_des_voisin_geometry;
			region_non_encore_visiter <-region_non_encore_visiter+somme_region_non_visiter;
			region_deja_visiter<-region_deja_visiter+somme_region_deja_visiter;
		}
		
	}
	reflex recherche_Point_Danger{
		
		list<Point_Danger> voisins <-  list(Point_Danger) where ((each distance_to self)<=rayon_observation);
		if(length(voisins)>0){
			loop voisin over:voisins{
			voisin.deja_visiter<-true;
			detected<<voisin;
			voisin.color <- #orange;
	}
		}
	
}

// retourner au centre
reflex revenir_au_centre when:(region_non_encore_visiter=region_deja_visiter){
	list<Centre> voisins <-  list(Centre) where ((each distance_to self)<=rayon_communication);
	if(length(voisins)>0){
		voisins[0].fin_parcours<-true;
	}
}

}
species Centre{
	bool fin_parcours <-false;
	init{
		create Robot number:6{
			location<-point(rnd(20),rnd(20));
		}
	}
	aspect basic{
		draw square(4) color:#green;
	}
	
	
	
}
species Point_Danger{
	bool deja_visiter <-false;
	int niveau <-rnd(6)+1;
	// definition de la couleur la gestion des controele superieure
	rgb color <-#gray;
	
	aspect basic{
		draw triangle(20) color: color;
		
	}
	
}

species Panneau{
	bool deja_visiter <-false;
	int niveau <-rnd(6)+1;
	aspect basic{
		draw circle(20) color:color;
	}
	
}


experiment danger_mapping type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display danger {
			species Robot aspect: basic;
			species Centre aspect: basic;
			species Point_Danger aspect: basic;
			species Panneau aspect:basic;
		}
	}
}