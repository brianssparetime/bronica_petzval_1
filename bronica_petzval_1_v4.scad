// parameters



eps = 0.01;
fn = 100;
// clr = 0.3;
clr = 0.5; // increased from 0.3


// surplus shed f = 125 mm, optical dia = 42.4mm, DCX  (L10971)
front_ele_dia = 43;// 42.4; 
front_ele_thk = 2.5; // 2.4

// surplus shed f = 125 mm, optical dia = 35mm,  achromat doublet (L14523)
// because this element is mounted in a metal ring, the optical diameter is smaller
// than the physical one
// Orient the achromat with its most curved side facing the film plane
back_ele_dia = 46.7; 
back_ele_thk = 12.65; 
back_ele_sm_dia = 42.5;

first_to_stop = 35; // calculated
stop_to_second = 15; // calculated
stop_thk = 1.0;

/* consider using this (https://rafcamera.com/adapter-m65x1f-to-m57x1m) as a base

 - adds 1.5mm to the exsting (measured to the flat disc surface we'd glue to)
 - throat looks like about 52mm (minus threading) diameter
 - surface flange is ring 65-52 = 13mm wide

*/
flange_dia = 64;
throat = 56.4;
base_reg_dist = 101.7 + 1.5; // camera's flange plus M65 to M47 thickness
optical_bfd = 96; // from calculations


wall_thk = 2;
front_retaining_ring_thk = 1.5;
ele_overlap = 3; // for spacer rings
end_overlap = 3; // how much in it goes over the rear of the rear lens element and front of front
end_cap_thk = 2; // how thick the end part is past the main barrel

// this is the back edge of the rear-most element
end_cap_insert_len = 6.5; // how far inside the main barrel this goes

// calculated

overall_height = front_retaining_ring_thk + front_ele_thk + first_to_stop + stop_thk + stop_to_second + back_ele_thk + end_cap_thk; 
intrude_dist = base_reg_dist - optical_bfd + end_cap_insert_len; // + back_ele_thk / 2;  /// this seems fishy TODO
flange_start = overall_height  - intrude_dist; // distance down from the top
flange_thk = min([5,flange_start]);
actual_bfd = base_reg_dist - intrude_dist;

barrel_id = max([front_ele_dia, back_ele_dia]) + clr;
barrel_od = barrel_id + wall_thk * 2;


// mounting flange
_flange_base_angle = 90-15;
_cone_h =  tan(_flange_base_angle) * ( flange_dia  / 2);
_ring_h =  tan(_flange_base_angle) * ( (flange_dia  - barrel_od ) / 2);

echo("Overall height = ", overall_height);
echo("barrel od = ", barrel_od);
echo("actual bfd = ", actual_bfd);
echo("intrude_dist  = ", intrude_dist);




module tube(id = -1, od = -1, thk = -1, h = 10, fn = 50) {
    function to_int(x) = x ? 1 : 0;
    num_given = to_int(id != -1) + to_int(od != -1) + to_int(thk != -1);
    assert(num_given == 2, "Exactly two of id, od, thk must be specified");

    if (id == -1) {
        linear_extrude(height = h) {
            difference() {
                circle(r = od / 2, $fn = fn);
                circle(r = od / 2 - thk, $fn = fn);
            }
        }
    } else if (od == -1) {
        linear_extrude(height = h) {
            difference() {
                circle(r = id / 2 + thk, $fn = fn);
                circle(r = id / 2, $fn = fn);
            }
        }
    } else if (thk == -1) {
        linear_extrude(height = h) {
            difference() {
                circle(r = od  / 2, $fn = fn);
                circle(r = id / 2, $fn = fn);
            }
        }
    } else {
        assert(0, "too many args");
    }
}

module cone(od, base_angle, fn) {
    //theta = (90 - base_angle); // half of the top angle
    //h = od / tan(theta);

    // tan base_angle = opp / adj = h / (od/2)
    h =  tan(base_angle) * (od / 2);
    
