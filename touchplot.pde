/*
 touchplot.pde
 Copyright (c) 2014-2015 Kitronyx http://www.kitronyx.com
 GPL V3.0
*/

import processing.serial.*; // import the Processing serial library
import controlP5.*;

// gui controls
ControlP5 cp5;
DropdownList dSerial;
Button bStartStop;
boolean do_data_acquisition = false;

Serial a_port; // The serial port

final int MAX_TOUCH = 10;
final int TOUCH_ID = 0;
final int TOUCH_PEN = 1;
final int TOUCH_X = 2;
final int TOUCH_Y = 3;
final int MAX_COORD = 4096; // 4095?
final int NO_TOUCH = -1;

final int nsensor = 4;

boolean bufferLocked = true;

int[][] touch = new int[MAX_TOUCH][4];

int canvas_origin_x;
int canvas_origin_y;
int canvas_width;
int canvas_height;
int touch_radius;
int[][] touch_color = {
    {
        0, 0, 0
    }
    , 
    {
        0, 0, 255
    }
    , 
    {
        0, 255, 0
    }
    , 
    {
        0, 255, 255
    }
    , 
    {
        255, 0, 0
    }
    , 
    {
        255, 0, 255
    }
    , 
    {
        255, 255, 0
    }
};

void setup()
{
    size(1024, 768);

    for (int i = 0; i < touch.length; i++)
    {
        touch[i][TOUCH_ID] = NO_TOUCH;
        touch[i][TOUCH_PEN] = NO_TOUCH;
        touch[i][TOUCH_X] = NO_TOUCH;
        touch[i][TOUCH_Y] = NO_TOUCH;
    }

    canvas_origin_x = width/10;
    canvas_origin_y = height/10;
    canvas_width = width*8/10;
    canvas_height = height*8/10;
    touch_radius = width/20;

    //a_port = new Serial(this, Serial.list()[0], 115200);
    
    // setup gui controls
    int controlWidth = 60;
    int controlHeight = 10;
    cp5 = new ControlP5(this);
    dSerial = cp5.addDropdownList("Serial").setPosition(10, 20);
    dSerial.captionLabel().set("Choose Port");
    for (int i=0; i<Serial.list ().length; i++)
    {
        dSerial.addItem(Serial.list()[i], i);
    }
    bStartStop = cp5.addButton("Start (s)", 0, dSerial.getWidth()+20, 10, controlWidth, controlHeight);
    
    draw_gui();
}

void controlEvent(ControlEvent theEvent)
{
    if (theEvent.isController())
    {
        if (theEvent.controller() == bStartStop)
        {
            if (do_data_acquisition)
            {
                bStartStop.setCaptionLabel("Start (s)");
                a_port.stop();
            }
            else
            {
                bStartStop.setCaptionLabel("Stop (s)");
                a_port = new Serial(this, Serial.list()[0], 115200);
                
                // if (!comPort.equals("Not Found"))
                // {
                //     startSerial();
                // }
            }
            
            do_data_acquisition = !do_data_acquisition;
        }
    }
}

void draw_gui()
{
    background(70, 100, 255);
    fill(255);
    rect(canvas_origin_x, canvas_origin_y, canvas_width, canvas_height);
    rect(width/2-100, 0, 200, 50, 0, 0, 100, 100);
    textAlign(CENTER);
    textSize(25);
    fill(0);
    text("KITRONYX", width/2, 30);
    
    fill(0);
    textAlign(RIGHT);
    textSize(12);
    text("Copyright(c) 2014-2015 Kitronyx Inc. All rights reserved", width-10, height-10);
}

void draw()
{
    if (bufferLocked == false)
    {
        draw_gui();

        noStroke();

        for (int i = 0; i < 10; i++)
        {
            if (touch[i][TOUCH_ID] != NO_TOUCH)
            {
                int touch_color_index = i % 7;
                int touchblob_x = canvas_origin_x + touch[i][TOUCH_X]*canvas_width/MAX_COORD;
                int touchblob_y = canvas_origin_y + touch[i][TOUCH_Y]*canvas_height/MAX_COORD; 
                fill(touch_color[touch_color_index][0], touch_color[touch_color_index][1], touch_color[touch_color_index][2]);
                ellipse(touchblob_x, 
                touchblob_y, 
                touch_radius, 
                touch_radius);
                fill(0);
                textSize(10);
                if (touchblob_x > width/2)
                {
                    textAlign(RIGHT);
                    text(String.format("ID %d (%d, %d)", touch[i][TOUCH_ID], touch[i][TOUCH_X], touch[i][TOUCH_Y]), 
                    touchblob_x - touch_radius/2, 
                    touchblob_y);
                } else
                {
                    textAlign(LEFT);
                    text(String.format("ID %d (%d, %d)", touch[i][TOUCH_ID], touch[i][TOUCH_X], touch[i][TOUCH_Y]), 
                    touchblob_x + touch_radius/2, 
                    touchblob_y);
                }
            }
        }
    }
}

void serialEvent(Serial a_port)
{
    // Lock data buffer.
    bufferLocked = true;

    try
    {
        // read the serial buffer:
        String myString = a_port.readStringUntil('\n');

        // if you got any bytes other than the linefeed:
        myString = trim(myString);

        // split the string at the commas
        // and convert the sections into integers:
        int sensors[] = int(split(myString, ','));

        // print out the values you got:
        for (int sensorNum = 0; sensorNum < sensors.length; sensorNum++)
        {
            print("Sensor " + sensorNum + ": " + sensors[sensorNum] + "\t");
        }
        println();

        if (sensors.length < nsensor)
        {
            println("Received data corrupted.");
            println("Number of measurements is " + sensors.length + " while " + nsensor + " measurements estimated.");
        } else
        {
            // fill graph buffer with measurements
            int tid = sensors[0];
            int tpen = sensors[1];
            int tx = sensors[2];
            int ty = sensors[3];
            if (tpen == 1)
            {
                touch[tid][TOUCH_ID] = tid;
                touch[tid][TOUCH_PEN] = tpen;
                touch[tid][TOUCH_X] = tx;
                touch[tid][TOUCH_Y] = ty;
            } else
            {
                touch[tid][TOUCH_ID] = NO_TOUCH;
                touch[tid][TOUCH_PEN] = NO_TOUCH;
                touch[tid][TOUCH_X] = NO_TOUCH;
                touch[tid][TOUCH_Y] = NO_TOUCH;
            }
        }
    }
    catch (Exception e)
    {
        //println("Exception occurs with message " + e.getMessage());
    }

    // Unlock buffer
    bufferLocked = false;
}
