/* -*- mode: c -*-
 * CatStruct-Plate.scad
 * Parametric generator of plates and flanged plates for the CatStruct system.
 * 2025 Shawn Vincent <svincent@svincent.com>
 */

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
element_type = "circle_plate"; // ["flanged_plate","plate","block","circle_plate"]
// Number of holes in X axis (count)
nx = 3;
// Number of holes in Y axis(count)
ny = 3;
// Number of holes in Z axis(count, only for blocks)
nz=1;

// Diameter of circle plate, in number of holes across (count)
n_diameter=5;

// thickness of the generated plate (mm)
plate_thickness = 3;

// thickness of the flanges (mm)
flange_thickness = 2;

// index divisor of through holes (1=every cell, 2=every 2nd, ...)  through_holes override tapped_holes
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


// generate geometry.
_generate_geometry=true;

_generate_mesh=true;
_generate_cells=true;
_generate_through_cells=true;
_generate_tapped_cells=true;
_generate_empty_cells=true;

_debug=false;


if (_debug) {
  

  catstruct_flanged_plate(nx=2,ny=7,plate_thickness=1, flange_thickness=1);
  

/*
  
  _catstruct_tapped_cell(
h=30, // thickness of plate
hole_diameter=3, // through hole for M3
size=7, // standard 10mm grid.
solids=true,
holes=true
) ;
  */

/*
translate([-20,0,0])
_catstruct_grid(nx=3,ny=3,solids=false);

translate([20,0,0])
_catstruct_grid(nx=3,ny=3,holes=false);
*/
//_catstruct_through_cell();

//prism(n=8,d=2,h=10,chamfer=4);
  
//cyl_prism(n=8,d_top=10,d_bot=20,h=5);
//tapped_hole(d=3,h=5);
 
} else if(!_generate_geometry) {
  
} else if (element_type=="flanged_plate") {
  catstruct_flanged_plate(nx=nx,ny=ny,	
    plate_thickness=plate_thickness,
    flange_thickness=flange_thickness,
    spacing=spacing, 
    through_holes=through_holes, 
    tapped_holes=tapped_holes,
    offset_holes_x=offset_holes_x,
    offset_holes_y=offset_holes_y);
} else if (element_type=="plate") {
  catstruct_plate(nx=nx,ny=ny,	
    plate_thickness=plate_thickness,
    spacing=spacing, 
    through_holes=through_holes, 
    tapped_holes=tapped_holes,
    offset_holes_x=offset_holes_x,
    offset_holes_y=offset_holes_y);  
} else if (element_type=="block") {
  catstruct_block(nx=nx,ny=ny,nz=nz,	
    spacing=spacing, 
    through_holes=through_holes, 
    tapped_holes=tapped_holes,
    offset_holes_x=offset_holes_x,
    offset_holes_y=offset_holes_y);  
} else if (element_type=="circle_plate") {
  catstruct_circle_plate(n_diameter=n_diameter,	
    plate_thickness=plate_thickness,
    spacing=spacing, 
    through_holes=through_holes, 
    tapped_holes=tapped_holes,
    offset_holes_x=offset_holes_x,
    offset_holes_y=offset_holes_y);
} else {
  
  assert(false, str("Unknown element type: ",element_type));
}


// ------------------------------------------------
// Plates and flanged plates
// ------------------------------------------------

/*
 * Generate a CatStruct plate (without flanges)
 */
module catstruct_plate(nx,ny,
         plate_thickness=2,
         spacing=10,
         through_holes=2,
         tapped_holes=1,
	 offset_holes_x=0,
	 offset_holes_y=0) 
{
  _catstruct_grid(nx=nx,ny=ny,h=plate_thickness,
    spacing=spacing,
    through_holes=through_holes,tapped_holes=tapped_holes,
    offset_holes_x=offset_holes_x,
    offset_holes_y=offset_holes_y);
}

/*
 * Generate a flanged CatStruct plate
 */