    cylinder(r1 = od/2, r2 = 0 , h = h, $fn=fn);
}



module funnel_id(id_top, id_bot, thk, h, fn) {
    difference() {
        // outer
        cylinder(r1 = (id_bot + thk * 2 ) / 2, r2 = (id_top + 2 * thk) / 2, h = h, $fn = fn );

        // inner negative
        translate([0,0,-eps]) {
            cylinder(r1 = id_bot / 2, r2 = id_top / 2, h = h + eps * 2, $fn = fn );
        }
    }
}
module funnel_od(od_top, od_bot, thk, h, fn) {
    difference() {
        // outer
        cylinder(r1 = od_bot / 2, r2 = od_top / 2, h = h, $fn = fn );

        // inner negative
        translate([0,0,-eps]) {
            cylinder(r1 = (od_bot - thk * 2 ) / 2, r2 = (od_top - 2 * thk) / 2, h = h + eps * 2, $fn = fn );
        }
    }
}
module funnel_angle(od_bot, theta, thk, h, fn) {
    // tan (90-theta) = ( od_extra / 2) / h
    od_top =  od_bot + 2 * h * tan(90 - theta);
    funnel_od(od_bot = od_bot, od_top = od_top, thk = thk, h = h, fn = fn);
}



// a ring with with a right-triangular cross-section, flat side inwards
module outer_fillet_ring(id, od, base_angle, fn) {
    difference() {
        cone(od = od, base_angle = base_angle, fn = fn);

        // tan ba = h / (id / 2)
        _neg_cyl_h = tan(base_angle) * (od / 2);
        translate([0,0,-eps])
        cylinder(d = id, h = _neg_cyl_h + eps * 2, $fn = fn);
    }
}




// ////////////////////////////////////////////////////////////////////






module petzval_adapter() {


    module inner_end_retainer_cap() {
        union() {
            // cap
            color("red")
            tube(id = back_ele_sm_dia - end_overlap, // TODO this needs to be small enough for the screw threads not to poke though!!! 
                od = barrel_od,                     //   or big enough that they grip
                h = end_cap_thk + eps,
                fn = fn
            );
            // barrel insert
            color("blue")
            translate([0,0,end_cap_thk]) {
                funnel_od(
                    od_top = barrel_id - (2 * clr), 
                    od_bot = barrel_id,  // no clr deliberately
                    thk = wall_thk, 
                    h = end_cap_insert_len, 
                    fn = fn
                );
            }
            // TODO:  consider an outer sleeve for more grip?  Is there room?
        }
    }


    module main_barrel() {
        union () {

            difference () {
                union() {
                    // main barrel
                    color("blue") 
                        tube(id = barrel_id, thk = wall_thk, h = overall_height, fn = fn);

                    // front retaining ring
                    //assert(front_ele_dia < barrel_id && front_ele_dia > barrel_id - end_overlap);
                    tube(od = barrel_id + eps, thk = barrel_id - front_ele_dia - ele_overlap * 2 , h = front_retaining_ring_thk, fn = fn);
                }
                    // inwards bevel on the front
                    color("red") 
                    //cone(od = barrel_od-3, base_angle = 30, fn = fn); // use without lens hood
                    cone(od = barrel_od - wall_thk * 2, base_angle = 30, fn = fn); // needs to match hood thickness for no overhang
            }



            // mounting flange 
            translate([0,0,flange_start]) {

                // centering ring that fits inside the adapter to keep everything in position - should be snug fit
                color("orange")
                    tube(od = throat, id = barrel_od - eps, h = 3, fn = fn);

                color("purple")
                mirror([0,0,1])
                    difference() {
                        cone(od = flange_dia, base_angle = _flange_base_angle, fn = fn);
                        translate([0,0,-eps]) {
                            // tan  (base_angle) = opp / adj =    h / (flange_dia / 2)
                            cylinder(r1 = (barrel_od - eps) / 2, r2 = (barrel_od - eps) / 2, h = _cone_h + 2 * eps, $fn = fn);
                        }
                    }
            }

           
        }
    }

    
    // consider 3 tube design with thinner walls?
    
