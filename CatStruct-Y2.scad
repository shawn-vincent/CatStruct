/* -*- mode: c -*-
 * CatStruct-Plate.scad
 * Parametric generator of plates and flanged plates for the CatStruct system.
 * 2025 Shawn Vincent <svincent@svincent.com>
 */

include <gears.scad>

/*
TODO:
  consider laying out cells in the grid using some kind of map of cell type/position/rule specifiers that can be configured.  This is too powerful for the Customizer pane, but for programatic stuff gives a ton of power.  ("throughHole",EVEN_CELLS_X,EVEN_CELLS_Y,Z==1).

  Also support different types of meshes.
*/

// ------------------------------------------------
// Parameters
// ------------------------------------------------
/* [Main] ----------------------------- */
// Type of element to generate
element_type = "flanged_plate"; // ["flanged_plate","plate","block","polygon_plate","pulley","gear","servo_plate","pin"]
// Number of holes in X axis (count)
nx = 3;
// Number of holes in Y axis (count)
ny = 3;
// Number of holes in Z axis (count, only for blocks)
nz=1;

// Number of sides of plate (allows polygons, rounds)
sides=4;

// thickness of the generated plate (mm)
h = 3;

// thickness of the flanges (mm)
flange_thickness = 3;

// index divisor of through holes (1=every cell, 2=every 2nd, ...)  through_holes override tapped_holes by default
through_holes = 2;

// index divisor of tapped holes (1=every cell, 2=every 2nd, ...)
tapped_holes = 1;

// offset holes (if you want a specific cell in the middle, for example)
offset_holes_x = 0;

// offset holes (if you want a specific cell in the middle, for example)
offset_holes_y = 0;

/* [Advanced Configuration] */

// spacing of holes(mm)
spacing = 10;


threshold = -23;

_debug=false;


// preconfigured shapes from UI.
if (_debug) {

  nx=8;
  ny=8;

  x = height_limits (feature_grid
		     =modulo_replace(feature_grid
				     =feature_grid(nx,ny,"tapped"),
				     type="through",
				     mx=2,my=2),
		   h=11,
		   min_height=3, min_height_replacement="through",
		   max_height=10, max_height_replacement="tapped");

  // echo(x);
  print_feature_grid(x);
  

  //  catstruct_flanged_plate(nx=2, ny=7, h=1, flange_thickness=1);
} else if (element_type == "flanged_plate") {
  catstruct_flanged_plate(nx=nx, ny=ny, h=h, flange_thickness=flange_thickness);
} else if (element_type == "plate") {
  catstruct_plate(nx=nx, ny=ny, h=h);
} else if (element_type == "block") {
  catstruct_block(nx=nx, ny=ny, nz=nz);
} else if (element_type == "polygon_plate") {
  catstruct_polygon_plate(nx=nx, ny=ny, sides=sides, h=h);
} else if (element_type == "pulley") {
  catstruct_pulley(nx=nx, ny=ny, h=h);
} else if (element_type == "gear") {
  catstruct_gear(nx=nx,ny=ny, h=h);
} else if (element_type == "servo_plate") {
  catstruct_servo_plate(nx=nx, ny=ny, h=h, flange_thickness=flange_thickness);
} else if (element_type == "pin") {
  catstruct_pin(pin_length=h,pin_d=3);
} else {
  assert(false, str("Unknown element type: ", element_type));
}



// ------------------------------------------------
// Plates and flanged plates
// ------------------------------------------------

module catstruct_plate(nx, ny, h) {
    _catstruct_grid(nx=nx, ny=ny, h=h);
}

module catstruct_flanged_plate(nx, ny, h, flange_thickness,
			       sides=[true,true,true,true]) {
  echo(sides);

  rotate([180, 0, 0]) {
        translate([0, 0, (spacing/2 - h/2)]) {
            _catstruct_grid(nx=nx, ny=ny, h=h);
	}
	_catstruct_plate_flanges(nx, ny, h, flange_thickness,sides=sides);
    }
}