module catstruct_flanged_plate(nx,ny,
         plate_thickness=2, flange_thickness=2,
         spacing=10,
         through_holes=2,
         tapped_holes=1,
	 offset_holes_x=0,
	 offset_holes_y=0) 
{
  rotate([180,0,0]) {
  translate([0,0,(spacing/2-plate_thickness/2)])
  _catstruct_grid(nx=nx,ny=ny,
    h=plate_thickness,spacing=spacing,
    through_holes=through_holes, tapped_holes=tapped_holes,
    offset_holes_x=offset_holes_x,
    offset_holes_y=offset_holes_y);
 
  // make flanges
  // XXX problem if top thickness <3mm: the flange tapped cells float above the baseplate.  I really want to add some kind of diagonal bracing here to fix the problem.  Maybe one on each corner.
  _catstruct_plate_flanges(nx=nx,ny=ny,
    spacing=spacing,
    plate_thickness=plate_thickness, 
    flange_thickness=flange_thickness);
  }
}

/*
 * Make some flanges
 */
module _catstruct_plate_flanges(nx,ny,
         plate_thickness, flange_thickness,
         spacing=10,
         through_holes=2,
         tapped_holes=1,
	 offset_holes_x=0,
	 offset_holes_y=0) {
           
  width=nx*spacing;
  height=ny*spacing;
  
  
  // Y flanges
  for(i=[-1,1]) {
    translate([0,i*-(height-flange_thickness)/2,0])
    rotate([90,0,i>0?0:180])
    _catstruct_flange(nx=nx,h=flange_thickness,
      spacing=spacing,
      through_holes=through_holes,
      tapped_holes=tapped_holes,
      offset_holes_x=offset_holes_x,
      offset_holes_y=offset_holes_y);
  }
  
 // X flanges
 for(i=[-1,1]) {
    
   // original that works... 
   /*
 translate([i*(width-flange_thickness)/2,0,0])
 rotate([0,0+i*90-30,0])
   */
  translate([i*(width-flange_thickness)/2,0,0])
  rotate([90,0,i*90])
  _catstruct_flange(nx=ny,h=flange_thickness,
    spacing=spacing,
    through_holes=through_holes,
    tapped_holes=tapped_holes,
    offset_holes_x=offset_holes_x,
    offset_holes_y=offset_holes_y);
  }
}

module _catstruct_flange(nx,h = 1,
         spacing=10,
         through_holes=2,
         tapped_holes=1,
	 offset_holes_x=0,
	 offset_holes_y=0,
         solids=true,
         holes=true) 
{
  
  _catstruct_grid(nx=nx,ny=1,h=h,
      spacing=spacing,
      through_holes= through_holes,
      tapped_holes=tapped_holes,
      offset_holes_x=offset_holes_x,
      offset_holes_y=offset_holes_y);
  
  for(i=[0:nx-1])
    translate([(i-nx/2)*spacing+spacing/2,0,0])
  _catstruct_flange_reinforcement(h=h);
}
  
module _catstruct_flange_reinforcement(h=undef)
{
  // XXX should be parameterized but is not.
  // XXX this whole thing is a total hack fest.
  tapped_hole_size=3;
  size=7;
  
  distance_tapped_from_edge=1.5;// XXX MAGIC
  chamfer=(min(h/3,2));
  
  thickness=1;
      
  // XXX magic and broken.
  // should be longer.
  // This is pythagorean triangle.
  // but I think I also have to factor in the right triangle of the chamfer itself and ... something something... Too tired now to fix this and it's FINE.for now for this avoidant thing I'm doing.
  height=2.4;//sqrt((distance_tapped_from_edge+chamfer)^2);
  

  width=6;