    module front_spacer() {
        // front spacer
        _id =  front_ele_dia - ele_overlap * 2;
            tube(od = barrel_id - clr, id = _id, h = first_to_stop - stop_thk, fn = fn);
    }

    module back_spacer() {
        // back spacer - must account for rear cap insert length - I think the previous statement is wrong
        _id =  back_ele_dia - ele_overlap * 2;
            tube(od = barrel_id - clr, id = _id, h = stop_to_second, fn = fn);

    }

    module lens_hood() {
         // lens hood




        //hood_length = 15;
        hood_length = _ring_h;
        hood_end_od = barrel_od * 1.25;
        coupler_overlap = 6;
        //coupler_barrel_l = coupler_overlap * 2.35;
        coupler_barrel_l = coupler_overlap; 
        mating_disc = 2;
        translate([0,0,hood_length + coupler_overlap + mating_disc])
        mirror([0,0,1])  

            union() {

                // hood
                translate([0,0,coupler_overlap + mating_disc - eps]) {
                    funnel_angle(
                        od_bot = barrel_od,
                        theta = _flange_base_angle,
                        thk = wall_thk,
                        h = hood_length,
                        fn = fn
                    );
                }


                // coupling ring
                tube(id = barrel_od + clr, thk = wall_thk, h = coupler_barrel_l + mating_disc, fn = fn);


                // mating disc
                color("red")
                translate([0,0,coupler_overlap]) {
                    tube(od = barrel_od + clr, 
                            id = barrel_od - 2 * wall_thk,
                            h = mating_disc, 
                            fn = fn
                    );
                }

            }
                // fillet ring
                color("green")
                translate([0,0,hood_length])
                mirror([0,0,1])
                outer_fillet_ring(
                    id = barrel_od + clr,
                    od = barrel_od + clr + 2 * wall_thk,
                    base_angle = 45,
                    fn = fn
                );
        
    }
            // translate([0,0,-hood_length+eps]) { 
            //     funnel_od(
            //         od_top = barrel_od,
            //         od_bot = hood_end_od,
            //         thk = wall_thk,
            //         h = hood_length
            //     );
            // }



    module stop_disc(fstop) {
        
        /* 

        fstop = focal length / aperture dia
        dia = 125 / 5.6 =~ 22.3mm
        
        entrance pupil mag
        m =~ f / (f - d)  = 125 / (125 - 35) = 1.4
        where d is distance to stop from first element

        so 22.3 / 1.4 =~  16mm hole

        */

        function aperture_hole_dia(fstop)  = (125 / fstop) / 1.4;
            

        //_stop_dia = 16;
        _stop_dia = aperture_hole_dia(fstop);
        _fsize = 6;
        tube(od=barrel_id - clr, id = _stop_dia, h = stop_thk, fn = fn);

        color("red")
        linear_extrude(stop_thk  + .6)
        translate([0,barrel_id / 3, 0])
        text(str("f/",fstop), size=_fsize, valign="center", halign="center");
    }









    spread = barrel_id + 2 * wall_thk + 30;

    //main_barrel();
    // translate([spread, 0, 0])
        // front_spacer();
    // translate([0, spread, 0])
    //    back_spacer();
    // translate([0, -spread, 0])
         inner_end_retainer_cap();
    // translate([-spread, 0, 0]) 
    //     lens_hood();

    // translate([spread * 2, 0, 0])
    //     stop_disc(fstop = 5.6);
    // translate([0, spread * 2, 0])
    //     stop_disc(fstop = 4);
    // translate([0, -spread * 2, 0])
    //     stop_disc(fstop = 8);

    
    // stop discs

//         stop_disc(fstop = 5.6);
//     translate([0, spread * .8, 0])
//         stop_disc(fstop = 4);
//     translate([0, -spread * .8, 0])
//         stop_disc(fstop = 8);



}


petzval_adapter();