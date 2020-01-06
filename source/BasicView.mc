using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Timer as Timer;

enum {
  SCREEN_SHAPE_CIRC = 0x000001,
  SCREEN_SHAPE_SEMICIRC = 0x000002,
  SCREEN_SHAPE_RECT = 0x000003
}

enum {
  FIELD_DDMM     = 0,
  FIELD_MMDD     = 1,
  FIELD_DAYDD    = 2,
  FIELD_DDMONTH  = 3,
  FIELD_MONTH    = 4,
  FIELD_DAY      = 5,
  FIELD_STEPS    = 6,
  FIELD_DISTANCE = 7,
  FIELD_STEPPROG = 8,
  FIELD_GOAL     = 9,
  FIELD_BATTERY  = 10,
  FIELD_BT       = 11
}


class BasicView extends Ui.WatchFace {

    // globals
    var debug = false;

    // timers - time between frames (approx 12fps @ 80ms)
    var timer_timeout = 80;
    var timer_steps = timer_timeout;
    var timer1;
    var has1hz = false;

    // sensors / status
    var battery = 0;
    var bluetooth = true;

    // time
    var hour = null;
    var minute = null;
    var day = null;
    var day_of_week = null;
    var month_str = null;
    var month = null;

    // layout
    var vert_layout = false;
    var canvas_h = 0;
    var canvas_w = 0;
    var canvas_shape = 0;
    var canvas_rect = false;
    var canvas_circ = false;
    var canvas_semicirc = false;
    var canvas_tall = false;
    var canvas_r240 = false;

    // positional offsets for items
    var y_offset_nyan = 30;
    var s_offset_date = 40;
    var s_offset_time = 80;
    var s_xoffset_batt = 20;
    var s_yoffset_batt = 10;

    // settings
    var set_leading_zero = false;
    var set_field = 2;
    var goal = 0;
    var steps = 0;
    var stepProgress = 0;
    var distance = 0;
    var is_metric = true;

    // fonts
    var f_nyan_font = null;
    var f_nyan_font_alpha = null;

    // bitmaps
    var b_nyan_head = null;
    var b_nyan_body = null;
    var b_nyan_legs = null;
    var b_nyan_tail_1 = null;
    var b_nyan_tail_2 = null;
    var b_nyan_tail_3 = null;
    var b_nyan_tail_4 = null;
    var b_nyan_tail_5 = null;
    var b_nyan_tail_6 = null;
    var b_nyan_tail = [];
    var b_rainbow = null;
    var b_rainbow_bt = null;
    var b_star_1 = null;
    var b_star_2 = null;
    var b_star_3 = null;
    var b_star_4 = null;
    var b_star_5 = null;
    var b_star_6 = null;
    var b_star = [];

    // animation settings
    var ani_step = 0;
    var is_animating = false;
    var num_of_frames = 12;
    var wave = [1,1,2,2,3,2,1,1,2,2,3,2];
    var nyan_head_x = [0,1,1,1,0,0,0,1,1,1,0,0];
    var nyan_head_y = [0,0,1,1,1,0,0,0,1,1,1,0];
    var nyan_body_y = [-1,-1,0,0,0,0,-1,-1,0,0,0,0];
    var nyan_legs_x = [ 1, 2,2,1,0,0, 1,  2, 3, 2, 1, 0];
    var nyan_legs_y = [-1,-1,0,0,0,0, -1,-1, 0, 0, 0, 0];

    // star details
    const sprite_star_height = 9;
    const sprite_star_width = 9;
    const num_of_frames_star = 6;
    var actual_sprite_star_height = 0;
    var actual_sprite_star_width = 0;
    var xp_star = 0;
    var yp_star = 0;
    var xp_star_prev = 0;
    var yp_star_prev = 0;

    // nyan details
    const sprite_height = 34;
    const sprite_width = 21;

    // default size of a pixel
    var sq_size = 4;