  translate([
    // X
    0
    ,
  
    // Y
    0
    +spacing/2
    -distance_tapped_from_edge
    //-(thickness/2) 
   -chamfer // chamfer    

    ,
  
    // Z
    0
    +h/2
    ,
  ])
    rotate([
    90
    +45
    ,
    0
    ,
    0])
       // move so point of rotation is on left side.
       translate([
                  0
                  
                  ,
                  0
                  -height/2
                  
                  ,
                  0
                  +thickness/2
                  // setback
                  +.2
                  ])
      bar([width,height,thickness]);
}


// ------------------------------------------------
// Block
// ------------------------------------------------

/*
 * Generate a CatStruct plate (without flanges)
 */
module catstruct_block(nx,ny,nz,
         spacing=10,
         through_holes=2,
         tapped_holes=1,
	 offset_holes_x=0,
	 offset_holes_y=0) 
{
  difference() {
    _catstruct_block_walls(nx=nx,ny=ny,nz=nz,
           spacing=spacing,
           through_holes=through_holes,
           tapped_holes=tapped_holes,
           offset_holes_x=offset_holes_x,
           offset_holes_y=offset_holes_y,
           holes=false);
    _catstruct_block_walls(nx=nx,ny=ny,nz=nz,
           spacing=spacing,
           through_holes=through_holes,
           tapped_holes=tapped_holes,
           offset_holes_x=offset_holes_x,
           offset_holes_y=offset_holes_y,
           solids=false);
  }
}

module _catstruct_block_walls(nx,ny,nz,
         spacing=10,
         through_holes=2,
         tapped_holes=1,
	 offset_holes_x=0,
	 offset_holes_y=0,
         holes=true,
         solids=true) 
{ 
  // Three really thick grids.
  // Ideally tapped holes would only go in 10mm from each end.
  
   _catstruct_grid(nx=nx,ny=ny,h=nz*spacing,
        spacing=spacing,
        through_holes=(nz==1)?through_holes:-1,
        tapped_holes=tapped_holes,
        offset_holes_x=offset_holes_x,
        offset_holes_y=offset_holes_y,
        holes=holes,solids=solids);
  
  
      rotate([90,0,0])
      _catstruct_grid(nx=nx,ny=nz,h=ny*spacing,
        spacing=spacing,
        through_holes=(ny==1)?through_holes:-1,
        tapped_holes=tapped_holes,
        offset_holes_x=offset_holes_x,
        offset_holes_y=offset_holes_y,
        holes=holes,solids=solids);

  
      rotate([0,90,0])
      _catstruct_grid(nx=nz,ny=ny,h=nx*spacing,
        spacing=spacing,
        through_holes=(nx==1)?through_holes:-1,
        tapped_holes=tapped_holes,
        offset_holes_x=offset_holes_x,
        offset_holes_y=offset_holes_y,
        holes=holes,solids=solids);
}




// ------------------------------------------------
// Circle Plate
// ------------------------------------------------

module catstruct_circle_plate(n_diameter,
         plate_thickness=2,
         spacing=10,
         through_holes=2,
   	 tapped_holes=1,
	 offset_holes_x=0,
	 offset_holes_y=0)
{
  border_width=3;

  difference() {
    union() {
      // make an outer border
      if (_generate_mesh) {
	difference() {
	  prism(n=64,d=n_diameter*spacing,h=plate_thickness);
	  prism(n=64,d=n_diameter*spacing-2*border_width,h=plate_thickness);
	}
      }

      //prism
      // make a grid constrained to a circle
      intersection() {
	_catstruct_grid(nx=n_diameter,ny=n_diameter,
	  h=plate_thickness,
	  spacing = spacing,
	  through_holes = through_holes,
	  tapped_holes = tapped_holes,
	  offset_holes_x=offset_holes_x,
	  offset_holes_y=offset_holes_y,
	  holes=false);
	prism(n=64,d=n_diameter*spacing,h=plate_thickness*10); // allow plate extensions
      }
    }

    #_catstruct_grid(nx=n_diameter,ny=n_diameter,
      h=plate_thickness,
      spacing = spacing,
      through_holes = through_holes,
      tapped_holes = tapped_holes,
      offset_holes_x=offset_holes_x,
      offset_holes_y=offset_holes_y,
      solids=false);
  }

}