module _catstruct_plate_flanges(nx, ny, h, flange_thickness,
				sides) {
  width = nx * spacing;
  height = ny * spacing;

  echo(sides);
  
  for (i=[-1,1]) {
    if((i==1 && sides[1]) || (i==-1 && sides[3])) {
      translate([i * (width - flange_thickness) / 2, 0, 0])
        rotate([90, 0, i * 90])
        _catstruct_flange(ny, flange_thickness);
    }
  }
  
  for (i=[-1,1]) {
    if((i==1 && sides[0]) || (i==-1 && sides[2])) {
      translate([0, i * -(height - flange_thickness) / 2, 0])
        rotate([90, 0, i > 0 ? 0 : 180])
        _catstruct_flange(nx, flange_thickness);
    }
  }
  
}

module _catstruct_flange(nx, h) {
    _catstruct_grid(nx=nx, ny=1, h=h);
}

// ------------------------------------------------
// Block
// ------------------------------------------------

module catstruct_block(nx, ny, nz) {
  difference() {
    union() {
      _catstruct_grid(nx=nx, ny=ny, h=nz * spacing,hole=false,mesh=false);
      rotate([90,0,0])
	_catstruct_grid(nx=nx, ny=nz, h=ny * spacing,hole=false,mesh=false);
      rotate([90,0,90])
	_catstruct_grid(nx=ny, ny=nz, h=nx * spacing,hole=false,mesh=false);
    }

    union() {
      _catstruct_grid(nx=nx, ny=ny, h=nz * spacing,solid=false,mesh=false);
      rotate([90,0,0])
	_catstruct_grid(nx=nx, ny=nz, h=ny * spacing,solid=false,mesh=false);
      rotate([90,0,90])
	_catstruct_grid(nx=ny, ny=nz, h=nx * spacing,solid=false,mesh=false);
    }

  }    
}


// ------------------------------------------------
// Polygon Plate
// ------------------------------------------------

module catstruct_polygon_plate(cell_config=undef, nx, ny, sides, h) {

  
  _cell_config =
    polygon_bound(cell_config!=undef ? cell_config : _default_cell_config(nx, ny, h),
		  dx=nx,dy=ny,sides=sides);

  
  border_width = 2;
  difference() {
    prism(n=sides, d=1, scale_x=nx*spacing, scale_y=ny*spacing, h=h);
    prism(n=sides, d=1, scale_x=nx*spacing-border_width*2, scale_y=ny*spacing-border_width*2, h=h);
  }
  
  print_feature_grid(_cell_config);

  intersection() {
    prism(n=sides, d=1, scale_x=nx*spacing, scale_y=ny*spacing, h=h);
    _catstruct_grid(cell_config=_cell_config, h=h);
  }
}

// ------------------------------------------------
// Pulley
// ------------------------------------------------

module catstruct_pulley(nx, ny, h) {

  assert(nx==ny, "Pulleys must be round (nx==ny)");

  cell_config = _default_cell_config(nx, ny, h);

  intersection() {

    difference() {
      union() {
	catstruct_polygon_plate(cell_config=cell_config, nx=nx, ny=ny, sides=64, h=h);
	if(nx>=2&&ny>=2)
	  _catstruct_hub_solid(h,spacing);
      }
      if(nx>=2&&ny>=2)
	_catstruct_hub_hole(h,spacing);
    }


    union() {
      translate([0,0,h/2/2])
	prism(n=64, d_top=nx*spacing-.5, d_bot=ny*spacing-4, h=h/2);
      translate([0,0,-h/2/2])
	prism(n=64, d_top=nx*spacing-4, d_bot=ny*spacing-.5, h=h/2);
    }
  }

}



// ------------------------------------------------
// Gear
// ------------------------------------------------

module catstruct_gear(nx, ny, h) {

  assert(nx==ny, "Pulleys must be round (nx==ny)");

  cell_config = _default_cell_config(nx, ny);


  difference() {
    // GEAR
    translate([0,0,-h/2])
      spur_gear(modul=1,tooth_number=nx*spacing,width=h,bore=.001,optimized=false);
    prism(n=32,d=nx*spacing-5,h=h);
  }
  
  
  intersection() {
    prism(n=32,d=nx*spacing-5,h=h);
    
    difference() {
      union() {
	catstruct_polygon_plate(cell_config=cell_config, nx=nx, ny=ny, sides=64, h=h);
	if(nx>=2&&ny>=2)
	  _catstruct_hub_solid(h,spacing);
      }
      if(nx>=2&&ny>=2) {
	_catstruct_hub_hole(h,spacing);
      }
    }
  }
}