    // globals to pre-calc and speed up onPartialUpdate
    var sq_size_49 = 49*sq_size;
    var sq_size_23 = 23*sq_size;
    var sq_size_21 = 21*sq_size;
    var sq_size_15 = 15*sq_size;
    var sq_size_14 = 14*sq_size;
    var sq_size_11 = 11*sq_size;
    var sq_size_7 = 7*sq_size;
    var sq_size_4 = 4*sq_size;
    var sq_size_3 = 3*sq_size;
    var pw = 0;
    var ph = 0;
    var dh_fifth = 0;
    var dh_two_fifths = 0;


    // helper function to retrieve the field type to display
    function getField(type){

      if (type == FIELD_DDMM) {
        return day.toString() + "/" +  month.toString();
      }

      if (type == FIELD_MMDD) {
        return month.toString() + "/" +  day.toString();
      }

      if (type == FIELD_DAY) {
        return day_of_week.toUpper().substring(0,3);
      }

      if (type == FIELD_DAYDD) {
        return day_of_week.toUpper().substring(0,3) +  " " + day.toString();
      }

      if (type == FIELD_DDMONTH) {
        return day.toString() + " " + month_str.toUpper().substring(0,3);
      }

      if (type == FIELD_MONTH) {
        return month_str.toUpper().substring(0,3);
      }

      if (type == FIELD_STEPS) {
        return steps.toString();
      }

      if (type == FIELD_GOAL) {
        var this_steps = goal - steps;
        if ( this_steps > 0) {
          return (this_steps).toString();
        } else {
          return "+"+(steps - goal).toString();
        }
      }

      if (type == FIELD_STEPPROG) {
        return stepProgress.toString()+"%";
      }

      if (type == FIELD_DISTANCE) {
        var d_units = (is_metric) ? "KM" : "MI";
        return distance.format("%.1f") + d_units;
      }

      if (type == FIELD_BATTERY) {
        return battery.toString()+"%";
      }

      return "";

    }

    // helper function to retrieve the property for any numeric setting
    function readKeyInt(myApp,key,thisDefault) {
      var value = myApp.getProperty(key);
              if(value == null || !(value instanceof Number)) {
              if(value != null) {
                  value = value.toNumber();
              } else {
                      value = thisDefault;
              }
      }
      return value;
    }


    function initialize() {
     Ui.WatchFace.initialize();

     if( Toybox.WatchUi.WatchFace has :onPartialUpdate ) {
       has1hz = true;
     }

    }


