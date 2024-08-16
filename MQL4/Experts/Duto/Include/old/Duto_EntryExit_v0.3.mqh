//+------------------------------------------------------------------+
//|                                               Duto_EntryExit.mqh |
//|                                               Tony Goss, 19Apr24 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property strict


enum ENUM_SIGNAL_ENTRY
{
   SIGNAL_ENTRY_NEUTRAL = 0, // SIGNAL ENTRY NEUTRAL
   SIGNAL_ENTRY_BUY = 1,     // SIGNAL ENTRY BUY
   SIGNAL_ENTRY_SELL = -1,   // SIGNAL ENTRY SELL
};

enum ENUM_SIGNAL_EXIT{
   SIGNAL_EXIT_NEUTRAL=0,     //SIGNAL EXIT NEUTRAL
   SIGNAL_EXIT_BUY=1,         //SIGNAL EXIT BUY
   SIGNAL_EXIT_SELL=-1,        //SIGNAL EXIT SELL
   SIGNAL_EXIT_ALL=2,         //SIGNAL EXIT ALL
};

ENUM_SIGNAL_ENTRY SignalEntry = SIGNAL_ENTRY_NEUTRAL; // Entry signal variable
ENUM_SIGNAL_EXIT SignalExit=SIGNAL_EXIT_NEUTRAL;         //Exit signal variable

bool IsNewCandle_Include=false;                   //Indicates if this is a new candle formed

//-INPUT PARAMETERS-//
// The input parameters are the ones that can be set by the user when launching the EA
// If you place a comment following the input variable this will be shown as description of the field

//********************************************************************************************************

// THIS IS WHERE YOU SHOULD INCLUDE THE INPUT PARAMETERS FOR YOUR ENTRY AND EXIT SIGNALS

input string Comment_strategy = "=========="; // Risk Management Settings

// used in EvaluateEntry(), EvaluateExit()

input int MAFastPeriod = 10;                             // Fast MA Period, found settings
//input int MAFastPeriod = 15;                               // Fast MA Period, duto settings

input int MAFastShift = 0;                                 // Fast MA Shift

input ENUM_MA_METHOD MAFastMethod = MODE_SMA;              // Fast MA Method, found settings
//input ENUM_MA_METHOD MAFastMethod = MODE_SMMA;              // Fast MA Method, duto settings

//input ENUM_APPLIED_PRICE MAFastAppliedPrice = PRICE_WEIGHTED; // Fast MA Applied Price, duto settings
input ENUM_APPLIED_PRICE MAFastAppliedPrice = PRICE_CLOSE; // Fast MA Applied Price, found settings

input int MASlowPeriod = 25;                               // Slow MA Period
input int MASlowShift = 0;                                 // Slow MA Shift

input ENUM_MA_METHOD MASlowMethod = MODE_SMA;              // Slow MA Method, found settings
//input ENUM_MA_METHOD MASlowMethod = MODE_SMMA;              // Slow MA Method, duto settings

//input ENUM_APPLIED_PRICE MASlowAppliedPrice = PRICE_MEDIAN; // Slow MA Applied Price, duto settings
input ENUM_APPLIED_PRICE MASlowAppliedPrice = PRICE_CLOSE; // Slow MA Applied Price, found settings

// used in ExecuteTrailingStop(), StopLossPriceCalculate()
//input double PSARStopStep = 0.04; // Stop Loss PSAR Step
//input double PSARStopMax = 0.4;   // Stop Loss PSAR Max

// THIS IS WHERE YOU SHOULD INCLUDE THE INPUT PARAMETERS FOR YOUR ENTRY AND EXIT SIGNALS

//********************************************************************************************************

//for early testing to make sure the include file can be reached
void PrintTestToMACrossoverInclude()
{
   Print("Printed from the include file yo.");
}