// ------------------------------------------------
// Servo Plate
// ------------------------------------------------

module catstruct_servo_plate(nx, ny, h, flange_thickness) {
}

module catstruct_servo_plate_old_and_busted(nx, ny, h, flange_thickness) {

  edge_to_servo_shaft = 10.4; // for interest -- this still matters.
  hole_spacing = 10;
  hole_size = 3;

  difference() {
    union() {
      catstruct_flanged_plate(nx=4,ny=2,h=h,flange_thickness=flange_thickness,
			      sides=[true,true,false,true]);
      
      // make a pentagon-ended block to hold the holes
      translate([0,-spacing/2+3/2,-spacing/2+h/2])
	prism_ended_bar(6, d=spacing+3, length=spacing*2, h=h,chamfer=_chamfer(h));
    }

    // holes
    for(x=[-hole_spacing/2,hole_spacing/2])
      translate([x,-spacing,0])
	rotate([0,0,90])
	  prism_ended_bar(n=8,d=2.5,length=20,h=10);
  }

  /*
  difference() {
    union() {
      catstruct_flanged_plate(nx=nx,ny=ny,h=h,flange_thickness=flange_thickness);
      %translate([0,0,-spacing/2+h/2])
	prism(n=4,
	      d=1,
	      scale_x=servo_width+servo_ease+reinforcement*2,
	      scale_y=servo_length+edge_to_holes+hole_size/2+servo_ease+reinforcement*2,
	      h=h);
    }
  
    for(ix=[-1,1])
      for(iy=[-1,1])
	translate([ix*hole_spacing/2,iy*(servo_length/2+edge_to_holes),0])
	  prism(n=4,d=1,scale_x=hole_size,scale_y=edge_to_holes*2-reinforcement/2,h=10);

    prism(n=4,
      d=1,
      scale_x=servo_width+servo_ease,
      scale_y=servo_length+servo_ease,
      h=10);
  }


  #prism(n=4,
         d=1,
	 scale_x=servo_width,
	 scale_y=servo_length,
	 h=40);
  */
  
}


/*
 * A snap-in pin design for 3.4mm chamfered holes.  Works suprsisingly
 * well!  Could obviously be better.
 */
module catstruct_pin(pin_length,pin_d) {
  // default pin has two identical sides.  Imagine other types of pins with different attachments.
  translate([0,0,pin_length/2])
    catstruct_pin_half(pin_length,pin_d);
  
  translate([0,0,-pin_length/2])
    mirror([0,0,1])
      catstruct_pin_half(pin_length,pin_d);
}

module catstruct_pin_half(pin_length,pin_d) {

  chamfer=_chamfer(pin_length);

  slot_length=pin_length-chamfer;
  slot_width=pin_d/3;

  difference() {

    union() {
      // main pin length
      difference()
	{
	  union() {
	    // main pin
	    prism(n=8,d=pin_d,h=pin_length);
	    
	    // manuallty add bottom chamfer
	    translate([0,0,-pin_length/2+chamfer/2])
	      prism(n=8,d_bot=pin_d+chamfer*2,d_top=pin_d,h=chamfer);

	    // add top snapping "tooth": basicaly half a chamfer.
	    translate([0,0,pin_length/2-chamfer/2])
	      // do 6 chamfers (every side but the slot side.
	      for(rot=[0,45,-45])
		rotate([0,0,rot])
		  for(i=[-1,1])
		    translate([i*pin_d/2,0,0])
		      rotate([90,45,0])
		      prism(n=4,d=chamfer/sqrt(2),h=slot_width*1.3);
	  }
	  
	  // slot
	  translate([0,0,pin_length/2-slot_length/2])
	    {
	      translate([0,0,(slot_width/2)/2])
		prism(n=4,d=1,scale_x=slot_width,scale_y=pin_d*2,
		      h=slot_length-slot_width/2);
	      
	      translate([0,0,-slot_length/2+slot_width/2])
		rotate([90,0,0])
		prism(n=16,d=slot_width,h=pin_d+.001);
	    }
	}
    }

    // slide off one side to make it printable.
    translate([0,pin_d*.9+chamfer,0])
      prism(n=4,d=pin_d+2*chamfer,h=pin_length);
  }

}