    function onLayout(dc) {

      // reset the animation
      ani_step = 0;

      // w,h of canvas
      canvas_w = dc.getWidth();
      canvas_h = dc.getHeight();

      // check the orientation
      if ( canvas_h > (canvas_w*1.2) ) {
        vert_layout = true;
      } else {
        vert_layout = false;
      }

      // let's grab the canvas shape
      var deviceSettings = Sys.getDeviceSettings();
      canvas_shape = deviceSettings.screenShape;

      if (debug) {
        Sys.println(Lang.format("canvas_shape: $1$", [canvas_shape]));
      }

      // find out the type of screen on the device
      canvas_tall = (vert_layout && canvas_shape == SCREEN_SHAPE_RECT) ? true : false;
      canvas_rect = (canvas_shape == SCREEN_SHAPE_RECT && !vert_layout) ? true : false;
      canvas_circ = (canvas_shape == SCREEN_SHAPE_CIRC) ? true : false;
      canvas_semicirc = (canvas_shape == SCREEN_SHAPE_SEMICIRC) ? true : false;
      canvas_r240 =  (canvas_w == 240 && canvas_w == 240) ? true : false;

      // check the orientation, set the pixel size smaller
      if (canvas_rect || canvas_tall) {
        sq_size = 3;
      }

      // pre-calc a few constants to improve performance with rendering in onPartialUpdate()
      sq_size_49 = 49*sq_size;
      sq_size_23 = 23*sq_size;
      sq_size_21 = 21*sq_size;
      sq_size_15 = 15*sq_size;
      sq_size_14 = 14*sq_size;
      sq_size_11 = 11*sq_size;
      sq_size_7 = 7*sq_size;
      sq_size_4 = 4*sq_size;
      sq_size_3 = 3*sq_size;
      dh_fifth = (canvas_h/5);
      dh_two_fifths = (canvas_h*2/5);
      actual_sprite_star_height = sprite_star_height*sq_size;
      actual_sprite_star_width = sprite_star_width*sq_size;

      // size of nyan on screen
      pw = sq_size*sprite_height;
      ph = sq_size*sprite_width;


      // set offsets based on screen type
      // positioning for different screen layouts
      if (canvas_tall) {
        y_offset_nyan = 30;
        s_offset_time = 87;
        s_yoffset_batt = 8;
        s_xoffset_batt = canvas_w / 2;
      }
      if (canvas_rect) {
        y_offset_nyan = 35;
        s_offset_time = 70;
        s_yoffset_batt = 8;
        s_xoffset_batt = canvas_w - 20;
      }
      if (canvas_circ) {

        switch(canvas_w) {

          case 280:
            y_offset_nyan = 40;
            s_offset_time = 115;
            s_yoffset_batt = 25;
            s_xoffset_batt = canvas_w /2;
          break;

          case 260:
            y_offset_nyan = 40;
            s_offset_time = 105;
            s_yoffset_batt = 18;
            s_xoffset_batt = canvas_w /2;
          break;

          case 240:
            y_offset_nyan = 30;
            s_offset_time = 95;
            s_yoffset_batt = 14;
            s_xoffset_batt = canvas_w /2;
          break;

          case 218:
            y_offset_nyan = 30;
            s_offset_time = 86;
            s_yoffset_batt = 8;
            s_xoffset_batt = canvas_w /2;
          break;

          default:
            y_offset_nyan = 30;
            s_offset_time = 86;
            s_yoffset_batt = 8;
            s_xoffset_batt = canvas_w /2;

        }

      }
      if (canvas_semicirc) {
        y_offset_nyan = 32;
        s_offset_time = 70;
        s_yoffset_batt = -1;
        s_xoffset_batt = canvas_w /2;
      }

      // load fonts
      f_nyan_font = Ui.loadResource(Rez.Fonts.nyan_font_digits);
      f_nyan_font_alpha = Ui.loadResource(Rez.Fonts.nyan_font_alpha);

      // load resources for larger resolution devices
      if (sq_size > 3) {

        b_nyan_head = Ui.loadResource(Rez.Drawables.nyan_head_4);
        b_nyan_body = Ui.loadResource(Rez.Drawables.nyan_body_4);
        b_nyan_legs= Ui.loadResource(Rez.Drawables.nyan_legs_4);

        b_nyan_tail_1 = Ui.loadResource(Rez.Drawables.nyan_tail_4_1);
        b_nyan_tail_2 = Ui.loadResource(Rez.Drawables.nyan_tail_4_2);
        b_nyan_tail_3 = Ui.loadResource(Rez.Drawables.nyan_tail_4_3);
        b_nyan_tail_4 = Ui.loadResource(Rez.Drawables.nyan_tail_4_4);
        b_nyan_tail_5 = Ui.loadResource(Rez.Drawables.nyan_tail_4_5);
        b_nyan_tail_6 = Ui.loadResource(Rez.Drawables.nyan_tail_4_6);

        // an array of all the animation frames for nyan
        b_nyan_tail = [b_nyan_tail_1,b_nyan_tail_2,b_nyan_tail_3,b_nyan_tail_4,b_nyan_tail_5,b_nyan_tail_6];

        b_rainbow = Ui.loadResource(Rez.Drawables.rainbow_4);
        b_rainbow_bt = Ui.loadResource(Rez.Drawables.rainbow_bt_4);

        b_star_1 = Ui.loadResource(Rez.Drawables.star_4_1);
        b_star_2 = Ui.loadResource(Rez.Drawables.star_4_2);
        b_star_3 = Ui.loadResource(Rez.Drawables.star_4_3);
        b_star_4 = Ui.loadResource(Rez.Drawables.star_4_4);
        b_star_5 = Ui.loadResource(Rez.Drawables.star_4_5);
        b_star_6 = Ui.loadResource(Rez.Drawables.star_4_6);

        // an array of all the animation frames for the star
        b_star = [b_star_1,b_star_2,b_star_3,b_star_4,b_star_5,b_star_6];

      } else {

        // load the smaller pixel resources here
        b_nyan_head = Ui.loadResource(Rez.Drawables.nyan_head);
        b_nyan_body = Ui.loadResource(Rez.Drawables.nyan_body);
        b_nyan_legs= Ui.loadResource(Rez.Drawables.nyan_legs);

        b_nyan_tail_1 = Ui.loadResource(Rez.Drawables.nyan_tail_1);
        b_nyan_tail_2 = Ui.loadResource(Rez.Drawables.nyan_tail_2);
        b_nyan_tail_3 = Ui.loadResource(Rez.Drawables.nyan_tail_3);
        b_nyan_tail_4 = Ui.loadResource(Rez.Drawables.nyan_tail_4);
        b_nyan_tail_5 = Ui.loadResource(Rez.Drawables.nyan_tail_5);
        b_nyan_tail_6 = Ui.loadResource(Rez.Drawables.nyan_tail_6);

        b_nyan_tail = [b_nyan_tail_1,b_nyan_tail_2,b_nyan_tail_3,b_nyan_tail_4,b_nyan_tail_5,b_nyan_tail_6];

        if (canvas_semicirc) {
          b_rainbow = Ui.loadResource(Rez.Drawables.rainbow_fr);
          b_rainbow_bt = Ui.loadResource(Rez.Drawables.rainbow_bt_fr);
        } else {
          b_rainbow = Ui.loadResource(Rez.Drawables.rainbow);
          b_rainbow_bt = Ui.loadResource(Rez.Drawables.rainbow_bt);
        }

        b_star_1 = Ui.loadResource(Rez.Drawables.star_1);
        b_star_2 = Ui.loadResource(Rez.Drawables.star_2);
        b_star_3 = Ui.loadResource(Rez.Drawables.star_3);
        b_star_4 = Ui.loadResource(Rez.Drawables.star_4);
        b_star_5 = Ui.loadResource(Rez.Drawables.star_5);
        b_star_6 = Ui.loadResource(Rez.Drawables.star_6);

        b_star = [b_star_1,b_star_2,b_star_3,b_star_4,b_star_5,b_star_6];

      }



    }


    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }


    //! Update the view
    function onUpdate(dc) {

      // grab the settings to display the correct field
      set_field = readKeyInt(App.getApp(),"field",2);

      // grab time objects
      var clockTime = Sys.getClockTime();
      var date = Time.Gregorian.info(Time.now(),0);

      // define time, day, month variables
      hour = clockTime.hour;
      minute = clockTime.min;
      day = date.day;
      month = date.month;
      day_of_week = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM).day_of_week;
      month_str = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM).month;

      // grab battery
      var stats = Sys.getSystemStats();
      var batteryRaw = stats.battery;
      battery = batteryRaw > batteryRaw.toNumber() ? (batteryRaw + 1).toNumber() : batteryRaw.toNumber();

      // do we have bluetooth?
      var deviceSettings = Sys.getDeviceSettings();
      bluetooth = deviceSettings.phoneConnected;

      // step progress
      var thisActivity = ActivityMonitor.getInfo();

      // turn debug values on
      if (debug) {
        goal = 12000;
        steps = Math.rand() % goal;
      } else {
        steps = thisActivity.steps;
        goal = thisActivity.stepGoal;
      }

      // define our current step progress in terms of % completed
      stepProgress = (100*(steps.toFloat()/goal.toFloat())).toNumber();
      var cm_distance = thisActivity.distance;

      if (deviceSettings.distanceUnits == Sys.UNIT_METRIC) {
        distance = (cm_distance).toFloat() / 100000;
        is_metric = true;
      } else {
        distance = (cm_distance).toFloat() / 160934;
        is_metric = false;
      }

      // 12-hour support
      if (hour > 12 || hour == 0) {
          if (!deviceSettings.is24Hour)
              {
              if (hour == 0)
                  {
                  hour = 12;
                  }
              else
                  {
                  hour = hour - 12;
                  }
              }
      }


      // add padding to units if required
      if( minute < 10 ) {
          minute = "0" + minute;
      }

      // add leading zero for 24hr settings
      if( hour < 10 && deviceSettings.is24Hour) {
          hour = "0" + hour;
      }

      if( day < 10 ) {
          day = "0" + day;
      }

      if( month < 10 ) {
          month = "0" + month;
      }


      // clear the screen clips and set BG
      if (has1hz) {
        dc.clearClip();
      }

      // clear the screen
      dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_DK_BLUE);

      // do we need to clear the screen?
      dc.clear();

      // w,h of canvas
      var dw = canvas_w;
      var dh = canvas_h;

      var yp = (dh/2)-(ph/2);
      var xp = (dw-pw)/2;

      // offset to center layout
      var x_offset = 0;
      var y_offset = 0;

      // reset the animation counter
      if (ani_step == num_of_frames) {
        ani_step = 0;
      }

      // draw the nyan!
      // --------------------
      drawNyan(dc,false);


      // draw date/field
      // --------------------
      var this_field = getField(set_field);

      dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
      dc.drawText(dw/2 + 2, dh - (s_offset_time) + (s_offset_date) + 2, f_nyan_font_alpha, this_field, Gfx.TEXT_JUSTIFY_CENTER);

      dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
      dc.drawText(dw/2, dh - (s_offset_time) + (s_offset_date), f_nyan_font_alpha, this_field, Gfx.TEXT_JUSTIFY_CENTER);


      // draw time
      // --------------------
      dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
      dc.drawText(dw/2 + 3, dh - (s_offset_time) + 3, f_nyan_font, hour.toString() + ":" + minute.toString(), Gfx.TEXT_JUSTIFY_CENTER);

      dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
      dc.drawText(dw/2, dh - (s_offset_time), f_nyan_font, hour.toString() + ":" + minute.toString(), Gfx.TEXT_JUSTIFY_CENTER);


      // draw battery (if battery is low) "@" glyph
      // --------------------
      if (battery < 21) {
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(s_xoffset_batt + 2, s_yoffset_batt + 2, f_nyan_font_alpha, "@", Gfx.TEXT_JUSTIFY_CENTER);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(s_xoffset_batt, s_yoffset_batt, f_nyan_font_alpha, "@", Gfx.TEXT_JUSTIFY_CENTER);
      }


    }

    // here's the onPartialUpdate() code for 1hz
    // --------------------
    function onPartialUpdate(dc) {

      if (!is_animating) {
        drawNyan(dc,true);
      }

    }

    // our drawNyan() function
    // --------------------
    // dc - we pass through the drawing context, and
    // do1hz - whether we should run a "partial" update (false = render everything, true = render with setClip)
    function drawNyan(dc,do1hz) {

      // w,h of canvas
      var dw = canvas_w;
      var dh = canvas_h;

      var yp = (dh/2)-(ph/2);
      var xp = (dw-pw)/2;

      // let's pre-calc the modulus for our animation steps, this improves performance by 0.5ms :)
      var step = ani_step%12;
      var step_half = ani_step%6;

      // position of nyan + rainbow
      yp = yp - sq_size - y_offset_nyan;


      // if we're in 1hz mode, clear only the sections of the dc that we will re-draw
      // --------------------

      // let's reset the colour to our background colour
      dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_DK_BLUE);

      // let's clip and clear the pervious star rendered to the dc
      if (do1hz) {
        dc.setClip(xp_star_prev, yp_star_prev, actual_sprite_star_width, actual_sprite_star_height);
        dc.clear();
      }

      // let's clip and clear the previous nyan, and rainbow rendered to the dc
      if (do1hz) {
        dc.setClip(xp + (-sq_size_14), yp - (sq_size) + (sq_size * wave[step]),49*sq_size,23*sq_size);
        dc.clear();
      }

      // draw rainbow
      // --------------------
      var rainbow_sprite = null;

      // if bluetooth not available, then display the alternate rainbow
      if (bluetooth) {
        rainbow_sprite = b_rainbow;
      } else {
        rainbow_sprite = b_rainbow_bt;
      }

      // small pre-calc, saves 0.2ms :)
      var yp_rainbow = yp + (sq_size_3);

      // each part of the rainbow is the same bitmap, x4 and shifted in different x/y locations
      dc.drawBitmap(xp + (0), yp_rainbow + (sq_size * wave[step]), rainbow_sprite);
      dc.drawBitmap(xp + (-sq_size_7), yp_rainbow + (sq_size * wave[(ani_step+1)%12]), rainbow_sprite);
      dc.drawBitmap(xp + (-sq_size_14), yp_rainbow + (sq_size * wave[(ani_step+2)%12]), rainbow_sprite);
      dc.drawBitmap(xp + (-sq_size_21), yp_rainbow + (sq_size * wave[(ani_step+3)%12]), rainbow_sprite);


      // draw nyan cat
      // --------------------
      yp = (dh/2) - (ph/2) - y_offset_nyan + (sq_size * wave[step]);
      xp = (dw-pw)/2 + (sq_size_7);

      // each part of the nyan cat is animated and drawn independently
      dc.drawBitmap(xp + (-sq_size_3) + (nyan_legs_x[step]*sq_size), yp + (sq_size_15) + (nyan_legs_y[step]*sq_size), b_nyan_legs);
      dc.drawBitmap(xp, yp + (nyan_body_y[step]*sq_size), b_nyan_body);
      dc.drawBitmap(xp + (sq_size_11) + (nyan_head_x[step]*sq_size), yp + (sq_size_4) + (nyan_head_y[step]*sq_size), b_nyan_head);
      dc.drawBitmap(xp + (-sq_size_7), yp + (sq_size_7), b_nyan_tail[step_half]);

      // draw stars
      // --------------------
      // if we're at the start of the animation, position the star 1/5 of the screen height
      if (step == 0) {
        xp_star = dw - (actual_sprite_star_height);
        yp_star = dh_fifth - (actual_sprite_star_height/2) - y_offset_nyan;
        // if we're half way thru, position the star 2/5 of the screen height
      } else if (step_half == 0) {
        xp_star = dw - (actual_sprite_star_height);
        yp_star = dh_two_fifths - (actual_sprite_star_height/2) - y_offset_nyan;
      }

      // move and animate stars
      var star_direction = -sq_size_4 - sq_size_4;

      // let's save the current position of the star. we'll use this in the next re-draw to clear the dc
      xp_star_prev = xp_star + (star_direction * (step_half));
      yp_star_prev = yp_star;

      // ok, let's define the clip for where the star is going to be drawn on the dc
      if (do1hz) {
        dc.setClip(xp_star_prev, yp_star_prev, actual_sprite_star_width, actual_sprite_star_height);
      }

      // draw the star
      dc.drawBitmap(xp_star_prev, yp_star_prev, b_star[step_half]);

      // almost done, increase animation counter!
      ani_step++;

    }


    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }

    // this is our animation loop callback
    function callback_animate() {

      // redraw the screen
      Ui.requestUpdate();

      // timer not greater than 500ms? then let's start the timer again
      if (timer_steps < 500) {
        timer1 = new Timer.Timer();
        timer1.start(method(:callback_animate), timer_steps, false );
      } else {
        // timer exists? stop it
        if (timer1) {
          timer1.stop();
        }
      }


    }

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {

      if (timer1) {
        timer1.stop();
      }

      // let's start our animation loop
      is_animating = true;

      // let's start our animation loop
      timer1 = new Timer.Timer();
      timer1.start(method(:callback_animate), timer_steps, false );

    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {

      // let's stop our animation loop
      is_animating = false;
      Ui.requestUpdate();

      // bye bye timer
      if (timer1) {
        timer1.stop();
      }

      // reset the timer steps counter to the original timeout value
      timer_steps = timer_timeout;


    }

}


// This is Jim's code here to debug the 1hz power budget... commented this out before deploying to a watch
/*
class PartialDelegate extends Ui.WatchFaceDelegate
{

	function initialize() {
		WatchFaceDelegate.initialize();
	}

    function onPowerBudgetExceeded(powerInfo) {
        Sys.println( "Average execution time: " + powerInfo.executionTimeAverage );
        Sys.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
    }
}
*/
