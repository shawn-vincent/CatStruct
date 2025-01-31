/* -*- mode: c -*-
 * CatStruct-Plate.scad
 * Parametric generator of plates and flanged plates for the CatStruct system.
 * 2025 Shawn Vincent <svincent@svincent.com>
 */

//include <BOSL2/std.scad>
//include <BOSL2/gears.scad>

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
element_type = "round_plate"; // ["flanged_plate","plate","block","round_plate","pulley"]
// Number of holes in X axis (count)
nx = 3;
// Number of holes in Y axis(count)
ny = 3;
// Number of holes in Z axis(count, only for blocks)
nz=1;

// thickness of the generated plate (mm)
// XXX rename to 'h'
h = 3;

// thickness of the flanges (mm)
flange_thickness = 2;

// index divisor of through holes (1=every cell, 2=every 2nd, ...)  through_holes override tapped_holes XXX make this configurable somehow
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
  catstruct_flanged_plate(nx=2,ny=7,h=1, flange_thickness=1);
  /*
  _catstruct_tapped_cell(
h=30, // thickness of plate
hole_diameter=3, // through hole for M3
size=7, // standard 10mm grid.
solids=true,
holes=true
) ;
translate([-20,0,0])
_catstruct_grid(nx=3,ny=3,solids=false);
translate([20,0,0])
_catstruct_grid(nx=3,ny=3,holes=false); */
//_catstruct_through_cell();
//prism(n=8,d=2,h=10,chamfer=4);
  