// ------------------------------------------------
// Grid and Cells
// ------------------------------------------------

function _default_cell_config(nx,ny,h) =
  height_limits(
      reflect_symmetrical
          (modulo_replace
               (modulo_replace
  	           (feature_grid(nx,ny, "empty"),
		    "tapped",tapped_holes,tapped_holes,
		    offset_holes_x, offset_holes_y),
		"through",through_holes,through_holes,
		offset_holes_x, offset_holes_y),
	   true, true),
      h=h,
      min_height=3, min_height_replacement="through",
      max_height=10, max_height_replacement="tapped");

module _catstruct_grid(cell_config=undef, nx=undef, ny=undef, h, solid=true, hole=true, mesh=true) {
  _cell_config =
    (cell_config == undef)
    ? _default_cell_config(nx,ny,h)
    : cell_config;

  assert(_cell_config!=undef);
  print_feature_grid(_cell_config);
  
  _nx=_nx(_cell_config); 
  _ny=_ny(_cell_config);

  width = _nx * spacing;
  height = _ny * spacing;
  

  for (iy = [0:_ny-1]) {
    for (ix = [0:_nx-1]) {
      xtrans = ix * spacing - width / 2 + spacing / 2;
      ytrans = iy * spacing - height / 2 + spacing / 2;
      translate([xtrans, ytrans, 0]) {
	let(cell = _cell_config[iy][ix]) {
	  difference() {
	    union() {
	      if(solid)
		_catstruct_cell_solid(h, spacing, get_feature(cell));
	      if (mesh) {
		_catstruct_mesh(ix, iy, _nx, _ny, h, spacing);
	      }
	    }
	    if(hole)
	      _catstruct_cell_hole(h, spacing, get_feature(cell));
	  }
	}
      }
    }
  }
}



module _catstruct_cell_solid(h, spacing, cell_type) {
    if (cell_type == "through") {
        _catstruct_through_solid(h, spacing);
    } else if (cell_type == "tapped") {
        _catstruct_tapped_solid(h, spacing);
    } else if (cell_type == "hub") {
        _catstruct_hub_solid(h, spacing);
    } else {
        _catstruct_empty_solid(h, spacing);
    }
}

module _catstruct_cell_hole(h, spacing, cell_type) {
    if (cell_type == "through") {
        _catstruct_through_hole(h);
    } else if (cell_type == "tapped") {
        _catstruct_tapped_hole(h);
    } else if (cell_type == "hub") {
        _catstruct_hub_hole(h);
    } else {
        _catstruct_empty_hole(h);
    }
}

/*
 * 🛠 Fixed: Ensure through and tapped cells actually generate HOLES
 */
module _catstruct_through_solid(h, spacing) {
  prism(n=8, d=spacing, h=h,chamfer=_chamfer(h));
}
module _catstruct_through_hole(h) {
  // normally through holes will be limit4ed to 10mm due to height
  // restrictions in the grid pattern.  But they can go all the way
  // through (maybe for axles or something?)
  prism(n=8, d=3.4, h=h,chamfer=-_chamfer(h)/2);
}

module _catstruct_tapped_solid(h, spacing) {
  prism(n=6, d=spacing-3, h=h,chamfer=_chamfer(h));
}

module _catstruct_tapped_hole(h) {

  // don't bother tappinga hole longer than 20mm.  Just do 10 from each side.
  if(h>20) {
    translate([0,0,h/2-10/2])
      tapped_hole(h=10, d=3);
    translate([0,0,-h/2+10/2])    
      tapped_hole(h=10, d=3);    
  } else {
    tapped_hole(h=h+0.01, d=3);
  }
}


module _catstruct_empty_solid(h, spacing) {
    prism(n=8, d=spacing-3, h=h,chamfer=_chamfer(h));
}
module _catstruct_empty_hole(h) {
}

module _catstruct_hub_solid(h, spacing) {
  intersection() {
    prism(n=4, d=spacing*2-3, h=h,chamfer=_chamfer(h));
    prism(n=8, d=spacing*(2+.3)-3, h=h,chamfer=_chamfer(h));
  }
}
module _catstruct_hub_hole(h, spacing) {
  union(){
    // hub holes
    _catstruct_through_hole(h=h); // through hole in center
    