//chart indicator history arrays
double FastMAHistoryBuffer[], SlowMAHistoryBuffer[], FiveFiftyMAHistoryBuffer[], DeltaCollapsedPosHistoryBuffer[], DeltaCollapsedNegHistoryBuffer[];
//MACD indicator history arrays
double MacdHistoryBuffer[],  MacdPlot2HistoryBuffer[], MacdPlot3HistoryBuffer[], MacdPlot4HistoryBuffer[];

void LogIndicatorData()
{
   //indicator testing
   string indicatorName = "_Custom\\Duto\\macd_color_indicator_plot1_v0.9";
   string duto_chart_indicators = "_Custom\\Duto\\duto_chart_indicators_v0.5";
   string duto_chart_moving_averages = "_Custom\\Duto\\duto_mas";
   string duto_chart_deltas = "_Custom\\Duto\\delta_v0.1";
   string strWriteLine, strWriteLine2 = "";
   int fileHandleIndicatorData;
   int periodArray[] = {60, 15, 5};
   
   //if the file exists, then delete it so only the most recent data is included
   if (FileIsExist("duto_indicator_data.csv")) {

      FileDelete("duto_indicator_data.csv");
   } 

   //open the file
   fileHandleIndicatorData = FileOpen("duto_indicator_data.csv", FILE_BIN | FILE_READ | FILE_WRITE | FILE_CSV);

   if (fileHandleIndicatorData < 1)
   {
      Print("can't open file error-", GetLastError());
      //return (0);
   }

   FileSeek(fileHandleIndicatorData, 0, SEEK_END);

   ArrayResize(FastMAHistoryBuffer, Bars + 1);
   ArrayResize(SlowMAHistoryBuffer, Bars + 1);
   ArrayResize(FiveFiftyMAHistoryBuffer, Bars + 1);
   ArrayResize(DeltaCollapsedPosHistoryBuffer, Bars + 1);
   ArrayResize(DeltaCollapsedNegHistoryBuffer, Bars + 1);

   ArrayResize(MacdHistoryBuffer, Bars + 1);
   ArrayResize(MacdPlot2HistoryBuffer, Bars + 1);
   ArrayResize(MacdPlot3HistoryBuffer, Bars + 1);
   ArrayResize(MacdPlot4HistoryBuffer, Bars + 1);

   //strWriteLine = "Look at candle 1 to compare history.  Candle 0 is unreliable for history because it is currently being built.\r\n";
   //FileWriteString(fileHandleIndicatorData, strWriteLine, StringLen(strWriteLine));

   strWriteLine = 
         "Candle Index"
         //+ ",Period " + Period()
         + ",Period H1"

         + ",FastMAHistoryBuffer H1"
         + ",SlowMAHistoryBuffer H1"
         + ",FiveFiftyMAHistoryBuffer H1"
         //+ ",DeltaCollapsedPosHistoryBuffer"
         //+ ",DeltaCollapsedNegHistoryBuffer"
         + ",DeltaCollapsedHistoryBuffer H1"
         + ",MacdHistoryBuffer H1"
         + ",MacdPlot2HistoryBuffer H1"
         + ",MacdPlot3HistoryBuffer H1"
         + ",MacdPlot4HistoryBuffer H1"

         + ",Candle Index"
         + ",Period M15"

         + ",FastMAHistoryBuffer M15"
         + ",SlowMAHistoryBuffer M15"
         + ",FiveFiftyMAHistoryBuffer M15"
         //+ ",DeltaCollapsedPosHistoryBuffer"
         //+ ",DeltaCollapsedNegHistoryBuffer"
         + ",DeltaCollapsedHistoryBuffer M15"

         + ",MacdHistoryBuffer M15"
         + ",MacdPlot2HistoryBuffer M15"
         + ",MacdPlot3HistoryBuffer M15"
         + ",MacdPlot4HistoryBuffer M15"

         + ",Candle Index"

         + ",Period M5"

         + ",FastMAHistoryBuffer M5"
         + ",SlowMAHistoryBuffer M5"
         + ",FiveFiftyMAHistoryBuffer M5"
         //+ ",DeltaCollapsedPosHistoryBuffer"
         //+ ",DeltaCollapsedNegHistoryBuffer"
         + ",DeltaCollapsedHistoryBuffer M5"

         + ",MacdHistoryBuffer M5"
         + ",MacdPlot2HistoryBuffer M5"
         + ",MacdPlot3HistoryBuffer M5"
         + ",MacdPlot4HistoryBuffer M5"
         
         + "\r\n";

   FileWriteString(fileHandleIndicatorData, strWriteLine, StringLen(strWriteLine));

   //reset strWriteLine
   //strWriteLine = "";
   //Print("ArraySize(periodArray): " + ArraySize(periodArray));

   for (int i = 0; i <= Bars; i++)
      {
         //build a line of data
         //60
         FastMAHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 0, i);
         SlowMAHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 1, i);
         FiveFiftyMAHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 4, i);

         DeltaCollapsedPosHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 5, i);
         DeltaCollapsedNegHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 6, i);

         MacdHistoryBuffer[i] = iCustom(Symbol(),60, indicatorName, 0, i);
         MacdPlot2HistoryBuffer[i] = iCustom(Symbol(),60, indicatorName, 1, i);
         MacdPlot3HistoryBuffer[i] = iCustom(Symbol(),60, indicatorName, 2, i);
         MacdPlot4HistoryBuffer[i] = iCustom(Symbol(),60, indicatorName, 3, i);

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {

            strWriteLine2 = ",Negative";
         }
         else {
            strWriteLine2 = ",Positive";
         }

         //build a line of strings based on a line of data
         strWriteLine = 
         "Candle " + i
         + "," + iTime(Symbol(), 60, i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 6)
         + "";

         //build a line of data
         //15
         FastMAHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 0, i);
         SlowMAHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 1, i);
         FiveFiftyMAHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 4, i);

         DeltaCollapsedPosHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 5, i);
         DeltaCollapsedNegHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 6, i);

         MacdHistoryBuffer[i] = iCustom(Symbol(),15, indicatorName, 0, i);
         MacdPlot2HistoryBuffer[i] = iCustom(Symbol(),15, indicatorName, 1, i);
         MacdPlot3HistoryBuffer[i] = iCustom(Symbol(),15, indicatorName, 2, i);
         MacdPlot4HistoryBuffer[i] = iCustom(Symbol(),15, indicatorName, 3, i);

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {

            strWriteLine2 = ",Negative";
         }
         else {
            strWriteLine2 = ",Positive";
         }

         //build a line of strings based on a line of data
         strWriteLine = strWriteLine +
         ",Candle " + i
         + "," + iTime(Symbol(), 15, i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 6)
         + "";

         //build a line of data
         //5
         FastMAHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 0, i);
         SlowMAHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 1, i);
         FiveFiftyMAHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 4, i);

         DeltaCollapsedPosHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 5, i);
         DeltaCollapsedNegHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 6, i);

         MacdHistoryBuffer[i] = iCustom(Symbol(),5, indicatorName, 0, i);
         MacdPlot2HistoryBuffer[i] = iCustom(Symbol(),5, indicatorName, 1, i);
         MacdPlot3HistoryBuffer[i] = iCustom(Symbol(),5, indicatorName, 2, i);
         MacdPlot4HistoryBuffer[i] = iCustom(Symbol(),5, indicatorName, 3, i);

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {

            strWriteLine2 = ",Negative";
         }
         else {
            strWriteLine2 = ",Positive";
         }

         //build a line of strings based on a line of data
         strWriteLine = strWriteLine +
         ",Candle " + i
         + "," + iTime(Symbol(), 5, i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 6)

         /* //build a line of data
         FastMAHistoryBuffer[i] = iCustom(Symbol(),Period(), duto_chart_indicators, 0, i);
         SlowMAHistoryBuffer[i] = iCustom(Symbol(),Period(), duto_chart_indicators, 1, i);
         FiveFiftyMAHistoryBuffer[i] = iCustom(Symbol(),Period(), duto_chart_indicators, 4, i);

         DeltaCollapsedPosHistoryBuffer[i] = iCustom(Symbol(),Period(), duto_chart_indicators, 5, i);
         DeltaCollapsedNegHistoryBuffer[i] = iCustom(Symbol(),Period(), duto_chart_indicators, 6, i);

         MacdHistoryBuffer[i] = iCustom(Symbol(),Period(), indicatorName, 0, i);
         MacdPlot2HistoryBuffer[i] = iCustom(Symbol(),Period(), indicatorName, 1, i);
         MacdPlot3HistoryBuffer[i] = iCustom(Symbol(),Period(), indicatorName, 2, i);
         MacdPlot4HistoryBuffer[i] = iCustom(Symbol(),Period(), indicatorName, 3, i);

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {

            strWriteLine2 = ",Negative";
         }
         else {
            strWriteLine2 = ",Positive";
         }

         //build a line of strings based on a line of data
         strWriteLine = 
         "Candle " + i
         + "," + iTime(Symbol(), Period(), i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 6)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 6) */
         
         + "\r\n";

         //write a line of strings to a file
         FileWriteString(fileHandleIndicatorData, strWriteLine, StringLen(strWriteLine));

         //in work
         /* //for each period in the array...
         //for (int periodArrayIndex = 0; periodArrayIndex <= ArraySize(periodArray); periodArrayIndex++)
         for (int periodArrayIndex = 0; periodArrayIndex <= 3; periodArrayIndex++)
         {
            Print("periodArray: " + periodArray[periodArrayIndex]);
            //Print("yo");

            //build a line of data
            FastMAHistoryBuffer[i] = iCustom(Symbol(),periodArrayIndex, duto_chart_indicators, 0, i);
            SlowMAHistoryBuffer[i] = iCustom(Symbol(),periodArrayIndex, duto_chart_indicators, 1, i);
            FiveFiftyMAHistoryBuffer[i] = iCustom(Symbol(),periodArrayIndex, duto_chart_indicators, 4, i);

            DeltaCollapsedPosHistoryBuffer[i] = iCustom(Symbol(),periodArrayIndex, duto_chart_indicators, 5, i);
            DeltaCollapsedNegHistoryBuffer[i] = iCustom(Symbol(),periodArrayIndex, duto_chart_indicators, 6, i);

            MacdHistoryBuffer[i] = iCustom(Symbol(),periodArrayIndex, indicatorName, 0, i);
            MacdPlot2HistoryBuffer[i] = iCustom(Symbol(),periodArrayIndex, indicatorName, 1, i);
            MacdPlot3HistoryBuffer[i] = iCustom(Symbol(),periodArrayIndex, indicatorName, 2, i);
            MacdPlot4HistoryBuffer[i] = iCustom(Symbol(),periodArrayIndex, indicatorName, 3, i);

            if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {

               strWriteLine2 = ",Negative";
            }
            else {
               strWriteLine2 = ",Positive";
            }

            //build a line of strings based on a line of data
            strWriteLine = 
            "Candle " + i
            + "," + iTime(Symbol(), periodArrayIndex, i) 

            + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
            + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
            + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

            + strWriteLine2
            
            + "," + DoubleToString(MacdHistoryBuffer[i], 6)
            + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 6)
            + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 6)
            + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 6)
            + "";
         } */

         //strWriteLine = strWriteLine + "\r\n";
         //write a line of strings to a file
         //FileWriteString(fileHandleIndicatorData, strWriteLine, StringLen(strWriteLine));
         //in work
      }  

   FileClose(fileHandleIndicatorData); 
}