// ------------------------------------------------
// Internals: Grid
// ------------------------------------------------


/*
 * Make a grid of CatStruct cells connected by a mesh.
 */
module _catstruct_grid(nx,ny,h = 1,
         spacing=10,
         through_holes=2,
         tapped_holes=1,
	 offset_holes_x=0,
	 offset_holes_y=0,
         solids=true,
         holes=true) 
{
  width=nx*spacing;
  height=ny*spacing;
  
  for (ix = [0:nx-1]) {
    for (iy = [0:ny-1]) {
      
      xtrans = ix*spacing-width/2+spacing/2;
      ytrans = iy*spacing-height/2+spacing/2;
      translate([xtrans,ytrans,0]) {

	effective_ix = ix+offset_holes_x;
	effective_iy = iy+offset_holes_y;
	
        // make a cell
        if(_generate_cells)
          _catstruct_cell(ix=effective_ix,iy=effective_iy,h=h, spacing=spacing, through_holes = through_holes,tapped_holes = tapped_holes,
        solids=solids,holes=holes);
        
        // make the inter-cell mesh
        if(_generate_mesh && solids)
          _catstruct_mesh(ix=ix,iy=iy,nx=nx,ny=ny,h=h,spacing=spacing);
      }
    }
  }    
}


// ------------------------------------------------
// cells
// ------------------------------------------------

/*
 * Make an appropriate CatStruct cell for the given indices
 */
module _catstruct_cell(ix,iy,h,
  spacing,
  through_holes = 2,
  tapped_holes = 1,
  solids=true,holes=true) 
{
  if (_generate_through_cells
      && through_holes > 0 
      && ix % through_holes==0
      && iy % through_holes==0)
    _catstruct_through_cell(h=h,size=spacing,
  solids=solids,holes=holes);
  else if (_generate_tapped_cells
           && tapped_holes>0
           && ix % tapped_holes==0
           && iy % tapped_holes==0)
    _catstruct_tapped_cell(h=h,size=spacing-3,solids=solids,holes=holes);
  else if (_generate_empty_cells)
    _catstruct_empty_cell(h=h,size=spacing-3,solids=solids,holes=holes);
}

/*
 * Make a CatStruct through-hole cell.
 */
module _catstruct_through_cell(
h=5, // thickness of plate
hole_diameter=3.4, // through hole for M3
size=10, // standard 10mm grid.
solids=true,
holes=true
) 
{
  rnd=min(1,h/3); // roundover radius
  hole_radius = hole_diameter/2;
  
  difference() {
    if (solids)
      prism(n=8,d=size,h=h,chamfer=rnd);
    if (holes)
      prism(n=16,d=hole_diameter, h=h, chamfer=-rnd/2);
  }
}

/*
 * Make a CatStruct tapped-hole cell.
 */
module _catstruct_tapped_cell(
h=1, // thickness of plate
hole_diameter=3, // through hole for M3
size=7, // standard 10mm grid.
solids=true,
holes=true
) 
{
  rnd=min(1,h/3); // roundover radius
  hole_radius = hole_diameter/2;
  min_height=3; // 3mm at least for tapped cells
  true_height=max(min_height,h);
  min_tapped_hole_wall=.5;

  difference() {
    if(solids)
    union() {
      // tapped holes use square cells.
      prism(n=4,d=size,h=h,chamfer=rnd);
        
      // tapped holes are backed by extra thickness
      if(h<min_height)
        translate([0,0,-min_height/2+h/2])
          prism(4, d_top=size-2*rnd,d_bot=hole_diameter+min_tapped_hole_wall*2,h=min_height);
    }
    
    if(holes) {
      // if the hole would be very deep, replace with 2 10mm holes from each end.  This is mostly for blocks where we don't want a network of threaded holes throughout making infill impossible when printing.  Kind of a hack, but life is short.
      if(h>20) {
        hole_depth = 10;
        translate([0,0,h/2-hole_depth/2])
          tapped_hole(d=hole_radius*2,hole_depth);

        translate([0,0,-(h/2-hole_depth/2)])
          tapped_hole(d=hole_radius*2,hole_depth);

      } else {
        translate([0,0,-true_height/2+h/2])
        tapped_hole(d=hole_radius*2,true_height);
      }
    }
  }
}