    // 5mm grid of holes around hub (to connect hubs together)
    for(ix=[-1:1])
      for (iy=[-1:1])
	if (!(ix==0&&iy==0))
	  translate([ix*spacing/2,iy*spacing/2,0])
	    _catstruct_tapped_hole(h=h);
  }
}


function _chamfer(h) =
  min(h/3,1);



/*
 * Mesh structure for reinforcement
 */
module _catstruct_mesh(ix, iy, nx, ny, h, spacing) {
    strut_width = 1;
    strut_length = spacing / 2+1;
    diagonal_strut_length = sqrt(strut_length * strut_length) + 4;
    border_width = 3;
    border_length = strut_length;

    top_border = iy == 0;
    bottom_border = iy == ny - 1;
    left_border = ix == 0;
    right_border = ix == nx - 1;

    vert_border=left_border||right_border;
    horiz_border=top_border||bottom_border;

    border = top_border || bottom_border || left_border || right_border;
    interior = !border;

    // 🛠 Borders for structural integrity
    if (border) {
        if (horiz_border && !right_border)
            translate([spacing/2, 0, 0]) bar([border_length, border_width, h]);
        if (vert_border && !bottom_border)
            translate([0, spacing/2, 0]) bar([border_width, border_length, h]);
    }

    // 🛠 Randomized interior mesh struts
    if (interior) {
        for (angle = [0, 90, 180, 270])
            rotate([0, 0, angle]) {
                if (rand_bool())
                    translate([0, spacing/2, 0]) bar([strut_width, strut_length, h]);
                else
                    translate([spacing/2, spacing/2, 0])
                        rotate([0, 0, -45]) bar([strut_width, diagonal_strut_length, h]);
            }
    }
}

// ------------------------------------------------
// Utility Functions
// ------------------------------------------------

function _ny(feature_grid) = len(feature_grid);

function _nx(feature_grid) = len(feature_grid[0]);

function get_feature(cell) = cell[0];
function get_arg(cell) = cell[1];

function make_cell(feature, arg) = [feature, arg];

function feature_grid(nx, ny, type) =
  [ for (y = [0:ny-1])
      [ for (x = [0:nx-1])
	  make_cell(type, [x, y]) ] ];

function modulo_replace(feature_grid, type, mx, my, offset_x=0, offset_y=0) =
    [ for (row = feature_grid)
	[ for (c = row) 
	    ((mx > 0 && (get_arg(c)[0]+offset_x) % mx == 0)
	     && (my > 0 && (get_arg(c)[1]+offset_y) % my == 0)) 
	      ? make_cell(type, get_arg(c))
	      : c ] ];

function reflect_symmetrical(feature_grid, x=true, y=true) =
  let(
      max_x = max([ for (c = feature_grid[0]) get_arg(c)[0] ]),  // Max X index
      max_y = max([ for (r = feature_grid) get_arg(r[0])[1] ]) // Max Y index
      )
  [ for (row = feature_grid)
      // Check if Y should reflect
      let(should_mirror_y = y && (get_arg(row[0])[1] > max_y / 2))
        [ for (c = row)
	    // Check if X should reflect
            let(should_mirror_x = x && (get_arg(c)[0] > max_x / 2))
	      make_cell(
			// feature
			get_feature(feature_grid
				    [should_mirror_y ? max_y - get_arg(c)[1] : get_arg(c)[1]]
				    [should_mirror_x ? max_x - get_arg(c)[0] : get_arg(c)[0]]),

			// arg
			[ 
			 should_mirror_x
			 ? max_x - get_arg(c)[0] : get_arg(c)[0],
			 
			 should_mirror_y
			 ? max_y - get_arg(c)[1] : get_arg(c)[1]
			  ]
			)
	  ]
    ];

/*
  h<3mm -> replace with "through"
  h>10mm -> replace with "tapped"
     height_limits(c,3,"through",10,"tapped")
 */
