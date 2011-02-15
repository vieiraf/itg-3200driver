// ITG-3200_calib
// Copyright 2010-2011 Filipe Vieira & various contributors.
// http://code.google.com/p/itg-3200driver
// Calculating m and c values for temperature compensated gyro.
// README:
//    1 - Run this code with a cold sensor;      
//    2 - Sampling reference and 1st set will run;
//    3 - Sampling 2nd set will run;
//        If you see "warning (2): temperature unchanged!" it means that temperature hasn't 
//        changed enough to allow a good calibration. Solution: warm or cool sensor btw 2 to 5 degrees!
//        If using artificial ways to warm/cool sensor make sure it is not affected by vibrations.
//    4 - pick the resulted line of code to your code to allow temperature compensation. 
//        The resulting line of code should look something like this example:
//
//           gyro.tc_param(-0.0121413028, 0.0272047185, -0.0273216032,
//                         65.5820007324, -13.6820001602, -21.9939994812, 1566);

#include <Wire.h>
#include <ITG3200.h>

ITG3200 gyro = ITG3200();

// tc variables
const int totSamples = 500; // number of samples to be used.
const int sampleDelay = 3; // ms btw samples
const int dT = 250; // min. temperature btw set1 and set2 (use something btw 2 and 5 degrees.
const bool tempTarget = false; // force a specific temperature for bias sampling?
const int refTemp = 2500; // target = refTemp +- refdT
const int refdT = 025;

// other variables
float  x,y,z,t;
int ix, iy, iz, it;
  
void setup(void) {
  Serial.begin(9600);
  Wire.begin();      // if experiencing gyro problems/crashes while reading XYZ values
                     // please read class constructor comments for further info.
  delay(1000);
  // Use ITG3200_ADDR_AD0_HIGH or ITG3200_ADDR_AD0_LOW as the ITG3200 address 
  // depending on how AD0 is connected on your breakout board, check its schematics for details
  gyro.init(ITG3200_ADDR_AD0_HIGH); 
  
  tc();     
}

void loop(void) {   
}

void tc() {
  float m[3]={0,0,0}, b[3]={0,0,0};
  int reft;

  int xyz[3];
  int temp1, i;
  float Samples[8]={0,0,0,0,0,0,0,0}; //x1,y1,z1,t1, x2,y2,z2,t2
  long temp=0;
    
  // b calculating bias at reference temperature
  Serial.print("Sampling reference... t0=");
  gyro.readTemp(&temp1);
  Serial.println(temp1,DEC);        
  i = 0;
  do {  
    gyro.readGyroRaw(xyz);
    delay(sampleDelay);
    gyro.readTemp(&temp1); 
    
    if (tempTarget && (temp1 < (refTemp-refdT) || temp1 > (refTemp+refdT))) {
      Serial.print("warning (1): not at target temperature!   ");
      Serial.print(refTemp-refdT);
      Serial.print("< t <");
      Serial.print(refTemp+refdT);
      Serial.print("   current=");
      Serial.println(temp1);
    }
    else {
      b[0] += xyz[0];
      b[1] += xyz[1];
      b[2] += xyz[2];
      temp += temp1;
      i++;
    }
  } while (i < totSamples);
  b[0] = -b[0] / totSamples;
  b[1] = -b[1] / totSamples;
  b[2] = -b[2] / totSamples;  
  reft = temp / (float)totSamples +0.5;  
  
  // 1st set of samples uses reference samples.
  Samples[0] = -b[0];
  Samples[1] = -b[1];
  Samples[2] = -b[2];
  Samples[3] = reft; // t
    
  // 2nd set of samples
  Serial.print("Sampling 2nd set of samples... t0=");
  gyro.readTemp(&temp1);  
  Serial.println(temp1,DEC);
  i = 0;
  do {
    gyro.readGyroRaw(xyz);
    delay(sampleDelay);    
    gyro.readTemp(&temp1);
    
    if ((temp1 > (Samples[3]-dT)) && (temp1 < (Samples[3]+dT))) {
      Serial.print("warning (2): temperature unchanged!   ");
      Serial.print(Samples[3]-dT);
      Serial.print("> t >");
      Serial.print(Samples[3]+dT);
      Serial.print("   current=");
      Serial.println(temp1);
    }
    else {
      Samples[4] += xyz[0];
      Samples[5] += xyz[1];
      Samples[6] += xyz[2];        
      Samples[7] += temp1; 
      i++;
    }
  } while (i < totSamples);
  Samples[4] /= totSamples;
  Samples[5] /= totSamples;
  Samples[6] /= totSamples;
  Samples[7] /= totSamples; // t
   
  // calc m  
  m[0] = (Samples[0] - Samples[4])/(Samples[3] - Samples[7]);
  m[1] = (Samples[1] - Samples[5])/(Samples[3] - Samples[7]);
  m[2] = (Samples[2] - Samples[6])/(Samples[3] - Samples[7]);  
 
  Serial.println("done.");
  
  Serial.println("===TC data===");   
  Serial.print("gyro.tc_param(");
  Serial.print(m[0],DEC);
  Serial.print(", ");    
  Serial.print(m[1],DEC);
  Serial.print(", ");    
  Serial.print(m[2],DEC);
  Serial.print(", ");    
  Serial.print(b[0],DEC);
  Serial.print(", ");  
  Serial.print(b[1],DEC);
  Serial.print(", ");  
  Serial.print(b[2],DEC);
  Serial.print(", ");  
  Serial.print(reft,DEC);
  Serial.println(");");
  Serial.println("======");
}