ENUM_SIGNAL_ENTRY ReturnSignalEntryToEvaluateEntry()
{
   //indicator testing
   //string indicatorName = "_Custom\\Duto\\macd_color_indicator_plot1_v0.8";
   //string duto_chart_indicators = "_Custom\\Duto\\duto_chart_indicators_v0.5";
   //string duto_chart_moving_averages = "_Custom\\Duto\\duto_mas";
   //string duto_chart_deltas = "_Custom\\Duto\\delta_v0.1";

   //double MacdHistoryBuffer[];

   //MACD value
   //double macd_color_indicator_pl1 = iCustom(Symbol(),Period(), indicatorName, 6, 1);
   //Print("macd_color_indicator_pl1 current value: " + macd_color_indicator_pl1);

   //double DeltaCollapsedPosBuffer_curr = iCustom(Symbol(),Period(), duto_chart_indicators, 5, 1);
   //double DeltaCollapsedPosBuffer_prev = iCustom(Symbol(),Period(), duto_chart_indicators, 5, 2);

   //Print("Number of bars in this chart: "+ Bars);
   
   CheckNewBar_Include();
   if (IsNewCandle_Include) {

      LogIndicatorData();

      /*
      ArrayResize(MacdHistoryBuffer, Bars + 1);
      Print("MacdHistoryBuffer has been re-sized to: " + ArraySize(MacdHistoryBuffer));
  
      for (int i = Bars; i >= 0; i--)
      {
         MacdHistoryBuffer[i] = iCustom(Symbol(),Period(), indicatorName, 6, i);

         Print("MacdHistoryBuffer[" + i + "]:" + MacdHistoryBuffer[i]);
      } 
      */ 
   }
   
   // Declaring the variables for the entry and exit check
   SignalExit=SIGNAL_EXIT_NEUTRAL;

   /*

   double MASlowPrev = iMA(Symbol(), PERIOD_CURRENT, MASlowPeriod, MASlowShift, MASlowMethod, MASlowAppliedPrice, 1);
   double MASlowCurr = iMA(Symbol(), PERIOD_CURRENT, MASlowPeriod, MASlowShift, MASlowMethod, MASlowAppliedPrice, 0);
   double MAFastPrev = iMA(Symbol(), PERIOD_CURRENT, MAFastPeriod, MAFastShift, MAFastMethod, MAFastAppliedPrice, 1);
   double MAFastCurr = iMA(Symbol(), PERIOD_CURRENT, MAFastPeriod, MAFastShift, MAFastMethod, MAFastAppliedPrice, 0);

   // This is where you should insert your Entry Signal for BUY orders
   // Include a condition to open a buy order, the condition will have to set SignalEntry=SIGNAL_ENTRY_BUY
   if (MAFastPrev < MASlowPrev && MAFastCurr > MASlowCurr)
   {
      Print("macd_color_indicator_pl1 one candle back, value 5 ENTRY, buy: " + NormalizeDouble(macd_color_indicator_pl1, 6));

      SignalEntry = SIGNAL_ENTRY_BUY;     
   }

   // This is where you should insert your Entry Signal for SELL orders
   // Include a condition to open a sell order, the condition will have to set SignalEntry=SIGNAL_ENTRY_SELL
   if (MAFastPrev > MASlowPrev && MAFastCurr < MASlowCurr)
   {
      Print("macd_color_indicator_pl1 one candle back, value 5 ENTRY, sell: " + NormalizeDouble(macd_color_indicator_pl1, 6));

      SignalEntry = SIGNAL_ENTRY_SELL;
   }

   */

  //buy
  //if (DeltaCollapsedPosBuffer_curr != 2147483647 && DeltaCollapsedPosBuffer_prev == 2147483647) {
      //Print("A change from red to green has occured.");
      //SignalEntry = SIGNAL_ENTRY_BUY;

   //}
      
   //Print("return signal entry from ReturnSignalEntryToEvaluateEntry() in the include file.");
   //Print("macd_color_indicator_pl1 ENTRY: " + macd_color_indicator_pl1);

   return SignalEntry;
}