//cyl_prism(n=8,d_top=10,d_bot=20,h=5);
//tapped_hole(d=3,h=5);
 
} else if(!_generate_geometry) {
  
} else if (element_type=="flanged_plate") {
  catstruct_flanged_plate(nx=nx,ny=ny,	
    h=h,
    flange_thickness=flange_thickness,
    spacing=spacing, 
    through_holes=through_holes, 
    tapped_holes=tapped_holes,
    offset_holes_x=offset_holes_x,
    offset_holes_y=offset_holes_y);
} else if (element_type=="plate") {
  catstruct_plate(nx=nx,ny=ny,	
    h=h,
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
} else if (element_type=="round_plate") {
  catstruct_round_plate(nx=nx,ny=ny,
    h=h,
    spacing=spacing, 
    through_holes=through_holes, 
    tapped_holes=tapped_holes,
    offset_holes_x=offset_holes_x,
    offset_holes_y=offset_holes_y);
} else if (element_type=="pulley") {
  catstruct_pulley(nx=nx,ny=ny,
    h=h,
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
         h=2,
         spacing=10,
         through_holes=2,
         tapped_holes=1,
	 offset_holes_x=0,
	 offset_holes_y=0) 
{
  _catstruct_grid(nx=nx,ny=ny,h=h,
    spacing=spacing,
    through_holes=through_holes,tapped_holes=tapped_holes,
    offset_holes_x=offset_holes_x,
    offset_holes_y=offset_holes_y);
}

/*
 * Generate a flanged CatStruct plate
 */
module catstruct_flanged_plate(nx,ny,
         h=2, flange_thickness=2,
         spacing=10,
         through_holes=2,
         tapped_holes=1,
	 offset_holes_x=0,
	 offset_holes_y=0) 
{
  rotate([180,0,0]) {
  translate([0,0,(spacing/2-h/2)])
  _catstruct_grid(nx=nx,ny=ny,
    h=h,spacing=spacing,
    through_holes=through_holes, tapped_holes=tapped_holes,
    offset_holes_x=offset_holes_x,
    offset_holes_y=offset_holes_y);
 
  // make flanges
  // XXX problem if top thickness <3mm: the flange tapped cells float above the baseplate.  I really want to add some kind of diagonal bracing here to fix the problem.  Maybe one on each corner.
  _catstruct_plate_flanges(nx=nx,ny=ny,
    spacing=spacing,
    h=h, 
    flange_thickness=flange_thickness);
  }
}

/*
 * Make some flanges
 */
module _catstruct_plate_flanges(nx,ny,
         h, flange_thickness,
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
  chamfer=_catstruct_chamfer(h);
  
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
// Round Plate
// ------------------------------------------------

module catstruct_round_plate(nx, ny,
         h=2,
         spacing=10,
         through_holes=2,
   	 tapped_holes=1,
	 offset_holes_x=0,
	 offset_holes_y=0)
{

  // Make a border to clean up the edges 
  border_width=2;
  difference() {
    prism(n=64,d_x=nx*spacing,d_y=ny*spacing,h=h);
    prism(n=64,
	  d_x=nx*spacing-border_width*2,
	  d_y=ny*spacing-border_width*2,
	  h=h);
  }
 

  // make a grid constrained to a round
  intersection() {
    _catstruct_grid(nx=nx,ny=ny,
      h=h,
      spacing = spacing,
      through_holes = through_holes,
      tapped_holes = tapped_holes,
      offset_holes_x=offset_holes_x,
		    offset_holes_y=offset_holes_y,
		    bound_round_xd=nx,bound_round_yd=ny);

    prism(n=64,d_x=nx*spacing,d_y=ny*spacing,h=h*10); // allow plate extensions
  }
}


// ------------------------------------------------
// Round Pulley
// ------------------------------------------------

module catstruct_pulley(nx, ny,
         h=2,
         spacing=10,
         through_holes=2,
   	 tapped_holes=1,
	 offset_holes_x=0,
	 offset_holes_y=0)
{
  difference() {
    union() {
      catstruct_round_plate(nx=nx, ny=ny,
			    h=h,
			    spacing=spacing,
			    through_holes=through_holes,
			    tapped_holes=tapped_holes,
			    offset_holes_x=offset_holes_x,
			    offset_holes_y=offset_holes_y);
      catstruct_hub(nx=nx,ny-ny,h=h,
	spacing=spacing,
	through_holes=through_holes,
	tapped_holes=tapped_holes,
	offset_holes_x=offset_holes_x,
	offset_holes_y=offset_holes_y,holes=false);
  }

  catstruct_hub(nx=nx,ny-ny,h=h,
		spacing=spacing,
		through_holes=through_holes,
		tapped_holes=tapped_holes,
		offset_holes_x=offset_holes_x,
		offset_holes_y=offset_holes_y,solids=false);
}
}

module catstruct_hub(nx,ny,
		     h,
		     spacing,
		     through_holes,
		     tapped_holes,
		     offset_holes_x,
		     offset_holes_y,
		     solids=true,
		     holes=true)
{


  difference()
    {
      if(solids) {
	prism(n=8,d=spacing,h=h,chamfer=_catstruct_chamfer(h));
	for(ix=[-1:1])
	  for (iy=[-1:1])
	    if (!(ix==0&&iy==0))
	      translate([ix*spacing/2,iy*spacing/2,0])
		prism(n=6,d=spacing/2+2,h=h,chamfer=_catstruct_chamfer(h));
      }

      if(holes)
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
}


// ------------------------------------------------
// Internals: Grid
// ------------------------------------------------


/*
 * Make a grid of CatStruct cells connected by a mesh.
 */
module _catstruct_grid(nx,ny,
		       h = 1,
		       spacing=10,
		       through_holes=2,
		       tapped_holes=1,
		       offset_holes_x=0,
		       offset_holes_y=0,
		       solids=true,
		       holes=true,
		       bound_round_xd=undef,bound_round_yd=undef) 
{
  width=nx*spacing;
  height=ny*spacing;
  
  for (iy = [0:ny-1]) {
    for (ix = [0:nx-1]) {

      xtrans = ix*spacing-width/2+spacing/2;
      ytrans = iy*spacing-height/2+spacing/2;
      translate([xtrans,ytrans,0]) {

	effective_ix = ix+offset_holes_x;
	effective_iy = iy+offset_holes_y;
	
        // make a cell
        if(_generate_cells)
          _catstruct_cell(ix=effective_ix,iy=effective_iy,h=h, spacing=spacing, through_holes = through_holes,tapped_holes = tapped_holes,
			  solids=solids,holes=holes,
			  bound_round_xd,bound_round_yd);
        
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
  solids=true,holes=true,bound_round_xd,bound_round_yd) 
{
  threshold = -23;
	   
  if (bound_round_xd!=undef && round(100*_cell_distance_from_round(ix,iy,bound_round_xd,bound_round_yd)) > threshold) {
      _catstruct_empty_cell(h=h,size=spacing-3,solids=solids,holes=holes);
  }
    
  else if (_generate_through_cells
      && through_holes > 0 
      && ix % through_holes==0
      && iy % through_holes==0)
    _catstruct_through_cell(h=h,spacing=spacing,solids=solids,holes=holes);
  else if (_generate_tapped_cells
           && tapped_holes>0
           && ix % tapped_holes==0
           && iy % tapped_holes==0)
    // XXX move "spacing" concept and size adjustments in cell generation methods.
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
spacing=10, // standard 10mm grid.
// XXX mqybe add bolt_size
solids=true,
holes=true
) 
{
  chamfer=_catstruct_chamfer(h);
  hole_radius = hole_diameter/2;
  
  difference() {
    if (solids)
      prism(n=8,d=spacing,h=h,chamfer=chamfer);
    if (holes)
      _catstruct_through_hole(h=h,hole_diameter=hole_diameter);
  }
}

module _catstruct_through_hole(h=5, // thickness of plate
			       hole_diameter=3.4) // through hole for M3
{
  chamfer=_catstruct_chamfer(h);

  
  prism(n=16,d=hole_diameter, h=h, chamfer=-chamfer/2);
}

function _catstruct_chamfer(h) =
  min(1,h/3);

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
  rnd=_catstruct_chamfer(h=h); // roundover radius
  hole_radius = hole_diameter/2;
  min_height=3; // 3mm at least for tapped cells
  true_height=max(min_height,h);
  min_tapped_hole_wall=.5;

  difference() {
    if(solids)
    union() {
      // tapped holes use square cells.
      echo("height",h);
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
          _catstruct_tapped_hole(d=hole_diameter,h=hole_depth);

        translate([0,0,-(h/2-hole_depth/2)])
          _catstruct_tapped_hole(d=hole_diameter,h=hole_depth);

      } else {
	echo("true_height",true_height,-true_height/2+h/2);
        translate([0,0,-true_height/2+h/2])
	  _catstruct_tapped_hole(d=hole_diameter,h=true_height+0.01);
      }
    }
  }
}


module _catstruct_tapped_hole(h=5, // thickness of plate
			      d=3) // tappable  hole for M3 (XXX good value?)
{
  tapped_hole(h=h,d=d);
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



module prism(n,
	     d=1,
	     d_top=undef,d_bot=undef,
	     d_x=undef,d_y=undef,
	     h=undef,
             chamfer=0) 
{
  if (d_x!=undef||d_y!=undef) {
    assert(d_x!=undef&&d_y!=undef, "Both or neither of d_x and d_y must be specified.");
    assert(d==1, "d must not be specified if d_x and d_y are specified.");
  }
  _scale_x = d_x!=undef?d_x:1;
  _scale_y = d_y!=undef?d_y:1;
  
  _id_top = (d != undef) ? d : d_top;
  _id_bot = (d != undef) ? d : d_bot;
  
  assert (_id_top != undef && _id_bot != undef,
    "cyl_prism needs either d or d_top+d_bot");
  
  // Calculate the diameter of the circle that matches the vertices
  _od_top = id2od(_id_top,n);
  _od_bot = id2od(_id_bot,n);
  
  // Create the chamfered prism
  scale([_scale_x, _scale_y, 1])
  rotate([0, 0, 360 / n / 2]) { // align with axes
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

/* AI Generated function!  
 */

// Compute the signed distance from a pixel (ix, iy) to the boundary of an ellipse
// with dimensions (xd, yd), centered in a grid of size (xd, yd).
// 
// Parameters:
//   ix - X coordinate of the pixel in the grid
//   iy - Y coordinate of the pixel in the grid
//   xd - Width of the ellipse (total horizontal extent)
//   yd - Height of the ellipse (total vertical extent)
//
// Returns:
//   The signed distance from (ix, iy) to the ellipse boundary. 
//   Negative values indicate inside the ellipse, positive values indicate outside.
function _cell_distance_from_round(ix, iy, xd, yd) =
    let(
        // Compute ellipse center coordinates
        cx = (xd / 2)-.5,  // Center X
        cy = (yd / 2)-.5,  // Center Y

	//cx = floor(xd / 2),  // Center X
        //cy = floor(yd / 2),  // Center Y

        // Compute ellipse radii
        rx = xd / 2,  // Radius in X direction
        ry = yd / 2,  // Radius in Y direction

        // Normalize coordinates to ellipse space (-1 to 1 range)
        norm_x = (ix - cx) / rx,
        norm_y = (iy - cy) / ry,

        // Compute distance using the implicit equation of an ellipse
        distance = sqrt(norm_x * norm_x + norm_y * norm_y) - 1
    )
    // Scale back to pixel distance using the smaller radius (to maintain correct proportions)
    distance * min(rx, ry);







// ------------------------------
//  Grid Creation & Core Structure
// ------------------------------

/*
 * Create an nx × ny grid with a default cell type.
 * Parameters:
 *  - nx, ny: Grid dimensions.
 *  - type: Default type for all cells.
 * Returns:
 *  - A 2D list representing the grid.
 */
function grid(nx, ny, type) =
    [ for (y = [0:ny-1]) [ for (x = [0:nx-1]) [x, y, type] ] ];

// ------------------------------
//  Grid Modification Functions
// ------------------------------

/*
 * Replace every nth cell along X and Y where (x % mx == 0 && y % my == 0).
 * Parameters:
 *  - g: The grid to modify.
 *  - type: The new cell type.
 *  - mx: Replace every mx-th cell in X direction.
 *  - my: Replace every my-th cell in Y direction.
 * Returns:
 *  - A modified grid with replacements at defined intervals.
 */
function modulo_replace(g, type, mx, my) =
    [ for (row = g) [ for (c = row)
        ((mx > 0 && c[0] % mx == 0) && (my > 0 && c[1] % my == 0))
        ? [c[0], c[1], type] : c ] ];

/*
 * Replace cells in a checkerboard pattern.
 * Parameters:
 *  - g: The grid to modify.
 *  - type: The new cell type.
 *  - spacing: Controls the size of the checkerboard squares.
 * Returns:
 *  - A modified grid with checkerboard replacements.
 */
function checkerboard_replace(g, type, spacing=2) =
    [ for (row = g) [ for (c = row)
        (((c[0] / spacing) % 2 == (c[1] / spacing) % 2))
        ? [c[0], c[1], type] : c ] ];

/*
 * Replace border cells within a given thickness.
 * Parameters:
 *  - g: The grid to modify.
 *  - type: The new cell type.
 *  - t: Border thickness in cells.
 * Returns:
 *  - A modified grid with replaced border cells.
 */
function border_replace(g, type, t=1) =
    [ for (row = g) [ for (c = row)
        (c[0] < t || c[1] < t || c[0] >= len(g)-t || c[1] >= len(g[0])-t)
        ? [c[0], c[1], type] : c ] ];

/*
 * Compute Euclidean distance from a point.
 * Parameters:
 *  - ix, iy: The coordinates of the cell.
 *  - dx, dy: The reference point.
 * Returns:
 *  - The distance from (dx, dy).
 */
function _cell_distance_from_center(ix, iy, dx, dy) =
    sqrt((ix - dx) * (ix - dx) + (iy - dy) * (iy - dy));

/*
 * Remove or modify cells outside a circular boundary.
 * Parameters:
 *  - g: The grid to modify.
 *  - dx, dy: The center of the circular boundary.
 *  - threshold: Cells beyond this distance will be set to "empty".
 * Returns:
 *  - A modified grid with "empty" cells beyond the boundary.
 */
function round_bound(g, dx, dy, threshold) =
    [ for (row = g) 
        [ for (c = row) 
            (_cell_distance_from_center(c[0], c[1], dx, dy) > threshold)
            ? [c[0], c[1], "empty"] 
            : c 
        ]  // Close second for-loop
    ];   // Close first for-loop

/*
 * Override specific cell positions.
 * Parameters:
 *  - g: The grid to modify.
 *  - o: A list of overrides in the form [[x, y, type], ...].
 * Returns:
 *  - A modified grid with manually overridden cells.
 */
function override(g, o) =
    [ for (row = g) [ for (c = row)
        let(m = [ for (entry = o) if (entry[0] == c[0] && entry[1] == c[1]) entry ])
        (len(m) > 0) ? m[0] : c ] ];

/*
 * Apply multi-cell components while removing conflicts.
 * Parameters:
 *  - g: The grid to modify.
 *  - o: A list of multi-cell elements in the form [x, y, type, width, height].
 * Returns:
 *  - A modified grid with multi-cell structures applied.
 */
function multi_cell_apply(g, o) =
    let(cleaned = 
        [ for (row = g) 
            [ for (c = row)
                let(mc = [ for (e = o) 
                    if (c[0] >= e[0] && c[0] < e[0]+e[3] && 
                        c[1] >= e[1] && c[1] < e[1]+e[4]) e ])
                (len(mc) > 0) ? [c[0], c[1], "empty"] : c
            ]  
        ])
    override(cleaned, o);

/*
 * Merge two grids, prioritizing non-empty cells from g2.
 * Parameters:
 *  - g1, g2: The two grids to merge.
 * Returns:
 *  - A merged grid with priority given to g2’s non-empty cells.
 */
function merge(g1, g2) =
    [ for (y = [0:len(g1)-1]) 
        [ for (x = [0:len(g1[y])-1]) 
            let(c1 = g1[y][x], c2 = g2[y][x])
            (c2[2] != "empty") ? c2 : c1
        ]  
    ];


// ------------------------------
// Example Usage
// ------------------------------
/*
g = grid(5, 5, "tapped");
g = modulo_replace(g, "through", 2, 2);
g = checkerboard_replace(g, "through", 2);
g = border_replace(g, "reinforced", 1);
g = round_bound(g, 2, 2, 3);
g = override(g, [[2, 2, "hub"], [1, 3, "special"]]);
g = multi_cell_apply(g, [[2, 2, "hub", 2, 2], [4, 1, "servo_cutout", 3, 1]]);
echo(g);
*/