/*
 * Make a CatStruct cell with no hole
 */
module _catstruct_empty_cell(
h=1, // thickness of plate
size=7, // standard 10mm grid.
solids=true,
holes=true
) 
{
  rnd=min(1,h/3); // roundover radius
  if(solids)
  prism(4,d=size,h=h,chamfer=rnd);
}


// ------------------------------------------------
// Mesh
// ------------------------------------------------

/*
 * Make a CatStruct mesh for the cell at the given indices
 */
module _catstruct_mesh(ix,iy,nx,ny,h,spacing) {
  
  strut_width=1;
  strut_length=spacing/2;
  diagonal_strut_length=sqrt(strut_length*strut_length)+4;
  border_width=3;
  border_length=strut_length;
  
  // figure out what border we're at if any.
  top_border=iy==0;
  bottom_border=iy==ny-1;
  horiz_border = top_border || bottom_border;
  left_border=ix==0;
  right_border=ix==nx-1;
  vert_border = left_border || right_border;
  border = horiz_border || vert_border;
  interior=!border;
  
  // special handling for 2xN meshes, as we can't use the same trick as below.
  if(nx==2 || ny == 2) {
    if (!bottom_border && !right_border) {
      // special case for 2-wide (can't do tris)
            translate([spacing/2,spacing/2,0])
        rotate([0,0,-45])
          bar([strut_width,diagonal_strut_length,h]);
    }
  }
  
  // a hacky experiment when building blocks.  Maybe not necessary in the end.
  if(false && !bottom_border) {
    if(!right_border)
     translate([spacing/2,spacing/2,0])
     rotate([0,0,45])
       bar([strut_width,  diagonal_strut_length,h]);
    if(!left_border)
     translate([-spacing/2,spacing/2,0])
     rotate([0,0,-45])
       bar([strut_width,  diagonal_strut_length,h]);
  }
  
  // edge borders
  if(border) {
    // to right
    if(horiz_border)
      if(!right_border)
        translate([spacing/2,0,0])
          bar([border_length,border_width,h]);
      
    // down
    if(vert_border)
       if(!bottom_border)
         translate([0,spacing/2,0])
           bar([border_width,border_length,h]);
  } 
 
  // interior nodes: random mesh.
  if (interior) {  
    for(angle=[0,90,180,270]) 
      rotate([0,0,angle]) {
        // choose a horizontal and a vertical on one corner
        if (rand_bool())
          translate([0,spacing/2,0])
            bar([strut_width,strut_length,h]);
        else {
          translate([spacing/2,spacing/2,0])
            rotate([0,0,-45])
              bar([strut_width,diagonal_strut_length,h]);
        }
      }
  }     
}


// ------------------------------------------------
// Utility
// ------------------------------------------------

module bar(size) {
  cube(size=size,center=true);
}



module prism(n,d=undef,
    d_top=undef,d_bot=undef, h=undef,
    chamfer=0) 
{
  _id_top = (d != undef) ? d : d_top;
  _id_bot = (d != undef) ? d : d_bot;
  
  assert (_id_top != undef && _id_bot != undef,
    "cyl_prism needs either d or d_top+d_bot");
  
  // Calculate the diameter of the circle that matches the vertices
  _od_top = id2od(_id_top,n);
  _od_bot = id2od(_id_bot,n);
  
  // Create the chamfered prism
  rotate([0, 0, 360 / n / 2]) {
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
       prism(n=6, d=1, h=h,chamfer=1);
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