ENUM_SIGNAL_ENTRY ReturnSignalExitToEvaluateExit()

{
   //indicator testing
   string indicatorName = "_Custom\\Duto\\macd_color_indicator_plot1_v0.8";
   string duto_chart_indicators = "_Custom\\Duto\\duto_chart_indicators_v0.5";
   string duto_chart_moving_averages = "_Custom\\Duto\\duto_mas";
   string duto_chart_deltas = "_Custom\\Duto\\delta_v0.1";

   //yellow line value
   //double macd_color_indicator_pl1 = iCustom(Symbol(),Period(), indicatorName, 12, 26, 9, 4, 1);

   //duto chart indicators
   //double duto_chart_indicators_value = iCustom(Symbol(),Period(), duto_chart_indicators, 15, 25, 20, 30, 0, 1);
   //double duto_chart_indicators_value = iCustom(Symbol(),Period(), duto_chart_indicators, 15, 25, 20, 30, 0, 1);
   //double duto_chart_indicators_value = iCustom(Symbol(),Period(), duto_chart_indicators, 15, 25, 20, 30, 60, 13, 0, 100, 0, 1);

   //double DeltaCollapsedPosBuffer_curr = iCustom(Symbol(),Period(), duto_chart_indicators, 5, 1);
   //Print("DeltaCollapsedPosBuffer_curr value to 5 is: " + NormalizeDouble(DeltaCollapsedPosBuffer_curr, 5));

   //double DeltaCollapsedPosBuffer_prev = iCustom(Symbol(),Period(), duto_chart_indicators, 5, 2);
   //Print("DeltaCollapsedPosBuffer_prev value to 5 is: " + NormalizeDouble(DeltaCollapsedPosBuffer_prev, 5));

   //double duto_chart_moving_averages_value = iCustom(Symbol(),Period(), duto_chart_moving_averages, 15, 25, 0, 1);
   //double duto_chart_deltas_value = iCustom(Symbol(),Period(), duto_chart_deltas, 60, 13, 0, 100, 0, 1);
   
   // Declaring the variables for the entry and exit check
   SignalExit=SIGNAL_EXIT_NEUTRAL;

   /*

   double MASlowPrev=iMA(Symbol(),PERIOD_CURRENT,MASlowPeriod,MASlowShift,MASlowMethod,MASlowAppliedPrice,1);
   double MASlowCurr=iMA(Symbol(),PERIOD_CURRENT,MASlowPeriod,MASlowShift,MASlowMethod,MASlowAppliedPrice,0);
   double MAFastPrev=iMA(Symbol(),PERIOD_CURRENT,MAFastPeriod,MAFastShift,MAFastMethod,MAFastAppliedPrice,1);
   double MAFastCurr=iMA(Symbol(),PERIOD_CURRENT,MAFastPeriod,MAFastShift,MAFastMethod,MAFastAppliedPrice,0);

   //This is where you should include your exit signal for BUY orders
   //If you want, include a condition to close the open buy orders, condition will have to set SignalExit=SIGNAL_EXIT_BUY then return 
   if(MAFastPrev>MASlowPrev && MAFastCurr<MASlowCurr)
   {
      Print("macd_color_indicator_pl1 one candle back, value 5 EXIT, buy: " + NormalizeDouble(macd_color_indicator_pl1, 6));
      SignalExit=SIGNAL_EXIT_BUY;
   }
    
   //This is where you should include your exit signal for SELL orders
   //If you want, include a condition to close the open sell orders, condition will have to set SignalExit=SIGNAL_EXIT_SELL then return 
   if(MAFastPrev<MASlowPrev && MAFastCurr>MASlowCurr)
   {
      Print("macd_color_indicator_pl1 one candle back, value 5 EXIT, sell: " + NormalizeDouble(macd_color_indicator_pl1, 6));
      SignalExit=SIGNAL_EXIT_SELL;
   } 

   */

   return SignalEntry;
}

//Check if it is a new bar
datetime NewBarTime_Include=TimeCurrent();
void CheckNewBar_Include(){
   //NewBarTime contains the open time of the last bar known
   //if that open time is the same as the current bar then we are still in the current bar, otherwise we are in a new bar
   if(NewBarTime_Include==Time[0]) IsNewCandle_Include=false;
   else{
      NewBarTime_Include=Time[0];
      IsNewCandle_Include=true;
   }
}


   