function height_limits(feature_grid,
		       h,
		       min_height, min_height_replacement,
		       max_height, max_height_replacement) =
    [ for (row = feature_grid)
	[ for (c = row) 
	    (h<min_height) 
	      ? make_cell(min_height_replacement, get_arg(c))
	      :
	      (h>max_height) 
	      ? make_cell(max_height_replacement, get_arg(c))
	      : c
	  ]
      ];


function polygon_bound(feature_grid, dx, dy, sides, threshold=-23) =
    [ for (row = feature_grid)
	[ for (c = row) 
	    (100*_cell_distance_from_polygon(get_arg(c)[0], get_arg(c)[1], dx, dy, sides)
	     > threshold) 
	    ? make_cell("empty", get_arg(c))
	    : c
	  ]
      ];


function _cell_distance_from_polygon(ix, iy, xd, yd, sides) =
    let(
        // Compute polygon center coordinates
        cx = (xd / 2) - 0.5,  
        cy = (yd / 2) - 0.5,

        // Compute normalized X and Y scales based on the bounding box
        rx = xd / 2,  // Half-width of bounding box
        ry = yd / 2,  // Half-height of bounding box

        // Transform pixel coordinates into normalized polygon space
        norm_x = (ix - cx) / rx,
        norm_y = (iy - cy) / ry,

        // Convert to polar coordinates and align base with X-axis
        angle = atan2(norm_y, norm_x) - (180 / sides),  // Rotate to align bottom edge
        radial_dist = sqrt(norm_x * norm_x + norm_y * norm_y),

        // Compute the closest polygon edge
        angle_step = 360 / sides,  // Angle per polygon side
        closest_edge_angle = round(angle / angle_step) * angle_step,

        // Convert angle back to Cartesian to find the closest edge point
        edge_x = cos(closest_edge_angle),
        edge_y = sin(closest_edge_angle),

        // Compute signed distance from the closest edge
        edge_dist = (norm_x * edge_x + norm_y * edge_y) - 1
    )
    edge_dist * min(rx, ry);

// Compute the signed distance from a pixel (ix, iy) to a regular polygon
function _cell_distance_from_polygon_old(ix, iy, xd, yd, sides) =
    let(
        // Compute polygon center coordinates
        cx = (xd / 2)-.5,  
        cy = (yd / 2)-.5,

        // Normalize coordinates into polygon space
        rx = xd / 2,  
        ry = yd / 2,  
        norm_x = (ix - cx) / rx,
        norm_y = (iy - cy) / ry,
        
        // Convert to polar coordinates
        angle = atan2(norm_y, norm_x),
        radial_dist = sqrt(norm_x * norm_x + norm_y * norm_y),

        // Compute closest polygon edge
        angle_step = 360 / sides,  // Angle per polygon side
        closest_edge_angle = round(angle / angle_step) * angle_step,
        
        // Convert angle back to Cartesian to find closest edge point
        edge_x = cos(closest_edge_angle),
        edge_y = sin(closest_edge_angle),

        // Compute signed distance from the closest edge
        edge_dist = (norm_x * edge_x + norm_y * edge_y) - 1
    )
    edge_dist * min(rx, ry);



module print_feature_grid(feature_grid) {
  echo("");
  for (iy = [0:_ny(feature_grid)-1]) {
    echo(str("y",iy," [ ",
	     _render_feature_list(feature_grid[iy]),
	     "]"));
    /* for (ix=[0:_nx(g)-1) { */
    /* 	echo(g[iy]); */
    /*   } */
  }
  echo("");
}

function _render_feature_list(row) =

  _render_feature_list_recurse(row,0);
  
  //str([for (c = row) str(c[2], " ")]);


function _render_feature_list_recurse(r,idx) =
  (idx>=len(r))
  ? ""
  : let(next = _render_feature_list_recurse(r, idx + 1),
	cell = _render_feature(r[idx]))
        str(cell, " ", next)
  ;

function _render_feature(cell) =
  let (feature=get_feature(cell))

  feature=="through"
  ? "◯"
  : feature=="tapped"
  ? "◦"
  : feature=="empty"
  ? "X"
  : feature==undef
  ? "null"
  : str("?",feature)
  ;


// ------------------------------------------------
// Utility
// ------------------------------------------------

module bar(size) {
  // XXXX shoudl support chamfers.  Then we wouldn't be hacking prism(n=4) so much.
  cube(size=size,center=true);
}


