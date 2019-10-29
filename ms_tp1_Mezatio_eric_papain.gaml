/***
* Name: mstp1Mezatioericpapain
* Author: eric
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model mstp1Mezatioericpapain

global {
	/** Insert the global definitions, variables and actions here */
	
	 int N <- 30 ; 
     int K <- 3;
     int size_point;
     int size_center;
     int size <- 3;
    
	/*N-> parameter(definir comme on defini des parametres en gama).
	k ->parameter.
	size.centre, size.point.*/
	
	init{
		/*creer N PointNormal(par hasard)
		creer K centre 	(par hasard)*/
	
	create N number: N;
        
    create K number :K;
        
    }
}

species PointGeneral{
	/*-position
	-color
	-size*/
	
	point position;
	int size;
	rgb color <- #yellow;
	
	
}

/*species PointNormal : parent: pointGeneral {
	
	set size<-size_point:
	
		reflex detect_centre{
		 
		 let my_center value: first(list(centre) sort_by(select distance_to each));
		  color <- my_center.color:
		 }
		 
		
		 aspect base{
		 	draw circle(size) color (color);
		 }
		}
	
	}*/
	
species PointNormal{
	/*-position
	-color
	-size*/
	point position;
	int size;
	rgb color <- #yellow;
	
	}	

/*species Centre : parent: pointGeneral {
	
		reflex detect_position{
		 
		 let my_group value: list(PointNormal) where(each.color)=self.color);
		  
		  // calculer la position moyenne.
		 }
		 
		
		 aspect base{
		 	draw circle(size); color (color);
		 }
		}
	
	}*/	


species Centre {
	
	point position;
	int size;
	rgb color <- #red;
	
	reflex detect_position{
		 
		 let my_group value: (list(PointNormal) where(each.color)=self.color);
		  
		  // calculer la position moyenne.
		   x <- mean (my_group);
		 }
		 
		
		 aspect base{
		 	draw circle(size) color: color;
		 }
		}
	


experiment mstp1Mezatioericpapain type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
	}
}
