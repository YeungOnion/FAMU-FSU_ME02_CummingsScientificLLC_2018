{\rtf1\ansi\ansicpg1252\cocoartf1561\cocoasubrtf200
{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww10800\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 /** Similar to previous implementation but attempting to include an array\
 * in data writing for sake of speed.\
 * Need to consider effect of this having too many data since old data can\
 * be overwritten before being put to the SD card\
 */\
 \
#include <SPI.h>\
#include <SD.h>\
#include <TimerThree.h>\
\
#define _READFREQ_ (400) // in Hz. Max is probably around 8000
#define _READTIME_ (1000000/_READTIME_) // period between interrupts in microseconds
#define DEBUG 0\
#define numSensors 4\
#define numValues 500        // amount values in buffer. Teensy 3.2 has 16KB RAM so 16/4KB=4KB=1024 element buffer max
#define A2D_RESOLUTION 10    // resolution of ADC. At +/- 200g at 10 bits = 0.4 is best resolution\
\
unsigned char pinX[numSensors] = \{A2, A5, A8, A11\};\
unsigned char pinY[numSensors] = \{A1, A4, A7, A10\};\
unsigned char pinZ[numSensors] = \{A0, A3, A6, A9\};\
\
int datax[numSensors][numValues] = \{0\};\
int datay[numSensors][numValues] = \{0\};\
int dataz[numSensors][numValues] = \{0\};\
long unsigned int readTime[numValues] = \{0\}; \
const int chipSelect = 10; // SD card pin\
volatile int valueCt = 0;  // where next accel data read into. voltatile because changes during interrupt (prob not needed for arrays)\
\
\
void setup() \
\{\
  pinMode(13, OUTPUT);  // startup blink sequence\
  blinkSeq();\
  blinkSeq();\
  \
  Serial.begin(19200);\
  \
  // put your setup code here, to run once:   \
  Serial.print("Initializing SD card...");\
  \
  if (!SD.begin(chipSelect)) \{ // see if the card is present and can be initialized:\
//    Serial.println("Card failed, or not present");\
    // don't do anything more:\
    while(1)\{\
      blinkSeq(); // constant blinking = problem\
      delay(1000);\
    \}\
    return;\
  \}\
  Serial.println("card initialized.");\
\
// not necessary because analogRead sets up everything for ADC\
//  for (int i=0; i<numSensors; i++)\
//  \{\
//    pinMode(pinX[i], INPUT);\
//    pinMode(pinY[i], INPUT);\
//    pinMode(pinZ[i], INPUT);\
//  \}\
  \
  Timer3.initialize(_READTIME_);\
  Timer3.attachInterrupt(readSensors);\
  digitalWrite(13, LOW);\
  analogReadResolution(A2D_RESOLUTION);    //set resolution\
\
  SD.remove("DATA.TXT"); // delete old file on startup\
\}\
\
void loop() \
\{\
  if (valueCt == numValues)\{\
//    noInterrupts(); // disable interrupts during SD writing\
    valueCt = 0; // place data back at the beginning of the array\
    writeToSD("data.txt");\
//    interrupts(); // re-enable interrupts\
  \}\
// Serial.print(pinX[3]); // MAKE SURE THIS IS COMMENTED OUT DURING TESTING FOR MINIMUM 100Hz GUARANTEE\
//        Serial.print(",");        //comma delimeter\
// Serial.print(pinY[3]); // MAKE SURE THIS IS COMMENTED OUT DURING TESTING FOR MINIMUM 100Hz GUARANTEE\
//       Serial.print(",");        //comma delimeter\
//  Serial.println(pinZ[3]); // MAKE SURE THIS IS COMMENTED OUT DURING TESTING FOR MINIMUM 100Hz GUARANTEE\
\}\
\
void writeToSD(char* fileName)\
\{\
  \
  // open the file. note that only one file can be open at a time,\
  // so you have to close this one before opening another.\
  File dataFile = SD.open(fileName, FILE_WRITE);\
\
  if (DEBUG)\
  \{\
    for(int j = 0; j < numValues;  j++)\{\
      //Serial.print(readTime[j]);   //PRINT TIME\
      //Serial.print(",");        //comma delimeter\
      for(int i = 1; i < 2; i++)\{//print first two accel data from buffer to Serial\
        Serial.print(datax[i][j]);\
        Serial.print(",");        //comma delimeter\
        Serial.print(datay[i][j]);\
        Serial.print(",");        //comma delimeter\
        Serial.print(dataz[i][j]);\
        Serial.print(",");        //comma delimeter        \
      \} \
      Serial.println(" ");\
    \}\
  \}\
//*/\
\
  // if the file is available, write to it:\
  if (dataFile) \{      \
    for(int j = 0; j < numValues;  j++)\{ // for each value stored\
        dataFile.print(readTime[j]);  \
        dataFile.print(",");        //comma delimeter\
      \
        for(int i = 0; i < numSensors; i++)\{//print first two accel data from buffer to SD\
          dataFile.print(datax[i][j]);\
          dataFile.print(",");        //comma delimeter\
          dataFile.print(datay[i][j]);\
          dataFile.print(",");        //comma delimeter\
          dataFile.print(dataz[i][j]);\
          dataFile.print(",");        //comma delimeter        \
        \} \
        dataFile.println(" ");\
      \}\
\
      dataFile.close();\
  \}\
  // if the file isn't open, pop up an error:\
  else \{\
    Serial.println("error opening datalog.txt");\
    digitalWrite(13, HIGH);\
  \}\
\
  \
\}\
\
void readSensors()\
\{ \
  for (int i=0; i<numSensors; i++)\
  \{\
    datax[i][valueCt] = analogRead(pinX[i]);\
    datay[i][valueCt] = analogRead(pinY[i]);\
    dataz[i][valueCt] = analogRead(pinZ[i]);\
    readTime[valueCt] = micros();\
  \}\
  valueCt++;\
  return;\
\}\
\
void blinkSeq()\
\{\
  digitalWrite(13, HIGH); delay(250);\
  digitalWrite(13, LOW ); delay(500);\
  digitalWrite(13, HIGH); delay(250);\
  digitalWrite(13, LOW ); delay(500);\
\}\
}