module prism_ended_bar(n,d,length,h,chamfer=0) {
  _length = length-d;
  translate([-_length/2,0,0])
    prism(n=n,d=d,h=h,chamfer=chamfer);
  // XXX chamfers on the bar???
  bar([_length,d,h]);
  translate([_length/2,0,0])
    prism(n=n,d=d,h=h,chamfer=chamfer);
}


module prism(n,
	     d=undef,
	     d_top=undef,d_bot=undef,
	     scale_x=undef,scale_y=undef,
	     h=undef,
             chamfer=0) 
{
  if (scale_x!=undef||scale_y!=undef) {
    assert(scale_x!=undef&&scale_y!=undef,
	   "Both or neither of scale_x and scale_y must be specified.");
  }
  assert(n!=undef);
  
  _scale_x = scale_x!=undef?scale_x:1;
  _scale_y = scale_y!=undef?scale_y:1;

  // XXX n=3 is a problem: makes a triangle too large.
  _id_top = (d != undef) ? d : d_top;
  _id_bot = (d != undef) ? d : d_bot;
  
  assert (_id_top != undef && _id_bot != undef,
	  "cyl_prism needs either d or d_top+d_bot");
  
  // Calculate the diameter of the circle that matches the vertices
  _od_top = id2od(id=_id_top,n=n);
  _od_bot = id2od(id=_id_bot,n=n);
  
  // Create the chamfered prism
  scale([_scale_x, _scale_y, 1])
  rotate([0, 0, 360 / n / 2-90]) { // align with axes
    if (chamfer != 0) {
      
      _h_chamfer = abs(chamfer);
          
      // Adjust heights for chamfer
      _h_body = h - 2 * _h_chamfer; // Main body height after chamfers
      assert(_h_body >= 0, 
             "Chamfer is too large for the given height");
      
      _chamferOd_top=max(0,id2od(_id_top-2*chamfer,n));
      _chamferOd_bot=max(0,id2od(_id_bot-2*chamfer,n));
              
      // add bottom chamfer
      translate([0, 0, -_h_chamfer/2 - _h_body/2])
        cylinder($fn=n,
          d1=_chamferOd_bot,d2=_od_bot,
          h=_h_chamfer, center=true);
      
      // Add main body
      if(_h_body>0)
        cylinder($fn=n, d1=_od_bot, d2=_od_top, 
          h=_h_body, center=true);
      
      // Add top chamfer
      translate([0, 0, _h_chamfer/2 + _h_body/2])
        cylinder($fn=n,
          d1=_od_top,d2=_chamferOd_top,
          h=_h_chamfer, center=true);
      
      
     
    } else {
      // No chamfer, just the main body
      cylinder($fn=n, d1=_od_bot, d2=_od_top, h=h, center=true);
    }
  }
}

function id2od(id,n) = id / cos(180 / n);

/*
 * Hole with ridged sides ready to be tapped by a bolt
 * Inspired by Made with Layers video:
 * https://www.youtube.com/watch?v=HgEEtk85rAY&t=383s
 */
module tapped_hole(h,d) {
  difference() {
    // the main hole
    prism(n=8, d=d, h=h);

    difference() {
      // 3 ridges around the side.
      for(rot=[0,90,180,270])
        _tapped_hole_ridge(d=d,h=h,rot=rot+45);

      // chamfer the tapped holes to make starting the tap easier.
      //translate([0,0,h/2-d/2])
      //  prism(n=8,d_bot=1, d_top=d,h=d);
    }
  }
}

/* Generate one of 3 ridges for the tapped holes */
module _tapped_hole_ridge(d,h,rot) {
    // push to the side of the hole and rotate it around.
   rotate([0,0,rot]) translate([d/2,0,0])
     // turn to an ellipse
     scale([0.8,1,1]) {
     prism(n=6, d=1, h=h,h<3?0:1);
  }
}

/* Generate a random boolean */
function rand_bool()
  = rand()>0.5;

function rand()
  = rand_range(0,1);

function rand_int(low,high)
  = rand()*(high-low)*10+low;

function rand_range(low,high)
  = rands(low,high,1)[0];

function rand_percent(percent=0.5)
  = rand()<=percent;

